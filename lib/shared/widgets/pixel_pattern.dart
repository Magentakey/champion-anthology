import 'package:flutter/material.dart';

import 'pixel_ui.dart';

/// Menggambar pola piksel dari teks (`.` = kosong, karakter lain = piksel berwarna) ke [rect].
///
/// - [outline] true: tiap sel terisi dikelilingi garis tepi gelap 1 sel (rect = pola + 2 sel).
/// - [outline] false: pola sudah membawa garis tepinya sendiri (mis. karakter `O`).
/// Tanpa antialiasing; dipakai widget Flutter ([PixelIcon]) dan komponen Flame (labirin).
void drawPixelPattern(
  Canvas canvas,
  List<String> rows,
  Rect rect,
  Color Function(String ch) colorOf, {
  bool outline = true,
}) {
  final cols = rows.first.length;
  final extra = outline ? 2 : 0;
  final cell = rect.width / (cols + extra);
  final paint = Paint()..isAntiAlias = false;
  final off = outline ? 1 : 0;

  bool filled(int x, int y) {
    if (y < 0 || y >= rows.length || x < 0 || x >= cols) return false;
    return rows[y][x] != '.';
  }

  void cellAt(int gx, int gy, Color c) {
    paint.color = c;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + gx * cell, rect.top + gy * cell, cell + 0.5, cell + 0.5),
      paint,
    );
  }

  final from = outline ? -1 : 0;
  for (var y = from; y < rows.length + off; y++) {
    for (var x = from; x < cols + off; x++) {
      if (filled(x, y)) {
        cellAt(x + off, y + off, colorOf(rows[y][x]));
      } else if (outline && (filled(x - 1, y) || filled(x + 1, y) || filled(x, y - 1) || filled(x, y + 1))) {
        cellAt(x + off, y + off, PixelUi.outline);
      }
    }
  }
}

/// Pola baku yang dipakai bersama.
class PixelPatterns {
  const PixelPatterns._();

  static const star = <String>[
    '...#...',
    '..###..',
    '#######',
    '.#####.',
    '..###..',
    '.##.##.',
    '.#...#.',
  ];

  static const lock = <String>[
    '..####..',
    '.##..##.',
    '.#....#.',
    '########',
    '########',
    '###kk###',
    '###kk###',
    '########',
    '########',
  ];

  static const heart = <String>[
    '.##.##.',
    '#######',
    '#######',
    '.#####.',
    '..###..',
    '...#...',
  ];

  static const arrowUp = <String>[
    '...#...',
    '..###..',
    '.#####.',
    '#######',
    '..###..',
    '..###..',
    '..###..',
  ];

  static const arrowDown = <String>[
    '..###..',
    '..###..',
    '..###..',
    '#######',
    '.#####.',
    '..###..',
    '...#...',
  ];

  static const arrowLeft = <String>[
    '...#...',
    '..##...',
    '.###...',
    '#######',
    '.###...',
    '..##...',
    '...#...',
  ];

  static const arrowRight = <String>[
    '...#...',
    '...##..',
    '...###.',
    '#######',
    '...###.',
    '...##..',
    '...#...',
  ];

  static const check = <String>[
    '.....#',
    '....##',
    '#..##.',
    '###.#.',
    '.##...',
    '..#...',
  ];

  static const fire = <String>[
    '...#...',
    '..##...',
    '..###..',
    '.#####.',
    '.#####.',
    '#######',
    '#######',
    '.#####.',
  ];

  /// Ikon tombol pertarungan (`k` = warna kedua: celah jari, palang perisai, gagang pisau).
  static const fist = <String>[
    '.#######.',
    '#########',
    '#k#k#k#k#',
    '#########',
    '#########',
    '.#######.',
    '..#####..',
    '...###...',
  ];

  static const boot = <String>[
    '..###....',
    '..###....',
    '..###....',
    '..####...',
    '..######.',
    '..#######',
    '.########',
    '.########',
  ];

  static const shield = <String>[
    '#########',
    '####k####',
    '#kkkkkkk#',
    '####k####',
    '.###k###.',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
  ];

  static const knife = <String>[
    '.......##',
    '......###',
    '.....###.',
    '....###..',
    '.k.###...',
    '.kk##....',
    '..kkk....',
    '.kk.k....',
    'kk.......',
  ];

  /// Anak panah kecil (`y` mata, `k` batang, `r` bulu) untuk hitungan sisa dan yang menancap di papan.
  static const arrowItem = <String>[
    '.y.',
    'yyy',
    '.k.',
    '.k.',
    '.k.',
    '.k.',
    'rkr',
    '.r.',
  ];

  /// Anak panah yang menancap di papan, dilihat dari belakang (`k` batang, `r` bulu, `y` mata).
  static const arrowStuck = <String>[
    'r...r',
    '.r.r.',
    '..k..',
    '.r.r.',
    'r...r',
  ];

  /// Kepala pemain 9x9 untuk labirin (garis tepi `O` sudah termasuk).
  static const playerHead = <String>[
    '..OOOOO..',
    '.OHHHHHO.',
    'OHHHHHHHO',
    'ORRRRRRRO',
    'OSSSSSSSO',
    'OSESSSESO',
    'OSSSSSSSO',
    '.OSSKSSO.',
    '..OOOOO..',
  ];

  static Color playerColor(String ch) => switch (ch) {
        'O' => PixelUi.outline,
        'H' => const Color(0xFF362E4A),
        'R' => const Color(0xFFE23636),
        'S' => const Color(0xFFFFD6AA),
        'E' => const Color(0xFF160E18),
        'K' => const Color(0xFF801A2C),
        _ => PixelUi.outline,
      };
}

/// Ikon piksel dari pola. [size] = tinggi total (dp) termasuk garis tepi; lebar mengikuti pola.
class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.rows,
    required this.size,
    this.color = PixelUi.cream,
    this.colorOf,
    this.outline = true,
  });

  final List<String> rows;
  final double size;
  final Color color;
  final Color Function(String ch)? colorOf;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final extra = outline ? 2 : 0;
    final cell = size / (rows.length + extra);
    return SizedBox(
      width: cell * (rows.first.length + extra),
      height: size,
      child: CustomPaint(
        painter: _IconPainter(rows, colorOf ?? (_) => color, outline),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.rows, this.colorOf, this.outline);

  final List<String> rows;
  final Color Function(String ch) colorOf;
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    drawPixelPattern(canvas, rows, Offset.zero & size, colorOf, outline: outline);
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) => true; // warna bisa berubah
}

/// Bar progres piksel: bingkai gelap, latar redup, dan blok-blok berwarna.
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    required this.color,
    required this.unit,
    this.segments = 20,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double unit;
  final int segments;

  /// Tinggi dalam piksel logis.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * unit,
      width: double.infinity,
      child: CustomPaint(painter: _BarPainter(value.clamp(0.0, 1.0), color, segments, unit)),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.value, this.color, this.segments, this.unit);

  final double value;
  final Color color;
  final int segments;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.color = PixelUi.outline;
    canvas.drawRect(Offset.zero & size, paint);
    final t = unit.clamp(1.0, 6.0);
    final inner = Rect.fromLTWH(t, t, size.width - 2 * t, size.height - 2 * t);
    paint.color = const Color(0xFF50466E);
    canvas.drawRect(inner, paint);
    final gap = t;
    final blockW = (inner.width - gap * (segments - 1)) / segments;
    final lit = (value * segments).ceil();
    paint.color = color;
    for (var i = 0; i < lit; i++) {
      canvas.drawRect(
        Rect.fromLTWH(inner.left + i * (blockW + gap), inner.top, blockW, inner.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) => true;
}

/// Hati piksel untuk nyawa.
class PixelHeart extends StatelessWidget {
  const PixelHeart({super.key, required this.filled, this.size = 16});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelIcon(
      rows: PixelPatterns.heart,
      size: size,
      color: filled ? const Color(0xFFE23636) : const Color(0xFF50466E),
    );
  }
}
