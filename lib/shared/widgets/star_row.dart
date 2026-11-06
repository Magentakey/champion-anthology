import 'package:flutter/material.dart';

import 'pixel_ui.dart';

/// Tiga bintang piksel; [stars] yang terisi berwarna emas. [size] = ukuran tiap bintang (dp).
class StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const StarRow({super.key, required this.stars, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: size * 0.12),
          PixelStar(filled: i < stars, size: size),
        ],
      ],
    );
  }
}
