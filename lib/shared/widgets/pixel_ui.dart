import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gaya dan widget pixel art (aturan lengkap: docs/PIXEL_ART_STYLE.md).
///
/// Semua layar piksel memakai kisi rujukan 240x426 "piksel logis". [PixelUi.unit] memberi ukuran
/// satu piksel logis dalam dp untuk layar sekarang, jadi layout mengikuti mockup di layar mana pun.
class PixelUi {
  const PixelUi._();

  static const fontFamily = 'PixelChampion';

  static const outline = Color(0xFF18122A);
  static const dark = Color(0xFF1A142C);
  static const cream = Color(0xFFFFF4D6);
  static const paper = Color(0xFFFAF0D6);
  static const ink = Color(0xFF281E3C);
  static const night = Color(0xFF161228);

  static const gold = Color(0xFFFFD640);
  static const goldOutline = Color(0xFF961E32);
  static const lavender = Color(0xFFBEB4DC);
  static const panelDark = Color(0xFF3A3050);

  static const gridWidth = 240.0;
  static const gridHeight = 426.0;

  /// dp per piksel logis; memakai sisi yang lebih sempit agar seluruh kisi muat.
  static double unitFor(Size size) => math.min(size.width / gridWidth, size.height / gridHeight);

  static double unit(BuildContext context) => unitFor(MediaQuery.sizeOf(context));

  /// Unit untuk overlay dan layar landscape: berdasarkan sisi terpendek layar, supaya tombol
  /// tetap besar di layar lebar (kisi 240x426 hanya cocok untuk layar potret).
  static double overlayUnit(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / 240).clamp(1.4, 3.0).toDouble();

  /// Gaya teks piksel. [scale] = ukuran 1 piksel font dalam piksel logis (1, 2, atau 3).
  /// Tebal tepi sama dengan [scale] (aturan style lock). Font hanya punya huruf besar:
  /// huruf kecil otomatis tampil sebagai huruf besar.
  static TextStyle text(
    double u, {
    double scale = 1,
    Color color = cream,
    Color? outline,
    Color? shadow,
    double height = 1.0,
  }) {
    final t = scale * u;
    final shadows = <Shadow>[];
    if (shadow != null) {
      shadows.add(Shadow(color: shadow, offset: Offset(t, scale > 1 ? 2 * t : t)));
    }
    if (outline != null) {
      for (final dx in const [-1.0, 0.0, 1.0]) {
        for (final dy in const [-1.0, 0.0, 1.0]) {
          if (dx != 0 || dy != 0) {
            shadows.add(Shadow(color: outline, offset: Offset(dx * t, dy * t)));
          }
        }
      }
    }
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 10 * t, // 1 piksel font = 100/1000 em
      color: color,
      height: height,
      letterSpacing: 0,
      fontWeight: FontWeight.normal,
      shadows: shadows,
    );
  }
}

/// Tombol piksel 104x26 piksel logis (atau 160x26 jika [wide]) + bayangan jatuh 2 piksel.
/// Label berupa teks biasa, jadi mudah diuji dan terbaca pembaca layar.
/// [secondary] = biru, selain itu merah. [unit] mengganti ukuran piksel (untuk overlay/landscape).
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.wide = false,
    this.unit,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;
  final bool wide;
  final double? unit;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit ?? PixelUi.unit(context);
    final kind = widget.secondary ? 'secondary' : 'primary';
    final asset = 'assets/images/home/btn_${widget.wide ? 'wide_' : ''}$kind.png';
    final w = widget.wide ? 160.0 : 104.0;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onPressed,
        child: SizedBox(
          width: (w + 2) * u,
          height: 28 * u,
          child: Transform.translate(
            offset: Offset(0, _down ? 2 * u : 0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(asset, fit: BoxFit.fill, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: w * u,
                  height: 26 * u,
                  child: Center(
                    child: Text(
                      widget.label,
                      style: PixelUi.text(u, scale: 2, outline: PixelUi.outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bingkai piksel: cincin krem 1 piksel, garis gelap 1 piksel, lalu isi [fill].
class PixelFrame extends StatelessWidget {
  const PixelFrame({
    super.key,
    required this.unit,
    required this.child,
    this.fill = PixelUi.dark,
    this.ring = PixelUi.cream,
    this.padding,
  });

  final double unit;
  final Widget child;
  final Color fill;
  final Color ring;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ring,
      padding: EdgeInsets.all(unit),
      child: Container(
        color: PixelUi.dark,
        padding: EdgeInsets.all(unit),
        child: Container(
          color: fill,
          padding: padding ?? EdgeInsets.all(4 * unit),
          child: child,
        ),
      ),
    );
  }
}

/// Gambar piksel dari pola teks (`#` terisi) dengan garis tepi gelap 1 sel di sekelilingnya.
class _PixelIconPainter extends CustomPainter {
  _PixelIconPainter({required this.rows, required this.colorOf, required this.cols});

  final List<String> rows;
  final int cols;
  final Color Function(String ch) colorOf;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / (cols + 2);
    final paint = Paint()..isAntiAlias = false;
    bool filled(int x, int y) {
      if (y < 0 || y >= rows.length || x < 0 || x >= cols) return false;
      return rows[y][x] != '.';
    }

    void cellAt(int gx, int gy, Color c) {
      paint.color = c;
      canvas.drawRect(Rect.fromLTWH(gx * cell, gy * cell, cell + 0.5, cell + 0.5), paint);
    }

    for (var y = -1; y <= rows.length; y++) {
      for (var x = -1; x <= cols; x++) {
        if (filled(x, y)) {
          cellAt(x + 1, y + 1, colorOf(rows[y][x]));
        } else if (filled(x - 1, y) || filled(x + 1, y) || filled(x, y - 1) || filled(x, y + 1)) {
          cellAt(x + 1, y + 1, PixelUi.outline);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter oldDelegate) => true; // warna bisa berubah (bintang terisi)
}

/// Bintang piksel: [filled] = emas, selain itu kosong (gelap).
class PixelStar extends StatelessWidget {
  const PixelStar({super.key, required this.filled, this.size = 16});

  final bool filled;

  /// Lebar dan tinggi (dp), termasuk garis tepi.
  final double size;

  static const _rows = <String>[
    '...#...',
    '..###..',
    '#######',
    '.#####.',
    '..###..',
    '.##.##.',
    '.#...#.',
  ];

  @override
  Widget build(BuildContext context) {
    final color = filled ? const Color(0xFFFFD640) : const Color(0xFF50466E);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(rows: _rows, cols: 7, colorOf: (_) => color),
      ),
    );
  }
}

/// Gembok piksel untuk level terkunci.
class PixelLock extends StatelessWidget {
  const PixelLock({super.key, this.size = 24});

  /// Tinggi (dp); lebar mengikuti pola.
  final double size;

  static const _rows = <String>[
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

  @override
  Widget build(BuildContext context) {
    final cell = size / 11;
    return SizedBox(
      width: cell * 10,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(
          rows: _rows,
          cols: 8,
          colorOf: (ch) => ch == 'k' ? PixelUi.dark : const Color(0xFFA8A0C8),
        ),
      ),
    );
  }
}

/// Tombol teks kecil (mis. "< Kembali") dengan font piksel.
class PixelTextButton extends StatelessWidget {
  const PixelTextButton({super.key, required this.label, required this.onPressed, this.unit});

  final String label;
  final VoidCallback onPressed;
  final double? unit;

  @override
  Widget build(BuildContext context) {
    final u = unit ?? PixelUi.unit(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4 * u, vertical: 5 * u),
        child: Text(label, style: PixelUi.text(u, color: PixelUi.lavender)),
      ),
    );
  }
}

/// Tombol jeda piksel (dua batang). Area sentuh 48 dp.
class PixelPauseButton extends StatelessWidget {
  const PixelPauseButton({super.key, required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 18 * u,
              height: 18 * u,
              color: PixelUi.cream,
              padding: EdgeInsets.all(u),
              child: Container(
                color: PixelUi.dark,
                padding: EdgeInsets.symmetric(horizontal: 4 * u, vertical: 3 * u),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 3 * u, color: PixelUi.cream),
                    Container(width: 3 * u, color: PixelUi.cream),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
