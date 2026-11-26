import 'dart:io';

import 'package:champion_anthology/levels/memory/memory_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Konstanta rancangan Level 8', () {
    test('tabel rancangan: pad, panjang awal, ronde, tempo, nyawa, dan batas waktu tiap step', () {
      expect(memoryPadCount, [4, 6, 9]);
      expect(memoryStartLength, [3, 4, 5]);
      expect(memoryRounds, [5, 6, 7]);
      expect(memoryShowMs, [600, 500, 420]);
      expect(memoryLives, [3, 2, 2]);
      expect(memoryInputTimeoutMs, [5000, 4000, 3000]);
    });

    test('kisi pad 2x2, 3x2, dan 3x3 memuat tepat jumlah pad tiap step', () {
      expect(memoryColumnsOf(1), 2);
      expect(memoryRowsOf(1), 2);
      expect(memoryColumnsOf(2), 3);
      expect(memoryRowsOf(2), 2);
      expect(memoryColumnsOf(3), 3);
      expect(memoryRowsOf(3), 3);
      for (var step = 1; step <= 3; step++) {
        expect(memoryColumnsOf(step) * memoryRowsOf(step), memoryPadsOf(step), reason: 'step $step');
      }
      expect(memoryMaxPads, 9);
    });

    test('panjang ronde terakhir = awal + ronde - 1 (7, 9, 11)', () {
      for (var step = 1; step <= 3; step++) {
        expect(memoryFinalLengthOf(step), memoryStartLengthOf(step) + memoryRoundsOf(step) - 1);
      }
      expect(memoryFinalLengthOf(1), 7);
      expect(memoryFinalLengthOf(2), 9);
      expect(memoryFinalLengthOf(3), 11);
    });

    test('panjang tiap ronde bertambah satu dari ronde pertama', () {
      expect([for (var r = 1; r <= 5; r++) memoryLengthOf(1, r)], [3, 4, 5, 6, 7]);
      expect([for (var r = 1; r <= 6; r++) memoryLengthOf(2, r)], [4, 5, 6, 7, 8, 9]);
      expect([for (var r = 1; r <= 7; r++) memoryLengthOf(3, r)], [5, 6, 7, 8, 9, 10, 11]);
    });

    test('total simbol yang harus diingat: 25, 39, 56', () {
      expect(memoryTotalSymbolsOf(1), 25);
      expect(memoryTotalSymbolsOf(2), 39);
      expect(memoryTotalSymbolsOf(3), 56);
    });

    test('helper per step mengikuti tabel dan meng-clamp step di luar 1..3', () {
      expect(memoryPadsOf(1), 4);
      expect(memoryPadsOf(3), 9);
      expect(memoryStartLengthOf(2), 4);
      expect(memoryRoundsOf(3), 7);
      expect(memoryShowMsOf(2), 500);
      expect(memoryLivesOf(1), 3);
      expect(memoryTimeoutMsOf(3), 3000);
      expect(memoryPadsOf(0), 4);
      expect(memoryPadsOf(9), 9);
      expect(memoryLengthOf(1, 0), 3); // ronde di luar rentang dipotong
      expect(memoryLengthOf(1, 99), 7);
    });

    test('pad menyala 70% dari tempo: 420, 350, 294 ms', () {
      expect(MemoryTuning.litFraction, 0.7);
      expect(memoryLitMsOf(1), 420);
      expect(memoryLitMsOf(2), 350);
      expect(memoryLitMsOf(3), 294);
      for (var step = 1; step <= 3; step++) {
        expect(memoryLitMsOf(step), greaterThanOrEqualTo(294)); // tetap terbaca di tempo tercepat
        expect(memoryLitMsOf(step), lessThan(memoryShowMsOf(step)));
      }
    });

    test('tempo makin cepat, nyawa tidak bertambah, dan batas waktu makin pendek tiap step', () {
      for (var i = 1; i < 3; i++) {
        expect(memoryShowMs[i], lessThan(memoryShowMs[i - 1]));
        expect(memoryInputTimeoutMs[i], lessThan(memoryInputTimeoutMs[i - 1]));
        expect(memoryPadCount[i], greaterThan(memoryPadCount[i - 1]));
        expect(memoryLives[i], lessThanOrEqualTo(memoryLives[i - 1]));
      }
    });

    test('aturan urutan: dua simbol sama boleh, tiga dilarang', () {
      expect(memoryMaxRepeat, 2);
    });

    test('durasi tahap berupa bilangan bulat milidetik yang masuk akal', () {
      expect(MemoryTuning.introMs, greaterThan(0));
      expect(MemoryTuning.roundClearMs, greaterThan(0));
      expect(MemoryTuning.retryMs, greaterThan(MemoryTuning.blinkMs)); // kedip selesai sebelum tayang ulang
      expect(MemoryTuning.resultMs, greaterThan(0));
      expect(MemoryTuning.stepGapMs, greaterThan(0));
      expect(MemoryTuning.showLeadMs, greaterThan(0));
    });

    test('satu-satunya angka desimal di berkas konfigurasi adalah 0.7 (porsi nyala)', () {
      final source = File('lib/levels/memory/memory_config.dart').readAsStringSync();
      final code = source.split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
      final found = RegExp(r'(?<![\w.])\d+\.\d+(?![\w.])').allMatches(code).map((m) => m.group(0)).toList();
      expect(found, ['0.7']);
    });
  });
}
