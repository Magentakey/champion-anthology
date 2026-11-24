import 'dart:math';
import 'dart:ui';

import 'archery_config.dart';

/// Skor satu anak panah dari jarak [distance] ke tengah papan (satuan jari-jari); 0 jika meleset.
int ringScore(double distance) {
  for (var i = 0; i < ArcheryTuning.ringRadius.length; i++) {
    if (distance <= ArcheryTuning.ringRadius[i]) return ArcheryTuning.ringScore[i];
  }
  return 0;
}

/// Hasil satu tembakan.
class ShotResult {
  const ShotResult({required this.impact, required this.score, required this.power});

  /// Titik jatuh relatif terhadap tengah papan (satuan jari-jari; y positif = ke bawah).
  final Offset impact;
  final int score;
  final double power;

  bool get bullseye => score >= ArcheryTuning.ringScore.first;
}

/// Gerak papan sasaran selama satu step: fungsi waktu murni, sehingga papan terus bergerak mulus
/// di antara tembakan dan anak panah yang menancap ikut bergerak bersama papan.
class TargetMotion {
  TargetMotion(this.config, Random rng) : _tp = [for (var i = 0; i < 2; i++) rng.nextDouble() * 2 * pi];

  final ArcheryStepConfig config;
  final List<double> _tp;

  /// Pusat papan relatif terhadap pusat area bidik pada [time] detik sejak step dimulai.
  Offset at(double time) {
    final c = config;
    if (!c.targetMoves) return Offset.zero;
    return Offset(
      c.targetX * sin(c.targetSpeed * time + _tp[0]),
      c.targetY * sin(0.7 * c.targetSpeed * time + _tp[1]),
    );
  }
}

/// Satu tembakan: bidikan yang bergoyang, busur yang ditarik, angin, dan papan yang mungkin bergerak.
/// Logika murni (tanpa Flame) yang digerakkan oleh `update(dt)` dari game, sehingga ikut berhenti
/// saat jeda dan mudah diuji.
///
/// Titik bidik [crosshair] sudah memuat angin dan jatuhnya anak panah karena tarikan kurang kuat,
/// jadi yang dilihat pemain di layar adalah tempat anak panah benar-benar akan mendarat.
class ArcheryShot {
  ArcheryShot(this.config, Random rng, {TargetMotion? motion, this.motionStart = 0})
      : _p = [for (var i = 0; i < 4; i++) rng.nextDouble() * 2 * pi],
        wind = config.hasWind ? (rng.nextBool() ? 1 : -1) * (0.4 + 0.6 * rng.nextDouble()) * config.wind : 0,
        motion = motion ?? TargetMotion(config, rng);

  final ArcheryStepConfig config;
  final List<double> _p;
  final TargetMotion motion;

  /// Waktu gerak papan saat tembakan ini dimulai (agar papan tidak melompat antar tembakan).
  final double motionStart;

  /// Arah dan kekuatan angin pada tembakan ini (negatif = ke kiri, satuan jari-jari).
  final double wind;

  /// Waktu sejak tembakan dimulai, dan lama busur sudah ditarik (detik).
  double t = 0;
  double hold = 0;
  bool drawing = false;
  bool released = false;

  void update(double dt) {
    if (released) return;
    t += dt;
    if (drawing) hold += dt;
  }

  /// Kekuatan tarikan 0..1.
  double get power => min(1.0, hold / ArcheryTuning.fillSeconds);

  /// Sudah ditarik cukup kuat sehingga anak panah terbang lurus.
  bool get fullyDrawn => power >= ArcheryTuning.minPower;

  /// Detik busur ditahan sesudah penuh (gemetar bertambah seiring waktu ini).
  double get tremble => max(0.0, hold - ArcheryTuning.fillSeconds);

  /// Jatuhnya anak panah (satuan jari-jari, positif = ke bawah) akibat tarikan kurang kuat.
  double get drop => power < ArcheryTuning.minPower ? (ArcheryTuning.minPower - power) * ArcheryTuning.dropFactor : 0;

  /// Dorongan angin pada titik jatuh; tarikan kuat membuat angin kurang berpengaruh.
  double get windPush => wind * (1.2 - 0.6 * power);

  /// Titik bidik relatif terhadap pusat area bidik (bukan pusat papan).
  Offset get crosshair {
    final c = config;
    final m = 1 + c.shake * tremble;
    final f = c.aimSpeed;
    final x = c.aimX * m * (0.75 * sin(f * t + _p[0]) + 0.25 * sin(2.3 * f * t + _p[1]));
    final y = c.aimY * m * (0.75 * sin(0.8 * f * t + _p[2]) + 0.25 * sin(1.9 * f * t + _p[3]));
    return Offset(x + windPush, y + drop);
  }

  /// Pusat papan relatif terhadap pusat area bidik.
  Offset get targetCenter => motion.at(motionStart + t);

  /// Titik bidik relatif terhadap pusat papan (yang menentukan skor).
  Offset get impact => crosshair - targetCenter;

  /// Skor jika dilepas sekarang.
  int get scoreNow => ringScore(impact.distance);

  /// Lepas anak panah. Hanya sekali; mengembalikan hasilnya.
  ShotResult release() {
    final r = ShotResult(impact: impact, score: scoreNow, power: power);
    released = true;
    drawing = false;
    return r;
  }
}
