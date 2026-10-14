import 'dart:io';
import 'dart:math';

import 'package:champion_anthology/levels/genius/genius_config.dart';
import 'package:champion_anthology/levels/genius/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late QuestionBank bank;

  setUpAll(() {
    // flutter test dijalankan dari root project.
    bank = QuestionBank.parse(File(QuestionBank.assetPath).readAsStringSync());
  });

  test('JSON valid dan berisi 3 step', () {
    expect(bank.steps.length, 3);
  });

  test('tiap step punya minimal 15 soal dan cukup untuk skenario terburuk', () {
    for (var i = 0; i < geniusSteps.length; i++) {
      final c = geniusSteps[i];
      final needed = c.targetCorrect + c.lives - 1;
      expect(bank.steps[i].length, greaterThanOrEqualTo(15));
      expect(bank.steps[i].length, greaterThanOrEqualTo(needed));
    }
  });

  test('tidak ada soal ganda di seluruh bank', () {
    final texts = [for (final s in bank.steps) for (final q in s) q.text];
    expect(texts.toSet().length, texts.length);
  });

  test('tiap soal punya 4 pilihan unik dan indeks benar sesuai', () {
    final rng = Random(1);
    for (final step in bank.steps) {
      for (final item in step) {
        final q = item.toQuestion(rng);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options[q.correctIndex], item.correct);
      }
    }
  });

  test('tiap step punya minimal 3 kategori berbeda', () {
    for (final step in bank.steps) {
      expect(step.map((q) => q.category).toSet().length, greaterThanOrEqualTo(3));
    }
  });

  test('parse menolak data tidak valid', () {
    const bad = '{"steps":[{"step":1,"questions":[{"category":"x","text":"t",'
        '"correct":"a","wrong":["a","b","c"]}]},{"step":2,"questions":[]},'
        '{"step":3,"questions":[]}]}';
    expect(() => QuestionBank.parse(bad), throwsFormatException);
  });
}
