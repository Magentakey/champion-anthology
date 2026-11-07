import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../shared/widgets/pixel_pattern.dart';
import 'maze_grid.dart';

/// Menggambar papan labirin bergaya piksel, pemain (kepala berikat kepala merah), dan tujuan (bintang emas).
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

  static const _pad = 6.0;

  // Semua paint tanpa antialiasing agar tepinya tetap tajam (pixel art).
  final Paint _ring = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFFFFF4D6);
  final Paint _dark = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF1A142C);
  final Paint _boardFill = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFFFAF0D6);
  final Paint _wall = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF281E3C)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square
    ..strokeJoin = StrokeJoin.miter;
  final Paint _startTile = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFFC8E6C9);
  final Paint _goalTile = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFFFFF3C4);

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
  }

  @override
  void render(Canvas canvas) {
    final g = _grid;
    if (g == null) return;
    if (_dirty || _builtFor.x != size.x || _builtFor.y != size.y) _rebuild(g);

    // Bingkai papan: cincin krem 1 sel, garis gelap 1 sel, lalu isi.
    final ringT = math.max(2.0, _cell * 0.12);
    final board = Rect.fromLTWH(
      _origin.dx - _pad,
      _origin.dy - _pad,
      _cell * g.cols + 2 * _pad,
      _cell * g.rows + 2 * _pad,
    );
    canvas.drawRect(board.inflate(ringT * 2), _ring);
    canvas.drawRect(board.inflate(ringT), _dark);
    canvas.drawRect(board, _boardFill);

    canvas.save();
    canvas.translate(_origin.dx, _origin.dy);

    canvas.drawRect(Rect.fromLTWH(g.startX * _cell, g.startY * _cell, _cell, _cell), _startTile);
    canvas.drawRect(Rect.fromLTWH(g.goalX * _cell, g.goalY * _cell, _cell, _cell), _goalTile);

    canvas.drawPath(_walls, _wall..strokeWidth = math.max(2.0, (_cell * 0.12).roundToDouble()));

    // tujuan: bintang emas berdenyut (pola piksel)
    final pulse = 1 + 0.08 * math.sin(_t * 5);
    final starSize = _cell * 0.86 * pulse;
    drawPixelPattern(
      canvas,
      PixelPatterns.star,
      Rect.fromCenter(
        center: Offset((g.goalX + 0.5) * _cell, (g.goalY + 0.5) * _cell),
        width: starSize,
        height: starSize,
      ),
      (_) => const Color(0xFFFFC107),
    );

    // pemain: kepala piksel dengan ikat kepala merah
    final playerSize = _cell * 0.86;
    drawPixelPattern(
      canvas,
      PixelPatterns.playerHead,
      Rect.fromCenter(
        center: Offset((_vx + 0.5) * _cell, (_vy + 0.5) * _cell),
        width: playerSize,
        height: playerSize,
      ),
      PixelPatterns.playerColor,
      outline: false,
    );

    canvas.restore();
  }
}
