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
import 'memory_config.dart';
import 'memory_dialog.dart';
import 'memory_hud.dart';
import 'memory_round.dart';
import 'memory_sequence.dart';
import 'memory_stage.dart';

LevelGame createMemoryGame(LevelSession session) => MemoryGame(session);

/// Tombol papan ketik untuk uji di emulator: 1..9 = pad 0..8 (urut kiri-kanan, atas-bawah).
const _padKeys = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// Efek SFX nada tiap pad (indeks = pad).
const _padNotes = <Sfx>[
  Sfx.memoryNote0,
  Sfx.memoryNote1,
  Sfx.memoryNote2,
  Sfx.memoryNote3,
  Sfx.memoryNote4,
  Sfx.memoryNote5,
  Sfx.memoryNote6,
  Sfx.memoryNote7,
  Sfx.memoryNote8,
];

/// Satu ketukan salah untuk animasi getar pad. Tiap kejadian memakai [serial] baru supaya animasi mulai lagi.
class MemoryWrongTap {
  const MemoryWrongTap(this.serial, this.pad);

  final int serial;

  /// Pad yang diketuk; null bila kesalahan karena waktu habis.
  final int? pad;
}

/// Level 8: Mira the Memory Keeper. Tiga step ingatan urutan pad (gaya Simon): tonton urutan, lalu ulangi.
/// Tiap ronde urutan bertambah satu. Salah atau waktu habis = nyawa berkurang dan urutan yang sama ditayangkan
/// ulang; nyawa habis = step gagal. Murni keterampilan: tanpa kesulitan dinamis dan tanpa bantuan tersembunyi.
/// Urutan diacak baru tiap percobaan lewat [Random] yang bisa disuntikkan (tes memakai seed tetap).
class MemoryGame extends LevelGame with KeyboardEvents {
  MemoryGame(
    super.session, {
    Random? random,
    MemorySequence Function(int step, Random random)? sequenceFor,
    Random? visualRandom,
  })  : run = MemoryRound(session, random: random, sequenceFor: sequenceFor),
        _visual = visualRandom ?? Random(),
        displayStep = ValueNotifier(session.step),
        lives = ValueNotifier(memoryLivesOf(session.step)),
        sequenceLength = ValueNotifier(memoryLengthOf(session.step, 1)) {
    run
      ..onPhase = _onPhase
      ..onShow = _onShow
      ..onLit = _onLit
      ..onCorrect = _onCorrect
      ..onWrong = _onWrong
      ..onRoundClear = _onRoundClear
      ..onStepResult = _onStepResult
      ..onBeforeCommit = _onBeforeCommit;
  }

  /// Mesin tahap (murni Dart).
  final MemoryRound run;

  /// Pengacak khusus tampilan (pemilihan kalimat); tidak memengaruhi permainan.
  final Random _visual;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<MemoryPhase> phase = ValueNotifier(MemoryPhase.idle);
  final ValueNotifier<bool> showBanner = ValueNotifier(false);
  final ValueNotifier<String> statusText = ValueNotifier('');
  final ValueNotifier<String?> resultText = ValueNotifier(null);
  final ValueNotifier<int> roundNo = ValueNotifier(1);
  final ValueNotifier<int> correct = ValueNotifier(0);
  final ValueNotifier<double> timeLeft = ValueNotifier(0);
  final ValueNotifier<int?> litPad = ValueNotifier(null);
  final ValueNotifier<int?> blinkPad = ValueNotifier(null);
  final ValueNotifier<MemoryWrongTap?> wrongTap = ValueNotifier(null);

  /// Nomor ronde (step) di bilah atas, banner, kisi pad, dan label. Berganti saat banner baru muncul,
  /// bukan saat sesi menaikkan step.
  final ValueNotifier<int> displayStep;

  /// Nyawa tersisa dan panjang urutan ronde sekarang.
  final ValueNotifier<int> lives;
  final ValueNotifier<int> sequenceLength;

  /// Pad yang sedang disentuh (menyala selama jari menempel).
  final List<ValueNotifier<bool>> padDown = List.generate(memoryMaxPads, (_) => ValueNotifier(false));

  late final CoverBackground _background;
  late final BossSprite _boss;
  late final MemoryStage _stage;
  bool _ready = false;

  int _sayToken = 0;
  int _blinkToken = 0;
  int _wrongSerial = 0;
  String? _lastLine;
  String? _resultLine;

  @override
  List<String> get assetPaths => const [
        'memory/boss_idle.png',
        'memory/boss_shock.png',
        'memory/boss_laugh.png',
        'memory/boss_defeat.png',
        'memory/stage.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFF161228);

  @override
  String get stepLabel => 'Ronde';

  @override
  Widget buildHud(BuildContext context) => MemoryHud(game: this);

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Image img(String file) => levelImages.fromCache('memory/$file.png');
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
    _stage = MemoryStage();
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
    final side = min(s.x * 0.5, s.y * MemoryLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x * MemoryLayout.bossCenterX, s.y * MemoryLayout.bossCenterY);
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) => run.beginStep(step);

  void _onPhase(MemoryPhase from, MemoryPhase to) {
    phase.value = to;
    switch (to) {
      case MemoryPhase.intro:
        displayStep.value = run.step;
        roundNo.value = run.round;
        lives.value = run.lives;
        correct.value = 0;
        sequenceLength.value = run.length;
        statusText.value = '';
        resultText.value = null;
        blinkPad.value = null;
        wrongTap.value = null;
        showBanner.value = true;
        if (_ready) {
          _stage.step = run.step;
          _stage.litPad = null;
        }
        if (_ready) _boss.setExpression(BossExpression.idle);
        _say(MemoryDialog.stepIntro[run.step - 1], seconds: 2.4);
      case MemoryPhase.showing:
        showBanner.value = false;
        roundNo.value = run.round;
        sequenceLength.value = run.length;
        correct.value = 0;
        statusText.value = MemoryDialog.watch;
      case MemoryPhase.input:
        correct.value = 0;
        statusText.value = MemoryDialog.yourTurn;
      case MemoryPhase.roundClear:
        statusText.value = MemoryDialog.right;
      case MemoryPhase.retry:
        break; // teks SALAH! / WAKTU HABIS diisi oleh _onWrong
      case MemoryPhase.result:
        statusText.value = '';
      case MemoryPhase.idle:
      case MemoryPhase.gap:
      case MemoryPhase.done:
        break;
    }
  }

  /// Getar ringan; kegagalan (mis. di emulator atau saat tes) diabaikan.
  void _haptic(Future<void> Function() feedback) {
    unawaited(feedback().catchError((Object _) {}));
  }

  void _onShow(int pad) {
    AudioService.instance.play(_padNotes[pad]);
  }

  void _onLit(int? pad) {
    litPad.value = pad;
    if (_ready) _stage.litPad = pad;
  }

  void _onCorrect(int pad, int count, int length) {
    correct.value = count;
    AudioService.instance.play(_padNotes[pad]);
    _haptic(HapticFeedback.selectionClick);
  }

  void _onWrong(MemoryMistake mistake) {
    lives.value = mistake.livesLeft;
    statusText.value = mistake.timeout ? MemoryDialog.timeUp : MemoryDialog.wrong;
    wrongTap.value = MemoryWrongTap(++_wrongSerial, mistake.tapped);
    correct.value = 0;
    AudioService.instance.play(Sfx.memoryWrong);
    _haptic(HapticFeedback.lightImpact);
    if (_ready) _stage.startFlash();

    // Pad yang benar berkedip satu kali, kecuali nyawa habis (jawaban benar tidak diungkap lagi).
    if (mistake.livesLeft > 0) {
      _blink(mistake.expected);
    }
    _react(BossExpression.laugh, mistake.timeout ? MemoryDialog.timeoutReact : MemoryDialog.wrongReact);
  }

  void _blink(int pad) {
    final token = ++_blinkToken;
    blinkPad.value = pad;
    if (!_ready) return;
    add(TimerComponent(
      period: MemoryTuning.blinkMs / 1000,
      removeOnFinish: true,
      onTick: () {
        if (token == _blinkToken) blinkPad.value = null;
      },
    ));
  }

  void _onRoundClear(int round, bool clean) {
    if (round >= run.rounds) return; // ronde terakhir ditangani _onStepResult
    AudioService.instance.play(Sfx.memoryClear);
    if (clean) {
      _react(BossExpression.shock, MemoryDialog.cleanReact);
    } else {
      _react(BossExpression.idle, MemoryDialog.correctReact);
    }
  }

  void _react(BossExpression expression, List<String> lines) {
    if (_ready) {
      if (expression == BossExpression.idle) {
        _boss.setExpression(BossExpression.idle);
      } else {
        _boss.setExpression(expression, revertAfter: MemoryTuning.reactionMs / 1000);
      }
    }
    _say(_pick(lines), seconds: 1.6);
  }

  void _onStepResult(bool passed) {
    resultText.value = passed ? MemoryDialog.passed : MemoryDialog.failed;
    blinkPad.value = null;
    final index = run.step - 1;
    final last = run.step >= StarCalculator.totalSteps;
    if (passed) {
      AudioService.instance.play(last ? Sfx.memoryWin : Sfx.stepUp);
      _haptic(HapticFeedback.mediumImpact);
      if (_ready) {
        _boss.flinch();
        _boss.setExpression(BossExpression.shock, revertAfter: MemoryTuning.reactionMs / 1000);
      }
      _say(_pick(MemoryDialog.win[index]), seconds: 1.8);
    } else {
      AudioService.instance.play(Sfx.memoryLose);
      if (_ready) {
        _boss.laugh();
        _boss.setExpression(BossExpression.laugh, revertAfter: MemoryTuning.reactionMs / 1000);
      }
      _say(_pick(MemoryDialog.lose[index]), seconds: 1.8);
    }
  }

  /// Kalimat layar hasil harus siap SEBELUM sesi berubah, karena layar hasil membacanya saat sesi selesai.
  void _onBeforeCommit(bool won) {
    if (!won) {
      _resultLine = _pick(MemoryDialog.resultByStars[session.stepsWon]);
      return;
    }
    if (run.step >= StarCalculator.totalSteps) {
      _resultLine = _pick(MemoryDialog.resultByStars[StarCalculator.totalSteps]);
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
  /// Pad ke-[pad] disentuh. Pad hanya merespons pada giliran pemain; saat tonton sentuhan diabaikan.
  /// Pad menyala hanya bila ketukan benar-benar diproses (satu ketukan per frame).
  void pressPad(int pad) {
    if (pad < 0 || pad >= run.padCount) return;
    final result = run.tapPad(pad);
    if (result == MemoryTap.ignored) return;
    padDown[pad].value = true;
  }

  void releasePad(int pad) {
    if (pad < 0 || pad >= memoryMaxPads) return;
    padDown[pad].value = false;
  }

  void _releaseAllPads() {
    for (final pad in padDown) {
      pad.value = false;
    }
  }

  /// Papan ketik untuk uji di emulator: 1..9.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final pad = _padKeys.indexOf(event.logicalKey);
    if (pad < 0) return KeyEventResult.ignored;
    if (event is KeyDownEvent) pressPad(pad);
    if (event is KeyUpEvent) releasePad(pad);
    return KeyEventResult.handled;
  }

  // ---------------- jeda ----------------
  /// Jeda membekukan tayangan, timer, dan animasi; pad yang sedang ditahan dilepas agar tidak "menyangkut".
  @override
  void pauseEngine() {
    _releaseAllPads();
    super.pauseEngine();
  }

  /// Lanjut: tayangan diulang dari awal, atau timer diatur ulang penuh saat giliran pemain.
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
    run.update(dt);
    timeLeft.value = run.timerFraction;
  }
}
