import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gelembung ucapan boss di sebelah kanan karakternya; [text] null = sembunyi.
class BossSpeechBubble extends StatelessWidget {
  const BossSpeechBubble({super.key, required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, alignment: Alignment.centerLeft, child: child),
        ),
        child: text == null
            ? const SizedBox.shrink(key: ValueKey('none'))
            : _BubbleBody(key: ValueKey(text), text: text!),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.grey.shade500);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(border),
          ),
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Positioned(
          left: -6,
          top: 20,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: border, bottom: border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Banner besar saat pergantian step ("STEP 2" + tingkat kesulitan).
class StepBannerCard extends StatelessWidget {
  const StepBannerCard({super.key, required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(step),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STEP $step',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
