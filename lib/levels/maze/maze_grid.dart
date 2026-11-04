import 'dart:collection';
import 'dart:math';

/// Arah gerak di labirin.
enum Dir {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Dir(this.dx, this.dy);

  final int dx;
  final int dy;

  /// Bit penanda lorong terbuka pada sel.
  int get bit => 1 << index;

  Dir get opposite => switch (this) {
        Dir.up => Dir.down,
        Dir.down => Dir.up,
        Dir.left => Dir.right,
        Dir.right => Dir.left,
      };
}

/// Labirin sempurna (satu jalur unik antar dua sel mana pun), dibuat dengan
/// recursive backtracker. Start di kiri atas, tujuan di kanan bawah.
/// Kelas ini murni Dart (tanpa Flame) supaya mudah diuji.
class MazeGrid {
  MazeGrid._(this.cols, this.rows, this._open);

  factory MazeGrid.generate(int cols, int rows, Random rng) {
    if (cols < 2 || rows < 2) {
      throw ArgumentError('Labirin minimal 2x2, diminta ${cols}x$rows');
    }
    final open = List<int>.filled(cols * rows, 0);
    final visited = List<bool>.filled(cols * rows, false);
    final stack = <int>[0];
    visited[0] = true;

    while (stack.isNotEmpty) {
      final cur = stack.last;
      final cx = cur % cols;
      final cy = cur ~/ cols;
      final options = <Dir>[
        for (final d in Dir.values)
          if (cx + d.dx >= 0 &&
              cx + d.dx < cols &&
              cy + d.dy >= 0 &&
              cy + d.dy < rows &&
              !visited[(cy + d.dy) * cols + cx + d.dx])
            d,
      ];
      if (options.isEmpty) {
        stack.removeLast();
        continue;
      }
      final d = options[rng.nextInt(options.length)];
      final next = (cy + d.dy) * cols + cx + d.dx;
      open[cur] |= d.bit;
      open[next] |= d.opposite.bit;
      visited[next] = true;
      stack.add(next);
    }
    return MazeGrid._(cols, rows, open);
  }

  final int cols;
  final int rows;
  final List<int> _open;

  int get startX => 0;
  int get startY => 0;
  int get goalX => cols - 1;
  int get goalY => rows - 1;

  /// true jika dari sel ([x], [y]) bisa melangkah ke arah [d] (tidak ada dinding).
  bool canMove(int x, int y, Dir d) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return false;
    return _open[y * cols + x] & d.bit != 0;
  }

  /// Jumlah lorong (sisi tanpa dinding antar dua sel). Labirin sempurna: sel - 1.
  int get passageCount {
    var bits = 0;
    for (final v in _open) {
      for (final d in Dir.values) {
        if (v & d.bit != 0) bits++;
      }
    }
    return bits ~/ 2;
  }

  /// Jumlah langkah terpendek dari start ke tujuan (BFS), atau -1 jika tak terhubung.
  int shortestPathLength() {
    final dist = List<int>.filled(cols * rows, -1);
    final queue = Queue<int>()..add(0);
    dist[0] = 0;
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      final cx = cur % cols;
      final cy = cur ~/ cols;
      if (cx == goalX && cy == goalY) return dist[cur];
      for (final d in Dir.values) {
        if (!canMove(cx, cy, d)) continue;
        final next = (cy + d.dy) * cols + cx + d.dx;
        if (dist[next] != -1) continue;
        dist[next] = dist[cur] + 1;
        queue.add(next);
      }
    }
    return -1;
  }
}

/// Posisi pemain di labirin.
class MazeRunner {
  MazeRunner(this.grid)
      : x = grid.startX,
        y = grid.startY;

  final MazeGrid grid;
  int x;
  int y;

  /// Melangkah satu sel; false jika terhalang dinding.
  bool tryMove(Dir d) {
    if (!grid.canMove(x, y, d)) return false;
    x += d.dx;
    y += d.dy;
    return true;
  }

  bool get atGoal => x == grid.goalX && y == grid.goalY;
}
