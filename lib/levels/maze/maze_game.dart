import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart' show KeyboardEvents;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, KeyEventResult, Widget;
import 'package:flutter/services.dart'
    show HapticFeedback, KeyDownEvent, KeyEvent, KeyUpEvent, LogicalKeyboardKey;

import '../../core/audio/audio_service.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'maze_boss.dart';
import 'maze_component.dart';
import 'maze_config.dart';
import 'maze_dialog.dart';
import 'maze_grid.dart';
import 'maze_hud.dart';

LevelGame createMazeGame(LevelSession session) => MazeGame(session);

enum _Phase { intro, playing, done }

/// Level 3: Asep the Mazelogist - temukan jalan keluar labirin sebelum waktu habis.
/// Step 1..3 hanya beda ukuran labirin dan batas waktu. Kontrol: tombol arah di layar
/// (tahan = jalan terus, ketuk = satu langkah). Waktu habis = kalah.
class MazeGame extends LevelGame with KeyboardEvents {
  MazeGame(super.session, {Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<int> secondsLeft = ValueNotifier(0);

  /// true selama banner step menutupi labirin (waktu belum berjalan).
  final ValueNotifier<bool> showBanner = ValueNotifier(false);

  late final MazeBoss _boss;
  late final MazeTimeBar _timeBar;
  late final MazeComponent _maze;
  bool _ready = false;

  late MazeStepConfig _config;
  MazeRunner? _runner;
  _Phase _phase = _Phase.done;
  double _timeLeft = 0;
  double _introLeft = 0;

  Dir? _held;
  double _repeatIn = 0;
  int _lastTick = -1;
  bool _hurried = false;
  int _sayToken = 0;
  String? _lastLine;
  String? _resultLine;

  @override
  List<String> get assetPaths => const [
        'maze/boss_idle.png',
        'maze/boss_shock.png',
        'maze/boss_laugh.png',
        'maze/boss_defeat.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFFFFEBEE);

  @override
  Widget buildHud(BuildContext context) => MazeHud(game: this);

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Sprite spriteOf(String file) => Sprite(levelImages.fromCache('maze/$file.png'));
    _boss = MazeBoss(
      sprites: {
        MazeMood.idle: spriteOf('boss_idle'),
        MazeMood.shock: spriteOf('boss_shock'),
        MazeMood.laugh: spriteOf('boss_laugh'),
        MazeMood.defeat: spriteOf('boss_defeat'),
      },
    );
    _timeBar = MazeTimeBar();
    _maze = MazeComponent();
    await addAll([_maze, _boss, _timeBar]);
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
    final side = min(s.x * 0.5, s.y * MazeLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x * MazeLayout.bossCenterX, s.y * MazeLayout.bossCenterY);
    _timeBar.size = Vector2(s.x - 2 * MazeLayout.sideMargin, 14);
    _timeBar.position = Vector2(MazeLayout.sideMargin, s.y * MazeLayout.timeBarY);
    _maze.size = Vector2(s.x - 2 * MazeLayout.sideMargin, s.y * MazeLayout.mazeHeight);
    _maze.position = Vector2(MazeLayout.sideMargin, s.y * MazeLayout.mazeTop);
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) {
    _config = mazeSteps[step - 1];
    final grid = MazeGrid.generate(_config.cols, _config.rows, _rng);
    _runner = MazeRunner(grid);
    _maze.setGrid(grid);

    _timeLeft = _config.seconds.toDouble();
    _timeBar.fraction = 1;
    secondsLeft.value = _config.seconds;
    _held = null;
    _lastTick = -1;
    _hurried = false;

    _phase = _Phase.intro;
    _introLeft = MazeTuning.introSeconds;
    showBanner.value = true;

    _boss.setMood(MazeMood.idle);
    _say(MazeDialog.stepIntro[step - 1], seconds: 2.6);
  }

  /// Tampilkan kalimat Asep di gelembung ucapan selama [seconds] detik.
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

  // ---------------- input ----------------
  /// Tombol arah ditekan (dipanggil HUD): satu langkah langsung, lalu berulang selama ditahan.
  void press(Dir d) {
    if (_phase != _Phase.playing || !session.isPlaying) return;
    _held = d;
    _repeatIn = MazeTuning.firstRepeatSeconds;
    if (!_move(d)) HapticFeedback.selectionClick(); // menabrak dinding
  }

  void release(Dir d) {
    if (_held == d) _held = null;
  }

  @override
  void pauseEngine() {
    _held = null; // tombol yang sedang ditahan dilepas agar tidak "menyangkut" saat lanjut
    super.pauseEngine();
  }

  static Dir? _dirFor(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) return Dir.up;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) return Dir.down;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) return Dir.left;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) return Dir.right;
    return null;
  }

  /// Papan ketik untuk uji di emulator: panah atau WASD.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final d = _dirFor(event.logicalKey);
    if (d == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) press(d);
    if (event is KeyUpEvent) release(d);
    return KeyEventResult.handled;
  }

  /// Melangkah satu sel; true jika berhasil.
  bool _move(Dir d) {
    final runner = _runner;
    if (runner == null || !runner.tryMove(d)) return false;
    _maze.moveTo(runner.x, runner.y);
    if (runner.atGoal) _finishStep(won: true);
    return true;
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
    if (!_hurried && _timeLeft <= MazeTuning.hurrySeconds && _config.seconds > MazeTuning.hurrySeconds * 2) {
      _hurried = true;
      _say(_pick(MazeDialog.hurry));
    }

    final held = _held;
    if (held != null) {
      _repeatIn -= dt;
      if (_repeatIn <= 0) {
        _repeatIn = MazeTuning.repeatSeconds;
        _move(held); // menabrak dinding saat ditahan: diam saja (tanpa getar berulang)
      }
    }

    // tiba di tujuan pada frame yang sama dengan habisnya waktu dihitung menang
    if (_phase == _Phase.playing && _timeLeft <= 0) _finishStep(won: false);
  }

  void _finishStep({required bool won}) {
    _phase = _Phase.done;
    _held = null;
    _sayToken++;
    bossSay.value = null;

    // Kalimat hasil harus siap SEBELUM session berubah (listener layar membacanya).
    if (!won) {
      _timeBar.fraction = 0;
      secondsLeft.value = 0;
      _resultLine = _pick(MazeDialog.resultByStars[session.stepsWon]);
      _boss.setMood(MazeMood.laugh);
      _boss.laugh();
      AudioService.instance.play(Sfx.lose);
      session.loseStep();
      return;
    }

    if (session.step >= StarCalculator.totalSteps) {
      _resultLine = _pick(MazeDialog.resultByStars[StarCalculator.totalSteps]);
      _boss.setMood(MazeMood.defeat);
    } else {
      _boss.flinch();
      _boss.setMood(MazeMood.shock, revertAfter: 1.0);
      _say(MazeDialog.stepClear[session.step - 1], seconds: 1.2);
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
