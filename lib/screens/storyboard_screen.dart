import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../core/save/progress_repository.dart';
import 'story_data.dart';

/// Storyboard 4 panel sesuai sketsa (1 atas, 4 kiri besar, 2 & 3 kanan).
/// Ketuk layar untuk memunculkan panel berikutnya.
class StoryboardScreen extends ConsumerStatefulWidget {
  const StoryboardScreen({super.key});

  @override
  ConsumerState<StoryboardScreen> createState() => _StoryboardScreenState();
}

class _StoryboardScreenState extends ConsumerState<StoryboardScreen> {
  int _revealed = 1;

  bool get _allRevealed => _revealed >= storyPanels.length;

  void _advance() {
    if (!_allRevealed) setState(() => _revealed++);
  }

  void _finish() {
    unawaited(ref.read(sharedPrefsProvider).setBool(storySeenKey, true));
    context.go('/levels');
  }

  Widget _panel(int index) {
    final panel = storyPanels[index];
    final visible = index < _revealed;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        color: Colors.white54,
      ),
      child: ClipRect(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 450),
          child: AnimatedScale(
            scale: visible ? 1 : 0.92,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  panel.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const ColoredBox(color: Color(0xFFE0E0E0)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      panel.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(AppText.storySkip),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Expanded(flex: 2, child: _panel(0)),
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Expanded(child: _panel(3)),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(child: _panel(1)),
                                  Expanded(child: _panel(2)),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _allRevealed
                    ? FilledButton(
                        onPressed: _finish,
                        child: const Text(AppText.storyContinue),
                      )
                    : const Text(
                        AppText.storyTapHint,
                        style: TextStyle(color: Colors.black54),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
