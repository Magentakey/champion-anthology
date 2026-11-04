import 'dart:io';
import 'dart:math';

import 'package:champion_anthology/levels/cooking/cooking_checks.dart';
import 'package:champion_anthology/levels/cooking/cooking_config.dart';
import 'package:champion_anthology/levels/cooking/cooking_dialog.dart';
import 'package:champion_anthology/levels/cooking/cooking_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _dt = 1 / 60;

void main() {
  group('resep dan pesanan', () {
    test('tiap resep valid: bahan dikenal, unik, minimal 5, awalan 3 bahan mencakup 2 stasiun', () {
      expect(recipes.length, greaterThanOrEqualTo(4));
      for (final r in recipes) {
        expect(r.name.trim(), isNotEmpty);
        expect(r.ingredientIds.length, greaterThanOrEqualTo(5), reason: r.name);
        expect(r.ingredientIds.toSet().length, r.ingredientIds.length, reason: '${r.name}: bahan ganda');
        final firstThree = [for (final id in r.ingredientIds.take(3)) ingredientById(id).station];
        expect(firstThree.toSet().length, greaterThanOrEqualTo(2), reason: r.name);
      }
    });

    test('ketiga stasiun punya bahan, dan id bahan unik', () {
      for (final s in Station.values) {
        expect(ingredientCatalog.where((i) => i.station == s), isNotEmpty);
      }
      expect({for (final i in ingredientCatalog) i.id}.length, ingredientCatalog.length);
    });

    test('OrderFactory: jumlah bahan benar, baki berisi semua bahan pesanan, pengecoh di luar resep', () {
      for (var seed = 0; seed < 60; seed++) {
        for (final cfg in cookingSteps) {
          final (order, tray) = OrderFactory.create(
            Random(seed),
            count: cfg.ingredients,
            decoys: cfg.decoys,
          );
          expect(order.ingredients.length, cfg.ingredients);
          expect(tray.length, cfg.ingredients + cfg.decoys);
          expect(tray.toSet().length, tray.length, reason: 'baki tidak boleh punya bahan ganda');
          for (final i in order.ingredients) {
            expect(tray, contains(i.id));
          }
          final decoyIds = tray.where((id) => !order.needs(id));
          expect(decoyIds.length, cfg.decoys);
          for (final id in decoyIds) {
            expect(order.recipe.ingredientIds, isNot(contains(id)));
          }
        }
      }
    });

    test('OrderFactory tidak mengulang resep yang dihindari', () {
      for (var seed = 0; seed < 40; seed++) {
        final (order, _) = OrderFactory.create(Random(seed), count: 3, decoys: 1, avoid: recipes.first);
        expect(order.recipe, isNot(recipes.first));
      }
    });
  });

  group('konfigurasi', () {
    test('3 step makin banyak bahan, check makin ketat', () {
      expect(cookingSteps.length, 3);
      expect(cookingStepLabels.length, 3);
      for (var i = 1; i < cookingSteps.length; i++) {
        final a = cookingSteps[i - 1];
        final b = cookingSteps[i];
        expect(b.ingredients, greaterThan(a.ingredients));
        expect(b.chop.tapsNeeded, greaterThan(a.chop.tapsNeeded));
        expect(b.boil.zoneHigh - b.boil.zoneLow, lessThan(a.boil.zoneHigh - a.boil.zoneLow));
        expect(b.fry.zoneWidth, lessThan(a.fry.zoneWidth));
      }
    });
  });

  group('ChopCheck (Talenan)', () {
    test('mengetuk 6 kali per detik lolos di semua step', () {
      for (final cfg in cookingSteps) {
        final c = ChopCheck(cfg.chop);
        var t = 0.0, next = 0.0;
        while (c.isRunning && t < 30) {
          if (t >= next) {
            c.onTap();
            next += 1 / 6;
          }
          c.update(_dt);
          t += _dt;
        }
        expect(c.status, CheckStatus.success);
        expect(c.perfect, isTrue); // secepat itu dapat bonus waktu
      }
    });

    test('tidak mengetuk = gagal saat batas waktu habis', () {
      for (final cfg in cookingSteps) {
        final c = ChopCheck(cfg.chop);
        while (c.isRunning) {
          c.update(_dt);
        }
        expect(c.status, CheckStatus.failed);
        expect(c.elapsed, closeTo(cfg.chop.maxSeconds, 0.1));
      }
    });

    test('mengetuk terlalu pelan (1 kali per detik) gagal di Step 3', () {
      final c = ChopCheck(cookingSteps[2].chop);
      var t = 0.0, next = 0.0;
      while (c.isRunning) {
        if (t >= next) {
          c.onTap();
          next += 1.0;
        }
        c.update(_dt);
        t += _dt;
      }
      expect(c.status, CheckStatus.failed);
    });

    test('bar turun saat berhenti mengetuk', () {
      final c = ChopCheck(cookingSteps[2].chop);
      for (var i = 0; i < 6; i++) {
        c.onTap();
      }
      final before = c.progress;
      for (var i = 0; i < 30; i++) {
        c.update(_dt); // 0,5 detik tanpa ketukan
      }
      expect(c.progress, lessThan(before));
    });
  });

  group('BoilCheck (Panci)', () {
    test('mengatur api (naik-turun di sekitar tengah zona) lolos di semua step', () {
      for (final cfg in cookingSteps) {
        for (var seed = 0; seed < 10; seed++) {
          final c = BoilCheck(cfg.boil, Random(seed));
          final mid = (cfg.boil.zoneLow + cfg.boil.zoneHigh) / 2;
          while (c.isRunning) {
            c.setHolding(c.temperature < mid);
            c.update(_dt);
          }
          expect(c.status, CheckStatus.success, reason: 'seed $seed');
        }
      }
    });

    test('menahan api terus = meluap (gagal)', () {
      final c = BoilCheck(cookingSteps[0].boil, Random(1))..setHolding(true);
      while (c.isRunning) {
        c.update(_dt);
      }
      expect(c.status, CheckStatus.failed);
      expect(c.overflowed, isTrue);
    });

    test('tidak menyalakan api = gagal karena waktu (tanpa meluap)', () {
      final c = BoilCheck(cookingSteps[0].boil, Random(1));
      while (c.isRunning) {
        c.update(_dt);
      }
      expect(c.status, CheckStatus.failed);
      expect(c.overflowed, isFalse);
    });
  });

  group('FryCheck (Wajan)', () {
    test('mengetuk tepat saat jarum di zona emas lolos tanpa meleset', () {
      for (final cfg in cookingSteps) {
        for (var seed = 0; seed < 10; seed++) {
          final c = FryCheck(cfg.fry, Random(seed));
          while (c.isRunning) {
            c.update(_dt);
            if (c.needleInZone) c.onTap();
          }
          expect(c.status, CheckStatus.success, reason: 'seed $seed');
          expect(c.misses, 0);
          expect(c.perfect, isTrue);
        }
      }
    });

    test('meleset melebihi batas = gosong', () {
      for (final cfg in cookingSteps) {
        final c = FryCheck(cfg.fry, Random(3));
        // jarum di tepi kiri (0) selalu di luar zona emas
        for (var i = 0; i <= cfg.fry.missesAllowed; i++) {
          expect(c.onTap(), isFalse);
        }
        expect(c.status, CheckStatus.failed);
      }
    });

    test('tidak mengetuk = gagal saat batas waktu habis', () {
      final c = FryCheck(cookingSteps[0].fry, Random(2));
      while (c.isRunning) {
        c.update(_dt);
      }
      expect(c.status, CheckStatus.failed);
    });
  });

  test('CookingCheck.create memilih jenis check sesuai stasiun', () {
    final rng = Random(0);
    expect(CookingCheck.create(Station.chop, cookingSteps[0], rng), isA<ChopCheck>());
    expect(CookingCheck.create(Station.boil, cookingSteps[0], rng), isA<BoilCheck>());
    expect(CookingCheck.create(Station.fry, cookingSteps[0], rng), isA<FryCheck>());
  });

  group('dialog dan aset', () {
    test('dialog lengkap dan tanpa kalimat kosong', () {
      expect(CookingDialog.stepIntro.length, 3);
      expect(CookingDialog.stepClear.length, 3);
      expect(CookingDialog.resultByStars.length, 4);
      for (final pool in [CookingDialog.checkOk, CookingDialog.checkFail, CookingDialog.wrong, CookingDialog.hurry]) {
        expect(pool.length, greaterThanOrEqualTo(3));
      }
      final all = [
        CookingDialog.intro,
        CookingDialog.tip,
        ...CookingDialog.stepIntro,
        ...CookingDialog.stepClear,
        ...CookingDialog.checkOk,
        ...CookingDialog.checkFail,
        ...CookingDialog.wrong,
        ...CookingDialog.hurry,
        for (final l in CookingDialog.resultByStars) ...l,
      ];
      for (final line in all) {
        expect(line.trim(), isNotEmpty);
      }
    });

    test('semua gambar Level 4 ada: chef, bahan, stasiun, latar', () {
      final files = [
        for (final f in ['idle', 'shock', 'laugh', 'defeat']) 'assets/images/cooking/boss_$f.png',
        for (final i in ingredientCatalog) i.imageAsset,
        for (final s in Station.values) 'assets/images/cooking/station_${s.name}.png',
        'assets/images/cooking/kitchen_bg.png',
      ];
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: f);
      }
    });
  });
}
