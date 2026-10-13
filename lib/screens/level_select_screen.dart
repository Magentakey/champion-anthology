import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/save/progress_repository.dart';
import '../levels/level_registry.dart';
import '../shared/widgets/star_row.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  static const _slotCount = 9; // grid 3x3 sesuai sketsa

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('< back'),
              ),
            ),
            Text('Beat them!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(24),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: List.generate(_slotCount, (i) {
                  if (i >= levelRegistry.length) {
                    return _Slot(label: '', stars: 0, locked: true, onTap: () {});
                  }
                  final level = levelRegistry[i];
                  final unlocked = notifier.isUnlocked(level);
                  return _Slot(
                    label: '${level.number}',
                    stars: progress[level.id] ?? 0,
                    locked: !unlocked,
                    onTap: () {
                      if (unlocked) {
                        context.push('/intro/${level.id}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(level.available
                                ? 'Selesaikan level sebelumnya dulu'
                                : 'Segera hadir'),
                          ),
                        );
                      }
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final int stars;
  final bool locked;
  final VoidCallback onTap;

  const _Slot({
    required this.label,
    required this.stars,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StarRow(stars: stars),
        const SizedBox(height: 4),
        Expanded(
          child: Material(
            color: locked ? Colors.grey.shade400 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Center(
                child: locked && label.isNotEmpty
                    ? const Icon(Icons.lock, color: Colors.black54)
                    : Text(label, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
