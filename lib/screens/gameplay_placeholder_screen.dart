import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/save/progress_repository.dart';

/// Sementara (minggu 1): simulasi hasil level untuk menguji penyimpanan bintang.
/// Minggu 2 diganti GameWidget Flame + StepController.
class GameplayPlaceholderScreen extends ConsumerWidget {
  final String levelId;

  const GameplayPlaceholderScreen({super.key, required this.levelId});

  Future<void> _finish(BuildContext context, WidgetRef ref, int stars) async {
    await ref.read(progressProvider.notifier).submitStars(levelId, stars);
    if (context.mounted) context.go('/levels');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gameplay: $levelId (placeholder)'),
              const SizedBox(height: 24),
              for (final s in [0, 1, 2, 3]) ...[
                FilledButton(
                  onPressed: () => _finish(context, ref, s),
                  child: Text('Simulasi hasil: $s bintang'),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
