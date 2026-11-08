import 'package:flutter/widgets.dart';

import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';

enum PadIcon { left, right, punch, kick, block, knife }

/// Ikon tombol kontrol bergaya piksel (pola di [PixelPatterns]); [size] = tinggi total (dp).
class PadIconView extends StatelessWidget {
  const PadIconView(this.icon, {super.key, required this.size});

  final PadIcon icon;
  final double size;

  static const _brown = Color(0xFF8D5C2E);

  @override
  Widget build(BuildContext context) {
    final rows = switch (icon) {
      PadIcon.left => PixelPatterns.arrowLeft,
      PadIcon.right => PixelPatterns.arrowRight,
      PadIcon.punch => PixelPatterns.fist,
      PadIcon.kick => PixelPatterns.boot,
      PadIcon.block => PixelPatterns.shield,
      PadIcon.knife => PixelPatterns.knife,
    };
    Color colorOf(String ch) => switch ((icon, ch)) {
          (PadIcon.knife, 'k') => _brown,
          (PadIcon.knife, _) => const Color(0xFFCFD8DC),
          (_, 'k') => PixelUi.dark,
          _ => PixelUi.cream,
        };
    return PixelIcon(rows: rows, size: size, colorOf: colorOf);
  }
}
