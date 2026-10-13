import 'package:flutter/material.dart';

import 'star_row.dart';

class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
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
  });

  final int stars;
  final int step;
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
          const SizedBox(height: 24),
          FilledButton(onPressed: onRestart, child: const Text('Ulangi')),
          const SizedBox(height: 12),
          FilledButton(onPressed: onExit, child: const Text('Level Select')),
        ],
      ),
    );
  }
}
