/// Tuning kesulitan Level 5 (Bima the Shooter): ubah angka di sini saja.
///
/// Satuan jarak: 1,0 = jari-jari papan sasaran. Cincin papan: 0,2 / 0,4 / 0,6 / 0,8 / 1,0.
/// Angka sudah disimulasikan dengan pemain mahir, biasa, pemula, dan asal-asalan; tes di
/// `archery_test.dart` menjaga agar tuning ini tidak rusak (pemain mahir menang, asal-asalan kalah).
class ArcheryStepConfig {
  const ArcheryStepConfig({
    required this.arrows,
    required this.targetScore,
    required this.aimX,
    required this.aimY,
    required this.aimSpeed,
    required this.shake,
    this.wind = 0,
    this.targetX = 0,
    this.targetY = 0,
    this.targetSpeed = 1,
  });

  /// Jumlah anak panah; skor harus mencapai [targetScore] sebelum habis.
  final int arrows;
  final int targetScore;

  /// Simpangan goyangan bidikan (satuan jari-jari) dan kecepatannya (rad/detik).
  final double aimX;
  final double aimY;
  final double aimSpeed;

  /// Pertambahan gemetar per detik setelah busur ditarik penuh (0,5 = +50% simpangan tiap detik).
  final double shake;

  /// Kekuatan angin maksimum (0 = tanpa angin).
  final double wind;

  /// Gerak papan sasaran (simpangan dan kecepatan); 0 = papan diam.
  final double targetX;
  final double targetY;
  final double targetSpeed;

  bool get hasWind => wind > 0;
  bool get targetMoves => targetX > 0 || targetY > 0;
}

const archerySteps = <ArcheryStepConfig>[
  // Step 1 - Mudah
  ArcheryStepConfig(arrows: 6, targetScore: 44, aimX: 0.65, aimY: 0.55, aimSpeed: 1.1, shake: 0.30),
  // Step 2 - Sedang: bidikan lebih liar dan ada angin
  ArcheryStepConfig(arrows: 7, targetScore: 46, aimX: 0.85, aimY: 0.70, aimSpeed: 1.4, shake: 0.45, wind: 0.35),
  // Step 3 - Sulit: angin kencang dan papan bergerak
  ArcheryStepConfig(
    arrows: 8,
    targetScore: 50,
    aimX: 0.95,
    aimY: 0.75,
    aimSpeed: 1.5,
    shake: 0.50,
    wind: 0.50,
    targetX: 0.40,
    targetY: 0.20,
    targetSpeed: 1.1,
  ),
];

const archeryStepLabels = <String>['Mudah', 'Sedang', 'Sulit'];

/// Konstanta bidikan dan permainan.
class ArcheryTuning {
  const ArcheryTuning._();

  /// Lama menarik busur dari kosong sampai penuh (detik).
  static const double fillSeconds = 1.2;

  /// Kekuatan minimum agar anak panah terbang lurus; di bawahnya jatuh ke bawah.
  static const double minPower = 0.9;

  /// Seberapa jauh anak panah jatuh per kekurangan kekuatan (satuan jari-jari).
  static const double dropFactor = 2.5;

  /// Batas waktu satu tembakan; habis = anak panah dilepas otomatis.
  static const double shotSeconds = 9;

  /// Tarikan lebih singkat dari ini dianggap tersentuh tak sengaja (dibatalkan, anak panah tidak terpakai).
  static const double minDrawSeconds = 0.15;

  /// Lama banner step sebelum tembakan pertama.
  static const double introSeconds = 1.4;

  /// Lama anak panah terbang dan jeda sebelum tembakan berikutnya.
  static const double flightSeconds = 0.22;
  static const double pauseSeconds = 0.7;

  /// Bos mengejek saat tinggal satu anak panah.
  static const int lastArrowHint = 1;

  /// Batas cincin (jarak maksimum) dan skornya, dari tengah ke tepi.
  static const List<double> ringRadius = [0.2, 0.4, 0.6, 0.8, 1.0];
  static const List<int> ringScore = [10, 8, 6, 4, 2];
}

/// Posisi vertikal (pecahan tinggi layar) yang dipakai bersama oleh Flame dan HUD Flutter.
/// Bos dan gelembung sama dengan level lain.
class ArcheryLayout {
  const ArcheryLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.10;
  static const double bubbleHeight = 0.15;
  static const double bubbleLeft = 0.52;
  static const double clockY = 0.335; // bar batas waktu tembakan
  static const double rangeTop = 0.365; // area papan sasaran
  static const double rangeHeight = 0.34;
  static const double windTop = 0.715;
  static const double windHeight = 0.045;
  static const double controlTop = 0.77;
  static const double controlBottom = 0.03;
  static const double sideMargin = 16;
}
