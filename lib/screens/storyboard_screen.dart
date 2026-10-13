import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Layout 4 panel sesuai sketsa: 1 di atas, 4 kiri besar, 2 & 3 bertumpuk di kanan.
class StoryboardScreen extends StatelessWidget {
  const StoryboardScreen({super.key});

  Widget _panel(int n) => Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(width: 2),
          color: Colors.white54,
        ),
        alignment: Alignment.center,
        child: Text('Panel $n'), // TODO(art): ilustrasi panel
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(flex: 2, child: _panel(1)),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(child: _panel(4)),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: _panel(2)),
                                Expanded(child: _panel(3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton(
                onPressed: () => context.go('/levels'),
                child: const Text('Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
