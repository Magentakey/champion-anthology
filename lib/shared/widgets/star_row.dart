import 'package:flutter/material.dart';

class StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const StarRow({super.key, required this.stars, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          i < stars ? Icons.star : Icons.star_border,
          size: size,
          color: i < stars ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}
