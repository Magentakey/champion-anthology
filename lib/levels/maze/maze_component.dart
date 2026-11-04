import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'maze_grid.dart';

/// Menggambar papan labirin, pemain (bulat putih berikat kepala merah), dan tujuan (bintang emas).
/// Dinding digabung jadi satu [Path] yang dibuat ulang hanya saat labirin atau ukuran berubah.
class MazeComponent extends PositionComponent {
  MazeGrid? _grid;
  int _px = 0;
  int _py = 0;
  double _vx = 0;
  double _vy = 0;
  double _t = 0;

  bool _dirty = true;
  final Vector2 _builtFor = Vector2.zero();
  double _cell = 0;
  Offset _origin = Offset.zero;
  Path _walls = Path();
  Path _star = Path();

  static const _pad = 6.0;

  final Paint _boardFill = Paint()..color = const Color(0xFFFAFAFA);
  final Paint _boardEdge = Paint()
    ..color = const Color(0xFFBDBDBD)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _wall = Paint()
    ..color = const Color(0xFF141418)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _startTile = Paint()..color = const Color(0xFFC8E6C9);
  final Paint _goalTile = Paint()..color = const Color(0xFFFFF3C4);
  final Paint _gold = Paint()..color = const Color(0xFFFFC107);
  final Paint _ink = Paint()
    ..color = const Color(0xFF141418)
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  final Paint _head = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _band = Paint()..color = const Color(0xFFD62828);

  /// Labirin baru; pemain kembali ke start.
  void setGrid(MazeGrid grid) {
    _grid = grid;
    _px = grid.startX;
    _py = grid.startY;
    _vx = _px.toDouble();
    _vy = _py.toDouble();
    _dirty = true;
  }

  /// Pindahkan pemain ke sel ([x], [y]); gambar bergeser halus.
  void moveTo(int x, int y) {
    _px = x;
    _py = y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final k = math.min(1.0, dt * 20);
    _vx += (_px - _vx) * k;
    _vy += (_py - _vy) * k;
  }

  void _rebuild(MazeGrid g) {
    _dirty = false;
    _builtFor.setFrom(size);
    _cell = math.min((size.x - 2 * _pad) / g.cols, (size.y - 2 * _pad) / g.rows);
    final w = _cell * g.cols;
    final h = _cell * g.rows;
    _origin = Offset((size.x - w) / 2, (size.y - h) / 2);

    final path = Path();
    for (var y = 0; y < g.rows; y++) {
      for (var x = 0; x < g.cols; x++) {
        final left = x * _cell;
        final top = y * _cell;
        if (x == 0) {
          path
            ..moveTo(left, top)
            ..lineTo(left, top + _cell);
        }
        if (y == 0) {
          path
            ..moveTo(left, top)
            ..lineTo(left + _cell, top);
        }
        if (!g.canMove(x, y, Dir.right)) {
          path
            ..moveTo(left + _cell, top)
            ..lineTo(left + _cell, top + _cell);
        }
        if (!g.canMove(x, y, Dir.down)) {
          path
            ..moveTo(left, top + _cell)
            ..lineTo(left + _cell, top + _cell);
        }
      }
    }
    _walls = path;

    final r = _cell * 0.36;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(math.cos(a) * rad, math.sin(a) * rad);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    _star = star..close();
  }

  @override
  void render(Canvas canvas) {
    final g = _grid;
    if (g == null) return;
    if (_dirty || _builtFor.x != size.x || _builtFor.y != size.y) _rebuild(g);

    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _origin.dx - _pad,
        _origin.dy - _pad,
        _cell * g.cols + 2 * _pad,
        _cell * g.rows + 2 * _pad,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(board, _boardFill);
    canvas.drawRRect(board, _boardEdge);

    canvas.save();
    canvas.translate(_origin.dx, _origin.dy);

    canvas.drawRect(Rect.fromLTWH(g.startX * _cell, g.startY * _cell, _cell, _cell), _startTile);
    canvas.drawRect(Rect.fromLTWH(g.goalX * _cell, g.goalY * _cell, _cell, _cell), _goalTile);

    final lw = math.max(2.0, _cell * 0.12);
    canvas.drawPath(_walls, _wall..strokeWidth = lw);

    // tujuan: bintang emas berdenyut
    canvas.save();
    canvas.translate((g.goalX + 0.5) * _cell, (g.goalY + 0.5) * _cell);
    final pulse = 1 + 0.08 * math.sin(_t * 5);
    canvas.scale(pulse, pulse);
    canvas.drawPath(_star, _gold);
    canvas.drawPath(_star, _ink..strokeWidth = math.max(1.5, _cell * 0.05));
    canvas.restore();

    // pemain
    final center = Offset((_vx + 0.5) * _cell, (_vy + 0.5) * _cell);
    final radius = _cell * 0.32;
    final headRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawOval(headRect, _head);
    canvas.save();
    canvas.clipPath(Path()..addOval(headRect));
    canvas.drawRect(
      Rect.fromLTRB(center.dx - radius, center.dy - radius * 0.55, center.dx + radius, center.dy - radius * 0.1),
      _band,
    );
    canvas.restore();
    canvas.drawOval(headRect, _ink..strokeWidth = math.max(1.5, _cell * 0.07));

    canvas.restore();
  }
}
