import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Curves;

import '../../core/level/boss_sprite.dart' show drawPixelTimeBar;

enum MazeMood { idle, shock, laugh, defeat }

/// Asep the Mazelogist (sprite 4 ekspresi).
/// TODO(art): ganti gambar boss_*.png di assets/images/maze/ dengan art final (cukup overwrite).
class MazeBoss extends SpriteComponent {
  MazeBoss({required Map<MazeMood, Sprite> sprites})
      : _sprites = sprites,
        super(
          sprite: sprites[MazeMood.idle],
          anchor: Anchor.center,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  final Map<MazeMood, Sprite> _sprites;
  int _moodToken = 0;

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
  void setMood(MazeMood mood, {double? revertAfter}) {
    sprite = _sprites[mood];
    final token = ++_moodToken;
    if (revertAfter != null) {
      add(TimerComponent(
        period: revertAfter,
        removeOnFinish: true,
        onTick: () {
          if (token == _moodToken) sprite = _sprites[MazeMood.idle];
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

/// Bar waktu piksel (sama untuk semua level).
class MazeTimeBar extends PositionComponent {
  double fraction = 1;

  @override
  void render(Canvas canvas) => drawPixelTimeBar(canvas, size.x, size.y, fraction);
}
