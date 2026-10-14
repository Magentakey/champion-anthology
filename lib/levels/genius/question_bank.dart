import 'dart:convert';

import 'genius_models.dart';

/// Bank soal Bob the Genius, dibaca dari assets/data/genius_questions.json.
/// Menambah soal = edit JSON saja, tanpa menyentuh kode.
class QuestionBank {
  QuestionBank(this.steps);

  /// Lokasi file (harus terdaftar di pubspec.yaml: `- assets/data/`).
  static const String assetPath = 'assets/data/genius_questions.json';

  /// Indeks list = step - 1.
  final List<List<QuizItem>> steps;

  List<QuizItem> forStep(int step) => steps[step - 1];

  /// Format: {"steps": [{"step": 1, "questions": [{category, text, correct, wrong[3]}]}]}
  factory QuestionBank.parse(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Root JSON harus object');
    }
    final rawSteps = root['steps'];
    if (rawSteps is! List || rawSteps.length != 3) {
      throw const FormatException('"steps" harus berisi tepat 3 step');
    }

    final steps = <List<QuizItem>>[];
    for (var i = 0; i < rawSteps.length; i++) {
      final raw = rawSteps[i] as Map<String, dynamic>;
      if (raw['step'] != i + 1) {
        throw FormatException('Urutan step salah di indeks $i');
      }
      final questions = (raw['questions'] as List<dynamic>)
          .map((q) => QuizItem.fromJson(q as Map<String, dynamic>))
          .toList();
      if (questions.isEmpty) {
        throw FormatException('Step ${i + 1} tidak punya soal');
      }
      steps.add(questions);
    }
    return QuestionBank(steps);
  }
}
