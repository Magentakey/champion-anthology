import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Karakter pemain besar di lapisan paling belakang.
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/mc_home.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Align(
                alignment: const Alignment(0, 0.25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppText.gameTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 8),
                          Shadow(color: Colors.white, blurRadius: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: FilledButton(
                        // Setiap menekan Main, cerita tampil lagi.
                        onPressed: () => context.go('/story'),
                        child: const Text(AppText.play),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: FilledButton(
                        onPressed: () => SystemNavigator.pop(),
                        child: const Text(AppText.quit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
