/// Tuning kesulitan Level 3: ubah angka di sini saja.
/// Perbedaan antar step hanya ukuran labirin dan waktu (tanpa jebakan atau kabut).
class MazeStepConfig {
  const MazeStepConfig({required this.cols, required this.rows, required this.seconds});

  final int cols;
  final int rows;

  /// Batas waktu untuk menemukan jalan keluar.
  final int seconds;
}

const mazeSteps = <MazeStepConfig>[
  MazeStepConfig(cols: 7, rows: 6, seconds: 35), // Step 1 - Mudah
  MazeStepConfig(cols: 11, rows: 9, seconds: 55), // Step 2 - Sedang
  MazeStepConfig(cols: 15, rows: 12, seconds: 80), // Step 3 - Sulit
];

const mazeStepLabels = <String>['Mudah', 'Sedang', 'Sulit'];

/// Kecepatan dan jeda.
class MazeTuning {
  const MazeTuning._();

  /// Jeda antar langkah saat tombol arah ditahan.
  static const double repeatSeconds = 0.10;

  /// Jeda sebelum langkah berulang pertama saat tombol ditahan (tap = tepat satu langkah).
  static const double firstRepeatSeconds = 0.18;

  /// Lama banner step tampil sebelum waktu mulai berjalan.
  static const double introSeconds = 1.4;

  /// Bos mengejek saat sisa waktu tinggal segini (detik).
  static const int hurrySeconds = 10;
}

/// Posisi vertikal (pecahan tinggi layar) yang dipakai bersama oleh Flame
/// (bos, bar waktu, labirin) dan HUD Flutter (gelembung, tombol arah) supaya sejajar.
/// Bos dan gelembung sama dengan Bob the Genius.
class MazeLayout {
  const MazeLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.10;
  static const double bubbleHeight = 0.15;
  static const double bubbleLeft = 0.52;
  static const double timeBarY = 0.335;
  static const double mazeTop = 0.365;
  static const double mazeHeight = 0.36;
  static const double padTop = 0.745;
  static const double padBottom = 0.03;
  static const double sideMargin = 16;
}
