import 'pose.dart';
import 'pose_library.dart';

/// Lembar sprite petarung (assets/images/fight/player_sheet.png dan rock_sheet.png):
/// satu bingkai piksel per pose, berjajar mendatar sesuai urutan [poses].
/// Dibuat oleh tools/art/pixel_fighters.py dari data pose yang sama; urutan harus sama
/// dengan urutan pose di pose_library.dart (dijaga oleh pose_frames_test.dart).
abstract final class PoseFrames {
  /// Sisi satu bingkai (piksel sprite).
  static const double frameSize = 96;

  /// Titik tanah tepat di bawah pinggul pada bingkai (piksel sprite).
  static const double originX = 40;
  static const double originY = 68;

  /// Satuan ruang pose per piksel sprite (1 piksel sprite = 18 satuan).
  static const double unitsPerPixel = 18;

  static const poses = <Pose>[
    Poses.idleA,
    Poses.idleB,
    Poses.walkA,
    Poses.walkB,
    Poses.walkC,
    Poses.punchWind,
    Poses.punchHit,
    Poses.crossWind,
    Poses.crossHit,
    Poses.kickWind,
    Poses.kickHit,
    Poses.throwWind,
    Poses.throwHit,
    Poses.block,
    Poses.hurt,
    Poses.fall,
    Poses.ko,
    Poses.win,
    Poses.taunt,
    Poses.heavyWind,
    Poses.heavyHit,
  ];

  /// Nomor bingkai untuk [pose] (0 bila bukan salah satu pose pustaka).
  static int indexOf(Pose pose) {
    for (var i = 0; i < poses.length; i++) {
      if (identical(poses[i], pose)) return i;
    }
    return 0;
  }
}
