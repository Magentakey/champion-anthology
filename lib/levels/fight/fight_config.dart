/// Tuning dan tata letak Level Fight. Ubah angka di sini saja.
library;

/// Posisi dan ukuran di layar landscape (pecahan tinggi / lebar layar).
abstract final class ArenaLayout {
  /// Garis tanah tempat kaki petarung berdiri.
  static const double groundY = 0.86;

  /// Tinggi petarung berdiri (dari ujung kepala sampai tanah).
  static const double fighterHeight = 0.60;

  static const double playerX = 0.30;
  static const double rockX = 0.70;

  /// Tinggi petarung dalam satuan ruang gambar pose (kepala pemain sampai tanah).
  static const double figureUnits = 1082;
}

/// Satu fase pertarungan = satu step di core. Rock punya satu bar HP; fase
/// selesai saat HP-nya turun ke [hpFloor] (pecahan dari HP penuh).
class FightPhase {
  const FightPhase(this.name, this.hpFloor);

  final String name;
  final double hpFloor;
}

const fightPhases = <FightPhase>[
  FightPhase('Pemanasan', 2 / 3),
  FightPhase('Serius', 1 / 3),
  FightPhase('Mengamuk', 0),
];

abstract final class FightStats {
  static const double playerMaxHp = 100;
  static const double rockMaxHp = 300;

  /// HP minimum Rock selama [step] (1..3): pukulan tidak bisa menurunkannya
  /// melewati batas fase dalam satu hit.
  static double rockFloorHp(int step) => rockMaxHp * fightPhases[step - 1].hpFloor;
}

/// Geometri tempur dalam satuan ruang gambar pose (1 satuan = 1 piksel bingkai 1000x1400).
abstract final class CombatGeometry {
  /// Kotak badan yang bisa terkena (kepala sampai pinggul), relatif terhadap titik tanah.
  static const double hurtHalfWidth = 170;
  static const double hurtTop = -1100;
  static const double hurtBottom = -330;

  /// Jarak minimum antar petarung agar badan tidak menumpuk.
  static const double minSeparation = 320;

  /// Margin dinding arena dari tepi.
  static const double wallMargin = 260;

  /// Kecepatan pisau (satuan per detik) dan panjang gambarnya.
  static const double knifeSpeed = 1900;
}

abstract final class PlayerStats {
  static const double walkSpeed = 650;
  static const double backSpeed = 480;

  /// Pisau: jeda antar lemparan.
  static const int knifeCooldownMs = 2000;
}

/// Pengurang damage saat tangkis: 80%, jadi hanya 20% yang tembus.
const double blockedDamageFactor = 0.2;

/// Kebal singkat setelah bangkit dari terkena, agar tidak terkunci rentetan pukulan.
const int recoveryInvulnerableMs = 250;

/// Penyangga input: serangan yang ditekan sedikit lebih awal tetap dijalankan.
const int inputBufferMs = 120;

/// Jendela menyambung rangkaian pukulan setelah satu pukulan selesai.
const int comboWindowMs = 350;

/// Perilaku Rock per fase (dipakai AI). Angka titik awal untuk tuning.
class RockPhaseStats {
  const RockPhaseStats({
    required this.speedScale,
    required this.reactionMs,
    required this.intervalMs,
    required this.punchDamage,
    required this.kickDamage,
    required this.blockChance,
    required this.hurtScale,
  });

  final double speedScale;

  /// Jeda sebelum Rock bereaksi pada serangan pemain.
  final int reactionMs;

  /// Jeda rata-rata antar serangan Rock.
  final int intervalMs;
  final double punchDamage;
  final double kickDamage;

  /// Peluang menangkis saat pemain menyerang dalam jangkauan.
  final double blockChance;

  /// Pengali lama terhenti saat terkena (Rock makin sulit dihentikan).
  final double hurtScale;
}

const rockPhaseStats = <RockPhaseStats>[
  RockPhaseStats(
    speedScale: 0.85, reactionMs: 700, intervalMs: 2200,
    punchDamage: 6, kickDamage: 9, blockChance: 0.10, hurtScale: 0.8,
  ),
  RockPhaseStats(
    speedScale: 1.0, reactionMs: 450, intervalMs: 1600,
    punchDamage: 8, kickDamage: 11, blockChance: 0.35, hurtScale: 0.55,
  ),
  RockPhaseStats(
    speedScale: 1.2, reactionMs: 250, intervalMs: 1100,
    punchDamage: 10, kickDamage: 13, blockChance: 0.50, hurtScale: 0.3,
  ),
];
