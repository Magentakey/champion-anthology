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
        super(sprite: sprites[BossExpression.idle], anchor: Anchor.center);

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

/// Bar waktu: biru, jadi merah saat tersisa kurang dari 30%.
class LevelTimeBar extends PositionComponent {
  double fraction = 1;

  final Paint _bg = Paint()..color = const Color(0xFFBDBDBD);
  final Paint _fill = Paint()..color = const Color(0xFF1976D2);
  final Paint _danger = Paint()..color = const Color(0xFFD32F2F);

  @override
  void render(Canvas canvas) {
    final f = fraction.clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bg);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * f, size.y),
      f > 0.3 ? _fill : _danger,
    );
  }
}
