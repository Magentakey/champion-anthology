import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                'The World in\nMy Hands!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/story'),
                child: const Text('Play'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Quit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
