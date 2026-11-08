import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'fight_arena.dart';

/// Percikan piksel saat pukulan mengenai (kuning) atau ditangkis (abu-abu kecil):
/// kotak-kotak kecil berlapis garis tepi gelap yang melesat keluar dan mengecil.
class HitSpark extends Component {
  HitSpark({required this.pos, required this.radius, required this.blocked});

  final Offset pos;
  final double radius;
  final bool blocked;

  static const _life = 0.2;
  double _t = 0;

  static final Paint _edge = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF18122A);
  static final Paint _fill = Paint()..isAntiAlias = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0).toDouble();
    final side = math.max(3.0, radius * (blocked ? 0.16 : 0.22) * (1 - 0.6 * p));
    final rays = blocked ? 5 : 8;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays + 0.3;
      final r = radius * (0.35 + 1.0 * p);
      final c = pos + Offset(math.cos(a) * r, math.sin(a) * r);
      final bright = i.isEven;
      _fill.color = blocked
          ? (bright ? const Color(0xFFCFD8DC) : const Color(0xFF90A4AE))
          : (bright ? const Color(0xFFFFF2A8) : const Color(0xFFFFB300));
      canvas.drawRect(Rect.fromCenter(center: c, width: side + 2, height: side + 2), _edge);
      canvas.drawRect(Rect.fromCenter(center: c, width: side, height: side), _fill);
    }
  }
}

/// Menggambar semua pisau yang sedang melayang (piksel, berputar dalam langkah 45 derajat).
class KnifeLayer extends Component {
  KnifeLayer(this.arena);

  final FightArena arena;
  double unit = 1;
  double groundY = 0;

  static final Paint _ink = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF18122A);
  static final Paint _handle = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF8D5C2E);
  static final Paint _blade = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFFCFD8DC);

  @override
  void render(Canvas canvas) {
    for (final k in arena.knives) {
      canvas.save();
      canvas.translate(k.x * unit, groundY + k.y * unit);
      canvas.scale(unit * k.dir, unit);
      const step = math.pi / 4;
      canvas.rotate((k.ageMs * 0.022 / step).floor() * step);
      canvas.translate(-60, 0);
      // garis tepi gelap (sedikit lebih besar), lalu isi: gagang, bilah, dan ujung bertangga
      canvas.drawRect(const Rect.fromLTRB(-80, -22, 140, 22), _ink);
      canvas.drawRect(const Rect.fromLTRB(140, -16, 164, 16), _ink);
      canvas.drawRect(const Rect.fromLTRB(164, -10, 184, 10), _ink);
      canvas.drawRect(const Rect.fromLTRB(-72, -14, 0, 14), _handle);
      canvas.drawRect(const Rect.fromLTRB(0, -14, 140, 14), _blade);
      canvas.drawRect(const Rect.fromLTRB(140, -9, 160, 9), _blade);
      canvas.drawRect(const Rect.fromLTRB(160, -4, 176, 4), _blade);
      canvas.restore();
    }
  }
}
