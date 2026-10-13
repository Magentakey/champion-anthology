import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../levels/level_registry.dart';

class BossIntroScreen extends StatelessWidget {
  final String levelId;

  const BossIntroScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    final level = levelById(levelId);
    if (level == null) {
      return const Scaffold(body: Center(child: Text('Level tidak ditemukan')));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('< back'),
                ),
              ),
              _Bubble(text: level.bossName),
              const Spacer(),
              // TODO(art): sprite boss
              const Icon(Icons.accessibility_new, size: 160, color: Colors.blue),
              const Spacer(),
              _Bubble(text: level.introDialog),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pushReplacement('/play/${level.id}'),
                child: const Text('Mulai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;

  const _Bubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
