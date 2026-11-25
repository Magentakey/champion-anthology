import 'dart:io';
import 'dart:typed_data';

import 'package:champion_anthology/levels/fight/fighter_body.dart';
import 'package:champion_anthology/levels/fight/pose_clips.dart';
import 'package:champion_anthology/levels/fight/pose_frames.dart';
import 'package:champion_anthology/levels/fight/pose_library.dart';
import 'package:flutter_test/flutter_test.dart';

(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

void main() {
  group('PoseFrames', () {
    test('urutan bingkai sama dengan urutan pose di pose_library.dart', () {
      final lib = File('lib/levels/fight/pose_library.dart').readAsStringSync();
      final names = RegExp(r'static const (\w+) = Pose\(').allMatches(lib).map((m) => m.group(1)!).toList();
      final frames = File('lib/levels/fight/pose_frames.dart').readAsStringSync();
      final listed = RegExp(r'Poses\.(\w+),').allMatches(frames).map((m) => m.group(1)!).toList();
      expect(listed, names);
      expect(PoseFrames.poses.length, names.length);
    });

    test('tiap pose punya bingkai sendiri (tidak ada yang kembar)', () {
      for (var i = 0; i < PoseFrames.poses.length; i++) {
        expect(PoseFrames.indexOf(PoseFrames.poses[i]), i);
      }
    });

    test('semua pose kunci pada semua klip tersedia sebagai bingkai', () {
      for (final entry in Clips.all.entries) {
        for (final key in entry.value.keys) {
          final i = PoseFrames.indexOf(key.pose);
          expect(identical(PoseFrames.poses[i], key.pose), isTrue, reason: '${entry.key} memakai pose di luar pustaka');
        }
      }
    });

    test('lembar sprite pemain dan Rock: lebar = jumlah bingkai x ukuran bingkai, tinggi = satu bingkai', () {
      final w = (PoseFrames.poses.length * PoseFrames.frameSize).round();
      final h = PoseFrames.frameSize.round();
      expect(_pngSize('assets/images/fight/player_sheet.png'), (w, h));
      expect(_pngSize('assets/images/fight/rock_sheet.png'), (w, h));
    });
  });

  group('PoseClip.sampleStepped', () {
    test('selalu mengembalikan salah satu pose kunci klip (tanpa campuran)', () {
      for (final entry in Clips.all.entries) {
        final c = entry.value;
        final keyPoses = [for (final k in c.keys) k.pose];
        for (var t = 0; t <= c.durationMs + 200; t += 7) {
          final p = c.sampleStepped(t);
          expect(keyPoses.any((k) => identical(k, p)), isTrue, reason: '${entry.key} @ $t ms');
        }
      }
    });

    test('mulai di pose pertama dan berakhir di pose terakhir', () {
      final c = Clips.punch;
      expect(c.sampleStepped(0), Poses.punchWind);
      expect(c.sampleStepped(c.durationMs + 1000), Poses.idleA);
      expect(Clips.ko.sampleStepped(Clips.ko.durationMs + 1000), Poses.ko);
    });

    test('pukulan: pose aba-aba, lalu hantaman, lalu kembali diam', () {
      final c = Clips.punch;
      expect(c.sampleStepped(10), Poses.punchWind);
      expect(c.sampleStepped(c.timeAtKey(3)), Poses.punchHit); // sepanjang fase aktif
      expect(c.sampleStepped(c.durationMs), Poses.idleA);
    });

    test('idle bernapas lewat tiga bingkai dan jalan memutar lima bingkai (v1.6.0)', () {
      final idleFrames = {for (var t = 0; t < 1400; t += 20) Clips.idle.sampleStepped(t)};
      expect(idleFrames, {Poses.idleA, Poses.idleB, Poses.idleC});
      final walkFrames = {for (var t = 0; t < 360; t += 10) Clips.walk.sampleStepped(t)};
      expect(walkFrames, {Poses.walkA, Poses.walkB, Poses.walkC, Poses.walkD, Poses.idleA});
    });
  });

  group('FighterBody.frameIndex', () {
    test('mulai di bingkai idleA', () {
      final body = FighterBody(maxHp: 100, x: 0, facing: 1);
      body.update(16, 500);
      expect(body.framePose, Poses.idleA);
      expect(body.frameIndex, PoseFrames.indexOf(Poses.idleA));
    });

    test('memukul melewati bingkai hantaman lalu kembali ke diam', () {
      final body = FighterBody(maxHp: 100, x: 0, facing: 1)..queuePunch();
      final seen = <int>{};
      for (var t = 0; t < 600; t += 16) {
        body.update(16, 500);
        seen.add(body.frameIndex);
      }
      expect(seen, contains(PoseFrames.indexOf(Poses.punchWind)));
      expect(seen, contains(PoseFrames.indexOf(Poses.punchHit)));
      expect(body.framePose, anyOf(Poses.idleA, Poses.idleB));
    });

    test('animasi KO berakhir di bingkai terbaring', () {
      final body = FighterBody(maxHp: 100, x: 0, facing: 1)..playScripted(Clips.ko);
      for (var t = 0; t < 400; t += 16) {
        body.update(16, 500);
      }
      expect(body.framePose, Poses.ko);
    });
  });
}
