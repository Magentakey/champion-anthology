import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart' show KeyboardEvents;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, KeyEventResult, Widget;
import 'package:flutter/services.dart' show HapticFeedback, KeyDownEvent, KeyEvent, KeyUpEvent, LogicalKeyboardKey;

import '../../core/audio/audio_service.dart';
import '../../core/level/boss_sprite.dart';
import '../../core/level/cover_background.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'rhythm_calibration.dart';
import 'rhythm_chart.dart';
import 'rhythm_config.dart';
import 'rhythm_dialog.dart';
import 'rhythm_hud.dart';
import 'rhythm_judge.dart';
import 'rhythm_run.dart';
import 'rhythm_stage.dart';

LevelGame createRhythmGame(LevelSession session) => RhythmGame(session);

/// Tombol papan ketik untuk uji di emulator: D F J K = jalur 0 sampai 3.
const _laneKeys = <LogicalKeyboardKey>[
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyJ,
  LogicalKeyboardKey.keyK,
];

/// Penilaian terbaru yang ditampilkan dekat garis ketuk. Tiap kejadian memakai [serial] baru supaya animasi mulai lagi.
class RhythmPopup {
  const RhythmPopup(this.serial, this.judgment, this.lane);

  final int serial;
  final Judgment judgment;
  final int lane;
}

/// Level 7: Rhea the Drummer. Tiga lagu ritme: not jatuh di empat jalur dan pemain mengetuk pad tepat saat
/// not menyentuh garis. Lulus bila akurasi mencapai ambang step itu (60%, 70%, 78%). Murni keterampilan:
/// not dan lagu selalu sama. Penilaian mengacu ke jam permainan di [RhythmRun], bukan ke posisi pemutar audio.
class RhythmGame extends LevelGame with KeyboardEvents {
  RhythmGame(
    super.session, {
    int Function()? offsetMs,
    RhythmChart Function(int step)? chartFor,
    Random? visualRandom,
  })  : run = RhythmRun(
          session,
          offsetMs: offsetMs ?? (() => RhythmCalibration.instance.offsetMs.value),
          chartFor: chartFor,
        ),
        _visual = visualRandom ?? Random(),
        displayStep = ValueNotifier(session.step) {
    run
      ..onPhase = _onPhase
      ..onJudged = _onJudged
      ..onCountBeat = _onCountBeat
      ..onStepResult = _onStepResult
      ..onBeforeCommit = _onBeforeCommit;
    _frame.start();
  }

  /// Mesin tahap dan penilai (murni Dart).
  final RhythmRun run;

  /// Pengacak khusus tampilan (pemilihan kalimat); tidak memengaruhi nilai.
  final Random _visual;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<RhythmPhase> phase = ValueNotifier(RhythmPhase.idle);
  final ValueNotifier<double> accuracy = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<String?> countText = ValueNotifier(null);
  final ValueNotifier<bool> showBanner = ValueNotifier(false);
  final ValueNotifier<RhythmPopup?> popup = ValueNotifier(null);
  final ValueNotifier<String?> resultText = ValueNotifier(null);

  /// Nomor ronde di bilah atas, banner, dan label target. Berganti saat banner ronde baru muncul,
  /// bukan saat sesi menaikkan step.
  final ValueNotifier<int> displayStep;

  /// Pad yang sedang disentuh (menyala).
  final List<ValueNotifier<bool>> padDown = List.generate(rhythmLaneCount, (_) => ValueNotifier(false));

  late final CoverBackground _background;
  late final BossSprite _boss;
  late final RhythmStage _stage;
  bool _ready = false;

  final Stopwatch _frame = Stopwatch();
  int _sayToken = 0;
  int _popupSerial = 0;
  String? _lastLine;
  String? _resultLine;

  @override
  List<String> get assetPaths => const [
        'rhythm/boss_idle.png',
        'rhythm/boss_shock.png',
        'rhythm/boss_laugh.png',
        'rhythm/boss_defeat.png',
        'rhythm/stage.png',
        'rhythm/note_0.png',
        'rhythm/note_1.png',
        'rhythm/note_2.png',
        'rhythm/note_3.png',
        'rhythm/hit_line.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFF161228);

  @override
  String get stepLabel => 'Round';

  @override
  Widget buildHud(BuildContext context) => RhythmHud(game: this);

  @override
  Widget? buildPauseExtras(BuildContext context) => const RhythmOffsetControl();

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Image img(String file) => levelImages.fromCache('rhythm/$file.png');
    Sprite spriteOf(String file) => Sprite(img(file));
    _background = CoverBackground(img('stage'), alignY: 1.0);
    _boss = BossSprite(
      sprites: {
        BossExpression.idle: spriteOf('boss_idle'),
        BossExpression.shock: spriteOf('boss_shock'),
        BossExpression.laugh: spriteOf('boss_laugh'),
        BossExpression.defeat: spriteOf('boss_defeat'),
      },
    );
    _stage = RhythmStage(
      RhythmImages(
        notes: [for (var i = 0; i < rhythmLaneCount; i++) img('note_$i')],
        hitLine: img('hit_line'),
      ),
    );
    await addAll([_background, _stage, _boss]);
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
    _stage.size = s;
    _stage.position = Vector2.zero();
    final side = min(s.x * 0.5, s.y * RhythmLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x * RhythmLayout.bossCenterX, s.y * RhythmLayout.bossCenterY);
  }

  @override
  void disposeAssets() {
    AudioService.instance.stopBgm(owner: this);
    super.disposeAssets();
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) => run.beginStep(step);

  void _onPhase(RhythmPhase from, RhythmPhase to) {
    phase.value = to;
    switch (to) {
      case RhythmPhase.intro:
        displayStep.value = run.step;
        combo.value = 0;
        accuracy.value = 0;
        countText.value = null;
        resultText.value = null;
        popup.value = null;
        showBanner.value = true;
        if (_ready) {
          _stage.reset();
          _stage.chart = run.chart;
          _stage.judge = run.judge;
          _stage.clock = run.clock;
          _boss.setExpression(BossExpression.idle);
        }
        _say(RhythmDialog.stepIntro[run.step - 1], seconds: 2.4);
      case RhythmPhase.countdown:
        showBanner.value = false;
      case RhythmPhase.playing:
        countText.value = null;
        if (from == RhythmPhase.countdown) {
          final file = rhythmSongFiles[run.step - 1];
          unawaited(AudioService.instance.playBgm(file, volume: 0.9, owner: this));
        } else if (from == RhythmPhase.resuming) {
          AudioService.instance.resumeBgm(owner: this);
        }
      case RhythmPhase.result:
        countText.value = null;
        AudioService.instance.stopBgm(owner: this);
      case RhythmPhase.idle:
      case RhythmPhase.resuming:
      case RhythmPhase.gap:
      case RhythmPhase.done:
        break;
    }
  }

  void _onCountBeat(int beat, int total) {
    countText.value = RhythmDialog.countWord(beat, total);
    AudioService.instance.play(Sfx.rhythmCount);
  }

  void _onJudged(int index, Judgment judgment) {
    final judge = run.judge;
    if (judge == null) return;
    final lane = judge.notes[index].lane;
    combo.value = judge.combo;
    accuracy.value = judge.runningAccuracy;
    popup.value = RhythmPopup(++_popupSerial, judgment, lane);
    switch (judgment) {
      case Judgment.perfect:
        AudioService.instance.play(Sfx.rhythmHitPerfect);
        HapticFeedback.selectionClick();
      case Judgment.good:
        AudioService.instance.play(Sfx.rhythmHitGood);
      case Judgment.miss:
        AudioService.instance.play(Sfx.rhythmMiss);
    }
    if (_ready) _stage.burst(lane, judgment);

    if (judgment != Judgment.miss && judge.combo > 0 && judge.combo % RhythmTuning.awedComboEvery == 0) {
      _react(BossExpression.shock, RhythmDialog.comboPraise);
    } else if (judgment == Judgment.miss && judge.missStreak > 0 && judge.missStreak % RhythmTuning.laughMissStreak == 0) {
      _react(BossExpression.laugh, RhythmDialog.missTaunt);
    }
  }

  void _react(BossExpression expression, List<String> lines) {
    if (_ready) _boss.setExpression(expression, revertAfter: 1.0);
    _say(_pick(lines), seconds: 1.4);
  }

  void _onStepResult(bool passed) {
    resultText.value = passed ? RhythmDialog.passed : RhythmDialog.failed;
    final index = run.step - 1;
    final last = run.step >= StarCalculator.totalSteps;
    if (passed) {
      AudioService.instance.play(last ? Sfx.win : Sfx.stepUp);
      HapticFeedback.mediumImpact();
      if (_ready) {
        _boss.flinch();
        _boss.setExpression(BossExpression.shock, revertAfter: 1.0);
      }
      _say(_pick(RhythmDialog.win[index]), seconds: 1.6);
    } else {
      AudioService.instance.play(Sfx.lose);
      if (_ready) {
        _boss.laugh();
        _boss.setExpression(BossExpression.laugh, revertAfter: 1.0);
      }
      _say(_pick(RhythmDialog.lose[index]), seconds: 1.6);
    }
  }

  /// Kalimat layar hasil harus siap SEBELUM sesi berubah, karena layar hasil membacanya saat sesi selesai.
  void _onBeforeCommit(bool won) {
    if (!won) {
      _resultLine = _pick(RhythmDialog.resultByStars[session.stepsWon]);
      return;
    }
    if (run.step >= StarCalculator.totalSteps) {
      _resultLine = _pick(RhythmDialog.resultByStars[StarCalculator.totalSteps]);
      if (_ready) _boss.setExpression(BossExpression.defeat);
    }
  }

  void _say(String line, {double seconds = 2.2}) {
    final token = ++_sayToken;
    bossSay.value = line;
    if (!_ready) return;
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
      line = lines[_visual.nextInt(lines.length)];
    } while (line == _lastLine);
    _lastLine = line;
    return line;
  }

  // ---------------- input ----------------
  /// Waktu jam permainan saat ini, termasuk bagian frame yang sudah berjalan sejak [update] terakhir.
  /// Ketukan datang di antara dua frame, jadi tanpa ini selalu terbaca terlalu awal (paling banyak satu frame).
  double _now() => run.clock + min(0.05, _frame.elapsedMicroseconds / 1e6);

  /// Ketukan pada jalur [lane]. Di luar tahap bermain tidak berpengaruh. [at] untuk uji.
  void tapLane(int lane, {double? at}) {
    if (lane < 0 || lane >= rhythmLaneCount || !run.acceptsTaps) return;
    if (_ready) _stage.flashLane(lane);
    run.tap(lane, at: at ?? _now());
  }

  /// Pad disentuh: menyala dan mengetuk jalurnya.
  void pressPad(int lane) {
    if (lane < 0 || lane >= rhythmLaneCount) return;
    padDown[lane].value = true;
    tapLane(lane);
  }

  void releasePad(int lane) {
    if (lane < 0 || lane >= rhythmLaneCount) return;
    padDown[lane].value = false;
  }

  void _releaseAllPads() {
    for (final pad in padDown) {
      pad.value = false;
    }
  }

  /// Papan ketik untuk uji di emulator: D F J K.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final lane = _laneKeys.indexOf(event.logicalKey);
    if (lane < 0) return KeyEventResult.ignored;
    if (event is KeyDownEvent) pressPad(lane);
    if (event is KeyUpEvent) releasePad(lane);
    return KeyEventResult.handled;
  }

  // ---------------- jeda ----------------
  /// Jeda menghentikan jam dan musik bersama; pad yang sedang ditahan dilepas agar tidak "menyangkut".
  @override
  void pauseEngine() {
    _releaseAllPads();
    AudioService.instance.pauseBgm(owner: this);
    super.pauseEngine();
  }

  /// Lanjut dengan hitung mundur 3 ketukan; musik menyusul saat hitungan selesai.
  @override
  void resumeEngine() {
    super.resumeEngine();
    run.resumeFromPause();
  }

  // ---------------- siklus frame ----------------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;
    _frame.reset();
    run.update(dt);
    _stage.clock = run.clock;
  }
}
