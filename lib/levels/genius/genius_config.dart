import 'genius_models.dart';

/// Tuning kesulitan: ubah angka di sini saja.
const geniusSteps = <StepConfig>[
  StepConfig(targetCorrect: 3, secondsPerQuestion: 12, lives: 3), // Step 1 - Mudah
  StepConfig(targetCorrect: 4, secondsPerQuestion: 9, lives: 3), // Step 2 - Sedang
  StepConfig(targetCorrect: 5, secondsPerQuestion: 7, lives: 2), // Step 3 - Sulit
];

const stepLabels = <String>['Mudah', 'Sedang', 'Sulit'];

/// Posisi vertikal (pecahan tinggi layar) yang dipakai bersama oleh Flame
/// (boss, time bar) dan HUD Flutter (soal, jawaban) supaya sejajar.
class ArenaLayout {
  const ArenaLayout._();

  static const double bossCenterY = 0.17;
  static const double bossHeight = 0.22;
  static const double questionTop = 0.33;
  static const double questionHeight = 0.19;
  static const double timeBarY = 0.565;
  static const double answersTop = 0.60;
  static const double answersBottom = 0.05;
}
