import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart' show KeyboardEvents;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart'
    show Alignment, BuildContext, KeyEventResult, Widget;
import 'package:flutter/services.dart'
    show DeviceOrientation, KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import 'arena_component.dart';
import 'attacks.dart';
import 'effects.dart';
import 'enemy_ai.dart';
import 'fight_arena.dart';
import 'fight_config.dart';
import 'fight_dialog.dart';
import 'fight_hud.dart';
import 'fighter.dart';
import 'pose_clips.dart';
import 'stick_renderer.dart';

LevelGame createFightGame(LevelSession session) => FightGame(session);

/// Level 1: Rock the Fighter - satu lawan, tiga fase menurut batas HP.
///
/// Tahap M2-M3: gerak, pukul/tendang/tangkis/pisau, deteksi hit, HP, alur fase ke core, dan AI Rock.
/// Lawan: [EnemyAi] (M3).
class FightGame extends LevelGame with KeyboardEvents {
  FightGame(super.session);

  late final FightArena arena;
  late final ArenaComponent _bg;
  late final Fighter _playerView;
  late final Fighter _rockView;
  late final KnifeLayer _knives;
  final EnemyAi _brain = EnemyAi();
  final math.Random _rnd = math.Random();

  bool _ready = false;
  bool _transitioning = false;
  bool _resultPending = false;
  double _hitStopMs = 0;
  double _shake = 0;
  double _unit = 1;
  double _groundY = 0;

  bool _left = false;
  bool _right = false;
  bool _block = false;

  /// Nilai untuk HUD (pecahan 0..1).
  final ValueNotifier<int> phase = ValueNotifier(1);
  final ValueNotifier<String?> banner = ValueNotifier(null);
  final ValueNotifier<double> playerHp = ValueNotifier(1);
  final ValueNotifier<double> rockHp = ValueNotifier(1);

  /// Kesiapan pisau: 1 = siap, <1 = sedang jeda.
  final ValueNotifier<double> knifeReady = ValueNotifier(1);

  /// Mode uji: Rock menyerang atau diam.
  final ValueNotifier<bool> rockAttacks = ValueNotifier(true);

  @override
  List<String> get assetPaths => const ['fight/arena.png'];

  @override
  List<DeviceOrientation>? get orientations => const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];

  // Tombol jeda di tengah atas, supaya HUD kiri-kanan tidak tertutup.
  @override
  Alignment get pauseButtonAlignment => Alignment.topCenter;

  @override
  String get stepLabel => 'Fase';

  @override
  Color backgroundColor() => const Color(0xFF2B1A10);

  @override
  Widget buildHud(BuildContext context) => FightHud(game: this);

  @override
  String? resultMessage() => FightDialog.resultLine(session.stars);

  @override
  Future<void> onLoad() async {
    await loadAssets();
    arena = FightArena(worldWidth: 1);
    _bg = ArenaComponent(levelImages.fromCache('fight/arena.png'))..priority = -10;
    _rockView = Fighter(body: arena.rock, style: FighterStyle.rockTheFighter)..priority = 0;
    _playerView = Fighter(body: arena.player, style: FighterStyle.player)..priority = 1;
    _knives = KnifeLayer(arena)..priority = 2;
    await addAll([_bg, _rockView, _playerView, _knives]);
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
    _bg.size = s;
    _unit = (s.y * ArenaLayout.fighterHeight) / ArenaLayout.figureUnits;
    _groundY = s.y * ArenaLayout.groundY;

    // jaga posisi relatif petarung saat ukuran layar berubah (mis. rotasi ke landscape)
    final oldW = arena.worldWidth;
    final pf = arena.player.x / oldW;
    final rf = arena.rock.x / oldW;
    arena.worldWidth = s.x / _unit;
    arena.player.x = pf * arena.worldWidth;
    arena.rock.x = rf * arena.worldWidth;

    for (final f in [_playerView, _rockView]) {
      f
        ..unit = _unit
        ..groundY = _groundY;
    }
    _knives
      ..unit = _unit
      ..groundY = _groundY;
  }

  // ---------------- alur fase ----------------
  @override
  void startStep(int step) {
    phase.value = step;
    _bg.setPhase(step);
    if (!_ready) return;
    arena.setStep(step);
    _showBanner('FASE $step: ${fightPhases[step - 1].name}\n${FightDialog.phaseLines[step - 1]}');
  }

  void _showBanner(String text) {
    banner.value = text;
    _later(2.2, () {
      if (banner.value == text) banner.value = null;
    });
  }

  void _later(double seconds, void Function() action) {
    add(TimerComponent(period: seconds, removeOnFinish: true, onTick: action));
  }

  /// Dipanggil tiap frame setelah hit diproses: KO Rock, KO pemain, atau pergantian fase.
  void _checkProgress() {
    if (_resultPending) return;
    final rock = arena.rock;
    final player = arena.player;

    if (rock.isDead) {
      _resultPending = true;
      arena.clearKnives();
      player.celebrate();
      _later(1.4, () {
        if (session.isPlaying) session.winStep();
      });
      return;
    }
    if (player.isDead) {
      _resultPending = true;
      arena.clearKnives();
      _later(1.0, () {
        if (session.isPlaying) session.loseStep();
      });
      return;
    }
    if (!_transitioning && arena.step < 3 && rock.atFloor) _beginPhaseBreak();
  }

  /// Rock mencapai batas HP fase: fase dimenangkan, Rock mengamuk sebentar (kebal).
  void _beginPhaseBreak() {
    _transitioning = true;
    arena.clearKnives();
    arena.rock
      ..invulnerable = true
      ..playScripted(Clips.taunt, holdMs: 1500);
    final next = session.step + 1;
    session.winStep();
    if (session.isPlaying) startStep(next);
    _later(1.5, () {
      arena.rock.invulnerable = false;
      _transitioning = false;
    });
  }

  // ---------------- input pemain ----------------
  bool get _canInput => _ready && session.isPlaying && !_resultPending && !arena.player.isDead;

  void setMoveLeft(bool v) => _left = v;
  void setMoveRight(bool v) => _right = v;
  void setBlock(bool v) => _block = v;

  void pressPunch() {
    if (_canInput) arena.player.queuePunch();
  }

  void pressKick() {
    if (_canInput) arena.player.queueAttack(Attacks.kick);
  }

  void pressKnife() {
    if (_canInput) arena.player.queueKnife();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool held(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    setMoveLeft(held([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]));
    setMoveRight(held([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]));
    setBlock(held([LogicalKeyboardKey.keyL, LogicalKeyboardKey.keyS]));
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyJ) pressPunch();
      if (event.logicalKey == LogicalKeyboardKey.keyK) pressKick();
      if (event.logicalKey == LogicalKeyboardKey.keyI) pressKnife();
    }
    return KeyEventResult.handled;
  }

  // ---------------- siklus frame ----------------
  @override
  void update(double dt) {
    if (!_ready) {
      super.update(dt);
      return;
    }
    final clamped = math.min(dt, 0.05);
    if (_hitStopMs > 0) {
      _hitStopMs -= clamped * 1000;
    } else {
      _stepWorld(clamped * 1000);
    }
    _shake = math.max(0, _shake - 70 * clamped);
    super.update(dt);
  }

  void _stepWorld(double dtMs) {
    final player = arena.player;
    if (_canInput) {
      player.moveInput = ((_right ? 1 : 0) - (_left ? 1 : 0)).toDouble();
      player.blockHeld = _block;
    } else {
      player.moveInput = 0;
      player.blockHeld = false;
    }
    _brain.enabled = rockAttacks.value && !_transitioning && !_resultPending;
    _brain.update(
      dtMs,
      arena.rock,
      player,
      rockPhaseStats[arena.step - 1],
      arena.step,
      arena.worldWidth,
    );

    arena.update(dtMs);
    _processEvents();
    _checkProgress();

    playerHp.value = player.hpFraction;
    rockHp.value = arena.rock.hpFraction;
    knifeReady.value = 1 - (player.knifeCooldownMs / PlayerStats.knifeCooldownMs).clamp(0.0, 1.0);
  }

  void _processEvents() {
    for (final e in arena.events) {
      final at = Offset(e.x * _unit, _groundY + e.y * _unit);
      final blocked = e.kind == HitKind.blocked;
      add(HitSpark(pos: at, radius: (blocked ? 200 : 300) * _unit, blocked: blocked));
      _hitStopMs = math.max(_hitStopMs, blocked ? 30 : 60);
      _shake = math.max(_shake, blocked ? 2 : (e.damage >= 10 ? 8 : 5));
    }
    arena.events.clear();
  }

  @override
  void render(Canvas canvas) {
    if (_shake > 0.5) {
      canvas.save();
      canvas.translate((_rnd.nextDouble() - 0.5) * _shake * 2, (_rnd.nextDouble() - 0.5) * _shake * 2);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  // ---------------- panel uji (sementara) ----------------
  void devPlay({required bool forPlayer, required String clipName}) {
    final clip = Clips.all[clipName];
    if (clip == null || !_ready) return;
    (forPlayer ? arena.player : arena.rock).playScripted(
      clip,
      holdMs: clip.holdLast || clip.loop ? 1500 : null,
    );
  }

  /// Memaksa menyelesaikan fase sekarang (laporan ke core, seperti saat Rock mencapai batas HP).
  void devWinPhase() {
    if (!_ready || !session.isPlaying || _resultPending) return;
    if (arena.step < 3) {
      arena.rock.hp = arena.rock.hpFloor;
      _checkProgress();
    } else {
      arena.rock.hp = 0;
      arena.rock.receiveHit(Attacks.kick.withDamage(1), arena.player.x);
    }
  }

  void devLose() {
    if (!_ready || !session.isPlaying || _resultPending) return;
    arena.player.receiveHit(Attacks.kick.withDamage(10000), arena.rock.x);
  }
}
