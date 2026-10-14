import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, Curves, Widget;
import 'package:flutter/services.dart' show rootBundle;

import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import 'genius_config.dart';
import 'genius_hud.dart';
import 'genius_models.dart';
import 'question_bank.dart';

LevelGame createGeniusGame(LevelSession session) => GeniusGame(session);

/// Level 1: Bob the Genius - kuis pengetahuan dengan time bar.
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
  List<String> get assetPaths => const ['genius/boss.png'];

  @override
  Color backgroundColor() => const Color(0xFFFFEBEE);

  @override
  Widget buildHud(BuildContext context) => GeniusHud(game: this);

  @override
  Future<void> onLoad() async {
    _bank = QuestionBank.parse(await rootBundle.loadString(QuestionBank.assetPath));
    await loadAssets();
    _boss = BossComponent(
      sprite: Sprite(levelImages.fromCache('genius/boss.png')),
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
    final side = min(s.x * 0.6, s.y * ArenaLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x / 2, s.y * ArenaLayout.bossCenterY);
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
    _awaiting = true;
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
    if (_timeLeft <= 0) {
      _awaiting = false;
      _resolve(chosen: -1, correct: question.value!.correctIndex);
    }
  }

  void _resolve({required int chosen, required int correct}) {
    final ok = chosen == correct;
    feedback.value = AnswerFeedback(chosen: chosen, correct: correct);
    if (ok) _boss.flinch();

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

    if (!won) {
      session.loseStep();
      return;
    }
    session.winStep();
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

/// TODO(art): ganti assets/images/genius/boss.png dengan art final (cukup overwrite).
class BossComponent extends SpriteComponent {
  BossComponent({required Sprite sprite})
      : super(sprite: sprite, anchor: Anchor.center);

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

  void flinch() {
    add(ScaleEffect.by(
      Vector2.all(0.9),
      EffectController(duration: 0.08, alternate: true),
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
