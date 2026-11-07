import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Gambar latar yang menutupi seluruh area (cover, dipotong di tepi) tanpa penghalusan (pixel art).
/// [alignY]: 0 = bagian atas gambar dipertahankan, 1 = bagian bawah dipertahankan.
class CoverBackground extends PositionComponent {
  CoverBackground(this._image, {this.alignY = 1.0});

  final Image _image;
  final double alignY;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  @override
  void render(Canvas canvas) {
    final iw = _image.width.toDouble();
    final ih = _image.height.toDouble();
    final scale = max(size.x / iw, size.y / ih);
    final srcW = size.x / scale;
    final srcH = size.y / scale;
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH((iw - srcW) / 2, (ih - srcH) * alignY, srcW, srcH),
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
}
