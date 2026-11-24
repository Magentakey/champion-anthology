import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../shared/widgets/pixel_pattern.dart';
import 'archery_model.dart';

/// Anak panah yang sedang terbang menuju papan.
class FlyingArrow {
  FlyingArrow(this.impact);

  /// Titik jatuh relatif terhadap pusat papan (satuan jari-jari).
  final Offset impact;
  double progress = 0;
}

/// Area bidik: papan sasaran bergaya piksel (kisi sel), kaki penyangga, anak panah yang menancap,
/// anak panah yang terbang, dan bidikan. Semua digambar tanpa antialiasing.
class ArcheryRange extends PositionComponent {
  /// Tembakan aktif (untuk bidikan) dan gerak papan; di-set oleh game.
  ArcheryShot? shot;
  TargetMotion? motion;

  /// Waktu gerak papan (detik sejak step dimulai).
  double clock = 0;

  /// Anak panah yang menancap, relatif terhadap pusat papan (satuan jari-jari).
  final List<Offset> stuck = [];
  FlyingArrow? flying;
  bool showCrosshair = false;

  static const _grid = 24; // sel per sisi gambar papan: 20 sel isi + 2 sel garis tepi tiap sisi
  static const _playable = 20;

  // Paint dipakai ulang; semuanya tanpa antialiasing (pixel art).
  final Paint _cell = Paint()..isAntiAlias = false;
  final Paint _line = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;

  Picture? _face;
  double _faceRadius = 0;

  static const _ink = Color(0xFF18122A);
  static const _wood = Color(0xFF8D5C2E);
  static const _ringColors = <Color>[
    Color(0xFFFFD640), // emas
    Color(0xFFE03C3C), // merah
    Color(0xFF3C7CE0), // biru
    Color(0xFF282232), // hitam
    Color(0xFFFAFAFA), // putih
  ];

  double get radius => math.min(size.x * 0.34, size.y * 0.40);
  Offset get aimCenter => Offset(size.x / 2, size.y / 2);

  Offset get targetCenter {
    final m = motion;
    return aimCenter + (m == null ? Offset.zero : m.at(clock)) * radius;
  }

  /// Gambar papan dibuat sekali per ukuran (sel persegi, lingkaran bergerigi piksel).
  Picture _buildFace(double r) {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final cell = 2 * r / _playable;
    final half = _grid / 2;
    for (var gy = 0; gy < _grid; gy++) {
      for (var gx = 0; gx < _grid; gx++) {
        final d = math.sqrt(math.pow(gx + 0.5 - half, 2) + math.pow(gy + 0.5 - half, 2)) / (_playable / 2);
        Color? color;
        if (d <= 1.0) {
          color = _ringColors[math.min(4, (d / 0.2).floor())];
        } else if (d <= 1.0 + 1.2 / (_playable / 2)) {
          color = _ink;
        }
        if (color == null) continue;
        _cell.color = color;
        c.drawRect(Rect.fromLTWH((gx - half) * cell, (gy - half) * cell, cell + 0.5, cell + 0.5), _cell);
      }
    }
    return rec.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final r = radius;
    if (r <= 0) return;
    final cell = 2 * r / _playable;
    final tc = targetCenter;

    // kaki penyangga (di belakang papan): garis tepi gelap, lalu kayu
    void leg(Offset a, Offset b, double w) {
      _line
        ..color = _ink
        ..strokeWidth = w + cell * 1.2;
      canvas.drawLine(a, b, _line);
      _line
        ..color = _wood
        ..strokeWidth = w;
      canvas.drawLine(a, b, _line);
    }

    leg(tc + Offset(-r * 0.45, r * 0.5), tc + Offset(-r * 0.85, r * 1.15), cell * 1.4);
    leg(tc + Offset(r * 0.45, r * 0.5), tc + Offset(r * 0.85, r * 1.15), cell * 1.4);
    leg(tc + Offset(0, r * 0.5), tc + Offset(0, r * 1.1), cell * 1.2);

    if (_face == null || (_faceRadius - r).abs() > 0.5) {
      _face = _buildFace(r);
      _faceRadius = r;
    }
    canvas.save();
    canvas.translate(tc.dx, tc.dy);
    canvas.drawPicture(_face!);
    canvas.restore();

    // anak panah yang menancap
    for (final off in stuck) {
      drawPixelPattern(
        canvas,
        PixelPatterns.arrowStuck,
        Rect.fromCenter(center: tc + off * r, width: cell * 3.6, height: cell * 3.6),
        _stuckColor,
        outline: false,
      );
    }

    _drawFlying(canvas, tc, r, cell);
    if (showCrosshair) _drawCrosshair(canvas, r, cell);
  }

  static Color _stuckColor(String ch) => switch (ch) {
        'k' => _wood,
        'r' => const Color(0xFFE03C3C),
        _ => const Color(0xFFCFD8DC),
      };

  void _drawFlying(Canvas canvas, Offset tc, double r, double cell) {
    final f = flying;
    if (f == null) return;
    final start = Offset(aimCenter.dx, size.y + 28);
    final end = tc + f.impact * r;
    final p = f.progress.clamp(0.0, 1.0).toDouble();
    final eased = 1 - math.pow(1 - p, 2).toDouble();
    final pos = Offset.lerp(start, end, eased)!;
    final dir = end - start;
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final shaft = 40.0 * (1 - 0.45 * p);
    final tail = pos - unit * shaft;
    _line
      ..color = _ink
      ..strokeWidth = cell * 1.5;
    canvas.drawLine(tail, pos, _line);
    _line
      ..color = _wood
      ..strokeWidth = cell * 0.7;
    canvas.drawLine(tail, pos, _line);
    // mata dan bulu
    _cell.color = const Color(0xFFCFD8DC);
    canvas.drawRect(Rect.fromCenter(center: pos, width: cell * 1.3, height: cell * 1.3), _cell);
    _cell.color = const Color(0xFFE03C3C);
    canvas.drawRect(Rect.fromCenter(center: tail, width: cell * 1.5, height: cell * 1.5), _cell);
  }

  void _drawCrosshair(Canvas canvas, double r, double cell) {
    final s = shot;
    if (s == null || s.released) return;
    final center = aimCenter + s.crosshair * r;
    final gold = s.scoreNow >= 10;
    final color = gold ? const Color(0xFFFFD640) : const Color(0xFFFFF4D6);
    final arm = r * 0.22;
    final gap = r * 0.06;
    final w = math.max(2.0, cell * 0.8);
    void bar(Rect rect) {
      _cell.color = _ink;
      canvas.drawRect(rect.inflate(w * 0.6), _cell);
    }

    final bars = <Rect>[
      Rect.fromLTRB(center.dx - gap - arm, center.dy - w / 2, center.dx - gap, center.dy + w / 2),
      Rect.fromLTRB(center.dx + gap, center.dy - w / 2, center.dx + gap + arm, center.dy + w / 2),
      Rect.fromLTRB(center.dx - w / 2, center.dy - gap - arm, center.dx + w / 2, center.dy - gap),
      Rect.fromLTRB(center.dx - w / 2, center.dy + gap, center.dx + w / 2, center.dy + gap + arm),
      Rect.fromCenter(center: center, width: w, height: w),
    ];
    bars.forEach(bar);
    _cell.color = color;
    for (final b in bars) {
      canvas.drawRect(b, _cell);
    }
  }
}
