import 'package:champion_anthology/levels/fight/fight_config.dart';
import 'package:champion_anthology/levels/fight/pose.dart';
import 'package:champion_anthology/levels/fight/pose_clips.dart';
import 'package:champion_anthology/levels/fight/pose_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pose.lerp', () {
    test('di ujung sama dengan pose asal dan tujuan', () {
      expect(Pose.lerp(Poses.idleA, Poses.punchHit, 0).handF, Poses.idleA.handF);
      expect(Pose.lerp(Poses.idleA, Poses.punchHit, 1).handF, Poses.punchHit.handF);
    });

    test('di tengah berada tepat di antara dua pose', () {
      final mid = Pose.lerp(Poses.idleA, Poses.punchHit, 0.5);
      final a = Poses.idleA.handF, b = Poses.punchHit.handF;
      expect(mid.handF.dx, closeTo((a.dx + b.dx) / 2, 1e-9));
      expect(mid.handF.dy, closeTo((a.dy + b.dy) / 2, 1e-9));
    });

    test('arah kepala tetap vektor satuan', () {
      final mid = Pose.lerp(Poses.idleA, Poses.ko, 0.5);
      expect(mid.headDir.distance, closeTo(1, 1e-9));
    });
  });

  group('PoseClip', () {
    test('klip sekali-putar mulai di pose pertama dan berakhir di pose terakhir', () {
      final c = Clips.punch;
      expect(c.sample(0).handF, Poses.punchWind.handF);
      expect(c.sample(c.durationMs).handF, Poses.idleA.handF);
      expect(c.isFinished(c.durationMs), isTrue);
      expect(c.isFinished(c.durationMs - 1), isFalse);
    });

    test('durasi pukul = 70 persiapan + 60 menuju + 70 aktif + 150 pemulihan', () {
      expect(Clips.punch.durationMs, 350);
      expect(Clips.punch.timeAtKey(2), 130); // pukulan mengenai di ms 130
      expect(Clips.punch.timeAtKey(3), 200); // fase aktif berakhir di ms 200
    });

    test('klip berulang membungkus dan tidak pernah selesai', () {
      final c = Clips.idle;
      expect(c.sample(0).neck, c.sample(c.durationMs).neck);
      expect(c.sample(0).neck, Poses.idleA.neck);
      expect(c.isFinished(999999), isFalse);
    });

    test('klip yang ditahan (KO) berhenti di pose terakhir', () {
      final c = Clips.ko;
      expect(c.holdLast, isTrue);
      expect(c.sample(c.durationMs + 5000).neck, Poses.ko.neck);
    });

    test('semua klip menghasilkan pose berhingga di sepanjang waktunya', () {
      for (final entry in Clips.all.entries) {
        final c = entry.value;
        for (var t = 0; t <= c.durationMs + 100; t += 10) {
          final p = c.sample(t);
          for (final o in [p.neck, p.hip, p.handF, p.handB, p.toeF, p.toeB]) {
            expect(o.dx.isFinite && o.dy.isFinite, isTrue, reason: '${entry.key} @ $t ms');
          }
        }
      }
    });
  });

  test('tidak ada ujung kaki yang menembus tanah', () {
    final poses = <Pose>[
      Poses.idleA, Poses.idleB, Poses.walkA, Poses.walkB, Poses.walkC, Poses.punchWind,
      Poses.punchHit, Poses.crossWind, Poses.crossHit, Poses.kickWind, Poses.kickHit,
      Poses.throwWind, Poses.throwHit, Poses.block, Poses.hurt, Poses.fall, Poses.ko,
      Poses.win, Poses.taunt, Poses.heavyWind, Poses.heavyHit,
    ];
    for (final p in poses) {
      expect(p.toeF.dy, lessThanOrEqualTo(5));
      expect(p.toeB.dy, lessThanOrEqualTo(5));
    }
  });

  group('FightStats', () {
    test('lantai HP Rock per fase: 200, 100, 0', () {
      expect(FightStats.rockFloorHp(1), closeTo(200, 1e-9));
      expect(FightStats.rockFloorHp(2), closeTo(100, 1e-9));
      expect(FightStats.rockFloorHp(3), 0);
    });

    test('ada tepat tiga fase (sejalan dengan tiga step di core)', () {
      expect(fightPhases.length, 3);
    });
  });
}
