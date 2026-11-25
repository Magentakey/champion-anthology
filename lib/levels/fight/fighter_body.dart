import 'dart:math' as math;

import 'attacks.dart';
import 'fight_config.dart';
import 'pose.dart';
import 'pose_clips.dart';
import 'pose_frames.dart';
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

  double _telegraphLeft = 0;
  double _stunMs = 0;
  double _kbLeft = 0;
  int _kbDir = 1;
  double _kbPerMs = 0;
  double _iFramesMs = 0;
  double _scriptMs = 0;

  /// Combo khusus pemain (tendang + tendang, pukul + silang + tendang). Rock tidak memakainya.
  bool combosEnabled = false;

  /// Sedang menahan tombol pukul untuk mengisi serangan tenaga (hanya pemain).
  bool charging = false;
  double chargeMs = 0;
  double _kickWindowMs = 0;

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
  Pose _framePose = Poses.idleA;

  // ---------------- keadaan ----------------
  bool get canAct =>
      state == BodyState.idle || state == BodyState.walk || state == BodyState.block;
  bool get isDead => state == BodyState.ko;

  /// Sedang menahan pose aba-aba sebelum serangan khusus (ditampilkan dengan cahaya merah).
  bool get telegraphing => state == BodyState.attack && _telegraphLeft > 0;
  bool get atFloor => hpFloor > 0 && hp <= hpFloor + 1e-6;
  double get hpFraction => maxHp == 0 ? 0 : hp / maxHp;

  /// Pukulan keberapa dalam rangkaian yang sedang berjalan atau baru selesai (0 = pukul, 1 = silang, 2 = penutup).
  int get chainStep => _chainStep;

  /// Masih dalam jendela menyambung combo (setelah pukulan rangkaian selesai).
  bool get inComboWindow => _chainWindowMs > 0;

  /// Isi serangan tenaga 0..1 (1 = penuh); 0 bila tidak sedang mengisi.
  double get chargeFraction => charging ? (chargeMs / chargeFullMs).clamp(0.0, 1.0).toDouble() : 0;

  /// Isi sudah cukup agar serangan tenaga keluar saat dilepas.
  bool get chargeReady => charging && chargeMs >= chargeMinMs;

  Pose get pose => _pose;

  /// Pose kunci yang digambar sebagai sprite (tanpa campuran antar pose) dan nomor bingkainya.
  Pose get framePose => _framePose;
  int get frameIndex => PoseFrames.indexOf(_framePose);
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

  /// Mulai mengisi serangan tenaga: berdiri menahan pose menarik tinju. Gagal (false) bila sedang
  /// menyerang, terkena, atau sudah mengisi.
  bool beginCharge() {
    if (!canAct || charging) return false;
    state = BodyState.attack;
    attack = null;
    _telegraphLeft = 0;
    _clearQueue();
    charging = true;
    chargeMs = 0;
    _play(Clips.heavyWind);
    return true;
  }

  /// Lepas tombol: mengayun bila isi cukup ([chargeSlam] atau [chargeFull]); selain itu batal.
  /// Mengembalikan serangan yang keluar, atau null bila batal.
  AttackSpec? releaseCharge() {
    if (!charging) return null;
    final ms = chargeMs;
    charging = false;
    chargeMs = 0;
    if (ms < chargeMinMs) {
      state = BodyState.idle;
      return null;
    }
    final spec = ms >= chargeFullMs ? Attacks.chargeFull : Attacks.chargeSlam;
    _startAttack(spec);
    return spec;
  }

  /// Membatalkan isi tanpa menyerang (mis. saat jeda).
  void cancelCharge() {
    if (!charging) return;
    charging = false;
    chargeMs = 0;
    if (state == BodyState.attack && attack == null) state = BodyState.idle;
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
    cancelCharge();
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
      _damage(spec.damage * spec.blockedFactor);
      if (hp <= 0) {
        _knockOut(pushDir, spec.knockback);
      } else {
        _knock(pushDir, spec.knockback * 0.4);
      }
      return HitOutcome.blocked;
    }

    _damage(spec.damage);
    final armored = state == BodyState.attack && (attack?.armored ?? false);
    if (hp <= 0) {
      _knockOut(pushDir, spec.knockback);
      return HitOutcome.hit;
    }
    // serangan berarmor tetap berjalan meski terkena (hanya menerima damage)
    if (armored) return HitOutcome.hit;
    attack = null;
    _telegraphLeft = 0;
    _clearQueue();
    charging = false; // terkena saat mengisi: isi hilang
    chargeMs = 0;
    state = BodyState.hurt;
    _stunMs = spec.hurtMs * hurtScale;
    _knock(pushDir, spec.knockback);
    _play(spec.hurtClip);
    return HitOutcome.hit;
  }

  // ---------------- pembaruan per frame ----------------
  void update(double dtMs, double opponentX) {
    if (knifeCooldownMs > 0) knifeCooldownMs = math.max(0, knifeCooldownMs - dtMs);
    if (_iFramesMs > 0) _iFramesMs = math.max(0, _iFramesMs - dtMs);
    if (_chainWindowMs > 0) _chainWindowMs = math.max(0, _chainWindowMs - dtMs);
    if (_kickWindowMs > 0) _kickWindowMs = math.max(0, _kickWindowMs - dtMs);
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
    if (charging) {
      chargeMs = math.min(chargeMs + dtMs, chargeFullMs.toDouble());
      return;
    }
    final spec = attack;
    if (spec == null) {
      state = BodyState.idle;
      return;
    }
    if (_telegraphLeft > 0) {
      _telegraphLeft -= dtMs;
      if (_telegraphLeft <= 0) _play(spec.clip);
      return;
    }
    attackMs += dtMs;
    if (spec.lunge > 0 && attackMs <= spec.hitStartMs) {
      x += facing * spec.lunge / math.max(1, spec.hitStartMs) * dtMs;
    }
    // batalkan pemulihan ke pukulan berikutnya dalam rangkaian
    if (spec.chain && _queuedPunch && attackMs >= spec.hitEndMs) {
      _startPunch();
      _clearQueue();
      return;
    }
    // pukul, silang, lalu tendang: tendangan boleh langsung menyambung dari pemulihan silang
    if (combosEnabled && spec.id == Attacks.cross.id && _queuedSpec?.id == Attacks.kick.id && attackMs >= spec.hitEndMs) {
      _startAttack(Attacks.comboKick);
      _clearQueue();
      return;
    }
    // tendang + tendang: tendangan kedua menyambung dari pemulihan tendangan pertama
    if (combosEnabled && spec.id == Attacks.kick.id && _queuedSpec?.id == Attacks.kick.id && attackMs >= spec.hitEndMs) {
      _startAttack(Attacks.kickHigh);
      _clearQueue();
      return;
    }
    if (attackMs >= spec.totalMs) {
      if (spec.chain) _chainWindowMs = comboWindowMs.toDouble();
      if (combosEnabled && spec.id == Attacks.kick.id) _kickWindowMs = comboWindowMs.toDouble();
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
      // tendangan yang ditekan di jendela combo setelah silang menjadi tendangan penutup
      final isKick = combosEnabled && spec.id == Attacks.kick.id;
      final comboKick = isKick && _chainWindowMs > 0 && _chainStep == 1;
      final kickHigh = isKick && !comboKick && _kickWindowMs > 0;
      _startAttack(comboKick ? Attacks.comboKick : (kickHigh ? Attacks.kickHigh : spec));
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
    _kickWindowMs = 0;
    charging = false;
    if (spec.projectile) knifeCooldownMs = PlayerStats.knifeCooldownMs.toDouble();
    state = BodyState.attack;
    attack = spec;
    attackMs = 0;
    hitDone = false;
    projectileSpawned = false;
    _telegraphLeft = spec.telegraphMs.toDouble();
    _play(spec.telegraphMs > 0 ? spec.telegraphClip : spec.clip);
  }

  void _clearQueue() {
    _queuedPunch = false;
    _queuedSpec = null;
    _queuedMs = 0;
  }

  void _knockOut(int dir, double knockback) {
    state = BodyState.ko;
    attack = null;
    charging = false;
    chargeMs = 0;
    _telegraphLeft = 0;
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
    _framePose = _clip.sampleStepped(_clipMs.round());
  }
}
