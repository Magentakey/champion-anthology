import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/gambler/gambler_config.dart';
import 'package:champion_anthology/levels/gambler/gambler_dialog.dart';
import 'package:champion_anthology/levels/gambler/gambler_game.dart';
import 'package:champion_anthology/levels/gambler/gambler_hud.dart';
import 'package:champion_anthology/levels/gambler/gambler_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

void main() {
  group('Dialog dan HUD', () {
    testWidgets('label peluang di layar sama dengan konstanta konfigurasi di tiap step', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = LevelSession();
      final game = GamblerGame(session, random: Random(1));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GamblerHud(game: game))));

      final odds = find.byKey(const ValueKey('odds_label'));
      for (var step = 1; step <= 3; step++) {
        final percent = (gamblerWinChance[step - 1] * 100).round();
        expect(tester.widget<Text>(odds).data, 'Peluang menang $percent%');
        expect(tester.widget<Text>(odds).data, GamblerDialog.oddsLabel(step));
        expect(find.text('Round $step/3'), findsOneWidget);
        if (step < 3) {
          session.winStep();
          // tampilan ronde baru baru dipakai setelah banner selesai
          expect(tester.widget<Text>(odds).data, GamblerDialog.oddsLabel(step), reason: 'belum berubah sebelum banner selesai');
          game.showStepUi(session.step);
          await tester.pump();
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('step 1 dan 3 punya area ketuk kartu atau cangkir, step 2 punya tombol KEPALA dan EKOR', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = LevelSession();
      final game = GamblerGame(session, random: Random(2));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GamblerHud(game: game))));

      expect(find.byKey(const ValueKey('slot_0')), findsOneWidget); // kartu
      expect(find.byKey(const ValueKey('slot_3')), findsOneWidget);
      expect(find.text('KEPALA'), findsNothing);

      session.winStep(); // step 2: koin, tapi UI-nya baru muncul setelah banner selesai
      await tester.pump();
      expect(find.text('KEPALA'), findsNothing);
      expect(find.byKey(const ValueKey('slot_0')), findsOneWidget);
      game.showStepUi(session.step);
      await tester.pump();
      expect(find.text('KEPALA'), findsOneWidget);
      expect(find.text('EKOR'), findsOneWidget);
      expect(find.byKey(const ValueKey('slot_0')), findsNothing);

      session.winStep(); // step 3: cangkir
      game.showStepUi(session.step);
      await tester.pump();
      expect(find.byKey(const ValueKey('slot_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot_3')), findsOneWidget);
      expect(find.text('KEPALA'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sebelum tahap memilih, mengetuk pilihan atau tombol konfirmasi tidak berpengaruh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = LevelSession();
      final game = GamblerGame(session, random: Random(3));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GamblerHud(game: game))));

      await tester.tap(find.byKey(const ValueKey('slot_1')));
      await tester.tap(find.byKey(const ValueKey('confirm')));
      await tester.pump();
      expect(game.selected.value, isNull);
      expect(game.canPick, isFalse);
      expect(game.canConfirm, isFalse);
      expect(session.isPlaying, isTrue);
      expect(session.stepsWon, 0);
    });

    test('kalimat dialog hanya memakai huruf yang ada di font piksel dan cukup pendek', () {
      final allowed = RegExp(r'^[A-Za-z0-9 !.,\-:/()' "'" r'"%+=*?;<>\n]*$');
      final lines = <String>[
        GamblerDialog.intro,
        GamblerDialog.tip,
        ...GamblerDialog.hintPick,
        ...GamblerDialog.hintReady,
        GamblerDialog.hintShuffle,
        GamblerDialog.hintReveal,
        ...GamblerDialog.confirmLabel,
        ...GamblerDialog.stepIntro,
        for (final group in GamblerDialog.win) ...group,
        for (final group in GamblerDialog.lose) ...group,
        for (final group in GamblerDialog.resultByStars) ...group,
        for (var s = 1; s <= 3; s++) GamblerDialog.oddsLabel(s),
        ...gamblerStepLabels,
      ];
      for (final line in lines) {
        expect(allowed.hasMatch(line), isTrue, reason: 'karakter tak didukung font: "$line"');
      }
      final speech = [
        ...GamblerDialog.stepIntro,
        for (final group in GamblerDialog.win) ...group,
        for (final group in GamblerDialog.lose) ...group,
        for (final group in GamblerDialog.resultByStars) ...group,
      ];
      for (final line in speech) {
        expect(line.length, lessThanOrEqualTo(60), reason: line);
      }
    });

    test('struktur dialog: 3 step dengan minimal 2 kalimat menang dan kalah, 4 kelompok hasil bintang', () {
      expect(GamblerDialog.stepIntro.length, 3);
      expect(GamblerDialog.win.length, 3);
      expect(GamblerDialog.lose.length, 3);
      expect(GamblerDialog.resultByStars.length, 4);
      expect(GamblerDialog.confirmLabel, ['BUKA', 'LEMPAR', 'BUKA']);
      for (final group in [...GamblerDialog.win, ...GamblerDialog.lose, ...GamblerDialog.resultByStars]) {
        expect(group.length, greaterThanOrEqualTo(2));
      }
      expect(gamblerStepLabels.length, 3);
    });
  });

  group('Tata letak meja', () {
    const areas = [Size(328, 264), Size(280, 200), Size(400, 320), Size(240, 150)];

    test('semua slot kartu dan cangkir berada di dalam meja dan tidak saling menimpa', () {
      for (final area in areas) {
        for (final game in [LuckGame.card, LuckGame.cup]) {
          final count = game == LuckGame.card ? GamblerTuning.cardCount : GamblerTuning.cupCount;
          final rects = [for (var i = 0; i < count; i++) GamblerLayout.slotRect(game, i, area)];
          for (var i = 0; i < count; i++) {
            expect(rects[i].left, greaterThanOrEqualTo(0), reason: '$game $i $area');
            expect(rects[i].right, lessThanOrEqualTo(area.width), reason: '$game $i $area');
            expect(rects[i].top, greaterThanOrEqualTo(0), reason: '$game $i $area');
            expect(rects[i].bottom, lessThanOrEqualTo(area.height), reason: '$game $i $area');
            if (i > 0) expect(rects[i].left, greaterThan(rects[i - 1].right), reason: '$game $i $area');
          }
        }
      }
    });

    test('koin dan tombol pilihannya berada di dalam meja dan tidak bertumpuk', () {
      for (final area in areas) {
        final coin = GamblerLayout.coinRect(area);
        final head = GamblerLayout.coinChoiceRect(0, area);
        final tail = GamblerLayout.coinChoiceRect(1, area);
        for (final r in [coin, head, tail]) {
          expect(r.left, greaterThanOrEqualTo(0), reason: '$area');
          expect(r.right, lessThanOrEqualTo(area.width), reason: '$area');
          expect(r.top, greaterThanOrEqualTo(0), reason: '$area');
          expect(r.bottom, lessThanOrEqualTo(area.height), reason: '$area');
        }
        expect(head.right, lessThan(tail.left));
        expect(coin.bottom, lessThan(head.top));
        expect(GamblerLayout.slotRect(LuckGame.coin, 0, area), head);
        expect(GamblerLayout.slotRect(LuckGame.coin, 1, area), tail);
      }
    });

    test('pecahan tata letak vertikal berurutan dan muat di layar', () {
      expect(GamblerLayout.tableTop + GamblerLayout.tableHeight, lessThan(GamblerLayout.oddsTop + 0.001));
      expect(GamblerLayout.oddsTop + GamblerLayout.oddsHeight, lessThanOrEqualTo(GamblerLayout.controlTop));
      expect(1 - GamblerLayout.controlBottom, greaterThan(GamblerLayout.controlTop));
      expect(GamblerLayout.bubbleTop + GamblerLayout.bubbleHeight, lessThan(GamblerLayout.tableTop));
    });
  });

  group('Animasi hiasan', () {
    test('kartu terpilih terbalik lebih dulu, tiga lainnya menyusul', () {
      expect(GamblerAnim.cardFlip(2, 2, 0), 0);
      expect(GamblerAnim.cardFlip(2, 2, GamblerTuning.cardFlipMs / 2), closeTo(0.5, 1e-9));
      expect(GamblerAnim.cardFlip(2, 2, GamblerTuning.cardFlipMs.toDouble()), 1);
      expect(GamblerAnim.cardFlip(0, 2, GamblerTuning.cardFlipMs.toDouble()), 0); // belum
      final done = (GamblerTuning.cardFlipMs + GamblerTuning.cardRevealMs).toDouble();
      for (var i = 0; i < GamblerTuning.cardCount; i++) {
        expect(GamblerAnim.cardFlip(i, 2, done), 1);
        expect(GamblerAnim.cardFlip(i, 2, done * 3), 1);
      }
    });

    test('skala balik kartu: penuh, nol saat tegak lurus, penuh lagi; muka tampil setelah separuh', () {
      expect(GamblerAnim.flipScale(0), 1);
      expect(GamblerAnim.flipScale(0.5), closeTo(0, 1e-9));
      expect(GamblerAnim.flipScale(1), closeTo(1, 1e-9));
      expect(GamblerAnim.showsFace(0.49), isFalse);
      expect(GamblerAnim.showsFace(0.5), isTrue);
    });

    test('koin selalu mendarat di sisi hasil, dan sisi hanya berganti saat koin tegak lurus', () {
      const h = GamblerTuning.coinHalfTurns;
      for (final landed in [0, 1]) {
        expect(GamblerAnim.coinFace(1, landed), landed);
        expect(GamblerAnim.coinFace(0.9999, landed), landed);
        for (var m = 1; m <= h; m++) {
          final edge = (m - 0.5) / h; // saat |cos| = 0
          expect(GamblerAnim.coinScale(edge), closeTo(0, 1e-9));
          expect(GamblerAnim.coinFace(edge - 1e-6, landed), isNot(GamblerAnim.coinFace(edge + 1e-6, landed)));
        }
        // di luar titik tegak lurus sisi stabil
        expect(GamblerAnim.coinFace(0.0, landed), (landed + h) % 2);
      }
      expect(GamblerAnim.coinScale(0), 1);
      expect(GamblerAnim.coinScale(1), closeTo(1, 1e-9));
    });

    test('lemparan koin: tinggi 0 di awal dan akhir, puncak di tengah', () {
      expect(GamblerAnim.coinLift(0), 0);
      expect(GamblerAnim.coinLift(0.5), 1);
      expect(GamblerAnim.coinLift(1), 0);
    });

    test('cangkir: terangkat saat bola ditampilkan, menutup, lalu diacak sampai selesai', () {
      expect(GamblerAnim.cupLiftPrepare(0), 1);
      expect(GamblerAnim.cupLiftPrepare(GamblerTuning.cupShowMs.toDouble()), 1);
      expect(GamblerAnim.cupLiftPrepare((GamblerTuning.cupShowMs + GamblerTuning.cupCoverMs).toDouble()), 0);
      expect(GamblerAnim.cupShuffleProgress(0), 0);
      expect(GamblerAnim.cupShuffleProgress(GamblerAnim.prepareMs(LuckGame.cup).toDouble()), 1);
      expect(GamblerAnim.cupLiftReveal(1, 1, GamblerTuning.cupLiftMs.toDouble()), 1);
      expect(GamblerAnim.cupLiftReveal(0, 1, GamblerTuning.cupLiftMs.toDouble()), 0);
      expect(GamblerAnim.cupLiftReveal(0, 1, GamblerAnim.revealMs(LuckGame.cup).toDouble()), 1);
    });

    test('cangkir: setelah acakan menyatu jadi satu tumpukan di tengah lalu dijajarkan lagi', () {
      const shuffleEnd = GamblerTuning.cupShowMs + GamblerTuning.cupCoverMs + GamblerTuning.cupShuffleMs;
      expect(GamblerAnim.cupMerge(0), 0);
      expect(GamblerAnim.cupMerge(shuffleEnd.toDouble()), 0);
      final gathered = (shuffleEnd + GamblerTuning.cupGatherMs).toDouble();
      expect(GamblerAnim.cupMerge(gathered), 1);
      expect(GamblerAnim.cupMerge(gathered + GamblerTuning.cupMergeHoldMs / 2), 1);
      expect(GamblerAnim.cupMerge(shuffleEnd + GamblerTuning.cupGatherMs / 2), inExclusiveRange(0, 1));
      expect(GamblerAnim.cupMerge(GamblerAnim.prepareMs(LuckGame.cup).toDouble()), 0);
    });

    test('lama persiapan dan lama membuka hasil per permainan', () {
      expect(GamblerAnim.prepareMs(LuckGame.card), 0);
      expect(GamblerAnim.prepareMs(LuckGame.coin), 0);
      expect(
        GamblerAnim.prepareMs(LuckGame.cup),
        GamblerTuning.cupShowMs +
            GamblerTuning.cupCoverMs +
            GamblerTuning.cupShuffleMs +
            GamblerTuning.cupGatherMs +
            GamblerTuning.cupMergeHoldMs +
            GamblerTuning.cupSpreadMs,
      );
      expect(GamblerAnim.revealMs(LuckGame.card), GamblerTuning.cardFlipMs + GamblerTuning.cardRevealMs);
      expect(GamblerAnim.revealMs(LuckGame.coin), GamblerTuning.coinTossMs + GamblerTuning.coinSettleMs);
      expect(GamblerAnim.revealMs(LuckGame.cup), GamblerTuning.cupLiftMs + GamblerTuning.cupRevealMs);
    });
  });

  group('Aset dan suara', () {
    test('semua gambar Level 6 ada dengan ukuran kelipatan 3 dari kisi pikselnya', () {
      const expected = <String, (int, int)>{
        'table.png': (720, 1278),
        'card_back.png': (60, 84),
        'card_safe.png': (60, 84),
        'card_bomb.png': (60, 84),
        'coin_head.png': (72, 72),
        'coin_tail.png': (72, 72),
        'coin_spin.png': (24, 72),
        'cup.png': (66, 78),
        'ball.png': (30, 30),
        'chip.png': (36, 36),
        'boss_idle.png': (512, 512),
        'boss_shock.png': (512, 512),
        'boss_laugh.png': (512, 512),
        'boss_defeat.png': (512, 512),
      };
      expected.forEach((file, size) {
        final path = 'assets/images/gambler/$file';
        expect(File(path).existsSync(), isTrue, reason: 'tidak ada: $path');
        expect(_pngSize(path), size, reason: path);
      });
    });

    testWidgets('game memuat semua aset yang diperlukan dan semuanya terdaftar di pubspec', (tester) async {
      final game = GamblerGame(LevelSession(), random: Random(1));
      for (final path in game.assetPaths) {
        expect(File('assets/images/$path').existsSync(), isTrue, reason: 'tidak ada: $path');
        expect(path, startsWith('gambler/'));
      }
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/images/gambler/'));
    });

    test('SFX Level 6 terdaftar dan nama berkasnya sesuai generator', () {
      final script = File('tools/audio/generate_gambler_audio.py').readAsStringSync();
      for (final name in ['card_flip.wav', 'coin_toss.wav', 'cup_slide.wav', 'win_chime.wav', 'lose_buzz.wav']) {
        expect(script, contains(name));
        expect(File('assets/audio/$name').lengthSync(), greaterThan(1000), reason: name);
      }
    });
  });
}
