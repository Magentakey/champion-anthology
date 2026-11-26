import 'dart:math';

import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_chart.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_judge.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_run.dart';
import 'package:flutter_test/flutter_test.dart';

const double _frame = 1 / 60;

/// Memajukan [run] sampai [target] tercapai (maksimal [limit] detik).
void advanceUntil(RhythmRun run, RhythmPhase target, {double limit = 200}) {
  var t = 0.0;
  while (run.phase != target && t < limit) {
    run.update(_frame);
    t += _frame;
  }
  expect(run.phase, target, reason: 'tidak mencapai $target dalam $limit detik');
}

/// Lagu kecil untuk uji alur: 5 bar pada 120 BPM (10 detik), 4 not (1, 2, 3, 4 detik).
RhythmChart tinyChart(int step) => RhythmChart(
      bpm: 120,
      bars: 5,
      gridPerBeat: 2,
      notes: const [RhythmNote(1.0, 0), RhythmNote(2.0, 1), RhythmNote(3.0, 2), RhythmNote(4.0, 3)],
    );

/// Pemain yang mengetuk semua not tepat waktu (atau [skip]-nya dilewatkan).
void playAll(RhythmRun run, {Set<int> skip = const {}}) {
  final notes = [...run.chart!.notes];
  var index = 0;
  while (run.phase == RhythmPhase.playing) {
    while (index < notes.length && notes[index].time <= run.clock + 1e-9) {
      if (!skip.contains(index)) run.tap(notes[index].lane, at: notes[index].time);
      index++;
    }
    run.update(_frame);
  }
}

void main() {
  group('Alur tahap', () {
    test('banner -> hitung mundur 4 ketukan -> bermain, jam mulai negatif lalu 0', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart);
      final phases = <RhythmPhase>[];
      final beats = <int>[];
      run.onPhase = (from, to) => phases.add(to);
      run.onCountBeat = (b, total) {
        expect(total, RhythmTuning.countdownBeats);
        beats.add(b);
      };
      expect(run.phase, RhythmPhase.idle);
      run.beginStep(1);
      expect(run.phase, RhythmPhase.intro);
      expect(run.clock, closeTo(-2.0, 1e-9)); // 4 ketukan pada 120 BPM

      advanceUntil(run, RhythmPhase.playing);
      expect(phases, [RhythmPhase.intro, RhythmPhase.countdown, RhythmPhase.playing]);
      expect(beats, [0, 1, 2, 3]);
      expect(run.clock, 0);
    });

    test('ketukan sebelum tahap bermain diabaikan', () {
      final run = RhythmRun(LevelSession(), chartFor: tinyChart);
      expect(run.tap(0, at: 1.0), isNull); // idle
      run.beginStep(1);
      expect(run.tap(0, at: 1.0), isNull); // banner
      advanceUntil(run, RhythmPhase.countdown);
      expect(run.tap(0, at: 1.0), isNull); // hitung mundur
      expect(run.judge!.judged, 0);
    });

    test('tidak ada kemajuan saat sesi dijeda', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      run.update(1.0);
      final before = run.clock;
      session.pause();
      run.update(5.0);
      expect(run.clock, before);
      expect(run.acceptsTaps, isFalse);
    });

    test('jeda lalu lanjut: hitung mundur 3 ketukan, jam tidak maju, ketukan ditolak', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      run.update(1.5);
      final frozen = run.clock;
      final beats = <int>[];
      run.onCountBeat = (b, total) {
        expect(total, RhythmTuning.resumeCountdownBeats);
        beats.add(b);
      };
      session.pause();
      session.resume();
      run.resumeFromPause();
      expect(run.phase, RhythmPhase.resuming);
      expect(run.acceptsTaps, isFalse);
      expect(run.tap(0, at: frozen), isNull);
      advanceUntil(run, RhythmPhase.playing);
      expect(beats, [0, 1, 2]);
      expect(run.clock, frozen); // lagu lanjut dari titik yang sama
      expect(run.acceptsTaps, isTrue);
    });

    test('resumeFromPause di luar tahap bermain tidak berbuat apa-apa', () {
      final run = RhythmRun(LevelSession(), chartFor: tinyChart)..beginStep(1);
      run.resumeFromPause();
      expect(run.phase, RhythmPhase.intro);
    });
  });

  group('Hasil step dan sesi', () {
    test('tiga step menang = 3 bintang, winStep tepat tiga kali', () {
      final session = LevelSession();
      var wins = 0;
      final run = RhythmRun(session, chartFor: tinyChart);
      final committed = <bool>[];
      run.onBeforeCommit = committed.add;
      run.beginStep(1);
      for (var step = 1; step <= 3; step++) {
        advanceUntil(run, RhythmPhase.playing);
        expect(run.step, step);
        playAll(run);
        expect(run.phase, RhythmPhase.result);
        expect(run.passed, isTrue);
        advanceUntil(run, step < 3 ? RhythmPhase.intro : RhythmPhase.done);
        wins++;
        expect(session.stepsWon, wins);
      }
      expect(session.isFinished, isTrue);
      expect(session.stars, 3);
      expect(committed, [true, true, true]);
    });

    test('gagal di step 2 = sesi selesai dengan 1 bintang, loseStep sekali', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      playAll(run);
      advanceUntil(run, RhythmPhase.intro); // step 2
      expect(session.step, 2);
      advanceUntil(run, RhythmPhase.playing);
      playAll(run, skip: {0, 1, 2, 3}); // tidak mengetuk apa pun
      expect(run.passed, isFalse);
      advanceUntil(run, RhythmPhase.done);
      expect(session.isFinished, isTrue);
      expect(session.stepsWon, 1);
      expect(session.stars, 1);
      // update lagi setelah selesai tidak mengubah apa-apa
      run.update(10);
      expect(session.stepsWon, 1);
      expect(run.phase, RhythmPhase.done);
    });

    test('gagal dini: begitu ambang mustahil, tahap langsung ke hasil (sebelum lagu habis)', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      final misses = <int>[];
      run.onJudged = (i, j) {
        if (j == Judgment.miss) misses.add(i);
      };
      var guard = 0;
      while (run.phase == RhythmPhase.playing && guard++ < 10000) {
        run.update(_frame);
      }
      expect(run.phase, RhythmPhase.result);
      expect(run.passed, isFalse);
      expect(run.clock, lessThan(run.chart!.duration)); // belum sampai akhir lagu
      expect(misses.length, 2); // 4 not, ambang 60%: gagal setelah MISS kedua (sisa 2 -> maksimum 50%)
    });

    test('tepat di ambang lulus: 3 dari 4 not (75%) lulus step 1', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      playAll(run, skip: {3});
      expect(run.judge!.accuracy, closeTo(0.75, 1e-9));
      expect(run.passed, isTrue);
    });

    test('lulus hanya dilaporkan setelah layar hasil selesai, bukan saat lagu berakhir', () {
      final session = LevelSession();
      final run = RhythmRun(session, chartFor: tinyChart)..beginStep(1);
      advanceUntil(run, RhythmPhase.playing);
      playAll(run);
      expect(run.phase, RhythmPhase.result);
      expect(session.stepsWon, 0);
      advanceUntil(run, RhythmPhase.intro);
      expect(session.stepsWon, 1);
    });

    test('callback hasil step dan penilaian dipanggil', () {
      final run = RhythmRun(LevelSession(), chartFor: tinyChart)..beginStep(1);
      final judged = <Judgment>[];
      bool? result;
      run.onJudged = (i, j) => judged.add(j);
      run.onStepResult = (p) => result = p;
      advanceUntil(run, RhythmPhase.playing);
      playAll(run);
      expect(judged, everyElement(Judgment.perfect));
      expect(judged.length, 4);
      expect(result, isTrue);
    });
  });

  group('Offset di dalam run', () {
    test('offset dari pengaturan dipakai pada penilai', () {
      var offset = 60;
      final run = RhythmRun(LevelSession(), offsetMs: () => offset, chartFor: tinyChart)..beginStep(1);
      expect(run.judge!.offset, closeTo(0.06, 1e-12));
      advanceUntil(run, RhythmPhase.playing);
      offset = -40; // diubah lewat layar jeda lalu dilanjutkan
      run.update(_frame);
      expect(run.judge!.offset, closeTo(-0.04, 1e-12));
    });
  });

  group('Pemain simulasi pada lagu asli', () {
    // Box-Muller; seed tetap supaya hasil sama tiap kali.
    double gaussian(Random r) => sqrt(-2 * log(1 - r.nextDouble())) * cos(2 * pi * r.nextDouble());

    /// Satu permainan: tiap not diketuk dengan galat acak N(0, sigma) detik. Mengembalikan penilai.
    RhythmJudge play(int step, double sigmaMs, Random rng) {
      final chart = RhythmChart.forStep(step);
      final judge = RhythmJudge.forStep(step, chart: chart);
      final taps = [for (final n in chart.notes) (n.time + gaussian(rng) * sigmaMs / 1000, n.lane)]..sort((a, b) => a.$1.compareTo(b.$1));
      for (final (time, lane) in taps) {
        judge.tap(lane, time);
      }
      judge.advance(chart.duration + 5);
      return judge;
    }

    ({double meanAccuracy, double passRate}) stats(int step, double sigmaMs, {int trials = 40, int seed = 99}) {
      final rng = Random(seed + step);
      var sum = 0.0;
      var pass = 0;
      for (var i = 0; i < trials; i++) {
        final j = play(step, sigmaMs, rng);
        sum += j.accuracy;
        if (j.passed) pass++;
      }
      return (meanAccuracy: sum / trials, passRate: pass / trials);
    }

    test('pemain rapi (galat 45 ms): akurasi tinggi dan lulus ketiga step hampir selalu', () {
      for (var step = 1; step <= 3; step++) {
        final s = stats(step, 45);
        expect(s.meanAccuracy, greaterThan(0.80), reason: 'step $step');
        expect(s.passRate, greaterThanOrEqualTo(0.85), reason: 'step $step');
      }
    });

    test('pemain sedang (galat 60 ms): step 1 dan 2 lulus, step 3 lebih sulit', () {
      expect(stats(1, 60).passRate, greaterThan(0.9));
      expect(stats(2, 60).passRate, greaterThan(0.5));
      expect(stats(3, 60).passRate, lessThan(0.75));
    });

    test('pemain longgar (galat 80 ms): step 1 sekitar 65%, step 3 hampir selalu gagal', () {
      final s1 = stats(1, 80);
      expect(s1.meanAccuracy, inInclusiveRange(0.55, 0.75));
      expect(stats(3, 80).passRate, lessThan(0.1));
    });

    test('mengetuk asal (acak jalur dan waktu) gagal di step 1', () {
      final rng = Random(5);
      for (var trial = 0; trial < 10; trial++) {
        final chart = RhythmChart.forStep(1);
        final judge = RhythmJudge.forStep(1, chart: chart);
        for (var t = 1.0; t < chart.duration; t += 0.2) {
          judge.tap(rng.nextInt(rhythmLaneCount), t);
        }
        judge.advance(chart.duration + 5);
        expect(judge.passed, isFalse, reason: 'trial $trial');
        expect(judge.accuracy, lessThan(0.45));
      }
    });
  });
}
