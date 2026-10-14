import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import 'star_row.dart';

class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Blur semua yang ada di belakang overlay (arena Flame + HUD); panel tetap tajam.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ColoredBox(
          color: const Color(0x55000000),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _Scrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pause', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          FilledButton(onPressed: onResume, child: const Text('Lanjut')),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRestart, child: const Text('Ulangi')),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.muted,
            builder: (context, muted, _) => FilledButton(
              onPressed: () => AudioService.instance.setMuted(!muted),
              child: Text(muted ? 'Suara: Mati' : 'Suara: Nyala'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onExit, child: const Text('Keluar')),
        ],
      ),
    );
  }
}

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.stars,
    required this.step,
    required this.onRestart,
    required this.onExit,
    this.bossName,
    this.message,
  });

  final int stars;
  final int step;
  final String? bossName;
  final String? message;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _Scrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stars >= 3 ? 'Perfect Clear!' : 'Kalah di Step $step',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          StarRow(stars: stars, size: 40),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              bossName == null ? '"$message"' : '$bossName:\n"$message"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: onRestart, child: const Text('Ulangi')),
          const SizedBox(height: 12),
          FilledButton(onPressed: onExit, child: const Text('Level Select')),
        ],
      ),
    );
  }
}
