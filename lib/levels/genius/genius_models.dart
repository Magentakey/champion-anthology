import 'dart:math';

/// Soal yang sudah diacak urutan pilihannya.
class Question {
  const Question({
    required this.category,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String category;
  final String text;
  final List<String> options;
  final int correctIndex;
}

/// Entri bank soal: jawaban benar + 3 pengecoh. Urutan diacak saat dimainkan.
class QuizItem {
  const QuizItem({
    required this.category,
    required this.text,
    required this.correct,
    required this.wrong,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    final item = QuizItem(
      category: (json['category'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
      correct: (json['correct'] as String?)?.trim() ?? '',
      wrong: [
        for (final w in (json['wrong'] as List<dynamic>? ?? const []))
          (w as String).trim(),
      ],
    );
    item.validate();
    return item;
  }

  final String category;
  final String text;
  final String correct;
  final List<String> wrong;

  /// Melempar [FormatException] jika data soal tidak valid.
  void validate() {
    if (text.isEmpty || correct.isEmpty) {
      throw FormatException('Soal/jawaban kosong: "$text"');
    }
    if (wrong.length != 3) {
      throw FormatException('Soal harus punya 3 pengecoh: "$text"');
    }
    if ({correct, ...wrong}.length != 4) {
      throw FormatException('Pilihan jawaban harus unik: "$text"');
    }
  }

  Question toQuestion(Random rng) {
    final options = [correct, ...wrong]..shuffle(rng);
    return Question(
      category: category,
      text: text,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }
}

/// Sorotan jawaban setelah dipilih (chosen = -1 jika waktu habis).
class AnswerFeedback {
  const AnswerFeedback({required this.chosen, required this.correct});

  final int chosen;
  final int correct;
}

class StepProgress {
  const StepProgress({
    required this.correct,
    required this.target,
    required this.lives,
    required this.maxLives,
  });

  const StepProgress.empty()
      : correct = 0,
        target = 0,
        lives = 0,
        maxLives = 0;

  final int correct;
  final int target;
  final int lives;
  final int maxLives;
}

class StepConfig {
  const StepConfig({
    required this.targetCorrect,
    required this.secondsPerQuestion,
    required this.lives,
  });

  /// Jawaban benar yang dibutuhkan untuk memenangkan step.
  final int targetCorrect;
  final double secondsPerQuestion;

  /// Kesempatan salah / telat sebelum kalah. Set 1 = salah sekali langsung kalah.
  final int lives;
}
