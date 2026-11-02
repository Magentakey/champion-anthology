import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Latar Colosseum satu gambar (cover) dengan lapisan warna per fase
/// (siang -> sore -> malam berapi). Satu tekstur saja agar hemat memori.
///
/// Efek di atasnya: dinding dan penonton melonjak saat ramai ([cheer]) dan obor menyala
/// berkedip di fase 3.
class ArenaComponent extends PositionComponent {
  ArenaComponent(this._image);

  final Image _image;

  /// Sorak penonton 0..1 (naik tiap pukulan, turun sendiri).
  double cheer = 0;

  static const _tints = <Color>[
    Color(0x00FFFFFF), // fase 1: terang
    Color(0x40FF6F00), // fase 2: sore oranye
    Color(0x70B71C1C), // fase 3: merah menyala
  ];

  /// Garis antara dinding dan pasir pada gambar (560 dari 720 px).
  static const _floorFraction = 560 / 720;

  /// Bagian pasir yang digambar ulang di atas garis agar tidak ada celah saat dinding melonjak.
  static const _floorOverlapPx = 14.0;

  /// Posisi obor di dinding (pecahan lebar dan tinggi gambar).
  static const _torchX = [0.17, 0.39, 0.61, 0.83];
  static const _torchY = 0.66;

  Color _tint = _tints.first;
  Color _target = _tints.first;
  double _t = 0;
  double _torch = 0;
  double _torchTarget = 0;

  void setPhase(int phase) {
    _target = _tints[math.min(math.max(phase - 1, 0), _tints.length - 1)];
    _torchTarget = phase >= 3 ? 1 : 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _tint = Color.lerp(_tint, _target, math.min(1, dt * 2.5)) ?? _target;
    _torch += (_torchTarget - _torch) * math.min(1, dt * 2);
  }

  @override
  void render(Canvas canvas) {
    final iw = _image.width.toDouble(), ih = _image.height.toDouble();
    final scale = math.max(size.x / iw, size.y / ih);
    final w = iw * scale, h = ih * scale;
    // gambar menempel di bawah; kelebihan tinggi terpotong di atas
    final left = (size.x - w) / 2, top = size.y - h;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    final wallSrcH = ih * _floorFraction;
    final bob = cheer > 0.02 ? math.sin(_t * 18).abs() * cheer * 7 : 0.0;

    // dinding dan penonton (melonjak saat ramai)
    canvas.save();
    canvas.translate(0, -bob);
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, iw, wallSrcH),
      Rect.fromLTWH(left, top, w, wallSrcH * scale),
      paint,
    );
    canvas.restore();

    // pasir (diam)
    final floorSrcTop = wallSrcH - _floorOverlapPx;
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, floorSrcTop, iw, ih - floorSrcTop),
      Rect.fromLTWH(left, top + floorSrcTop * scale, w, (ih - floorSrcTop) * scale),
      paint,
    );

    if (_torch > 0.01) _drawTorches(canvas, Rect.fromLTWH(left, top, w, h), scale);

    if (_tint.a > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = _tint);
    }
  }

  void _drawTorches(Canvas canvas, Rect dst, double scale) {
    for (var i = 0; i < _torchX.length; i++) {
      final cx = dst.left + dst.width * _torchX[i];
      final cy = dst.top + dst.height * _torchY;
      final flicker = 0.75 + 0.25 * math.sin(_t * 17 + i * 2.1) + 0.1 * math.sin(_t * 29 + i);

      // cahaya hangat di sekitar obor
      final radius = 150 * scale;
      final alpha = math.min(255, math.max(0, (120 * _torch * flicker).round()));
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = Gradient.radial(
            Offset(cx, cy),
            radius,
            [Color.fromARGB(alpha, 255, 170, 40), const Color(0x00FFAA28)],
          ),
      );

      // tiang obor
      canvas.drawLine(
        Offset(cx, cy + 8 * scale),
        Offset(cx, cy + 46 * scale),
        Paint()
          ..color = const Color(0xFF141418)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6 * scale,
      );

      // api: lapisan oranye lalu kuning
      final fh = 50 * scale * flicker * _torch;
      final fw = 17 * scale * _torch;
      Path flame(double k) => Path()
        ..moveTo(cx, cy + 8 * scale)
        ..quadraticBezierTo(cx - fw * k, cy - fh * k * 0.35, cx, cy + 8 * scale - fh * k)
        ..quadraticBezierTo(cx + fw * k, cy - fh * k * 0.35, cx, cy + 8 * scale);
      canvas.drawPath(flame(1), Paint()..color = const Color(0xFFFF7A00));
      canvas.drawPath(flame(0.55), Paint()..color = const Color(0xFFFFD54F));
    }
  }
}
