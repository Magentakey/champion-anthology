import 'dart:math';

/// Soal yang sudah diacak urutan pilihannya.
class Question {
  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String text;
  final List<String> options;
  final int correctIndex;
}

/// Entri bank soal: jawaban benar + 3 pengecoh. Urutan diacak saat dimainkan.
class QuizItem {
  const QuizItem(this.text, this.correct, this.wrong);

  final String text;
  final String correct;
  final List<String> wrong;

  Question toQuestion(Random rng) {
    final options = [correct, ...wrong]..shuffle(rng);
    return Question(
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
