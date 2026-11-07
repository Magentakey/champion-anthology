import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Curves;

/// Empat ekspresi standar karakter boss (idle, kaget, tertawa, kalah).
enum BossExpression { idle, shock, laugh, defeat }

/// Sprite boss dengan ekspresi yang bisa diganti, goyang naik-turun pelan, dan efek kaget/tawa.
/// Gambar: `assets/images/(level)/boss_idle|shock|laugh|defeat.png` (timpa file untuk mengganti art).
class BossSprite extends SpriteComponent {
  BossSprite({required Map<BossExpression, Sprite> sprites})
      : _sprites = sprites,
        super(
          sprite: sprites[BossExpression.idle],
          anchor: Anchor.center,
          paint: Paint()..filterQuality = FilterQuality.none, // pixel art: tanpa penghalusan
        );

  final Map<BossExpression, Sprite> _sprites;
  int _token = 0;

  @override
  Future<void> onLoad() async {
    add(MoveEffect.by(
      Vector2(0, 6),
      EffectController(
        duration: 0.9,
        alternate: true,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));
  }

  /// Ganti ekspresi; jika [revertAfter] diisi, kembali ke idle setelah jeda itu.
  void setExpression(BossExpression e, {double? revertAfter}) {
    sprite = _sprites[e];
    final token = ++_token;
    if (revertAfter != null) {
      add(TimerComponent(
        period: revertAfter,
        removeOnFinish: true,
        onTick: () {
          if (token == _token) sprite = _sprites[BossExpression.idle];
        },
      ));
    }
  }

  void flinch() {
    add(ScaleEffect.by(
      Vector2.all(0.9),
      EffectController(duration: 0.08, alternate: true),
    ));
  }

  void laugh() {
    add(ScaleEffect.by(
      Vector2.all(1.12),
      EffectController(duration: 0.12, alternate: true, repeatCount: 2),
    ));
  }
}

/// Menggambar bar waktu piksel: bingkai gelap, latar redup, dan blok-blok. Biru, lalu merah saat
/// tersisa kurang dari 30%. Dipakai semua level agar tampilannya seragam.
void drawPixelTimeBar(Canvas canvas, double width, double height, double fraction) {
  final f = fraction.clamp(0.0, 1.0);
  final paint = Paint()..isAntiAlias = false;
  paint.color = const Color(0xFF18122A);
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
  final t = (height / 6).roundToDouble().clamp(1.0, 4.0);
  final inner = Rect.fromLTWH(t, t, width - 2 * t, height - 2 * t);
  paint.color = const Color(0xFF50466E);
  canvas.drawRect(inner, paint);
  const segments = 24;
  final gap = t;
  final blockW = (inner.width - gap * (segments - 1)) / segments;
  final lit = (f * segments).ceil();
  paint.color = f > 0.3 ? const Color(0xFF3C7CE0) : const Color(0xFFE03C3C);
  for (var i = 0; i < lit; i++) {
    canvas.drawRect(Rect.fromLTWH(inner.left + i * (blockW + gap), inner.top, blockW, inner.height), paint);
  }
}

/// Bar waktu level (lihat [drawPixelTimeBar]).
class LevelTimeBar extends PositionComponent {
  double fraction = 1;

  @override
  void render(Canvas canvas) => drawPixelTimeBar(canvas, size.x, size.y, fraction);
}
