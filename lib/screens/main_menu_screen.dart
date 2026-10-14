import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../core/save/progress_repository.dart';
import 'story_data.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storySeen =
        ref.read(sharedPrefsProvider).getBool(storySeenKey) ?? false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TODO(art): ganti dengan logo / karakter MC final
              const Icon(Icons.accessibility_new, size: 160, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppText.gameTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              FilledButton(
                // Cerita hanya otomatis tampil pertama kali.
                onPressed: () => context.go(storySeen ? '/levels' : '/story'),
                child: const Text(AppText.play),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text(AppText.quit),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/story'),
                child: const Text(AppText.viewStory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
