import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:champion_anthology/levels/archery/archery_config.dart';
import 'package:champion_anthology/levels/archery/archery_dialog.dart';
import 'package:champion_anthology/levels/archery/archery_model.dart';
import 'package:flutter_test/flutter_test.dart';

(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

enum _Strategy { perfect, careless, early, random }

/// Satu step dimainkan bot; true jika skor target tercapai sebelum anak panah habis.
/// perfect = tahu persis lintasan bidikan 3 detik ke depan dan melepas di titik terbaik (tanpa galat),
/// careless = langsung melepas begitu busur cukup tegang, early = melepas terlalu cepat,
/// random = menahan sembarang lama.
bool _playStep(ArcheryStepConfig cfg, Random rng, _Strategy strategy) {
  final motion = TargetMotion(cfg, rng);
  const start = ArcheryTuning.minPower * ArcheryTuning.fillSeconds;
  var clock = 0.0;
  var total = 0;
  for (var a = 0; a < cfg.arrows; a++) {
    final seed = rng.nextInt(1 << 30);
    final double releaseAt;
    switch (strategy) {
      case _Strategy.perfect:
        final probe = ArcheryShot(cfg, Random(seed), motion: motion, motionStart: clock)..drawing = true;
        while (probe.hold < start) {
          probe.update(0.02);
        }
        var best = double.infinity;
        var bestAt = start;
        for (var i = 0; i < 150; i++) {
          final d = probe.impact.distance;
          if (d < best) {
            best = d;
            bestAt = probe.hold;
          }
          probe.update(0.02);
        }
        releaseAt = bestAt;
      case _Strategy.careless:
        releaseAt = start;
      case _Strategy.early:
        releaseAt = 0.5;
      case _Strategy.random:
        releaseAt = 0.3 + rng.nextDouble() * 6.7;
    }
    final shot = ArcheryShot(cfg, Random(seed), motion: motion, motionStart: clock)..drawing = true;
    while (shot.hold < releaseAt) {
      shot.update(0.02);
    }
    total += shot.release().score;
    clock += releaseAt + 1.0;
    if (total >= cfg.targetScore) return true;
  }
  return false;
}

double _winRate(ArcheryStepConfig cfg, _Strategy s, {int trials = 60, int seed = 7}) {
  final rng = Random(seed);
  var wins = 0;
  for (var i = 0; i < trials; i++) {
    if (_playStep(cfg, rng, s)) wins++;
  }
  return wins / trials;
}

void main() {
  group('skor cincin', () {
    test('batas cincin tepat: 10, 8, 6, 4, 2, lalu meleset', () {
      expect(ringScore(0), 10);
      expect(ringScore(0.2), 10);
      expect(ringScore(0.21), 8);
      expect(ringScore(0.4), 8);
      expect(ringScore(0.6), 6);
      expect(ringScore(0.8), 4);
      expect(ringScore(1.0), 2);
      expect(ringScore(1.01), 0);
    });
  });

  group('konfigurasi', () {
    test('3 step makin sulit: bidikan makin liar, gemetar naik, angin dan papan bergerak muncul', () {
      expect(archerySteps.length, 3);
      expect(archeryStepLabels.length, 3);
      for (var i = 1; i < archerySteps.length; i++) {
        expect(archerySteps[i].arrows, greaterThanOrEqualTo(archerySteps[i - 1].arrows));
        expect(archerySteps[i].aimX, greaterThan(archerySteps[i - 1].aimX));
        expect(archerySteps[i].aimSpeed, greaterThan(archerySteps[i - 1].aimSpeed));
        expect(archerySteps[i].shake, greaterThan(archerySteps[i - 1].shake));
      }
      expect(archerySteps[0].hasWind, isFalse);
      expect(archerySteps[1].hasWind, isTrue);
      expect(archerySteps[0].targetMoves, isFalse);
      expect(archerySteps[1].targetMoves, isFalse);
      expect(archerySteps[2].targetMoves, isTrue);
    });

    test('target skor bisa dicapai (di bawah skor maksimum) tapi menuntut rata-rata tinggi', () {
      for (final c in archerySteps) {
        final perArrow = c.targetScore / c.arrows;
        expect(perArrow, lessThan(10));
        expect(perArrow, greaterThan(5), reason: 'terlalu mudah: rata-rata ${perArrow.toStringAsFixed(1)} per panah');
      }
    });
  });

  group('ArcheryShot', () {
    test('tarikan belum penuh: anak panah jatuh ke bawah dan jauh dari papan', () {
      final shot = ArcheryShot(archerySteps[0], Random(1));
      expect(shot.power, 0);
      expect(shot.drop, closeTo(ArcheryTuning.minPower * ArcheryTuning.dropFactor, 1e-9));
      expect(shot.scoreNow, 0);
    });

    test('busur hanya terisi saat ditarik, dan berhenti setelah dilepas', () {
      final shot = ArcheryShot(archerySteps[0], Random(1));
      shot.update(1.0);
      expect(shot.hold, 0);
      expect(shot.t, 1.0);
      shot.drawing = true;
      shot.update(0.6);
      expect(shot.power, closeTo(0.5, 1e-9));
      shot.release();
      expect(shot.released, isTrue);
      final t = shot.t;
      shot.update(1.0);
      expect(shot.t, t); // sudah dilepas: waktu tidak berjalan lagi
    });

    test('tarikan penuh menghapus jatuhnya anak panah; gemetar baru mulai setelah penuh', () {
      final shot = ArcheryShot(archerySteps[0], Random(1))..drawing = true;
      shot.update(ArcheryTuning.fillSeconds);
      expect(shot.power, 1);
      expect(shot.drop, 0);
      expect(shot.tremble, closeTo(0, 1e-9));
      shot.update(1.0);
      expect(shot.tremble, closeTo(1.0, 1e-9));
    });

    test('angin mendorong lebih kuat saat tarikan lemah', () {
      final cfg = archerySteps[1];
      final shot = ArcheryShot(cfg, Random(3));
      expect(shot.wind.abs(), inInclusiveRange(0.4 * cfg.wind, cfg.wind));
      final weak = shot.windPush.abs();
      shot
        ..drawing = true
        ..update(ArcheryTuning.fillSeconds);
      final strong = shot.windPush.abs();
      expect(strong, lessThan(weak));
      expect(strong, closeTo(weak * 0.6 / 1.2, 1e-9));
    });

    test('Step 1 tanpa angin dan papan diam', () {
      final shot = ArcheryShot(archerySteps[0], Random(5));
      expect(shot.wind, 0);
      expect(shot.windPush, 0);
      for (var i = 0; i < 50; i++) {
        shot.update(0.1);
        expect(shot.targetCenter, Offset.zero);
      }
    });

    test('Step 3: papan bergerak dalam batas simpangan dan tidak melompat antar tembakan', () {
      final cfg = archerySteps[2];
      final motion = TargetMotion(cfg, Random(9));
      var moved = false;
      for (var t = 0.0; t < 20; t += 0.1) {
        final c = motion.at(t);
        expect(c.dx.abs(), lessThanOrEqualTo(cfg.targetX + 1e-9));
        expect(c.dy.abs(), lessThanOrEqualTo(cfg.targetY + 1e-9));
        if (c.distance > 0.05) moved = true;
      }
      expect(moved, isTrue);
      // tembakan yang dimulai pada waktu T melihat papan di tempat yang sama dengan gerak papan pada T
      final shot = ArcheryShot(cfg, Random(2), motion: motion, motionStart: 7.5);
      expect(shot.targetCenter, motion.at(7.5));
      shot.update(0.5);
      expect(shot.targetCenter, motion.at(8.0));
    });

    test('simpangan bidikan dibatasi amplitudenya', () {
      final cfg = archerySteps[2];
      final shot = ArcheryShot(cfg, Random(4))
        ..drawing = true
        ..hold = ArcheryTuning.fillSeconds; // busur penuh, belum gemetar
      for (var i = 0; i < 400; i++) {
        shot.update(0.01);
        final c = shot.crosshair;
        // bidikan = goyangan (maks aimX x 1,0) + dorongan angin, dengan gemetar yang tumbuh
        final m = 1 + cfg.shake * shot.tremble;
        expect((c.dx - shot.windPush).abs(), lessThanOrEqualTo(cfg.aimX * m + 1e-9));
        expect(c.dy.abs(), lessThanOrEqualTo(cfg.aimY * m + 1e-9));
      }
    });

    test('hasil tembakan memuat skor dari jarak titik jatuh', () {
      final shot = ArcheryShot(archerySteps[0], Random(6))
        ..drawing = true
        ..update(1.2);
      final expected = ringScore(shot.impact.distance);
      final r = shot.release();
      expect(r.score, expected);
      expect(r.bullseye, expected == 10);
    });
  });

  group('tuning kesulitan (bot)', () {
    test('pemain sempurna hampir selalu menang di semua step', () {
      for (var i = 0; i < archerySteps.length; i++) {
        expect(_winRate(archerySteps[i], _Strategy.perfect), greaterThanOrEqualTo(0.75), reason: 'Step ${i + 1}');
      }
    });

    test('melepas langsung begitu tegang tidak cukup, apalagi di step akhir', () {
      expect(_winRate(archerySteps[0], _Strategy.careless), lessThanOrEqualTo(0.45), reason: 'Step 1');
      expect(_winRate(archerySteps[1], _Strategy.careless), lessThanOrEqualTo(0.30), reason: 'Step 2');
      expect(_winRate(archerySteps[2], _Strategy.careless), lessThanOrEqualTo(0.20), reason: 'Step 3');
    });

    test('menembak sembarangan atau terlalu cepat hampir tidak pernah menang', () {
      for (var i = 0; i < archerySteps.length; i++) {
        expect(_winRate(archerySteps[i], _Strategy.random), lessThanOrEqualTo(0.10), reason: 'acak Step ${i + 1}');
        expect(_winRate(archerySteps[i], _Strategy.early), lessThanOrEqualTo(0.05), reason: 'cepat Step ${i + 1}');
      }
    });
  });

  group('dialog dan aset', () {
    test('dialog lengkap dan tanpa kalimat kosong', () {
      expect(ArcheryDialog.stepIntro.length, 3);
      expect(ArcheryDialog.stepClear.length, 3);
      expect(ArcheryDialog.resultByStars.length, 4);
      final all = [
        ArcheryDialog.intro,
        ArcheryDialog.tip,
        ...ArcheryDialog.stepIntro,
        ...ArcheryDialog.stepClear,
        ...ArcheryDialog.bullseye,
        ...ArcheryDialog.good,
        ...ArcheryDialog.meh,
        ...ArcheryDialog.miss,
        ...ArcheryDialog.lastArrow,
        for (final l in ArcheryDialog.resultByStars) ...l,
      ];
      for (final line in all) {
        expect(line.trim(), isNotEmpty);
      }
      for (final pool in [ArcheryDialog.bullseye, ArcheryDialog.good, ArcheryDialog.meh, ArcheryDialog.miss]) {
        expect(pool.length, greaterThanOrEqualTo(2));
      }
    });

    test('gambar Bima (4 ekspresi) dan latar lapangan ada dengan ukuran yang benar', () {
      for (final f in ['idle', 'shock', 'laugh', 'defeat']) {
        expect(_pngSize('assets/images/archery/boss_$f.png'), (512, 512), reason: f);
      }
      expect(_pngSize('assets/images/archery/archery_bg.png'), (720, 1278));
    });
  });
}
