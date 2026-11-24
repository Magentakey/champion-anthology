import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart' show KeyboardEvents;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, KeyEventResult, Widget;
import 'package:flutter/services.dart'
    show HapticFeedback, KeyDownEvent, KeyEvent, KeyUpEvent, LogicalKeyboardKey;

import '../../core/audio/audio_service.dart';
import '../../core/level/boss_sprite.dart';
import '../../core/level/cover_background.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'archery_config.dart';
import 'archery_dialog.dart';
import 'archery_hud.dart';
import 'archery_model.dart';
import 'archery_range.dart';

LevelGame createArcheryGame(LevelSession session) => ArcheryGame(session);

enum _Phase { intro, aiming, flying, pause, done }

/// Skor yang melayang di layar setelah anak panah mendarat (id berubah tiap tembakan agar animasi mengulang).
class ShotPopup {
  const ShotPopup(this.id, this.score);

  final int id;
  final int score;
}

/// Level 5: Bima the Shooter. Tahan tombol untuk menarik busur sampai penuh, lalu lepas saat bidikan
/// tepat di tengah papan. Makin lama busur ditahan, makin gemetar bidikannya. Skor harus mencapai target
/// sebelum anak panah habis; Step 2 menambah angin, Step 3 menambah papan yang bergerak.
class ArcheryGame extends LevelGame with KeyboardEvents {
  ArcheryGame(super.session, {Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> arrowsLeft = ValueNotifier(0);
  final ValueNotifier<double> wind = ValueNotifier(0);

  /// Kekuatan tarikan 0..1 dan apakah tombol sedang ditahan.
  final ValueNotifier<double> power = ValueNotifier(0);
  final ValueNotifier<bool> drawing = ValueNotifier(false);
  final ValueNotifier<bool> showBanner = ValueNotifier(false);
  final ValueNotifier<ShotPopup?> popup = ValueNotifier(null);

  late final CoverBackground _background;
  late final BossSprite _boss;
  late final LevelTimeBar _clockBar;
  late final ArcheryRange _range;
  bool _ready = false;

  // Diisi dari step sesi sejak awal (bukan baru di onLoad), karena HUD Flutter membaca targetScore/arrowsTotal
  // pada frame pertama, sebelum onLoad selesai. startStep() tetap menimpanya tiap pergantian step.
  late ArcheryStepConfig _config = archerySteps[session.step - 1];
  TargetMotion? _motion;
  ArcheryShot? _shot;
  ShotResult? _pending;
  _Phase _phase = _Phase.done;
  double _clock = 0;
  double _introLeft = 0;
  double _flyLeft = 0;
  double _pauseLeft = 0;
  int _popupId = 0;
  int _sayToken = 0;
  String? _lastLine;
  String? _resultLine;

  /// Skor yang harus dicapai dan jumlah anak panah pada step ini (untuk HUD).
  int get targetScore => _config.targetScore;
  int get arrowsTotal => _config.arrows;

  /// Tombol tarik hanya bekerja saat sedang membidik.
  bool get canDraw => _phase == _Phase.aiming && session.isPlaying;

  @override
  List<String> get assetPaths => const [
        'archery/boss_idle.png',
        'archery/boss_shock.png',
        'archery/boss_laugh.png',
        'archery/boss_defeat.png',
        'archery/archery_bg.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFF8FC4F0);

  @override
  Widget buildHud(BuildContext context) => ArcheryHud(game: this);

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Sprite spriteOf(String file) => Sprite(levelImages.fromCache('archery/$file.png'));
    _background = CoverBackground(levelImages.fromCache('archery/archery_bg.png'), alignY: 1.0);
    _boss = BossSprite(
      sprites: {
        BossExpression.idle: spriteOf('boss_idle'),
        BossExpression.shock: spriteOf('boss_shock'),
        BossExpression.laugh: spriteOf('boss_laugh'),
        BossExpression.defeat: spriteOf('boss_defeat'),
      },
    );
    _clockBar = LevelTimeBar();
    _range = ArcheryRange();
    await addAll([_background, _range, _boss, _clockBar]);
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
    final side = min(s.x * 0.5, s.y * ArcheryLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x * ArcheryLayout.bossCenterX, s.y * ArcheryLayout.bossCenterY);
    _clockBar.size = Vector2(s.x - 2 * ArcheryLayout.sideMargin, 14);
    _clockBar.position = Vector2(ArcheryLayout.sideMargin, s.y * ArcheryLayout.clockY);
    _range.size = Vector2(s.x - 2 * ArcheryLayout.sideMargin, s.y * ArcheryLayout.rangeHeight);
    _range.position = Vector2(ArcheryLayout.sideMargin, s.y * ArcheryLayout.rangeTop);
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) {
    _config = archerySteps[step - 1];
    _motion = TargetMotion(_config, _rng);
    _clock = 0;
    _shot = null;
    _pending = null;

    score.value = 0;
    arrowsLeft.value = _config.arrows;
    wind.value = 0;
    power.value = 0;
    drawing.value = false;
    popup.value = null;

    _range
      ..motion = _motion
      ..clock = 0
      ..shot = null
      ..flying = null
      ..showCrosshair = false
      ..stuck.clear();
    _clockBar.fraction = 1;

    _phase = _Phase.intro;
    _introLeft = ArcheryTuning.introSeconds;
    showBanner.value = true;

    _boss.setExpression(BossExpression.idle);
    _say(ArcheryDialog.stepIntro[step - 1], seconds: 2.6);
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

  void _nextShot() {
    final shot = ArcheryShot(_config, _rng, motion: _motion, motionStart: _clock);
    _shot = shot;
    wind.value = shot.wind;
    power.value = 0;
    drawing.value = false;
    _clockBar.fraction = 1;
    _range
      ..shot = shot
      ..showCrosshair = true;
    _phase = _Phase.aiming;
    if (arrowsLeft.value == ArcheryTuning.lastArrowHint) _say(_pick(ArcheryDialog.lastArrow), seconds: 1.8);
  }

  // ---------------- input dari HUD ----------------
  /// Tombol tarik ditekan: mulai menarik busur.
  void pressDraw() {
    final shot = _shot;
    if (!canDraw || shot == null || shot.released || shot.drawing) return;
    shot.drawing = true;
    drawing.value = true;
    AudioService.instance.play(Sfx.bowDraw);
  }

  /// Tombol dilepas: tarikan sangat singkat dibatalkan, selain itu anak panah dilepas.
  void releaseDraw() {
    final shot = _shot;
    if (_phase != _Phase.aiming || shot == null || !shot.drawing) return;
    if (shot.hold < ArcheryTuning.minDrawSeconds) {
      _cancelDraw();
      return;
    }
    _release();
  }

  void _cancelDraw() {
    final shot = _shot;
    if (shot != null && !shot.released) {
      shot.drawing = false;
      shot.hold = 0;
    }
    drawing.value = false;
    power.value = 0;
  }

  @override
  void pauseEngine() {
    if (_phase == _Phase.aiming) _cancelDraw(); // tarikan yang sedang berjalan dibatalkan saat jeda
    super.pauseEngine();
  }

  /// Papan ketik untuk uji di emulator: spasi = tarik, lepas spasi = tembak.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event.logicalKey != LogicalKeyboardKey.space) return KeyEventResult.ignored;
    if (event is KeyDownEvent) pressDraw();
    if (event is KeyUpEvent) releaseDraw();
    return KeyEventResult.handled;
  }

  void _release() {
    final shot = _shot;
    if (shot == null || shot.released) return;
    final result = shot.release();
    _pending = result;
    drawing.value = false;
    power.value = 0;
    arrowsLeft.value = max(0, arrowsLeft.value - 1);
    AudioService.instance.play(Sfx.arrowShoot);
    _range
      ..showCrosshair = false
      ..flying = FlyingArrow(result.impact);
    _phase = _Phase.flying;
    _flyLeft = ArcheryTuning.flightSeconds;
  }

  // ---------------- siklus frame ----------------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;

    _clock += dt;
    _range.clock = _clock;

    switch (_phase) {
      case _Phase.intro:
        _introLeft -= dt;
        if (_introLeft <= 0) {
          showBanner.value = false;
          _nextShot();
        }
      case _Phase.aiming:
        final shot = _shot;
        if (shot == null || !session.isPlaying) return;
        shot.update(dt);
        if ((shot.power - power.value).abs() > 0.004) power.value = shot.power;
        _clockBar.fraction = 1 - shot.t / ArcheryTuning.shotSeconds;
        if (shot.t >= ArcheryTuning.shotSeconds) _release(); // habis waktu: dilepas otomatis
      case _Phase.flying:
        _flyLeft -= dt;
        final f = _range.flying;
        if (f != null) f.progress = 1 - max(0.0, _flyLeft) / ArcheryTuning.flightSeconds;
        if (_flyLeft <= 0) _land();
      case _Phase.pause:
        _pauseLeft -= dt;
        if (_pauseLeft <= 0) _afterShot();
      case _Phase.done:
        break;
    }
  }

  /// Anak panah tiba di papan: tancap, hitung skor, bos bereaksi.
  void _land() {
    final r = _pending;
    _range.flying = null;
    if (r == null) return;
    if (r.impact.distance <= 2.2) _range.stuck.add(r.impact); // yang terlalu jauh terbang ke rumput
    score.value += r.score;
    popup.value = ShotPopup(++_popupId, r.score);

    if (r.bullseye) {
      AudioService.instance.play(Sfx.bullseye);
      HapticFeedback.mediumImpact();
      _boss.flinch();
      _boss.setExpression(BossExpression.shock, revertAfter: 1.0);
      _say(_pick(ArcheryDialog.bullseye), seconds: 1.6);
    } else {
      AudioService.instance.play(r.score > 0 ? Sfx.arrowHit : Sfx.wrong);
      HapticFeedback.selectionClick();
      if (r.score >= 6) {
        _say(_pick(ArcheryDialog.good), seconds: 1.4);
      } else if (r.score >= 2) {
        _say(_pick(ArcheryDialog.meh), seconds: 1.4);
      } else {
        _boss.laugh();
        _boss.setExpression(BossExpression.laugh, revertAfter: 0.9);
        _say(_pick(ArcheryDialog.miss), seconds: 1.4);
      }
    }
    _phase = _Phase.pause;
    _pauseLeft = ArcheryTuning.pauseSeconds;
  }

  void _afterShot() {
    if (score.value >= _config.targetScore) {
      _finishStep(won: true);
    } else if (arrowsLeft.value <= 0) {
      _finishStep(won: false);
    } else {
      _nextShot();
    }
  }

  void _finishStep({required bool won}) {
    _phase = _Phase.done;
    _clockBar.fraction = 0;
    _sayToken++;
    bossSay.value = null;

    // Kalimat hasil harus siap SEBELUM session berubah (listener layar membacanya).
    if (!won) {
      _resultLine = _pick(ArcheryDialog.resultByStars[session.stepsWon]);
      _boss.setExpression(BossExpression.laugh);
      _boss.laugh();
      AudioService.instance.play(Sfx.lose);
      session.loseStep();
      return;
    }

    if (session.step >= StarCalculator.totalSteps) {
      _resultLine = _pick(ArcheryDialog.resultByStars[StarCalculator.totalSteps]);
      _boss.setExpression(BossExpression.defeat);
    } else {
      _boss.flinch();
      _boss.setExpression(BossExpression.shock, revertAfter: 1.0);
      _say(ArcheryDialog.stepClear[session.step - 1], seconds: 1.2);
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
