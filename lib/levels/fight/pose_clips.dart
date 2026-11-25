import 'pose.dart';
import 'pose_library.dart';

/// Kurva percepatan antar dua pose.
enum Ease { linear, inOut, out }

double applyEase(Ease ease, double t) {
  switch (ease) {
    case Ease.linear:
      return t;
    case Ease.inOut:
      return t * t * (3 - 2 * t);
    case Ease.out:
      return 1 - (1 - t) * (1 - t);
  }
}

/// Ekspresi wajah yang dipakai sebuah klip.
enum FaceState { idle, attack, hurt, ko, win, block, taunt }

/// Satu kunci animasi: [ms] = waktu untuk TIBA di [pose] dari kunci sebelumnya.
/// Dua kunci berurutan dengan pose sama berarti "tahan" selama [ms].
class PoseKey {
  const PoseKey(this.pose, this.ms, {this.ease = Ease.inOut});

  final Pose pose;
  final int ms;
  final Ease ease;
}

class PoseClip {
  const PoseClip(
    this.name,
    this.keys, {
    this.loop = false,
    this.face = FaceState.idle,
    this.holdLast = false,
  });

  final String name;
  final List<PoseKey> keys;

  /// Klip berulang: dimulai di kunci pertama; setelah kunci terakhir kembali ke kunci pertama
  /// selama keys.first.ms.
  final bool loop;
  final FaceState face;

  /// Klip yang berhenti di pose terakhir (KO, menang) dan tidak kembali ke diam.
  final bool holdLast;

  int get durationMs {
    var total = 0;
    for (var i = loop ? 0 : 1; i < keys.length; i++) {
      total += keys[i].ms;
    }
    return total;
  }

  /// Waktu (ms sejak klip mulai) saat kunci ke-[index] tercapai. Dipakai pertarungan untuk
  /// menyelaraskan fase serangan (persiapan, aktif, pemulihan) dengan animasinya.
  int timeAtKey(int index) {
    var total = 0;
    for (var i = 1; i <= index && i < keys.length; i++) {
      total += keys[i].ms;
    }
    return total;
  }

  bool isFinished(int tMs) => !loop && tMs >= durationMs;

  Pose sample(int tMs) {
    if (keys.length == 1) return keys.first.pose;
    if (loop) {
      final cycle = durationMs;
      var t = cycle == 0 ? 0 : (tMs < 0 ? 0 : tMs) % cycle;
      for (var i = 1; i < keys.length; i++) {
        final seg = keys[i].ms;
        if (t < seg) return _blend(keys[i - 1], keys[i], t / seg);
        t -= seg;
      }
      // segmen penutup: dari kunci terakhir kembali ke kunci pertama
      final wrap = keys.first.ms;
      return wrap == 0 ? keys.first.pose : _blend(keys.last, keys.first, t / wrap);
    }
    var t = tMs < 0 ? 0 : tMs;
    for (var i = 1; i < keys.length; i++) {
      final seg = keys[i].ms;
      if (seg == 0) continue;
      if (t < seg) return _blend(keys[i - 1], keys[i], t / seg);
      t -= seg;
    }
    return keys.last.pose;
  }

  /// Pose kunci yang ditampilkan pada [tMs] TANPA campuran antar pose (animasi sprite per bingkai):
  /// pose kunci asal sampai kemajuan (sudah diberi kurva percepatan) mencapai separuh, lalu pose tujuan.
  /// Waktu fase serangan tidak berubah; hanya gambar yang melompat antar pose kunci.
  Pose sampleStepped(int tMs) {
    if (keys.length == 1) return keys.first.pose;
    if (loop) {
      final cycle = durationMs;
      var t = cycle == 0 ? 0 : (tMs < 0 ? 0 : tMs) % cycle;
      for (var i = 1; i < keys.length; i++) {
        final seg = keys[i].ms;
        if (t < seg) return _pick(keys[i - 1], keys[i], t / seg);
        t -= seg;
      }
      final wrap = keys.first.ms;
      return wrap == 0 ? keys.first.pose : _pick(keys.last, keys.first, t / wrap);
    }
    var t = tMs < 0 ? 0 : tMs;
    for (var i = 1; i < keys.length; i++) {
      final seg = keys[i].ms;
      if (seg == 0) continue;
      if (t < seg) return _pick(keys[i - 1], keys[i], t / seg);
      t -= seg;
    }
    return keys.last.pose;
  }

  static Pose _pick(PoseKey from, PoseKey to, double u) => applyEase(to.ease, u) < 0.5 ? from.pose : to.pose;

  static Pose _blend(PoseKey from, PoseKey to, double u) =>
      Pose.lerp(from.pose, to.pose, applyEase(to.ease, u));
}

/// Semua klip animasi. Waktu (ms) = data fase serangan: persiapan -> aktif -> pemulihan.
abstract final class Clips {
  static const idle = PoseClip(
    'idle',
    [
      PoseKey(Poses.idleA, 350),
      PoseKey(Poses.idleB, 350),
      PoseKey(Poses.idleA, 350),
      PoseKey(Poses.idleC, 350),
    ],
    loop: true,
  );

  static const walk = PoseClip(
    'walk',
    [
      PoseKey(Poses.walkA, 72),
      PoseKey(Poses.walkB, 72),
      PoseKey(Poses.walkC, 72),
      PoseKey(Poses.walkD, 72),
      PoseKey(Poses.idleA, 72),
    ],
    loop: true,
  );

  /// Jab: persiapan 70, aktif 70, pemulihan 150 (ms).
  static const punch = PoseClip(
    'punch',
    [
      PoseKey(Poses.punchWind, 0),
      PoseKey(Poses.punchWind, 70),
      PoseKey(Poses.punchHit, 60, ease: Ease.out),
      PoseKey(Poses.punchHit, 70),
      PoseKey(Poses.idleA, 150),
    ],
    face: FaceState.attack,
  );

  static const cross = PoseClip(
    'cross',
    [
      PoseKey(Poses.crossWind, 0),
      PoseKey(Poses.crossWind, 70),
      PoseKey(Poses.crossHit, 60, ease: Ease.out),
      PoseKey(Poses.crossHit, 70),
      PoseKey(Poses.idleA, 160),
    ],
    face: FaceState.attack,
  );

  /// Tendangan: persiapan 130, aktif 90, pemulihan 260.
  static const kick = PoseClip(
    'kick',
    [
      PoseKey(Poses.kickWind, 0),
      PoseKey(Poses.kickWind, 130),
      PoseKey(Poses.kickHit, 70, ease: Ease.out),
      PoseKey(Poses.kickHit, 90),
      PoseKey(Poses.idleA, 260),
    ],
    face: FaceState.attack,
  );

  static const throwKnife = PoseClip(
    'throw',
    [
      PoseKey(Poses.throwWind, 0),
      PoseKey(Poses.throwWind, 110),
      PoseKey(Poses.throwHit, 70, ease: Ease.out),
      PoseKey(Poses.throwHit, 60),
      PoseKey(Poses.idleA, 180),
    ],
    face: FaceState.attack,
  );

  static const block = PoseClip(
    'block',
    [PoseKey(Poses.idleA, 0), PoseKey(Poses.block, 80)],
    face: FaceState.block,
    holdLast: true,
  );

  static const hurt = PoseClip(
    'hurt',
    [
      PoseKey(Poses.idleA, 0),
      PoseKey(Poses.hurt, 70, ease: Ease.out),
      PoseKey(Poses.hurt, 160),
      PoseKey(Poses.idleA, 200),
    ],
    face: FaceState.hurt,
  );

  /// Uppercut penutup combo pemain. Waktu SAMA dengan [punch] (persiapan 70, aktif 70, pemulihan 150)
  /// supaya angka pertarungan tidak berubah; hanya gerakannya yang berbeda: jongkok, melompat, tinju naik.
  static const uppercut = PoseClip(
    'uppercut',
    [
      PoseKey(Poses.uppercutWind, 0),
      PoseKey(Poses.uppercutWind, 70),
      PoseKey(Poses.uppercutHit, 60, ease: Ease.out),
      PoseKey(Poses.uppercutAir, 70),
      PoseKey(Poses.idleA, 150),
    ],
    face: FaceState.attack,
  );

  /// Tendangan tinggi: tendangan kedua pada combo tendang + tendang. Waktu SAMA dengan [kick].
  static const kickHigh = PoseClip(
    'kickHigh',
    [
      PoseKey(Poses.kickWind, 0),
      PoseKey(Poses.kickWind, 130),
      PoseKey(Poses.kickHighHit, 70, ease: Ease.out),
      PoseKey(Poses.kickHighHit, 90),
      PoseKey(Poses.idleA, 260),
    ],
    face: FaceState.attack,
  );

  /// Aba-aba Tendangan Putar Rock (ditahan sampai aba-aba selesai).
  static const roundhouseWind = PoseClip(
    'roundhouseWind',
    [PoseKey(Poses.idleA, 0), PoseKey(Poses.roundhouseWind, 280)],
    face: FaceState.attack,
    holdLast: true,
  );

  /// Tendangan Putar Rock. Waktu SAMA dengan [kick] (persiapan 130, aktif 90, pemulihan 260).
  static const roundhouse = PoseClip(
    'roundhouse',
    [
      PoseKey(Poses.roundhouseWind, 0),
      PoseKey(Poses.roundhouseWind, 130),
      PoseKey(Poses.roundhouseHit, 70, ease: Ease.out),
      PoseKey(Poses.roundhouseHit, 90),
      PoseKey(Poses.idleA, 260),
    ],
    face: FaceState.attack,
  );

  /// Aba-aba pukulan terjang Rock (membungkuk ke depan).
  static const dashWind = PoseClip(
    'dashWind',
    [PoseKey(Poses.idleA, 0), PoseKey(Poses.dashWind, 200)],
    face: FaceState.attack,
    holdLast: true,
  );

  /// Pukulan terjang Rock. Waktu SAMA dengan [punch].
  static const dash = PoseClip(
    'dash',
    [
      PoseKey(Poses.dashWind, 0),
      PoseKey(Poses.dashWind, 70),
      PoseKey(Poses.dashHit, 60, ease: Ease.out),
      PoseKey(Poses.dashHit, 70),
      PoseKey(Poses.idleA, 150),
    ],
    face: FaceState.attack,
  );

  /// Reaksi terkena pukulan ringan: kepala tersentak sebentar.
  static const hurtLight = PoseClip(
    'hurtLight',
    [
      PoseKey(Poses.idleA, 0),
      PoseKey(Poses.hurtLight, 50, ease: Ease.out),
      PoseKey(Poses.hurtLight, 120),
      PoseKey(Poses.idleA, 150),
    ],
    face: FaceState.hurt,
  );

  /// Reaksi terkena serangan sedang: terhuyung ke belakang.
  static const stagger = PoseClip(
    'stagger',
    [
      PoseKey(Poses.idleA, 0),
      PoseKey(Poses.stagger, 70, ease: Ease.out),
      PoseKey(Poses.stagger, 180),
      PoseKey(Poses.idleA, 200),
    ],
    face: FaceState.hurt,
  );

  /// Reaksi terkena serangan berat: terlempar sebentar lalu bangkit.
  static const launched = PoseClip(
    'launched',
    [
      PoseKey(Poses.idleA, 0),
      PoseKey(Poses.hurt, 50, ease: Ease.out),
      PoseKey(Poses.fall, 110),
      PoseKey(Poses.fall, 120),
      PoseKey(Poses.idleA, 160),
    ],
    face: FaceState.hurt,
  );

  static const ko = PoseClip(
    'ko',
    [
      PoseKey(Poses.hurt, 0),
      PoseKey(Poses.fall, 260),
      PoseKey(Poses.ko, 300, ease: Ease.out),
    ],
    face: FaceState.ko,
    holdLast: true,
  );

  static const win = PoseClip(
    'win',
    [PoseKey(Poses.idleA, 0), PoseKey(Poses.win, 220, ease: Ease.out)],
    face: FaceState.win,
    holdLast: true,
  );

  static const taunt = PoseClip(
    'taunt',
    [
      PoseKey(Poses.idleA, 0),
      PoseKey(Poses.taunt, 180, ease: Ease.out),
      PoseKey(Poses.taunt, 900),
      PoseKey(Poses.idleA, 220),
    ],
    face: FaceState.taunt,
  );

  /// Aba-aba pukulan berat (Rock): membungkuk dan menarik tinju, lalu menghantam.
  static const heavyWind = PoseClip(
    'heavyWind',
    [PoseKey(Poses.idleA, 0), PoseKey(Poses.heavyWind, 420)],
    face: FaceState.attack,
    holdLast: true,
  );

  static const heavyHit = PoseClip(
    'heavyHit',
    [
      PoseKey(Poses.heavyWind, 0),
      PoseKey(Poses.heavyHit, 70, ease: Ease.out),
      PoseKey(Poses.heavyHit, 140),
      PoseKey(Poses.idleA, 280),
    ],
    face: FaceState.attack,
  );

  /// Daftar bernama untuk panel uji dan pencarian klip.
  static const all = <String, PoseClip>{
    'idle': idle,
    'walk': walk,
    'punch': punch,
    'cross': cross,
    'kick': kick,
    'throw': throwKnife,
    'block': block,
    'hurt': hurt,
    'ko': ko,
    'win': win,
    'taunt': taunt,
    'heavyWind': heavyWind,
    'heavyHit': heavyHit,
    'uppercut': uppercut,
    'kickHigh': kickHigh,
    'roundhouseWind': roundhouseWind,
    'roundhouse': roundhouse,
    'dashWind': dashWind,
    'dash': dash,
    'hurtLight': hurtLight,
    'stagger': stagger,
    'launched': launched,
  };
}
