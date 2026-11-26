import 'dart:math';

import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/memory/memory_round.dart';
import 'package:flutter_test/flutter_test.dart';

/// Langkah waktu simulasi (detik). Pemain mengetuk satu pad per frame, jadi batas waktu tidak pernah tercapai.
const double _dt = 0.05;

/// Peluang lulus tiap step (indeks = step - 1) menurut model galat per ketukan di docs rancangan bagian 3.1.
final Map<double, List<double>> _expectedPass = {
  0.01: [0.996, 0.932, 0.877],
  0.02: [0.976, 0.789, 0.658],
  0.03: [0.935, 0.631, 0.455],
  0.05: [0.800, 0.363, 0.188],
};

int _wrongPad(Random rnd, int expected, int pads) {
  final other = rnd.nextInt(pads - 1);
  return other >= expected ? other + 1 : other;
}

/// Satu ketukan pemain simulasi bila sedang giliran: salah dengan peluang [error] (pad salah dipilih acak),
/// selain itu benar. [blind] = menebak asal di antara semua pad.
void _act(MemoryRound run, Random rnd, double error, bool blind) {
  if (run.phase != MemoryPhase.input) return;
  final expected = run.currentSequence[run.correct];
  final int pad;
  if (blind) {
    pad = rnd.nextInt(run.padCount);
  } else if (rnd.nextDouble() < error) {
    pad = _wrongPad(rnd, expected, run.padCount);
  } else {
    pad = expected;
  }
  run.tapPad(pad);
}

/// Memainkan satu step sampai tahap hasil; true bila lulus.
bool _playStep(int step, double error, Random rnd, {bool blind = false}) {
  final run = MemoryRound(LevelSession(), random: rnd);
  run.beginStep(step);
  var frames = 0;
  while (run.phase != MemoryPhase.result) {
    _act(run, rnd, error, blind);
    run.update(_dt);
    if (++frames > 300000) fail('simulasi step $step tidak selesai');
  }
  return run.passed;
}

/// Memainkan satu sesi penuh (Step 1 sampai 3, berhenti saat kalah); mengembalikan bintang.
int _playSession(double error, Random rnd) {
  final session = LevelSession();
  final run = MemoryRound(session, random: rnd);
  run.beginStep(1);
  var frames = 0;
  while (!session.isFinished) {
    _act(run, rnd, error, false);
    run.update(_dt);
    if (++frames > 600000) fail('simulasi sesi tidak selesai');
  }
  return session.stars;
}

double _passRate(int step, double error, int trials, int seed) {
  final rnd = Random(seed);
  var passes = 0;
  for (var i = 0; i < trials; i++) {
    if (_playStep(step, error, rnd)) passes++;
  }
  return passes / trials;
}

void main() {
  group('Pemain simulasi', () {
    test('pemain sempurna (galat 0) lulus ketiga step dan mendapat 3 bintang', () {
      for (var seed = 0; seed < 30; seed++) {
        final rnd = Random(seed);
        for (var step = 1; step <= 3; step++) {
          expect(_playStep(step, 0, rnd), isTrue, reason: 'step $step seed $seed');
        }
        expect(_playSession(0, Random(seed)), 3, reason: 'seed $seed');
      }
    });

    for (final entry in _expectedPass.entries) {
      final error = entry.key;
      final expected = entry.value;
      test('galat ${(error * 100).round()}% per ketukan: peluang lulus tiap step mengikuti tabel 3.1 (toleransi 0,10)', () {
        for (var step = 1; step <= 3; step++) {
          final rate = _passRate(step, error, 400, 1000 + step * 17 + (error * 1000).round());
          expect(rate, closeTo(expected[step - 1], 0.10), reason: 'step $step, galat $error');
        }
      });
    }

    test('makin sering salah, makin sulit lulus Step 3', () {
      final rapi = _passRate(3, 0.01, 200, 5);
      final sedang = _passRate(3, 0.03, 200, 6);
      final lupa = _passRate(3, 0.08, 200, 7);
      expect(rapi, greaterThan(sedang));
      expect(sedang, greaterThan(lupa));
      expect(lupa, lessThan(0.15));
    });

    test('pengetuk asal gagal di semua step (minimal 99,9% dari percobaan)', () {
      for (var step = 1; step <= 3; step++) {
        final rnd = Random(77 + step);
        const trials = 1000;
        var fails = 0;
        for (var i = 0; i < trials; i++) {
          if (!_playStep(step, 0, rnd, blind: true)) fails++;
        }
        expect(fails / trials, greaterThanOrEqualTo(0.999), reason: 'step $step');
      }
    });

    test('pemain sedang (galat 3%) rata-rata sekitar 1,8 bintang; 3 bintang sekitar 27%', () {
      final rnd = Random(2026);
      const sessions = 400;
      var total = 0;
      var perfect = 0;
      for (var i = 0; i < sessions; i++) {
        final stars = _playSession(0.03, rnd);
        total += stars;
        if (stars == 3) perfect++;
      }
      expect(total / sessions, closeTo(1.79, 0.3)); // 0,935 + 0,935 x 0,631 + 0,935 x 0,631 x 0,455
      expect(perfect / sessions, closeTo(0.27, 0.10));
    });

    test('pemain rapi (galat 2%) mendapat 3 bintang sekitar separuh percobaan', () {
      final rnd = Random(404);
      const sessions = 400;
      var perfect = 0;
      for (var i = 0; i < sessions; i++) {
        if (_playSession(0.02, rnd) == 3) perfect++;
      }
      expect(perfect / sessions, closeTo(0.51, 0.10));
    });
  });
}
