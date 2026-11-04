import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, Widget;
import 'package:flutter/services.dart' show HapticFeedback;

import '../../core/audio/audio_service.dart';
import '../../core/level/boss_sprite.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'cooking_checks.dart';
import 'cooking_config.dart';
import 'cooking_dialog.dart';
import 'cooking_hud.dart';
import 'cooking_models.dart';

LevelGame createCookingGame(LevelSession session) => CookingGame(session);

enum _Phase { intro, playing, done }

/// Perubahan waktu (penalti negatif atau bonus positif) untuk popup "-3s" di HUD.
class TimeEvent {
  const TimeEvent(this.id, this.seconds);

  final int id;
  final int seconds;
}

/// Level 4: Cooking Champion. Tiap step ada satu pesanan acak: geser bahan dari baki ke stasiun
/// yang tepat (Talenan, Panci, Wajan), lalu selesaikan cooking check di stasiun itu.
/// Salah stasiun atau gagal masak mengurangi waktu; semua bahan selesai = menang; waktu habis = kalah.
class CookingGame extends LevelGame {
  CookingGame(super.session, {Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<int> secondsLeft = ValueNotifier(0);
  final ValueNotifier<bool> showBanner = ValueNotifier(false);
  final ValueNotifier<Order?> order = ValueNotifier(null);
  final ValueNotifier<List<String>> tray = ValueNotifier(const []);
  final ValueNotifier<Set<String>> done = ValueNotifier(const {});
  final ValueNotifier<CookingCheck?> activeCheck = ValueNotifier(null);

  /// Naik tiap frame selama ada check aktif (HUD panel check menggambar ulang).
  final ValueNotifier<int> checkTick = ValueNotifier(0);
  final ValueNotifier<TimeEvent?> timeEvent = ValueNotifier(null);

  /// Naik tiap kesalahan; memicu getar + kilat merah di HUD.
  final ValueNotifier<int> wrongCount = ValueNotifier(0);

  late final _KitchenBackground _background;
  late final BossSprite _chef;
  late final LevelTimeBar _timeBar;
  bool _ready = false;

  late CookingStepConfig _config;
  _Phase _phase = _Phase.done;
  double _timeLeft = 0;
  double _introLeft = 0;
  String? _checkingId;
  Recipe? _lastRecipe;
  int _eventId = 0;
  int _lastTick = -1;
  bool _hurried = false;
  int _sayToken = 0;
  String? _lastLine;
  String? _resultLine;

  /// Bahan yang sedang dikerjakan di cooking check (untuk judul panel).
  String? get checkingId => _checkingId;

  /// true jika pemain boleh menjatuhkan bahan ke stasiun sekarang.
  bool get canAct => _phase == _Phase.playing && session.isPlaying && activeCheck.value == null;

  @override
  List<String> get assetPaths => const [
        'cooking/kitchen_bg.png',
        'cooking/boss_idle.png',
        'cooking/boss_shock.png',
        'cooking/boss_laugh.png',
        'cooking/boss_defeat.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFFFFF3E0);

  @override
  Widget buildHud(BuildContext context) => CookingHud(game: this);

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Sprite spriteOf(String file) => Sprite(levelImages.fromCache('cooking/$file.png'));
    _background = _KitchenBackground(levelImages.fromCache('cooking/kitchen_bg.png'));
    _chef = BossSprite(
      sprites: {
        BossExpression.idle: spriteOf('boss_idle'),
        BossExpression.shock: spriteOf('boss_shock'),
        BossExpression.laugh: spriteOf('boss_laugh'),
        BossExpression.defeat: spriteOf('boss_defeat'),
      },
    );
    _timeBar = LevelTimeBar();
    await addAll([_background, _chef, _timeBar]);
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
    _background.size = s;
    final side = min(s.x * 0.5, s.y * CookingLayout.bossHeight);
    _chef.size = Vector2.all(side);
    _chef.position = Vector2(s.x * CookingLayout.bossCenterX, s.y * CookingLayout.bossCenterY);
    _timeBar.size = Vector2(s.x - 2 * CookingLayout.sideMargin, 14);
    _timeBar.position = Vector2(CookingLayout.sideMargin, s.y * CookingLayout.timeBarY);
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) {
    _config = cookingSteps[step - 1];
    final (newOrder, trayIds) = OrderFactory.create(
      _rng,
      count: _config.ingredients,
      decoys: _config.decoys,
      avoid: _lastRecipe,
    );
    _lastRecipe = newOrder.recipe;
    order.value = newOrder;
    tray.value = trayIds;
    done.value = const {};
    activeCheck.value = null;
    _checkingId = null;

    _timeLeft = _config.seconds.toDouble();
    _timeBar.fraction = 1;
    secondsLeft.value = _config.seconds;
    _lastTick = -1;
    _hurried = false;

    _phase = _Phase.intro;
    _introLeft = CookingTuning.introSeconds;
    showBanner.value = true;

    _chef.setExpression(BossExpression.idle);
    _say(CookingDialog.stepIntro[step - 1], seconds: 2.6);
  }

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

  String _pick(List<String> lines) {
    if (lines.length == 1) return lines.first;
    String line;
    do {
      line = lines[_rng.nextInt(lines.length)];
    } while (line == _lastLine);
    _lastLine = line;
    return line;
  }

  void _adjustTime(double delta) {
    _timeLeft += delta;
    secondsLeft.value = max(0, _timeLeft.ceil());
    timeEvent.value = TimeEvent(++_eventId, delta.round());
  }

  // ---------------- input dari HUD ----------------
  /// Bahan [id] dijatuhkan ke stasiun [station].
  void drop(String id, Station station) {
    final o = order.value;
    if (!canAct || o == null) return;
    final ingredient = ingredientById(id);
    final needed = o.needs(id) && !done.value.contains(id);
    if (!needed || ingredient.station != station) {
      _wrong();
      return;
    }
    tray.value = [
      for (final t in tray.value)
        if (t != id) t,
    ];
    _checkingId = id;
    activeCheck.value = CookingCheck.create(station, _config, _rng);
    if (station == Station.fry) AudioService.instance.play(Sfx.sizzle);
    if (station == Station.boil) AudioService.instance.play(Sfx.bubble);
  }

  /// Ketukan di panel check (Talenan atau Wajan).
  void tapCheck() {
    final c = activeCheck.value;
    if (c == null || !c.isRunning || _phase != _Phase.playing || !session.isPlaying) return;
    final good = c.onTap();
    if (c.station == Station.chop) {
      AudioService.instance.play(Sfx.chop);
      HapticFeedback.lightImpact();
    } else if (good) {
      AudioService.instance.play(Sfx.sizzle);
      HapticFeedback.lightImpact();
    } else {
      AudioService.instance.play(Sfx.wrong);
      HapticFeedback.mediumImpact();
    }
  }

  /// Tombol api Panci ditahan / dilepas.
  void holdCheck(bool holding) {
    final c = activeCheck.value;
    if (c == null || !c.isRunning || _phase != _Phase.playing || !session.isPlaying) {
      c?.setHolding(false);
      return;
    }
    c.setHolding(holding);
    if (holding) AudioService.instance.play(Sfx.bubble);
  }

  @override
  void pauseEngine() {
    activeCheck.value?.setHolding(false); // api yang sedang ditahan dilepas saat jeda
    super.pauseEngine();
  }

  void _wrong() {
    AudioService.instance.play(Sfx.wrong);
    HapticFeedback.mediumImpact();
    wrongCount.value++;
    _adjustTime(-CookingTuning.wrongPenalty);
    _chef.laugh();
    _chef.setExpression(BossExpression.laugh, revertAfter: 0.9);
    _say(_pick(CookingDialog.wrong));
  }

  // ---------------- siklus frame ----------------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;

    if (_phase == _Phase.intro) {
      _introLeft -= dt;
      if (_introLeft <= 0) {
        _phase = _Phase.playing;
        showBanner.value = false;
      }
      return;
    }
    if (_phase != _Phase.playing || !session.isPlaying) return;

    _timeLeft -= dt;
    _timeBar.fraction = _timeLeft / _config.seconds;
    final left = max(0, _timeLeft.ceil());
    if (left != secondsLeft.value) secondsLeft.value = left;
    if (left > 0 && left <= 3 && left != _lastTick) {
      _lastTick = left;
      AudioService.instance.play(Sfx.tick);
    }
    if (!_hurried && _timeLeft <= CookingTuning.hurrySeconds && _config.seconds > CookingTuning.hurrySeconds * 2) {
      _hurried = true;
      _say(_pick(CookingDialog.hurry));
    }

    final check = activeCheck.value;
    if (check != null) {
      check.update(dt);
      checkTick.value++;
      if (!check.isRunning) _resolveCheck(check);
    }

    // check yang selesai pada frame yang sama dengan habisnya waktu dihitung menang
    if (_phase == _Phase.playing && _timeLeft <= 0) _finishStep(won: false);
  }

  void _resolveCheck(CookingCheck check) {
    final id = _checkingId;
    activeCheck.value = null;
    _checkingId = null;
    if (id == null) return;

    if (check.status == CheckStatus.success) {
      done.value = {...done.value, id};
      AudioService.instance.play(Sfx.correct);
      if (check.perfect) _adjustTime(CookingTuning.perfectBonus);
      if (done.value.length >= (order.value?.ingredients.length ?? 0)) {
        _finishStep(won: true);
        return;
      }
      _chef.flinch();
      _chef.setExpression(BossExpression.shock, revertAfter: 0.8);
      _say(_pick(CookingDialog.checkOk), seconds: 1.4);
    } else {
      AudioService.instance.play(Sfx.burn);
      HapticFeedback.mediumImpact();
      wrongCount.value++;
      tray.value = [...tray.value, id]; // bahan kembali ke baki
      _adjustTime(-CookingTuning.failPenalty);
      _chef.laugh();
      _chef.setExpression(BossExpression.laugh, revertAfter: 0.9);
      _say(_pick(CookingDialog.checkFail));
    }
  }

  void _finishStep({required bool won}) {
    _phase = _Phase.done;
    activeCheck.value = null;
    _checkingId = null;
    _sayToken++;
    bossSay.value = null;

    // Kalimat hasil harus siap SEBELUM session berubah (listener layar membacanya).
    if (!won) {
      _timeBar.fraction = 0;
      secondsLeft.value = 0;
      _resultLine = _pick(CookingDialog.resultByStars[session.stepsWon]);
      _chef.setExpression(BossExpression.laugh);
      _chef.laugh();
      AudioService.instance.play(Sfx.lose);
      session.loseStep();
      return;
    }

    if (session.step >= StarCalculator.totalSteps) {
      _resultLine = _pick(CookingDialog.resultByStars[StarCalculator.totalSteps]);
      _chef.setExpression(BossExpression.defeat);
    } else {
      _chef.flinch();
      _chef.setExpression(BossExpression.shock, revertAfter: 1.0);
      _say(CookingDialog.stepClear[session.step - 1], seconds: 1.2);
    }
    session.winStep();
    AudioService.instance.play(session.isPlaying ? Sfx.stepUp : Sfx.win);
    if (session.isPlaying) {
      add(TimerComponent(
        period: 1.2,
        removeOnFinish: true,
        onTick: () => startStep(session.step),
      ));
    }
  }
}

/// Latar dapur: gambar potret dipotong ke tengah agar menutupi seluruh layar (cover).
class _KitchenBackground extends PositionComponent {
  _KitchenBackground(this._image);

  final Image _image;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  @override
  void render(Canvas canvas) {
    final iw = _image.width.toDouble();
    final ih = _image.height.toDouble();
    final scale = max(size.x / iw, size.y / ih);
    final srcW = size.x / scale;
    final srcH = size.y / scale;
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH((iw - srcW) / 2, (ih - srcH) / 2, srcW, srcH),
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
}
