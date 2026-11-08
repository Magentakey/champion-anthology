import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../shared/widgets/pixel_pattern.dart';

/// Latar Colosseum piksel satu gambar (cover) dengan lapisan warna per fase
/// (siang -> sore -> malam berapi). Satu tekstur saja agar hemat memori.
///
/// Efek di atasnya: dinding dan penonton melonjak saat ramai ([cheer]) dan obor piksel menyala
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

  /// Tiga bingkai api obor (`o` oranye, `y` kuning), digambar bergantian agar berkedip.
  static const _flames = <List<String>>[
    [
      '...o...',
      '..oo...',
      '..ooo..',
      '.oooyo.',
      '.ooyyo.',
      'oooyyoo',
      'oooyyoo',
      '.oooyo.',
    ],
    [
      '....o..',
      '...oo..',
      '..ooo..',
      '.ooyoo.',
      '.oyyoo.',
      'ooyyooo',
      'ooyyooo',
      '.ooyoo.',
    ],
    [
      '..o....',
      '..oo...',
      '.ooo...',
      '.oyooo.',
      '.oyyoo.',
      'ooyyoo.',
      'ooyyooo',
      '.ooyoo.',
    ],
  ];

  // Paint dipakai ulang tiap frame; semuanya tanpa antialiasing dan tanpa penghalusan (pixel art).
  static final Paint _imagePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final Paint _tintPaint = Paint()..isAntiAlias = false;
  final Paint _glowPaint = Paint()..isAntiAlias = false;
  final Paint _polePaint = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF8D5C2E);
  final Paint _poleEdge = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF18122A);

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
    final paint = _imagePaint;

    final wallSrcH = ih * _floorFraction;
    // lonjakan penonton dibulatkan ke piksel layar utuh agar tetap tajam
    final bob = cheer > 0.02 ? (math.sin(_t * 18).abs() * cheer * 7).roundToDouble() : 0.0;

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
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _tintPaint..color = _tint);
    }
  }

  void _drawTorches(Canvas canvas, Rect dst, double scale) {
    // satu "piksel" gambar arena = 4 px gambar; api digambar dengan ukuran sel yang sama
    final cell = 4 * scale;
    for (var i = 0; i < _torchX.length; i++) {
      final cx = dst.left + dst.width * _torchX[i];
      final cy = dst.top + dst.height * _torchY;
      final flicker = 0.75 + 0.25 * math.sin(_t * 17 + i * 2.1) + 0.1 * math.sin(_t * 29 + i);

      // cahaya hangat di sekitar obor: tiga cincin berpita (tanpa gradasi halus)
      final glow = math.min(1.0, math.max(0.0, _torch * flicker));
      const rings = <(double, int)>[(150, 22), (104, 30), (60, 40)];
      for (final (r, a) in rings) {
        _glowPaint.color = Color.fromARGB((a * glow).round(), 255, 170, 40);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 2 * r * scale, height: 2 * r * scale), _glowPaint);
      }

      // tiang obor
      canvas.drawRect(Rect.fromLTWH(cx - cell * 1.5, cy + cell * 2, cell * 3, cell * 9), _poleEdge);
      canvas.drawRect(Rect.fromLTWH(cx - cell * 0.5, cy + cell * 2, cell * 2, cell * 9), _polePaint);

      // api: bingkai bergantian, ukuran mengikuti nyala obor
      final frame = _flames[((_t * 9 + i) % _flames.length).floor()];
      final k = 0.6 + 0.4 * _torch;
      final fw = cell * 7 * k, fh = cell * 8 * k;
      drawPixelPattern(
        canvas,
        frame,
        Rect.fromLTWH(cx - fw / 2, cy + cell * 2 - fh, fw, fh),
        (ch) => ch == 'y' ? const Color(0xFFFFD54F) : const Color(0xFFFF7A00),
        outline: false,
      );
    }
  }
}
