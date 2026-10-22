import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Latar Colosseum satu gambar (cover) dengan lapisan warna per fase:
/// siang -> sore -> malam berapi. Satu tekstur saja agar hemat memori.
class ArenaComponent extends PositionComponent {
  ArenaComponent(this._image);

  final Image _image;

  static const _tints = <Color>[
    Color(0x00FFFFFF), // fase 1: terang
    Color(0x40FF6F00), // fase 2: sore oranye
    Color(0x70B71C1C), // fase 3: merah menyala
  ];

  Color _tint = _tints.first;
  Color _target = _tints.first;

  void setPhase(int phase) {
    _target = _tints[math.min(math.max(phase - 1, 0), _tints.length - 1)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tint = Color.lerp(_tint, _target, math.min(1, dt * 2.5)) ?? _target;
  }

  @override
  void render(Canvas canvas) {
    final iw = _image.width.toDouble(), ih = _image.height.toDouble();
    final scale = math.max(size.x / iw, size.y / ih);
    final w = iw * scale, h = ih * scale;
    // gambar menempel di bawah; kelebihan tinggi terpotong di atas
    final dst = Rect.fromLTWH((size.x - w) / 2, size.y - h, w, h);
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, iw, ih),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    if (_tint.a > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = _tint);
    }
  }
}
