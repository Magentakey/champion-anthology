import 'dart:math';

import 'cooking_config.dart';
import 'cooking_models.dart';

enum CheckStatus { running, success, failed }

/// "Cooking check" di satu stasiun. Murni logika Dart (tanpa Flame/Flutter) yang digerakkan
/// oleh `update(dt)` dari game, sehingga ikut berhenti saat jeda dan mudah diuji.
abstract class CookingCheck {
  CookingCheck(this.station, this.maxSeconds);

  final Station station;
  final double maxSeconds;
  CheckStatus status = CheckStatus.running;
  double elapsed = 0;

  /// 0..1 untuk bar kemajuan di HUD.
  double get progress;

  /// Selesai dengan mulus (memberi bonus waktu).
  bool get perfect;

  bool get isRunning => status == CheckStatus.running;

  void update(double dt) {
    if (!isRunning) return;
    elapsed += dt;
    step(dt);
    if (isRunning && elapsed >= maxSeconds) status = CheckStatus.failed;
  }

  /// Kemajuan khusus tiap jenis check.
  void step(double dt);

  /// Ketukan pemain. true = ketukan bagus (benar), false = meleset.
  bool onTap() => true;

  /// Tombol api ditahan / dilepas (hanya Panci).
  void setHolding(bool holding) {}

  void _succeed() => status = CheckStatus.success;
  void _fail() => status = CheckStatus.failed;

  static CookingCheck create(Station s, CookingStepConfig cfg, Random rng) => switch (s) {
        Station.chop => ChopCheck(cfg.chop),
        Station.boil => BoilCheck(cfg.boil, rng),
        Station.fry => FryCheck(cfg.fry, rng),
      };
}

/// Talenan: ketuk terus sampai bar penuh; bar turun jika berhenti.
class ChopCheck extends CookingCheck {
  ChopCheck(this.params) : super(Station.chop, params.maxSeconds);

  final ChopParams params;
  double _fill = 0;
  double _sinceTap = 1;
  int tapCount = 0;

  static const _grace = 0.25;

  @override
  double get progress => _fill.clamp(0.0, 1.0);

  @override
  bool get perfect => elapsed <= maxSeconds * 0.6;

  @override
  bool onTap() {
    if (!isRunning) return true;
    tapCount++;
    _sinceTap = 0;
    _fill += 1 / params.tapsNeeded;
    if (_fill >= 1) {
      _fill = 1;
      _succeed();
    }
    return true;
  }

  @override
  void step(double dt) {
    _sinceTap += dt;
    if (_sinceTap > _grace) {
      _fill = max(0, _fill - params.decayTapsPerSec / params.tapsNeeded * dt);
    }
  }
}

/// Panci: jaga suhu di zona hijau selama [BoilParams.holdSeconds]. Terlalu panas = meluap (gagal).
class BoilCheck extends CookingCheck {
  BoilCheck(this.params, Random rng)
      : _phase = rng.nextDouble() * 2 * pi,
        super(Station.boil, params.maxSeconds);

  final BoilParams params;
  final double _phase;
  double temperature = 0.25;
  double _held = 0;
  bool holding = false;
  bool overflowed = false;

  @override
  double get progress => (_held / params.holdSeconds).clamp(0.0, 1.0);

  bool get inZone => temperature >= params.zoneLow && temperature <= params.zoneHigh;

  /// Suhu mendekati batas meluap (untuk peringatan di HUD).
  bool get danger => temperature > 0.85;

  @override
  bool get perfect => elapsed <= params.holdSeconds * 1.6;

  @override
  void setHolding(bool holding) => this.holding = holding;

  @override
  void step(double dt) {
    // penurunan suhu bergelombang agar tidak cukup menekan tombol dengan ritme tetap
    final wobble = 1 + 0.4 * sin(elapsed * 2.3 + _phase);
    temperature += (holding ? params.riseRate : -params.fallRate * wobble) * dt;
    if (temperature >= 1) {
      temperature = 1;
      overflowed = true;
      _fail();
      return;
    }
    if (temperature < 0) temperature = 0;

    if (inZone) {
      _held += dt;
      if (_held >= params.holdSeconds) _succeed();
    } else {
      _held = max(0, _held - dt * 0.5);
    }
  }
}

/// Wajan: ketuk saat jarum ada di zona emas; [FryParams.hitsNeeded] kali tepat.
class FryCheck extends CookingCheck {
  FryCheck(this.params, this._rng) : super(Station.fry, params.maxSeconds) {
    _speed = params.sweepSpeed;
    center = _newCenter(null);
  }

  final FryParams params;
  final Random _rng;
  late double _speed;
  double needle = 0;
  int _dir = 1;
  late double center;
  int hits = 0;
  int misses = 0;
  int tapCount = 0;

  @override
  double get progress => hits / params.hitsNeeded;

  @override
  bool get perfect => misses == 0;

  bool get needleInZone => (needle - center).abs() <= params.zoneWidth / 2;

  double _newCenter(double? avoid) {
    final lo = params.zoneWidth / 2 + 0.05;
    final hi = 1 - params.zoneWidth / 2 - 0.05;
    double c;
    var guard = 0;
    do {
      c = lo + _rng.nextDouble() * (hi - lo);
    } while (avoid != null && (c - avoid).abs() < 0.25 && ++guard < 20);
    return c;
  }

  @override
  void step(double dt) {
    needle += _dir * _speed * dt;
    if (needle >= 1) {
      needle = 1;
      _dir = -1;
    } else if (needle <= 0) {
      needle = 0;
      _dir = 1;
    }
  }

  @override
  bool onTap() {
    if (!isRunning) return true;
    tapCount++;
    if (needleInZone) {
      hits++;
      if (hits >= params.hitsNeeded) {
        _succeed();
      } else {
        center = _newCenter(center);
        _speed *= 1.1;
      }
      return true;
    }
    misses++;
    if (misses > params.missesAllowed) _fail();
    return false;
  }
}
