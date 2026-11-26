import 'package:champion_anthology/levels/rhythm/rhythm_chart.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:flutter_test/flutter_test.dart';

const eps = 1e-9;

List<RhythmNote> byTime(RhythmChart c) => [...c.notes]..sort((a, b) => a.time != b.time ? a.time.compareTo(b.time) : a.lane.compareTo(b.lane));

/// Kelompok not per waktu (not bersamaan masuk satu kelompok).
List<List<RhythmNote>> onsets(RhythmChart c) {
  final out = <List<RhythmNote>>[];
  for (final n in byTime(c)) {
    if (out.isNotEmpty && (out.last.first.time - n.time).abs() < eps) {
      out.last.add(n);
    } else {
      out.add([n]);
    }
  }
  return out;
}

void expectChartRules(RhythmChart c, {required int notes, required int doubles, String reason = ''}) {
  expect(c.noteCount, notes, reason: reason);
  expect(c.doubleCount, doubles, reason: reason);

  // not hanya di kisi ketukan
  final gridSeconds = 60 / (c.bpm * c.gridPerBeat);
  for (final n in c.notes) {
    final slot = n.time / gridSeconds;
    expect((slot - slot.round()).abs(), lessThan(1e-6), reason: '$reason tidak di kisi: ${n.time}');
    expect(n.lane, inInclusiveRange(0, rhythmLaneCount - 1), reason: reason);
  }

  // 1 detik pertama dan terakhir kosong
  for (final n in c.notes) {
    expect(n.time, greaterThanOrEqualTo(ChartRules.edgeSeconds - eps), reason: '$reason awal');
    expect(n.time, lessThanOrEqualTo(c.duration - ChartRules.edgeSeconds + eps), reason: '$reason akhir');
  }

  // jarak minimal antar not di jalur yang sama
  for (var lane = 0; lane < rhythmLaneCount; lane++) {
    final times = byTime(c).where((n) => n.lane == lane).map((n) => n.time).toList();
    for (var i = 1; i < times.length; i++) {
      expect(times[i] - times[i - 1], greaterThanOrEqualTo(ChartRules.sameLaneGapSeconds - eps), reason: '$reason jalur $lane');
    }
  }

  // jarak antar saat-ketuk, pasangan bersamaan tidak di jalur yang sama dan tidak ada tiga serentak
  final groups = onsets(c);
  for (var i = 0; i < groups.length; i++) {
    expect(groups[i].length, lessThanOrEqualTo(2), reason: '$reason tiga not serentak');
    if (groups[i].length == 2) {
      expect(groups[i][0].lane, isNot(groups[i][1].lane), reason: '$reason pasangan satu jalur');
    }
    if (i > 0) {
      expect(groups[i].first.time - groups[i - 1].first.time, greaterThanOrEqualTo(ChartRules.onsetGapSeconds - eps), reason: '$reason rapat');
    }
  }
}

void main() {
  group('Lagu tetap tiap step', () {
    test('jumlah not, pasangan, dan aturan pembuatan sesuai tabel rancangan', () {
      for (var step = 1; step <= 3; step++) {
        final c = RhythmChart.forStep(step);
        expect(c.bpm, rhythmBpmOf(step));
        expect(c.bars, rhythmBarsOf(step));
        expectChartRules(c, notes: rhythmNoteCountOf(step), doubles: rhythmDoubleCount[step - 1], reason: 'step $step');
      }
    });

    test('durasi lagu = bar x 4 ketukan x 60 / BPM', () {
      for (var step = 1; step <= 3; step++) {
        expect(RhythmChart.forStep(step).duration, closeTo(rhythmSongSeconds(step), eps));
      }
    });

    test('lagu sama persis tiap kali diminta (deterministik, dan di-cache)', () {
      for (var step = 1; step <= 3; step++) {
        expect(identical(RhythmChart.forStep(step), RhythmChart.forStep(step)), isTrue);
        final again = RhythmChart.generate(
          bpm: rhythmBpmOf(step),
          bars: rhythmBarsOf(step),
          noteCount: rhythmNoteCountOf(step),
          doubles: rhythmDoubleCount[step - 1],
          seed: rhythmSeeds[step - 1],
          gridPerBeat: step >= 3 ? 4 : 2,
          maxLaneJump: step == 1 ? 2 : 3,
          bias: step == 1 ? LaneBias.near : (step == 2 ? LaneBias.neutral : LaneBias.far),
        );
        expect(again.notes, RhythmChart.forStep(step).notes, reason: 'step $step');
      }
    });

    test('step 1 tanpa pasangan, lompat antar jalur paling jauh 2, maksimal 2 not berurutan di jalur sama', () {
      final c = RhythmChart.forStep(1);
      expect(c.doubleCount, 0);
      final seq = byTime(c);
      var run = 1;
      for (var i = 1; i < seq.length; i++) {
        expect((seq[i].lane - seq[i - 1].lane).abs(), lessThanOrEqualTo(2));
        run = seq[i].lane == seq[i - 1].lane ? run + 1 : 1;
        expect(run, lessThanOrEqualTo(ChartRules.maxSameLaneRun));
      }
    });

    test('step 1 hanya memakai kisi ketukan penuh dan setengah, step 3 boleh seperempat', () {
      for (final step in [1, 2]) {
        expect(RhythmChart.forStep(step).gridPerBeat, 2);
      }
      expect(RhythmChart.forStep(3).gridPerBeat, 4);
    });

    test('semua jalur dipakai di tiap lagu', () {
      for (var step = 1; step <= 3; step++) {
        final lanes = RhythmChart.forStep(step).notes.map((n) => n.lane).toSet();
        expect(lanes, {0, 1, 2, 3}, reason: 'step $step');
      }
    });

    test('lagu berbeda tiap step', () {
      expect(RhythmChart.forStep(1).notes, isNot(RhythmChart.forStep(2).notes));
    });
  });

  group('Pembuat lagu', () {
    test('banyak seed menghasilkan lagu yang memenuhi semua aturan', () {
      for (var step = 1; step <= 3; step++) {
        for (var seed = 1; seed <= 120; seed++) {
          final c = RhythmChart.generate(
            bpm: rhythmBpmOf(step),
            bars: rhythmBarsOf(step),
            noteCount: rhythmNoteCountOf(step),
            doubles: rhythmDoubleCount[step - 1],
            seed: seed * 31,
            gridPerBeat: step >= 3 ? 4 : 2,
            maxLaneJump: step == 1 ? 2 : 3,
            bias: step == 1 ? LaneBias.near : (step == 2 ? LaneBias.neutral : LaneBias.far),
          );
          expectChartRules(c, notes: rhythmNoteCountOf(step), doubles: rhythmDoubleCount[step - 1], reason: 'step $step seed ${seed * 31}');
        }
      }
    });

    test('seed berbeda biasanya menghasilkan lagu berbeda', () {
      RhythmChart make(int seed) => RhythmChart.generate(bpm: 110, bars: 20, noteCount: 48, doubles: 6, seed: seed);
      expect(make(1).notes, isNot(make(2).notes));
      expect(make(5).notes, make(5).notes);
    });

    test('argumen tidak masuk akal dilempar sebagai ArgumentError', () {
      expect(() => RhythmChart.generate(bpm: 90, bars: 16, noteCount: 3, doubles: 3, seed: 1), throwsArgumentError);
      expect(() => RhythmChart.generate(bpm: 90, bars: 16, noteCount: 3, doubles: -1, seed: 1), throwsArgumentError);
    });

    test('permintaan mustahil (terlalu banyak not untuk lagu pendek) gagal dengan StateError', () {
      expect(() => RhythmChart.generate(bpm: 90, bars: 2, noteCount: 40, doubles: 0, seed: 1), throwsStateError);
    });

    test('daftar not tidak bisa diubah', () {
      expect(() => RhythmChart.forStep(1).notes.add(const RhythmNote(1, 0)), throwsUnsupportedError);
    });
  });
}
