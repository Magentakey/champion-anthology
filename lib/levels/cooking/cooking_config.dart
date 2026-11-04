// Tuning kesulitan Level 4: ubah angka di sini saja.
// Step 1..3 berbeda pada jumlah bahan, pengecoh, dan seberapa ketat tiap cooking check.

/// Iris: ketuk berulang sampai bar penuh; bar turun pelan jika berhenti mengetuk.
class ChopParams {
  const ChopParams({required this.tapsNeeded, required this.decayTapsPerSec, required this.maxSeconds});

  final int tapsNeeded;

  /// Kecepatan bar turun, dalam "ketukan per detik" (setelah jeda singkat tanpa ketukan).
  final double decayTapsPerSec;
  final double maxSeconds;
}

/// Rebus: tahan tombol api untuk menaikkan suhu, lepas untuk menurunkan; jaga di zona hijau.
class BoilParams {
  const BoilParams({
    required this.zoneLow,
    required this.zoneHigh,
    required this.holdSeconds,
    required this.riseRate,
    required this.fallRate,
    required this.maxSeconds,
  });

  final double zoneLow;
  final double zoneHigh;

  /// Lama total berada di zona hijau untuk lolos.
  final double holdSeconds;
  final double riseRate; // per detik saat api ditahan
  final double fallRate; // per detik saat dilepas (bergelombang sedikit)
  final double maxSeconds;
}

/// Goreng: ketuk saat jarum melewati zona emas.
class FryParams {
  const FryParams({
    required this.zoneWidth,
    required this.sweepSpeed,
    required this.hitsNeeded,
    required this.missesAllowed,
    required this.maxSeconds,
  });

  final double zoneWidth; // lebar zona emas, pecahan lebar bar (0..1)
  final double sweepSpeed; // lebar bar per detik
  final int hitsNeeded;
  final int missesAllowed; // meleset lebih dari ini = gosong
  final double maxSeconds;
}

class CookingStepConfig {
  const CookingStepConfig({
    required this.ingredients,
    required this.decoys,
    required this.seconds,
    required this.chop,
    required this.boil,
    required this.fry,
  });

  final int ingredients;
  final int decoys;
  final int seconds;
  final ChopParams chop;
  final BoilParams boil;
  final FryParams fry;
}

const cookingSteps = <CookingStepConfig>[
  // Step 1 - Mudah
  CookingStepConfig(
    ingredients: 3,
    decoys: 1,
    seconds: 60,
    chop: ChopParams(tapsNeeded: 10, decayTapsPerSec: 1.0, maxSeconds: 6),
    boil: BoilParams(zoneLow: 0.40, zoneHigh: 0.70, holdSeconds: 2.0, riseRate: 0.55, fallRate: 0.35, maxSeconds: 8),
    fry: FryParams(zoneWidth: 0.30, sweepSpeed: 0.8, hitsNeeded: 2, missesAllowed: 2, maxSeconds: 8),
  ),
  // Step 2 - Sedang
  CookingStepConfig(
    ingredients: 4,
    decoys: 2,
    seconds: 60,
    chop: ChopParams(tapsNeeded: 12, decayTapsPerSec: 2.0, maxSeconds: 6),
    boil: BoilParams(zoneLow: 0.45, zoneHigh: 0.67, holdSeconds: 2.5, riseRate: 0.60, fallRate: 0.40, maxSeconds: 8),
    fry: FryParams(zoneWidth: 0.22, sweepSpeed: 1.1, hitsNeeded: 2, missesAllowed: 1, maxSeconds: 8),
  ),
  // Step 3 - Sulit
  CookingStepConfig(
    ingredients: 5,
    decoys: 2,
    seconds: 70,
    chop: ChopParams(tapsNeeded: 14, decayTapsPerSec: 3.0, maxSeconds: 6.5),
    boil: BoilParams(zoneLow: 0.48, zoneHigh: 0.64, holdSeconds: 3.0, riseRate: 0.65, fallRate: 0.45, maxSeconds: 9),
    fry: FryParams(zoneWidth: 0.16, sweepSpeed: 1.4, hitsNeeded: 3, missesAllowed: 1, maxSeconds: 9),
  ),
];

const cookingStepLabels = <String>['Mudah', 'Sedang', 'Sulit'];

class CookingTuning {
  const CookingTuning._();

  /// Salah stasiun / memberi bahan di luar pesanan.
  static const double wrongPenalty = 3;

  /// Cooking check gagal (gosong, meluap, atau kehabisan waktu check).
  static const double failPenalty = 4;

  /// Check sempurna menambah waktu.
  static const double perfectBonus = 1;

  /// Lama banner step tampil sebelum waktu mulai berjalan.
  static const double introSeconds = 1.4;

  static const int hurrySeconds = 10;
}

/// Posisi vertikal (pecahan tinggi layar) yang dipakai bersama oleh Flame dan HUD Flutter.
/// Chef dan gelembung sama dengan Bob the Genius.
class CookingLayout {
  const CookingLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.10;
  static const double bubbleHeight = 0.15;
  static const double bubbleLeft = 0.52;
  static const double orderTop = 0.31;
  static const double orderHeight = 0.125;
  static const double timeBarY = 0.452;
  static const double lowerTop = 0.48; // awal area stasiun (panel check menutupi sampai bawah)
  static const double stationsHeight = 0.265;
  static const double trayTop = 0.765;
  static const double lowerBottom = 0.03;
  static const double sideMargin = 16;
}
