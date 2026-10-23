import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, Curves, Widget;
import 'package:flutter/services.dart' show rootBundle;

import '../../core/audio/audio_service.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'genius_config.dart';
import 'genius_dialog.dart';
import 'genius_hud.dart';
import 'genius_models.dart';
import 'question_bank.dart';

LevelGame createGeniusGame(LevelSession session) => GeniusGame(session);

/// Level 2: Bob the Genius - kuis pengetahuan dengan time bar.
/// Alur step: jawab benar [targetCorrect] kali untuk menang; salah atau
/// kehabisan waktu mengurangi nyawa; nyawa habis = kalah.
class GeniusGame extends LevelGame {
  GeniusGame(super.session, {Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<Question?> question = ValueNotifier(null);
  final ValueNotifier<AnswerFeedback?> feedback = ValueNotifier(null);
  final ValueNotifier<StepProgress> progress =
      ValueNotifier(const StepProgress.empty());

  /// Bertambah setiap jawaban salah / telat; memicu efek getar + kilat di HUD.
  final ValueNotifier<int> wrongCount = ValueNotifier(0);

  /// Kalimat Bob yang sedang tampil di gelembung ucapan (null = sembunyi).
  final ValueNotifier<String?> bossSay = ValueNotifier(null);

  int _lastTick = -1;
  int _sayToken = 0;
  String? _lastLine;
  String? _resultLine;

  late final BossComponent _boss;
  late final TimeBarComponent _timeBar;
  bool _ready = false;

  late StepConfig _config;
  late final QuestionBank _bank;
  List<QuizItem> _pool = [];
  String? _lastCategory;
  int _correct = 0;
  int _lives = 0;
  double _timeLeft = 0;
  bool _awaiting = false;

  @override
  List<String> get assetPaths => const [
        'genius/boss_idle.png',
        'genius/boss_shock.png',
        'genius/boss_laugh.png',
        'genius/boss_defeat.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFFFFEBEE);

  @override
  Widget buildHud(BuildContext context) => GeniusHud(game: this);

  @override
  Future<void> onLoad() async {
    _bank = QuestionBank.parse(await rootBundle.loadString(QuestionBank.assetPath));
    await loadAssets();
    Sprite spriteOf(String file) =>
        Sprite(levelImages.fromCache('genius/$file.png'));
    _boss = BossComponent(
      sprites: {
        BossMood.idle: spriteOf('boss_idle'),
        BossMood.shock: spriteOf('boss_shock'),
        BossMood.laugh: spriteOf('boss_laugh'),
        BossMood.defeat: spriteOf('boss_defeat'),
      },
    );
    _timeBar = TimeBarComponent();
    await addAll([_boss, _timeBar]);
    _ready = true;
    _layout(size);
    startStep(session.step);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _layout(size);
  }

  void _layout(Vector2 s) {
    final side = min(s.x * 0.5, s.y * ArenaLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(
      s.x * ArenaLayout.bossCenterX,
      s.y * ArenaLayout.bossCenterY,
    );
    _timeBar.size = Vector2(s.x - 32, 14);
    _timeBar.position = Vector2(16, s.y * ArenaLayout.timeBarY);
  }

  @override
  void startStep(int step) {
    _config = geniusSteps[step - 1];
    _pool = List.of(_bank.forStep(step))..shuffle(_rng);
    _lastCategory = null;
    _correct = 0;
    _lives = _config.lives;
    _publishProgress();
    _boss.setMood(BossMood.idle);
    _say(GeniusDialog.stepIntro[step - 1], seconds: 2.6);
    _nextQuestion();
  }

  void _publishProgress() {
    progress.value = StepProgress(
      correct: _correct,
      target: _config.targetCorrect,
      lives: _lives,
      maxLives: _config.lives,
    );
  }

  void _nextQuestion() {
    final item = _takeNext();
    feedback.value = null;
    question.value = item.toQuestion(_rng);
    _timeLeft = _config.secondsPerQuestion;
    _timeBar.fraction = 1;
    _lastTick = -1;
    _awaiting = true;
  }

  @override
  String? resultMessage() => _resultLine;

  /// Tampilkan kalimat Bob di gelembung ucapan selama [seconds] detik.
  void _say(String line, {double seconds = 2.2}) {
    final token = ++_sayToken;
    bossSay.value = line;
    add(TimerComponent(
      period: seconds,
      removeOnFinish: true,
      onTick: () {
        if (token == _sayToken) bossSay.value = null;
      },
    ));
  }

  /// Pilih kalimat acak, hindari mengulang kalimat yang sama berturut-turut.
  String _pick(List<String> lines) {
    if (lines.length == 1) return lines.first;
    String line;
    do {
      line = lines[_rng.nextInt(lines.length)];
    } while (line == _lastLine);
    _lastLine = line;
    return line;
  }

  /// Ambil soal berikutnya; hindari kategori yang sama berturut-turut jika bisa.
  QuizItem _takeNext() {
    if (_pool.isEmpty) {
      _pool = List.of(_bank.forStep(session.step))..shuffle(_rng);
    }
    var index = _pool.length - 1;
    for (var i = _pool.length - 1; i >= 0; i--) {
      if (_pool[i].category != _lastCategory) {
        index = i;
        break;
      }
    }
    final item = _pool.removeAt(index);
    _lastCategory = item.category;
    return item;
  }

  /// Dipanggil HUD saat pemain memilih jawaban.
  void answer(int index) {
    final q = question.value;
    if (!_awaiting || q == null || !session.isPlaying) return;
    _awaiting = false;
    _resolve(chosen: index, correct: q.correctIndex);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_awaiting) return;
    _timeLeft -= dt;
    _timeBar.fraction = _timeLeft / _config.secondsPerQuestion;
    final secondsLeft = _timeLeft.ceil();
    if (secondsLeft > 0 && secondsLeft <= 3 && secondsLeft != _lastTick) {
      _lastTick = secondsLeft;
      AudioService.instance.play(Sfx.tick);
    }
    if (_timeLeft <= 0) {
      _awaiting = false;
      _resolve(chosen: -1, correct: question.value!.correctIndex);
    }
  }

  void _resolve({required int chosen, required int correct}) {
    final ok = chosen == correct;
    feedback.value = AnswerFeedback(chosen: chosen, correct: correct);
    if (ok) {
      _boss.flinch();
      _boss.setMood(BossMood.shock, revertAfter: 0.9);
      _say(_pick(GeniusDialog.correct));
      AudioService.instance.play(Sfx.correct);
    } else {
      _boss.laugh();
      _boss.setMood(BossMood.laugh, revertAfter: 0.9);
      _say(_pick(chosen < 0 ? GeniusDialog.timeout : GeniusDialog.wrong));
      wrongCount.value++;
      AudioService.instance.play(Sfx.wrong);
    }

    // Jeda singkat agar pemain melihat benar/salah. Berhenti otomatis saat pause.
    add(TimerComponent(
      period: 0.8,
      removeOnFinish: true,
      onTick: () {
        if (ok) {
          _correct++;
        } else {
          _lives--;
        }
        _publishProgress();

        if (ok && _correct >= _config.targetCorrect) {
          _finishStep(won: true);
        } else if (!ok && _lives <= 0) {
          _finishStep(won: false);
        } else {
          _nextQuestion();
        }
      },
    ));
  }

  void _finishStep({required bool won}) {
    question.value = null;
    feedback.value = null;

    _sayToken++;
    bossSay.value = null;

    // Kalimat hasil harus siap SEBELUM session berubah (listener layar membacanya).
    if (!won) {
      _resultLine = _pick(GeniusDialog.resultByStars[session.stepsWon]);
      _boss.setMood(BossMood.laugh);
      AudioService.instance.play(Sfx.lose);
      session.loseStep();
      return;
    }
    if (session.step >= StarCalculator.totalSteps) {
      _resultLine =
          _pick(GeniusDialog.resultByStars[StarCalculator.totalSteps]);
      _boss.setMood(BossMood.defeat);
    }
    session.winStep();
    AudioService.instance.play(session.isPlaying ? Sfx.stepUp : Sfx.win);
    if (session.isPlaying) {
      // Jeda singkat lalu lanjut otomatis ke step berikutnya.
      add(TimerComponent(
        period: 1.2,
        removeOnFinish: true,
        onTick: () => startStep(session.step),
      ));
    }
  }
}

enum BossMood { idle, shock, laugh, defeat }

/// TODO(art): ganti gambar boss_*.png di assets/images/genius/ dengan art final (cukup overwrite).
class BossComponent extends SpriteComponent {
  BossComponent({required Map<BossMood, Sprite> sprites})
      : _sprites = sprites,
        super(sprite: sprites[BossMood.idle], anchor: Anchor.center);

  final Map<BossMood, Sprite> _sprites;
  int _moodToken = 0;

  @override
  Future<void> onLoad() async {
    add(MoveEffect.by(
      Vector2(0, 6),
      EffectController(
        duration: 0.9,
        alternate: true,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));
  }

  /// Ganti ekspresi; jika [revertAfter] diisi, kembali ke idle setelah jeda itu.
  void setMood(BossMood mood, {double? revertAfter}) {
    sprite = _sprites[mood];
    final token = ++_moodToken;
    if (revertAfter != null) {
      add(TimerComponent(
        period: revertAfter,
        removeOnFinish: true,
        onTick: () {
          if (token == _moodToken) sprite = _sprites[BossMood.idle];
        },
      ));
    }
  }

  void flinch() {
    add(ScaleEffect.by(
      Vector2.all(0.9),
      EffectController(duration: 0.08, alternate: true),
    ));
  }

  /// Bob menertawakan jawaban salah.
  void laugh() {
    add(ScaleEffect.by(
      Vector2.all(1.12),
      EffectController(duration: 0.12, alternate: true, repeatCount: 2),
    ));
  }
}

class TimeBarComponent extends PositionComponent {
  double fraction = 1;

  final Paint _bg = Paint()..color = const Color(0xFFBDBDBD);
  final Paint _fill = Paint()..color = const Color(0xFF1976D2);
  final Paint _danger = Paint()..color = const Color(0xFFD32F2F);

  @override
  void render(Canvas canvas) {
    final f = fraction.clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bg);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * f, size.y),
      f > 0.3 ? _fill : _danger,
    );
  }
}
