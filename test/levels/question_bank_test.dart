import 'dart:math';

import 'package:champion_anthology/levels/genius/genius_config.dart';
import 'package:champion_anthology/levels/genius/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jumlah soal tiap step cukup untuk skenario terburuk', () {
    for (var i = 0; i < geniusSteps.length; i++) {
      final c = geniusSteps[i];
      final needed = c.targetCorrect + c.lives - 1;
      expect(geniusBank[i].length, greaterThanOrEqualTo(needed));
    }
  });

  test('tiap soal punya 4 pilihan unik dan indeks benar sesuai', () {
    final rng = Random(1);
    for (final step in geniusBank) {
      for (final item in step) {
        final q = item.toQuestion(rng);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options[q.correctIndex], item.correct);
      }
    }
  });
}
