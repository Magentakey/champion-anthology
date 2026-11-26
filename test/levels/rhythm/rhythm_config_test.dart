import 'dart:io';

import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Konstanta rancangan Level 7', () {
    test('tempo, panjang bar, jumlah not, pasangan bersamaan, dan ambang tiap step', () {
      expect(rhythmLaneCount, 4);
      expect(rhythmBpm, [90, 110, 128]);
      expect(rhythmBars, [16, 20, 24]);
      expect(rhythmNoteCount, [32, 48, 72]);
      expect(rhythmDoubleCount, [0, 6, 12]);
      expect(rhythmPassThreshold, [0.6, 0.7, 0.78]);
      expect(rhythmPerfectScore, 1);
      expect(rhythmGoodScore, 0.5);
    });

    test('jendela waktu 50 / 110 / 130 ms dan waktu jatuh 1,4 detik', () {
      expect(RhythmTuning.perfectWindowMs, 50);
      expect(RhythmTuning.goodWindowMs, 110);
      expect(RhythmTuning.missWindowMs, 130);
      expect(RhythmTuning.fallMs, 1400);
      expect(RhythmTuning.beatsPerBar, 4);
    });

    test('rentang offset: 0 awal, -150..+150 dengan langkah 10 ms', () {
      expect(RhythmTuning.defaultOffsetMs, 0);
      expect(RhythmTuning.minOffsetMs, -150);
      expect(RhythmTuning.maxOffsetMs, 150);
      expect(RhythmTuning.offsetStepMs, 10);
    });

    test('helper per step mengikuti tabel dan meng-clamp step di luar 1..3', () {
      expect(rhythmBpmOf(1), 90);
      expect(rhythmBpmOf(3), 128);
      expect(rhythmBarsOf(2), 20);
      expect(rhythmNoteCountOf(3), 72);
      expect(rhythmThresholdOf(2), 0.7);
      expect(rhythmThresholdPercent(1), 60);
      expect(rhythmThresholdPercent(2), 70);
      expect(rhythmThresholdPercent(3), 78);
      expect(rhythmBpmOf(0), 90);
      expect(rhythmBpmOf(9), 128);
    });

    test('lagu sekitar 45 detik: 42,67 / 43,64 / 45,0', () {
      expect(rhythmSongSeconds(1), closeTo(42.667, 0.01));
      expect(rhythmSongSeconds(2), closeTo(43.636, 0.01));
      expect(rhythmSongSeconds(3), closeTo(45.0, 0.01));
      expect(rhythmBeatSeconds(1), closeTo(60 / 90, 1e-9));
    });

    test('judul lagu, seed, dan berkas audio tersedia untuk 3 step', () {
      expect(rhythmSongTitles, hasLength(3));
      expect(rhythmSeeds, hasLength(3));
      expect(rhythmSeeds.toSet(), hasLength(3));
      expect(rhythmSongFiles, hasLength(3));
      for (final f in rhythmSongFiles) {
        expect(File('assets/audio/$f').existsSync(), isTrue, reason: f);
      }
    });

    test('satu-satunya angka desimal di berkas konfigurasi adalah 0.6, 0.7, 0.78, 0.5', () {
      final source = File('lib/levels/rhythm/rhythm_config.dart').readAsStringSync();
      final code = source.split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
      final found = RegExp(r'(?<![\w.])\d+\.\d+(?![\w.])').allMatches(code).map((m) => m.group(0)).toList();
      expect(found, ['0.6', '0.7', '0.78', '0.5']);
    });
  });
}
