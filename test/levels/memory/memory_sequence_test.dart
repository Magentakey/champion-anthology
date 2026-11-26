import 'dart:math';

import 'package:champion_anthology/levels/memory/memory_config.dart';
import 'package:champion_anthology/levels/memory/memory_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

bool hasTriple(List<int> s) {
  for (var i = 2; i < s.length; i++) {
    if (s[i] == s[i - 1] && s[i] == s[i - 2]) return true;
  }
  return false;
}

bool hasDouble(List<int> s) {
  for (var i = 1; i < s.length; i++) {
    if (s[i] == s[i - 1]) return true;
  }
  return false;
}

void main() {
  group('Pembuat urutan', () {
    test('panjang seluruh urutan = panjang ronde terakhir tiap step', () {
      for (var step = 1; step <= 3; step++) {
        final seq = MemorySequence.generate(step, Random(step));
        expect(seq.length, memoryFinalLengthOf(step));
        expect(seq.padCount, memoryPadsOf(step));
        expect(seq.step, step);
      }
    });

    test('panjang tiap ronde sesuai konfigurasi', () {
      for (var step = 1; step <= 3; step++) {
        final seq = MemorySequence.generate(step, Random(7));
        for (var round = 1; round <= memoryRoundsOf(step); round++) {
          expect(seq.forRound(round), hasLength(memoryLengthOf(step, round)));
          expect(seq.lengthOfRound(round), memoryLengthOf(step, round));
        }
      }
    });

    test('urutan ronde r adalah awalan urutan ronde r+1 (tambah satu simbol di belakang)', () {
      for (var step = 1; step <= 3; step++) {
        final seq = MemorySequence.generate(step, Random(100 + step));
        for (var round = 1; round < memoryRoundsOf(step); round++) {
          final shorter = seq.forRound(round);
          final longer = seq.forRound(round + 1);
          expect(longer.length, shorter.length + 1);
          expect(longer.sublist(0, shorter.length), shorter);
        }
      }
    });

    test('tidak ada tiga simbol sama berturut-turut (ratusan seed, tiap step)', () {
      for (var step = 1; step <= 3; step++) {
        for (var seed = 0; seed < 400; seed++) {
          final seq = MemorySequence.generate(step, Random(seed));
          expect(hasTriple(seq.symbols), isFalse, reason: 'step $step seed $seed: ${seq.symbols}');
        }
      }
    });

    test('dua simbol sama berturut-turut diperbolehkan dan memang muncul', () {
      var found = false;
      for (var seed = 0; seed < 400 && !found; seed++) {
        found = hasDouble(MemorySequence.generate(1, Random(seed)).symbols);
      }
      expect(found, isTrue);
    });

    test('semua pad muncul sedikitnya sekali di urutan ronde terakhir (ratusan seed, tiap step)', () {
      for (var step = 1; step <= 3; step++) {
        for (var seed = 0; seed < 400; seed++) {
          final seq = MemorySequence.generate(step, Random(seed));
          expect(seq.symbols.toSet(), hasLength(memoryPadsOf(step)), reason: 'step $step seed $seed: ${seq.symbols}');
        }
      }
    });

    test('simbol selalu dalam 0..pad-1', () {
      for (var step = 1; step <= 3; step++) {
        for (var seed = 0; seed < 200; seed++) {
          final seq = MemorySequence.generate(step, Random(seed));
          for (final s in seq.symbols) {
            expect(s, inInclusiveRange(0, memoryPadsOf(step) - 1));
          }
        }
      }
    });

    test('followsRules menerima urutan yang dibuat dan menolak urutan yang melanggar aturan', () {
      for (var step = 1; step <= 3; step++) {
        final seq = MemorySequence.generate(step, Random(3));
        expect(MemorySequence.followsRules(seq.symbols, memoryPadsOf(step)), isTrue);
      }
      expect(MemorySequence.followsRules([0, 0, 0, 1, 2, 3, 0], 4), isFalse); // tiga sama
      expect(MemorySequence.followsRules([0, 1, 2, 0, 1, 2, 0], 4), isFalse); // pad 3 tidak pernah muncul
      expect(MemorySequence.followsRules([0, 1, 2, 4, 1, 2, 3], 4), isFalse); // simbol di luar rentang
      expect(MemorySequence.followsRules([0, 0, 1, 1, 2, 2, 3], 4), isTrue);
    });

    test('seed sama menghasilkan urutan sama', () {
      for (var step = 1; step <= 3; step++) {
        final a = MemorySequence.generate(step, Random(42));
        final b = MemorySequence.generate(step, Random(42));
        expect(a.symbols, b.symbols);
      }
    });

    test('seed berbeda biasanya menghasilkan urutan berbeda', () {
      for (var step = 1; step <= 3; step++) {
        final distinct = <String>{
          for (var seed = 0; seed < 50; seed++) MemorySequence.generate(step, Random(seed)).symbols.join(','),
        };
        expect(distinct.length, greaterThan(30), reason: 'step $step');
      }
    });

    test('daftar simbol tidak bisa diubah dari luar', () {
      final seq = MemorySequence.generate(1, Random(1));
      expect(() => seq.symbols.add(0), throwsUnsupportedError);
      expect(() => seq.symbols[0] = 1, throwsUnsupportedError);
    });
  });

  group('Memilih simbol baru', () {
    test('tiga simbol sama berturut-turut tidak pernah dipilih', () {
      for (var seed = 0; seed < 300; seed++) {
        final next = MemorySequence.nextSymbol([1, 1], 4, 10, Random(seed));
        expect(next, isNot(1), reason: 'seed $seed');
        expect(next, inInclusiveRange(0, 3));
      }
    });

    test('dua simbol sama berturut-turut masih bisa dipilih bila yang sebelumnya hanya satu', () {
      final picks = <int>{
        for (var seed = 0; seed < 300; seed++) MemorySequence.nextSymbol([1, 2], 4, 10, Random(seed)),
      };
      expect(picks, {0, 1, 2, 3});
    });

    test('sisa tempat hanya cukup untuk pad yang belum muncul: wajib memilih pad baru', () {
      // Total 4, sudah [0, 0]: pad 1, 2, 3 belum muncul dan hanya tersisa 2 tempat setelah ini.
      for (var seed = 0; seed < 200; seed++) {
        final next = MemorySequence.nextSymbol([0, 0], 4, 4, Random(seed));
        expect({1, 2, 3}, contains(next), reason: 'seed $seed');
      }
    });

    test('pad yang sudah muncul semua: bebas memilih (asal tidak melanggar aturan tiga)', () {
      final picks = <int>{
        for (var seed = 0; seed < 300; seed++) MemorySequence.nextSymbol([0, 1, 2, 3], 4, 8, Random(seed)),
      };
      expect(picks, {0, 1, 2, 3});
    });
  });
}
