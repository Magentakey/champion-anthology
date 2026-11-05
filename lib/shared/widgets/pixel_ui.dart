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

  static const gridWidth = 240.0;
  static const gridHeight = 426.0;

  /// dp per piksel logis; memakai sisi yang lebih sempit agar seluruh kisi muat.
  static double unitFor(Size size) => math.min(size.width / gridWidth, size.height / gridHeight);

  static double unit(BuildContext context) => unitFor(MediaQuery.sizeOf(context));

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

/// Tombol piksel 104x26 piksel logis (+ bayangan jatuh 2 piksel). Label berupa teks biasa,
/// jadi mudah diuji dan terbaca pembaca layar. [secondary] = biru, selain itu merah.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

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
    final u = PixelUi.unit(context);
    final asset = widget.secondary ? 'assets/images/home/btn_secondary.png' : 'assets/images/home/btn_primary.png';
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
          width: 106 * u,
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
                  width: 104 * u,
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
