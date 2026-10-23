import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../core/level/level_definition.dart';
import '../core/level/level_game.dart';
import '../core/level/level_session.dart';
import '../core/save/progress_repository.dart';
import '../levels/level_registry.dart';
import '../shared/widgets/level_overlays.dart';

/// Layar gameplay generik: menjalankan level apa pun dari registry.
/// Flow: langsung main Step 1 -> 2 -> 3. Kalah = selesai, bintang = step yang dimenangkan.
class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.levelId});

  final String levelId;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  LevelDefinition? _level;
  LevelSession? _session;
  LevelGame? _game;
  bool _saved = false;
  bool _orientationLocked = false;
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    _level = levelById(widget.levelId);
    if (_level?.createGame != null) {
      _startRun();
      _lockOrientation();
    }
  }

  /// Level landscape mengunci orientasi saat masuk; dipulihkan ke potret di dispose().
  void _lockOrientation() {
    final orientations = _game?.orientations;
    if (orientations == null) return;
    _orientationLocked = true;
    SystemChrome.setPreferredOrientations(orientations);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startRun() {
    final session = LevelSession()..addListener(_onSessionChanged);
    _session = session;
    _game = _level!.createGame!(session);
    _saved = false;
  }

  void _onSessionChanged() {
    final session = _session;
    final level = _level;
    if (session == null || level == null) return;
    if (session.isFinished && !_saved) {
      _saved = true;
      _game?.pauseEngine(); // hasil sudah final; hentikan loop agar ringan di balik blur
      ref.read(progressProvider.notifier).submitStars(level.id, session.stars);
    }
  }

  void _restart() {
    final oldGame = _game;
    final oldSession = _session;
    oldSession?.removeListener(_onSessionChanged);
    setState(() {
      _runId++;
      _startRun();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldGame?.disposeAssets();
      oldSession?.dispose();
    });
  }

  void _pause() {
    final session = _session;
    if (session == null || !session.isPlaying) return;
    _game?.pauseEngine();
    session.pause();
  }

  void _resume() {
    _session?.resume();
    _game?.resumeEngine();
  }

  void _exit() => context.go('/levels');

  @override
  void dispose() {
    if (_orientationLocked) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    _session?.removeListener(_onSessionChanged);
    _game?.disposeAssets();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final session = _session;

    if (game == null || session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppText.levelUnavailable),
              const SizedBox(height: 16),
              FilledButton(onPressed: _exit, child: const Text(AppText.backButton)),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _pause(); // tombol back = pause, bukan keluar
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWidget(
                key: ValueKey(_runId),
                game: game,
                loadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
            Positioned.fill(child: game.buildHud(context)),
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: game.pauseButtonAlignment,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    child: ListenableBuilder(
                      listenable: session,
                      builder: (context, _) => session.isPlaying
                          ? IconButton(
                              icon: const Icon(Icons.pause_circle_outline, size: 32),
                              onPressed: _pause,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  switch (session.state) {
                    case SessionState.paused:
                      return PauseOverlay(
                        onResume: _resume,
                        onRestart: _restart,
                        onExit: _exit,
                      );
                    case SessionState.finished:
                      return ResultOverlay(
                        stars: session.stars,
                        step: session.step,
                        stepLabel: game.stepLabel,
                        bossName: _level?.bossName,
                        message: game.resultMessage(),
                        onRestart: _restart,
                        onExit: _exit,
                      );
                    case SessionState.playing:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
