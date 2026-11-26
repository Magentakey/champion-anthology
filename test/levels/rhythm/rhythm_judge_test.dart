import 'package:champion_anthology/levels/rhythm/rhythm_chart.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_judge.dart';
import 'package:flutter_test/flutter_test.dart';

RhythmJudge judgeOf(List<RhythmNote> notes, {double threshold = 0.6, double offset = 0}) =>
    RhythmJudge(notes, threshold: threshold, offset: offset);

void main() {
  group('Batas jendela penilaian', () {
    test('tepat waktu, 50 ms awal/akhir = PERFECT', () {
      for (final d in [0.0, 0.05, -0.05, 0.049, -0.049]) {
        final j = judgeOf([const RhythmNote(2.0, 1)]);
        expect(j.tap(1, 2.0 + d), Judgment.perfect, reason: 'delta $d');
      }
    });

    test('51 sampai 110 ms = GOOD', () {
      for (final d in [0.051, 0.08, 0.11, -0.051, -0.11]) {
        final j = judgeOf([const RhythmNote(2.0, 1)]);
        expect(j.tap(1, 2.0 + d), Judgment.good, reason: 'delta $d');
      }
    });

    test('lebih dari 110 ms tidak cocok dengan not mana pun dan diabaikan', () {
      final j = judgeOf([const RhythmNote(2.0, 1)]);
      expect(j.tap(1, 2.111), isNull);
      expect(j.tap(1, 1.889), isNull);
      expect(j.judged, 0);
      expect(j.combo, 0);
    });

    test('not menjadi MISS setelah lewat 130 ms, tidak sebelumnya', () {
      final j = judgeOf([const RhythmNote(2.0, 0)]);
      expect(j.advance(2.13), isEmpty); // tepat 130 ms: belum MISS
      expect(j.misses, 0);
      expect(j.advance(2.131), [0]);
      expect(j.misses, 1);
      expect(j.resultOf(0), Judgment.miss);
      expect(j.advance(5), isEmpty); // tidak dilaporkan dua kali
    });

    test('ketukan di antara 110 dan 130 ms terlambat diabaikan, lalu not tetap MISS', () {
      final j = judgeOf([const RhythmNote(2.0, 0)]);
      expect(j.tap(0, 2.12), isNull);
      j.advance(2.2);
      expect(j.misses, 1);
    });
  });

  group('Satu ketukan satu not', () {
    test('ketukan kedua pada not yang sama tidak dihitung lagi', () {
      final j = judgeOf([const RhythmNote(2.0, 2), const RhythmNote(3.0, 2)]);
      expect(j.tap(2, 2.0), Judgment.perfect);
      expect(j.tap(2, 2.01), isNull); // not 2 baru 1 detik lagi
      expect(j.judged, 1);
    });

    test('ketukan di jalur lain tidak memengaruhi not jalur ini', () {
      final j = judgeOf([const RhythmNote(2.0, 0), const RhythmNote(2.0, 3)]);
      expect(j.tap(1, 2.0), isNull);
      expect(j.tap(3, 2.0), Judgment.perfect);
      expect(j.resultOf(0), isNull);
      expect(j.resultOf(1), Judgment.perfect);
    });

    test('not dalam satu jalur dinilai berurutan', () {
      final j = judgeOf([const RhythmNote(2.0, 0), const RhythmNote(2.5, 0), const RhythmNote(3.0, 0)]);
      expect(j.tap(0, 2.0), Judgment.perfect);
      expect(j.lastTappedIndex, 0);
      expect(j.tap(0, 2.52), Judgment.perfect);
      expect(j.lastTappedIndex, 1);
      expect(j.tap(0, 3.08), Judgment.good);
      expect(j.lastTappedIndex, 2);
      expect(j.isFinished, isTrue);
    });

    test('not yang terlewat ditandai MISS lebih dulu saat ketukan berikutnya tiba', () {
      final j = judgeOf([const RhythmNote(2.0, 0), const RhythmNote(2.25, 0)]);
      expect(j.tap(0, 2.25), Judgment.perfect); // not pertama (2.0) sudah lewat 250 ms: MISS
      expect(j.resultOf(0), Judgment.miss);
      expect(j.resultOf(1), Judgment.perfect);
      expect(j.advance(2.25), [0]);
    });

    test('jalur di luar 0..3 diabaikan', () {
      final j = judgeOf([const RhythmNote(2.0, 0)]);
      expect(j.tap(-1, 2.0), isNull);
      expect(j.tap(4, 2.0), isNull);
    });

    test('pasangan bersamaan di dua jalur dinilai terpisah', () {
      final j = judgeOf([const RhythmNote(2.0, 0), const RhythmNote(2.0, 1)]);
      expect(j.tap(0, 2.0), Judgment.perfect);
      expect(j.tap(1, 2.04), Judgment.perfect);
      expect(j.perfects, 2);
    });
  });

  group('Akurasi, combo, dan ambang', () {
    List<RhythmNote> many(int n) => [for (var i = 0; i < n; i++) RhythmNote(2.0 + i * 0.5, i % 4)];

    test('contoh rancangan: 20 PERFECT + 8 GOOD + 4 MISS dari 32 not = 75%', () {
      final notes = many(32);
      final j = judgeOf(notes);
      for (var i = 0; i < 32; i++) {
        final t = notes[i].time;
        if (i < 20) {
          j.tap(notes[i].lane, t);
        } else if (i < 28) {
          j.tap(notes[i].lane, t + 0.08);
        }
      }
      j.advance(100);
      expect(j.perfects, 20);
      expect(j.goods, 8);
      expect(j.misses, 4);
      expect(j.accuracy, closeTo(0.75, 1e-9));
      expect(j.isFinished, isTrue);
      expect(j.passed, isTrue);
    });

    test('akurasi sementara memakai not yang sudah dinilai', () {
      final j = judgeOf(many(4));
      expect(j.runningAccuracy, 0);
      j.tap(0, 2.0);
      expect(j.runningAccuracy, 1.0);
      j.tap(1, 2.58); // GOOD
      expect(j.runningAccuracy, closeTo(0.75, 1e-9));
      expect(j.accuracy, closeTo(1.5 / 4, 1e-9));
    });

    test('combo naik pada PERFECT/GOOD, putus pada MISS, dan maxCombo diingat', () {
      final notes = many(6);
      final j = judgeOf(notes);
      j.tap(0, 2.0);
      j.tap(1, 2.5);
      j.tap(2, 3.08);
      expect(j.combo, 3);
      j.advance(4.0); // not ke-4 (3.5) MISS
      expect(j.combo, 0);
      expect(j.maxCombo, 3);
      expect(j.missStreak, 1);
      j.tap(0, 4.0);
      expect(j.missStreak, 0);
      expect(j.combo, 1);
    });

    test('tepat di ambang 60% dari 10 not lulus, 55% gagal', () {
      final notes = many(10);
      final exact = judgeOf(notes);
      for (var i = 0; i < 6; i++) {
        exact.tap(notes[i].lane, notes[i].time);
      }
      exact.advance(100);
      expect(exact.accuracy, closeTo(0.6, 1e-9));
      expect(exact.passed, isTrue);

      final below = judgeOf(notes);
      for (var i = 0; i < 5; i++) {
        below.tap(notes[i].lane, notes[i].time);
      }
      below.tap(notes[5].lane, notes[5].time + 0.08); // 5 + 0.5 = 55%
      below.advance(100);
      expect(below.accuracy, closeTo(0.55, 1e-9));
      expect(below.passed, isFalse);
    });

    test('ambang 78% pada 72 not: 57 PERFECT lulus (79,2%), 56 gagal (77,8%)', () {
      final notes = [for (var i = 0; i < 72; i++) RhythmNote(2.0 + i * 0.5, i % 4)];
      final a = judgeOf(notes, threshold: 0.78);
      for (var i = 0; i < 57; i++) {
        a.tap(notes[i].lane, notes[i].time);
      }
      a.advance(500);
      expect(a.accuracy, closeTo(57 / 72, 1e-9)); // 79,17% >= 78%
      expect(a.passed, isTrue);

      final b = judgeOf(notes, threshold: 0.78);
      for (var i = 0; i < 56; i++) {
        b.tap(notes[i].lane, notes[i].time);
      }
      b.advance(500);
      expect(b.accuracy, closeTo(56 / 72, 1e-9)); // 77,78% < 78%
      expect(b.passed, isFalse);
    });

    test('belum selesai berarti belum lulus', () {
      final j = judgeOf(many(4));
      j.tap(0, 2.0);
      expect(j.passed, isFalse);
    });
  });

  group('Gagal dini (ambang mustahil dicapai)', () {
    test('terkunci tepat saat sisa not tidak bisa lagi menutup ambang', () {
      final notes = [for (var i = 0; i < 10; i++) RhythmNote(2.0 + i * 0.5, i % 4)];
      final j = judgeOf(notes); // ambang 60% = butuh 6 poin penuh dari 10
      expect(j.isLocked, isFalse);
      // 4 MISS: sisa 6 not masih bisa 6/10 = 60%
      j.advance(2.0 + 3 * 0.5 + 0.2);
      expect(j.misses, 4);
      expect(j.isLocked, isFalse);
      // MISS kelima: maksimum 5/10 = 50% < 60%
      j.advance(2.0 + 4 * 0.5 + 0.2);
      expect(j.misses, 5);
      expect(j.isLocked, isTrue);
    });

    test('GOOD yang mengurangi poin maksimum juga bisa mengunci', () {
      final notes = [for (var i = 0; i < 4; i++) RhythmNote(2.0 + i, i)];
      final j = judgeOf(notes, threshold: 0.78); // butuh 3.12 poin dari 4
      expect(j.isLocked, isFalse);
      j.tap(0, 2.08); // GOOD: maksimum 3.5 -> masih mungkin
      expect(j.isLocked, isFalse);
      j.tap(1, 3.08); // GOOD: maksimum 3.0 < 3.12
      expect(j.isLocked, isTrue);
    });
  });

  group('Offset kalibrasi', () {
    test('offset positif menggeser waktu not dan jendela ikut bergeser', () {
      final j = judgeOf([const RhythmNote(2.0, 0)], offset: 0.1);
      expect(j.timeOf(0), closeTo(2.1, 1e-12));
      expect(j.tap(0, 2.1), Judgment.perfect);
    });

    test('offset negatif', () {
      final j = judgeOf([const RhythmNote(2.0, 0)], offset: -0.15);
      expect(j.tap(0, 1.85), Judgment.perfect);
    });

    test('offset diubah saat bermain berlaku untuk penilaian berikutnya', () {
      final j = judgeOf([const RhythmNote(2.0, 0)]);
      j.offset = 0.06;
      expect(j.tap(0, 2.0), Judgment.good); // selisih 60 ms
    });
  });

  group('Lagu nyata', () {
    test('pemain sempurna mendapat 100% di ketiga step', () {
      for (var step = 1; step <= 3; step++) {
        final chart = RhythmChart.forStep(step);
        final j = RhythmJudge.forStep(step, chart: chart);
        final order = [...chart.notes]..sort((a, b) => a.time.compareTo(b.time));
        for (final n in order) {
          j.tap(n.lane, n.time);
        }
        expect(j.perfects, chart.noteCount, reason: 'step $step');
        expect(j.accuracy, 1.0);
        expect(j.passed, isTrue);
      }
    });

    test('tidak mengetuk sama sekali: semua MISS dan terkunci', () {
      final j = RhythmJudge.forStep(1);
      j.advance(1000);
      expect(j.misses, 32);
      expect(j.accuracy, 0);
      expect(j.passed, isFalse);
      expect(j.isLocked, isTrue);
    });
  });
}
