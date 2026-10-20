import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Karakter pemain di lapisan paling belakang.
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/mc_home.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppText.gameTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    // Setiap menekan Main, cerita tampil lagi.
                    onPressed: () => context.go('/story'),
                    child: const Text(AppText.play),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text(AppText.quit),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
