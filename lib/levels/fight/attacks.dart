import 'dart:ui' show Offset;

import 'fight_config.dart';
import 'pose.dart';
import 'pose_clips.dart';

/// Bagian tubuh yang menjadi ujung serangan (titik yang diuji terhadap badan lawan).
enum Tip { handF, handB, toeF }

/// Data satu serangan. Jendela waktu diambil dari klip animasinya, jadi gerakan di layar
/// dan kapan serangan benar-benar mengenai selalu sinkron.
class AttackSpec {
  AttackSpec({
    required this.id,
    required this.clip,
    required this.damage,
    required this.knockback,
    required this.hurtMs,
    this.tip = Tip.handF,
    this.arriveKey = 2,
    this.projectile = false,
    this.blockable = true,
    this.chain = false,
    this.telegraphMs = 0,
    this.lunge = 0,
    this.armored = false,
    this.blockedFactor = blockedDamageFactor,
  })  : hitStartMs = clip.timeAtKey(arriveKey) - 30,
        hitEndMs = clip.timeAtKey(arriveKey + 1);

  final String id;
  final PoseClip clip;
  final double damage;

  /// Dorongan mundur (satuan ruang gambar) saat mengenai.
  final double knockback;

  /// Lama lawan terhenti saat terkena.
  final int hurtMs;
  final Tip tip;

  /// Indeks kunci klip saat anggota badan tiba di titik hantam.
  final int arriveKey;

  /// Serangan lempar (pisau): tidak ada uji ujung anggota badan; benda dilepas di [hitStartMs].
  final bool projectile;
  final bool blockable;

  /// Bagian dari rangkaian pukulan (pukul, silang, penutup) yang boleh dibatalkan ke pukulan berikutnya.
  final bool chain;

  /// Aba-aba sebelum serangan (ms): petarung menahan pose bersiap dan menyala merah.
  final int telegraphMs;

  /// Jarak maju (satuan ruang gambar) selama fase persiapan serangan.
  final double lunge;

  /// Tidak terhenti saat terkena ketika sedang menyiapkan atau melakukan serangan ini.
  final bool armored;

  /// Bagian damage yang tembus saat ditangkis (bawaan 0,2; pukulan berat lebih tembus).
  final double blockedFactor;

  /// Awal dan akhir jendela hantam (ms sejak serangan mulai).
  final int hitStartMs;
  final int hitEndMs;

  int get totalMs => clip.durationMs;

  /// Letak ujung serangan pada pose [p] (relatif terhadap titik tanah penyerang, menghadap kanan).
  Offset tipOf(Pose p) {
    switch (tip) {
      case Tip.handF:
        return p.handF;
      case Tip.handB:
        return p.handB;
      case Tip.toeF:
        return p.toeF;
    }
  }

  AttackSpec withDamage(double value) => AttackSpec(
        id: id,
        clip: clip,
        damage: value,
        knockback: knockback,
        hurtMs: hurtMs,
        tip: tip,
        arriveKey: arriveKey,
        projectile: projectile,
        blockable: blockable,
        chain: chain,
        telegraphMs: telegraphMs,
        lunge: lunge,
        armored: armored,
        blockedFactor: blockedFactor,
      );
}

/// Semua serangan. Angka damage pemain: pukul 6, tendang 10, pisau 9 (1,5x pukul).
abstract final class Attacks {
  static final punch = AttackSpec(
    id: 'punch',
    clip: Clips.punch,
    damage: 6,
    knockback: 110,
    hurtMs: 260,
    chain: true,
  );

  static final cross = AttackSpec(
    id: 'cross',
    clip: Clips.cross,
    damage: 6,
    knockback: 130,
    hurtMs: 260,
    tip: Tip.handB,
    chain: true,
  );

  /// Pukulan ke-3 dalam rangkaian: lebih kuat dan mendorong jauh.
  static final finisher = AttackSpec(
    id: 'finisher',
    clip: Clips.punch,
    damage: 8,
    knockback: 320,
    hurtMs: 380,
    chain: true,
  );

  static final kick = AttackSpec(
    id: 'kick',
    clip: Clips.kick,
    damage: 10,
    knockback: 260,
    hurtMs: 360,
    tip: Tip.toeF,
  );

  /// Lempar pisau: damage 1,5x pukul. Pisau dilepas saat tangan tiba di depan.
  static final throwKnife = AttackSpec(
    id: 'throw',
    clip: Clips.throwKnife,
    damage: 9,
    knockback: 90,
    hurtMs: 220,
    projectile: true,
  );

  /// Hantaman Rock (fase 3): aba-aba merah 0,5 dtk, maju, tidak bisa dihentikan,
  /// dan hanya berkurang 40% saat ditangkis.
  static final heavy = AttackSpec(
    id: 'heavy',
    clip: Clips.heavyHit,
    damage: 18,
    knockback: 380,
    hurtMs: 460,
    arriveKey: 1,
    telegraphMs: 500,
    lunge: 140,
    armored: true,
    blockedFactor: 0.6,
  );

  /// Tendangan Putar Rock (fase 2 dan 3): aba-aba 0,35 dtk lalu menerjang sambil menendang.
  static final roundhouse = AttackSpec(
    id: 'roundhouse',
    clip: Clips.kick,
    damage: 12,
    knockback: 320,
    hurtMs: 420,
    tip: Tip.toeF,
    telegraphMs: 350,
    lunge: 260,
  );

  /// Pukulan terjang Rock (fase 3): menutup jarak jauh dengan cepat.
  static final dash = AttackSpec(
    id: 'dash',
    clip: Clips.punch,
    damage: 10,
    knockback: 200,
    hurtMs: 300,
    telegraphMs: 250,
    lunge: 480,
  );

  /// Urutan rangkaian pukulan pemain.
  static final List<AttackSpec> punchChain = [punch, cross, finisher];
}
