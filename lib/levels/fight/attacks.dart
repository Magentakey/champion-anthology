import 'dart:ui' show Offset;

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

  /// Pukulan berat Rock (fase 3): sulit ditangkis, aba-aba panjang.
  static final heavy = AttackSpec(
    id: 'heavy',
    clip: Clips.heavyHit,
    damage: 18,
    knockback: 380,
    hurtMs: 460,
    arriveKey: 1,
  );

  /// Urutan rangkaian pukulan pemain.
  static final List<AttackSpec> punchChain = [punch, cross, finisher];
}
