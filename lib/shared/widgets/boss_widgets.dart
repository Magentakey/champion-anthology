import 'package:flutter/material.dart';

import 'pixel_pattern.dart';
import 'pixel_ui.dart';

/// Gelembung ucapan boss di sebelah kanan karakternya; [text] null = sembunyi.
/// Bingkai krem bergaya piksel dengan ekor kecil yang menunjuk ke boss (kiri).
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

  static const _tail = <String>['..#', '.##', '###', '.##', '..#'];

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.unit(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -4 * u,
          top: 10 * u,
          child: PixelIcon(rows: _tail, size: 7 * u, color: PixelUi.paper),
        ),
        PixelFrame(
          unit: u,
          fill: PixelUi.paper,
          padding: EdgeInsets.all(4 * u),
          child: Text(
            text,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: PixelUi.text(u, color: PixelUi.ink, height: 1.15),
          ),
        ),
      ],
    );
  }
}

/// Banner besar saat pergantian step ("STEP 2" + tingkat kesulitan).
class StepBannerCard extends StatelessWidget {
  const StepBannerCard({super.key, required this.step, required this.label, this.word = 'STEP', this.note});

  final int step;
  final String label;

  /// Baris kecil di bawah [label] (mis. target akurasi Level 7). null = tidak ada.
  final String? note;

  /// Kata di judul banner (default "STEP"; Level 6 memakai "ROUND").
  final String word;

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.unit(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(step),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: SizedBox.expand(
        child: PixelFrame(
          unit: u,
          padding: EdgeInsets.all(4 * u),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$word $step',
                    style: PixelUi.text(u, scale: 3, color: PixelUi.gold, outline: PixelUi.goldOutline, shadow: PixelUi.outline),
                  ),
                  SizedBox(height: 6 * u),
                  Text(label, style: PixelUi.text(u, scale: 2, color: PixelUi.cream)),
                  if (note != null) ...[
                    SizedBox(height: 6 * u),
                    Text(note!, style: PixelUi.text(u, color: PixelUi.gold)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
