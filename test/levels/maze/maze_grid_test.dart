import 'dart:io';
import 'dart:math';

import 'package:champion_anthology/levels/maze/maze_config.dart';
import 'package:champion_anthology/levels/maze/maze_dialog.dart';
import 'package:champion_anthology/levels/maze/maze_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MazeGrid', () {
    test('labirin sempurna: jumlah lorong = sel - 1 dan tujuan selalu terjangkau', () {
      for (var seed = 0; seed < 40; seed++) {
        for (final cfg in mazeSteps) {
          final g = MazeGrid.generate(cfg.cols, cfg.rows, Random(seed));
          expect(g.passageCount, cfg.cols * cfg.rows - 1);
          expect(g.shortestPathLength(), greaterThan(0));
        }
      }
    });

    test('dinding luar tidak pernah bisa ditembus', () {
      final g = MazeGrid.generate(6, 5, Random(1));
      for (var x = 0; x < g.cols; x++) {
        expect(g.canMove(x, 0, Dir.up), isFalse);
        expect(g.canMove(x, g.rows - 1, Dir.down), isFalse);
      }
      for (var y = 0; y < g.rows; y++) {
        expect(g.canMove(0, y, Dir.left), isFalse);
        expect(g.canMove(g.cols - 1, y, Dir.right), isFalse);
      }
    });

    test('lorong dua arah: kalau A bisa ke B, B bisa kembali ke A', () {
      final g = MazeGrid.generate(8, 7, Random(7));
      for (var y = 0; y < g.rows; y++) {
        for (var x = 0; x < g.cols; x++) {
          for (final d in Dir.values) {
            if (g.canMove(x, y, d)) {
              expect(g.canMove(x + d.dx, y + d.dy, d.opposite), isTrue);
            }
          }
        }
      }
    });

    test('seed sama menghasilkan labirin sama', () {
      final a = MazeGrid.generate(10, 8, Random(42));
      final b = MazeGrid.generate(10, 8, Random(42));
      for (var y = 0; y < a.rows; y++) {
        for (var x = 0; x < a.cols; x++) {
          for (final d in Dir.values) {
            expect(a.canMove(x, y, d), b.canMove(x, y, d));
          }
        }
      }
    });

    test('ukuran di bawah 2x2 ditolak', () {
      expect(() => MazeGrid.generate(1, 5, Random(0)), throwsArgumentError);
    });
  });

  group('MazeRunner', () {
    test('mulai di start, tertahan dinding, dan sampai tujuan lewat jalur terpendek', () {
      final g = MazeGrid.generate(7, 6, Random(3));
      final r = MazeRunner(g);
      expect((r.x, r.y), (0, 0));
      expect(r.atGoal, isFalse);
      expect(r.tryMove(Dir.up), isFalse); // dinding luar
      expect(r.tryMove(Dir.left), isFalse);

      // ikuti jalur terpendek dengan menelusuri BFS sederhana
      final path = _shortestDirs(g);
      expect(path.length, g.shortestPathLength());
      for (final d in path) {
        expect(r.tryMove(d), isTrue);
      }
      expect(r.atGoal, isTrue);
    });
  });

  group('konfigurasi level', () {
    test('3 step, makin besar dan makin lama', () {
      expect(mazeSteps.length, 3);
      expect(mazeStepLabels.length, 3);
      for (var i = 1; i < mazeSteps.length; i++) {
        expect(mazeSteps[i].cols * mazeSteps[i].rows,
            greaterThan(mazeSteps[i - 1].cols * mazeSteps[i - 1].rows));
        expect(mazeSteps[i].seconds, greaterThan(mazeSteps[i - 1].seconds));
      }
    });

    test('waktu cukup: jalur terpendek terlama tetap jauh di bawah batas waktu', () {
      // Jalur terpendek ditempuh minimal 2x lebih cepat dari batas waktu, bahkan
      // untuk labirin terpanjang dari 200 percobaan.
      for (final cfg in mazeSteps) {
        var worst = 0;
        for (var seed = 0; seed < 200; seed++) {
          final len = MazeGrid.generate(cfg.cols, cfg.rows, Random(seed)).shortestPathLength();
          if (len > worst) worst = len;
        }
        expect(worst * MazeTuning.repeatSeconds, lessThan(cfg.seconds / 2),
            reason: '${cfg.cols}x${cfg.rows}: jalur terpanjang $worst langkah');
      }
    });
  });

  group('MazeDialog', () {
    test('lengkap: 3 intro, 3 tanda selesai, 4 kelompok hasil, tanpa kalimat kosong', () {
      expect(MazeDialog.stepIntro.length, 3);
      expect(MazeDialog.stepClear.length, 3);
      expect(MazeDialog.resultByStars.length, 4);
      expect(MazeDialog.hurry.length, greaterThanOrEqualTo(3));
      final all = [
        MazeDialog.tip,
        ...MazeDialog.stepIntro,
        ...MazeDialog.stepClear,
        ...MazeDialog.hurry,
        for (final l in MazeDialog.resultByStars) ...l,
      ];
      for (final line in all) {
        expect(line.trim(), isNotEmpty);
      }
      for (final lines in MazeDialog.resultByStars) {
        expect(lines, isNotEmpty);
      }
    });
  });

  test('gambar Asep untuk 4 ekspresi ada', () {
    for (final f in ['idle', 'shock', 'laugh', 'defeat']) {
      expect(File('assets/images/maze/boss_$f.png').existsSync(), isTrue, reason: f);
    }
  });
}

/// Jalur terpendek start -> tujuan sebagai daftar arah (BFS).
List<Dir> _shortestDirs(MazeGrid g) {
  final prev = <int, (int, Dir)>{};
  final seen = <int>{0};
  final queue = <int>[0];
  final goal = g.goalY * g.cols + g.goalX;
  for (var i = 0; i < queue.length; i++) {
    final cur = queue[i];
    if (cur == goal) break;
    final x = cur % g.cols, y = cur ~/ g.cols;
    for (final d in Dir.values) {
      if (!g.canMove(x, y, d)) continue;
      final next = (y + d.dy) * g.cols + x + d.dx;
      if (seen.add(next)) {
        prev[next] = (cur, d);
        queue.add(next);
      }
    }
  }
  final out = <Dir>[];
  var at = goal;
  while (at != 0) {
    final (p, d) = prev[at]!;
    out.add(d);
    at = p;
  }
  return out.reversed.toList();
}
