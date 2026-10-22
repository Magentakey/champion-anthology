import 'dart:math' as math;

import 'attacks.dart';
import 'fight_config.dart';
import 'pose.dart';
import 'pose_clips.dart';
import 'pose_library.dart';

enum BodyState { idle, walk, attack, block, hurt, ko, win, scripted }

enum HitOutcome { ignored, hit, blocked }

/// Logika satu petarung (tanpa Flame): posisi, HP, mesin keadaan, serangan, tangkis,
/// dan pemutaran animasi. Semua waktu dalam milidetik, jarak dalam satuan ruang gambar pose.
class FighterBody {
  FighterBody({
    required this.maxHp,
    required this.x,
    required this.facing,
    this.walkSpeed = PlayerStats.walkSpeed,
    this.backSpeed = PlayerStats.backSpeed,
  }) : hp = maxHp;

  static const _blendInMs = 60.0;

  final double maxHp;
  double hp;

  /// HP tidak bisa turun di bawah ini (batas fase Rock). 0 = bisa KO.
  double hpFloor = 0;

  double x;
  int facing;
  double walkSpeed;
  double backSpeed;
  double speedScale = 1;

  /// Pengali lama terhenti saat terkena (Rock makin sulit dihentikan).
  double hurtScale = 1;
  bool invulnerable = false;

  /// Masukan gerak (-1 kiri, 0 diam, 1 kanan) dan tombol tangkis yang sedang ditahan.
  double moveInput = 0;
  bool blockHeld = false;

  BodyState state = BodyState.idle;
  AttackSpec? attack;
  double attackMs = 0;
  bool hitDone = false;
  bool projectileSpawned = false;

  /// Sisa jeda pisau (ms).
  double knifeCooldownMs = 0;

  double _stunMs = 0;
  double _kbLeft = 0;
  int _kbDir = 1;
  double _kbPerMs = 0;
  double _iFramesMs = 0;
  double _scriptMs = 0;

  bool _queuedPunch = false;
  AttackSpec? _queuedSpec;
  double _queuedMs = 0;

  int _chainStep = 0;
  double _chainWindowMs = 0;

  PoseClip _clip = Clips.idle;
  double _clipMs = 0;
  double _blendMs = _blendInMs;
  Pose _blendFrom = Poses.idleA;
  Pose _pose = Poses.idleA;

  // ---------------- keadaan ----------------
  bool get canAct =>
      state == BodyState.idle || state == BodyState.walk || state == BodyState.block;
  bool get isDead => state == BodyState.ko;
  bool get atFloor => hpFloor > 0 && hp <= hpFloor + 1e-6;
  double get hpFraction => maxHp == 0 ? 0 : hp / maxHp;

  Pose get pose => _pose;
  PoseClip get clip => _clip;
  FaceState get face => _clip.face;

  // ---------------- perintah ----------------
  /// Tekan pukul: menyambung rangkaian pukul -> silang -> penutup bila masih dalam jendela combo.
  void queuePunch() {
    _queuedPunch = true;
    _queuedSpec = null;
    _queuedMs = inputBufferMs.toDouble();
  }

  void queueAttack(AttackSpec spec) {
    _queuedPunch = false;
    _queuedSpec = spec;
    _queuedMs = inputBufferMs.toDouble();
  }

  /// Gagal (false) jika pisau masih jeda.
  bool queueKnife() {
    if (knifeCooldownMs > 0) return false;
    queueAttack(Attacks.throwKnife);
    return true;
  }

  /// Memutar [clip] apa adanya selama [holdMs] (default: selama klipnya) lalu kembali diam.
  void playScripted(PoseClip clip, {int? holdMs}) {
    if (isDead) return;
    state = BodyState.scripted;
    attack = null;
    _clearQueue();
    _scriptMs = (holdMs ?? clip.durationMs).toDouble();
    _play(clip);
  }

  void celebrate() {
    if (isDead) return;
    state = BodyState.win;
    attack = null;
    _clearQueue();
    _play(Clips.win);
  }

  /// Menerima serangan [spec] dari penyerang di posisi [attackerX].
  HitOutcome receiveHit(AttackSpec spec, double attackerX) {
    if (state == BodyState.ko || state == BodyState.win) return HitOutcome.ignored;
    if (invulnerable || _iFramesMs > 0) return HitOutcome.ignored;

    final attackerSide = attackerX >= x ? 1 : -1;
    final pushDir = -attackerSide;
    final blocked = state == BodyState.block && spec.blockable && attackerSide == facing;

    if (blocked) {
      _damage(spec.damage * blockedDamageFactor);
      if (hp <= 0) {
        _knockOut(pushDir, spec.knockback);
      } else {
        _knock(pushDir, spec.knockback * 0.4);
      }
      return HitOutcome.blocked;
    }

    _damage(spec.damage);
    attack = null;
    _clearQueue();
    if (hp <= 0) {
      _knockOut(pushDir, spec.knockback);
      return HitOutcome.hit;
    }
    state = BodyState.hurt;
    _stunMs = spec.hurtMs * hurtScale;
    _knock(pushDir, spec.knockback);
    _play(Clips.hurt);
    return HitOutcome.hit;
  }

  // ---------------- pembaruan per frame ----------------
  void update(double dtMs, double opponentX) {
    if (knifeCooldownMs > 0) knifeCooldownMs = math.max(0, knifeCooldownMs - dtMs);
    if (_iFramesMs > 0) _iFramesMs = math.max(0, _iFramesMs - dtMs);
    if (_chainWindowMs > 0) _chainWindowMs = math.max(0, _chainWindowMs - dtMs);
    if (_queuedMs > 0) {
      _queuedMs -= dtMs;
      if (_queuedMs <= 0) _clearQueue();
    }
    _applyKnockback(dtMs);

    switch (state) {
      case BodyState.ko:
      case BodyState.win:
        break;
      case BodyState.scripted:
        _scriptMs -= dtMs;
        if (_scriptMs <= 0) state = BodyState.idle;
      case BodyState.hurt:
        _stunMs -= dtMs;
        if (_stunMs <= 0) {
          state = BodyState.idle;
          _iFramesMs = recoveryInvulnerableMs.toDouble();
        }
      case BodyState.attack:
        _updateAttack(dtMs);
      case BodyState.idle:
      case BodyState.walk:
      case BodyState.block:
        _updateFree(dtMs, opponentX);
    }

    _syncClip();
    _advanceAnimation(dtMs);
  }

  void _updateFree(double dtMs, double opponentX) {
    if (opponentX != x) facing = opponentX > x ? 1 : -1;
    if (_startQueued()) return;
    if (blockHeld) {
      state = BodyState.block;
      return;
    }
    if (moveInput != 0) {
      final toward = moveInput.sign * facing > 0;
      final speed = (toward ? walkSpeed : backSpeed) * speedScale;
      x += moveInput.sign * speed * dtMs / 1000;
      state = BodyState.walk;
    } else {
      state = BodyState.idle;
    }
  }

  void _updateAttack(double dtMs) {
    final spec = attack;
    if (spec == null) {
      state = BodyState.idle;
      return;
    }
    attackMs += dtMs;
    // batalkan pemulihan ke pukulan berikutnya dalam rangkaian
    if (spec.chain && _queuedPunch && attackMs >= spec.hitEndMs) {
      _startPunch();
      _clearQueue();
      return;
    }
    if (attackMs >= spec.totalMs) {
      if (spec.chain) _chainWindowMs = comboWindowMs.toDouble();
      attack = null;
      state = BodyState.idle;
    }
  }

  bool _startQueued() {
    if (_queuedPunch) {
      _startPunch();
      _clearQueue();
      return true;
    }
    final spec = _queuedSpec;
    if (spec != null) {
      _startAttack(spec);
      _clearQueue();
      return true;
    }
    return false;
  }

  void _startPunch() {
    final chaining = _chainWindowMs > 0 || (attack?.chain ?? false);
    _chainStep = chaining ? (_chainStep + 1) % Attacks.punchChain.length : 0;
    _startAttack(Attacks.punchChain[_chainStep]);
  }

  void _startAttack(AttackSpec spec) {
    if (!spec.chain) _chainWindowMs = 0;
    if (spec.projectile) knifeCooldownMs = PlayerStats.knifeCooldownMs.toDouble();
    state = BodyState.attack;
    attack = spec;
    attackMs = 0;
    hitDone = false;
    projectileSpawned = false;
    _play(spec.clip);
  }

  void _clearQueue() {
    _queuedPunch = false;
    _queuedSpec = null;
    _queuedMs = 0;
  }

  void _knockOut(int dir, double knockback) {
    state = BodyState.ko;
    attack = null;
    _clearQueue();
    _knock(dir, knockback);
    _play(Clips.ko);
  }

  void _damage(double amount) {
    hp = math.max(hp - amount, hpFloor);
  }

  void _knock(int dir, double distance) {
    _kbDir = dir;
    _kbLeft = distance;
    _kbPerMs = distance / 150;
  }

  void _applyKnockback(double dtMs) {
    if (_kbLeft <= 0) return;
    final step = math.min(_kbLeft, _kbPerMs * dtMs);
    x += _kbDir * step;
    _kbLeft -= step;
  }

  // ---------------- animasi ----------------
  void _syncClip() {
    switch (state) {
      case BodyState.idle:
        _play(Clips.idle, restart: false);
      case BodyState.walk:
        _play(Clips.walk, restart: false);
      case BodyState.block:
        _play(Clips.block, restart: false);
      case BodyState.attack:
      case BodyState.hurt:
      case BodyState.ko:
      case BodyState.win:
      case BodyState.scripted:
        break;
    }
  }

  void _play(PoseClip clip, {bool restart = true}) {
    if (!restart && identical(_clip, clip)) return;
    _blendFrom = _pose;
    _blendMs = 0;
    _clip = clip;
    _clipMs = 0;
  }

  void _advanceAnimation(double dtMs) {
    _clipMs += dtMs;
    if (_blendMs < _blendInMs) _blendMs += dtMs;
    final target = _clip.sample(_clipMs.round());
    _pose = _blendMs >= _blendInMs
        ? target
        : Pose.lerp(_blendFrom, target, applyEase(Ease.out, _blendMs / _blendInMs));
  }
}
