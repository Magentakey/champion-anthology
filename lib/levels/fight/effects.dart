import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'fight_arena.dart';

/// Percikan garis saat pukulan mengenai (hitam) atau ditangkis (abu-abu kecil).
class HitSpark extends Component {
  HitSpark({required this.pos, required this.radius, required this.blocked});

  final Offset pos;
  final double radius;
  final bool blocked;

  static const _life = 0.2;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..color = blocked ? const Color(0xFF607D8B) : const Color(0xFF141418)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (blocked ? 3.0 : 5.0) * (1 - p) + 1.5;
    final rays = blocked ? 5 : 8;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays + 0.3;
      final r0 = radius * (0.3 + 0.6 * p);
      final r1 = radius * (0.75 + 0.9 * p);
      canvas.drawLine(
        pos + Offset(math.cos(a) * r0, math.sin(a) * r0),
        pos + Offset(math.cos(a) * r1, math.sin(a) * r1),
        paint,
      );
    }
  }
}

/// Menggambar semua pisau yang sedang melayang.
class KnifeLayer extends Component {
  KnifeLayer(this.arena);

  final FightArena arena;
  double unit = 1;
  double groundY = 0;

  static final _blade = Path()
    ..moveTo(0, -14)
    ..lineTo(110, -14)
    ..lineTo(175, 0)
    ..lineTo(110, 14)
    ..lineTo(0, 14)
    ..close();

  @override
  void render(Canvas canvas) {
    for (final k in arena.knives) {
      canvas.save();
      canvas.translate(k.x * unit, groundY + k.y * unit);
      canvas.scale(unit * k.dir, unit);
      canvas.rotate(k.ageMs * 0.022);
      canvas.translate(-60, 0);
      final ink = Paint()
        ..color = const Color(0xFF141418)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 7;
      final handle = Rect.fromLTRB(-70, -12, 0, 12);
      canvas.drawRect(handle, Paint()..color = const Color(0xFF8D5C2E));
      canvas.drawRect(handle, ink);
      canvas.drawPath(_blade, Paint()..color = const Color(0xFFCFD8DC));
      canvas.drawPath(_blade, ink);
      canvas.restore();
    }
  }
}
