import 'dart:io';
import 'dart:typed_data';

import 'package:champion_anthology/core/audio/audio_service.dart';
import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/level_registry.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_calibration.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_chart.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_dialog.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_game.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_hud.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_judge.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_run.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

Future<void> _bigScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

RhythmChart _tiny(int step) => RhythmChart(
      bpm: 120,
      bars: 5,
      gridPerBeat: 2,
      notes: const [RhythmNote(1.0, 0), RhythmNote(2.0, 1), RhythmNote(3.0, 2), RhythmNote(4.0, 3)],
    );

void main() {
  group('Dialog', () {
    test('lengkap: 3 intro step, 4 kelompok hasil, variasi reaksi, tidak ada kalimat kosong', () {
      expect(RhythmDialog.stepIntro, hasLength(3));
      expect(RhythmDialog.win, hasLength(3));
      expect(RhythmDialog.lose, hasLength(3));
      expect(RhythmDialog.resultByStars, hasLength(4));
      for (final lines in RhythmDialog.resultByStars) {
        expect(lines, isNotEmpty);
      }
      expect(RhythmDialog.comboPraise.length, greaterThanOrEqualTo(2));
      expect(RhythmDialog.missTaunt.length, greaterThanOrEqualTo(2));
    });

    test('semua teks hanya berisi karakter ASCII yang bisa digambar font piksel', () {
      final all = <String>[
        RhythmDialog.intro,
        RhythmDialog.tip,
        RhythmDialog.perfect,
        RhythmDialog.good,
        RhythmDialog.miss,
        RhythmDialog.passed,
        RhythmDialog.failed,
        RhythmDialog.offsetTitle,
        RhythmDialog.offsetHint,
        ...RhythmDialog.stepIntro,
        ...RhythmDialog.comboPraise,
        ...RhythmDialog.missTaunt,
        for (final l in RhythmDialog.win) ...l,
        for (final l in RhythmDialog.lose) ...l,
        for (final l in RhythmDialog.resultByStars) ...l,
        for (var s = 1; s <= 3; s++) RhythmDialog.targetLabel(s),
        RhythmDialog.accuracyLabel(0.756),
        RhythmDialog.comboLabel(12),
        RhythmDialog.offsetLabel(-30),
      ];
      for (final s in all) {
        expect(s.trim(), isNotEmpty);
        for (final r in s.runes) {
          expect(r == 10 || (r >= 32 && r <= 126), isTrue, reason: 'karakter di luar ASCII pada "$s"');
        }
      }
    });

    test('label target selalu berasal dari konstanta konfigurasi', () {
      expect(RhythmDialog.targetLabel(1), 'Target akurasi 60%');
      expect(RhythmDialog.targetLabel(2), 'Target akurasi 70%');
      expect(RhythmDialog.targetLabel(3), 'Target akurasi 78%');
    });

    test('label akurasi, combo, dan offset', () {
      expect(RhythmDialog.accuracyLabel(0.756), 'Akurasi 76%');
      expect(RhythmDialog.accuracyLabel(0), 'Akurasi 0%');
      expect(RhythmDialog.comboLabel(12), '12 COMBO');
      expect(RhythmDialog.offsetLabel(30), '+30 ms');
      expect(RhythmDialog.offsetLabel(-30), '-30 ms');
      expect(RhythmDialog.offsetLabel(0), '0 ms');
    });

    test('kata hitung mundur: 4 ketukan = 3 2 1 MULAI, 3 ketukan = 3 2 1', () {
      final four = [for (var b = 0; b < 4; b++) RhythmDialog.countWord(b, 4)];
      final three = [for (var b = 0; b < 3; b++) RhythmDialog.countWord(b, 3)];
      expect(four.first, '3');
      expect(four[2], '1');
      expect(four.last, isNot('1'));
      expect(three, ['3', '2', '1']);
    });
  });

  group('Registri level', () {
    test('Level 7 terdaftar sebagai Rhea the Drummer dan terbuka setelah Level 6', () {
      final level = levelById('rhythm');
      expect(level, isNotNull);
      expect(level!.number, 7);
      expect(level.bossName, 'Rhea the Drummer');
      expect(level.introDialog, RhythmDialog.intro);
      expect(level.tip, RhythmDialog.tip);
    });
  });

  group('Tata letak', () {
    test('zona vertikal berurutan tanpa tumpang tindih', () {
      expect(RhythmLayout.laneTop, lessThan(RhythmLayout.hitLine));
      expect(RhythmLayout.hitLine, lessThan(RhythmLayout.laneBottom));
      expect(RhythmLayout.laneBottom, lessThanOrEqualTo(RhythmLayout.barTop));
      expect(RhythmLayout.barBottom, lessThanOrEqualTo(RhythmLayout.padTop));
      expect(RhythmLayout.padBottom, lessThanOrEqualTo(1.0));
    });

    test('empat pad sejajar, sama lebar, tidak saling menimpa, dan di dalam layar', () {
      for (final size in const [Size(360, 640), Size(411, 891), Size(1080, 2400)]) {
        final rects = [for (var l = 0; l < rhythmLaneCount; l++) RhythmLayout.padRect(l, size)];
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].left, greaterThanOrEqualTo(0));
          expect(rects[i].right, lessThanOrEqualTo(size.width));
          expect(rects[i].bottom, lessThanOrEqualTo(size.height));
          expect(rects[i].width, closeTo(rects[0].width, 1e-6));
          if (i > 0) expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right));
        }
      }
    });

    test('empat jalur tidak tumpang tindih', () {
      const size = Size(411, 891);
      for (var l = 1; l < rhythmLaneCount; l++) {
        expect(RhythmLayout.laneRect(l, size).left, greaterThanOrEqualTo(RhythmLayout.laneRect(l - 1, size).right - 1e-6));
      }
    });

    test('not yang waktunya tepat berada di garis ketuk', () {
      const size = Size(411, 891);
      expect(RhythmLayout.noteCenterY(0, size), closeTo(RhythmLayout.hitY(size.height), 1e-6));
      expect(RhythmLayout.noteCenterY(1.4, size), lessThan(RhythmLayout.noteCenterY(0.7, size)));
    });
  });

  group('Aset', () {
    test('ukuran PNG sesuai kisi piksel', () {
      expect(_pngSize('assets/images/rhythm/stage.png'), (720, 1278));
      for (var i = 0; i < rhythmLaneCount; i++) {
        expect(_pngSize('assets/images/rhythm/note_$i.png'), (60, 36), reason: 'note_$i');
        expect(_pngSize('assets/images/rhythm/pad_$i.png'), (120, 96), reason: 'pad_$i (dua bingkai 60x96)');
      }
      expect(_pngSize('assets/images/rhythm/hit_line.png'), (720, 12));
    });

    test('gambar boss Rhea lengkap dan folder terdaftar di pubspec', () {
      for (final f in ['boss_idle', 'boss_shock', 'boss_laugh', 'boss_defeat']) {
        expect(File('assets/images/rhythm/$f.png').existsSync(), isTrue, reason: f);
      }
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/images/rhythm/'));
    });

    test('SFX dan lagu Level 7 terdaftar dan ada', () {
      for (final sfx in [Sfx.rhythmHitPerfect, Sfx.rhythmHitGood, Sfx.rhythmMiss, Sfx.rhythmCount]) {
        expect(File('assets/audio/${sfx.file}').lengthSync(), greaterThan(1000), reason: sfx.file);
      }
      for (final f in rhythmSongFiles) {
        expect(File('assets/audio/$f').lengthSync(), greaterThan(100000), reason: f);
      }
    });
  });

  group('HUD', () {
    testWidgets('label target dan akurasi tampil di layar sama dengan konfigurasi tiap step', (tester) async {
      await _bigScreen(tester);
      final session = LevelSession();
      final game = RhythmGame(session, chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));

      final target = find.byKey(const ValueKey('target_label'));
      for (var step = 1; step <= 3; step++) {
        expect(tester.widget<Text>(target).data, 'Target akurasi ${rhythmThresholdPercent(step)}%');
        expect(tester.widget<Text>(target).data, RhythmDialog.targetLabel(step));
        expect(find.text('Round $step/3'), findsOneWidget);
        if (step < 3) {
          game.displayStep.value = step + 1;
          await tester.pump();
        }
      }
      expect(find.byKey(const ValueKey('accuracy_label')), findsOneWidget);
      expect(find.byKey(const ValueKey('spirit_bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('label combo hanya muncul mulai combo 2', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      final combo = find.byKey(const ValueKey('combo_label'));
      expect(combo, findsNothing);
      game.combo.value = 1;
      await tester.pump();
      expect(combo, findsNothing);
      game.combo.value = 7;
      await tester.pump();
      expect(tester.widget<Text>(combo).data, '7 COMBO');
    });

    testWidgets('akurasi sementara ditampilkan dari notifier', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      game.accuracy.value = 0.75;
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const ValueKey('accuracy_label'))).data, 'Akurasi 75%');
    });

    testWidgets('penilaian dan hitung mundur muncul lalu hilang', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      expect(find.byKey(const ValueKey('popup_text')), findsNothing);
      game.popup.value = const RhythmPopup(1, Judgment.perfect, 2);
      game.countText.value = '3';
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const ValueKey('popup_text'))).data, RhythmDialog.perfect);
      expect(tester.widget<Text>(find.byKey(const ValueKey('count_text'))).data, '3');
      game.popup.value = null;
      game.countText.value = null;
      await tester.pump();
      expect(find.byKey(const ValueKey('popup_text')), findsNothing);
      expect(find.byKey(const ValueKey('count_text')), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('hasil LULUS dan GAGAL tampil di jalur', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      game.resultText.value = RhythmDialog.passed;
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const ValueKey('result_text'))).data, 'LULUS!');
      game.resultText.value = RhythmDialog.failed;
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const ValueKey('result_text'))).data, 'GAGAL');
    });

    testWidgets('empat pad ada dan bisa disentuh serentak dengan empat jari', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));

      final down = <int>[];
      for (var i = 0; i < rhythmLaneCount; i++) {
        game.padDown[i].addListener(() {
          if (game.padDown[i].value) down.add(i);
        });
      }
      final gestures = <TestGesture>[];
      for (var i = 0; i < rhythmLaneCount; i++) {
        final finder = find.byKey(ValueKey('pad_$i'));
        expect(finder, findsOneWidget);
        gestures.add(await tester.startGesture(tester.getCenter(finder), pointer: 100 + i));
      }
      await tester.pump();
      expect(down, [0, 1, 2, 3]);
      expect([for (final p in game.padDown) p.value], everyElement(isTrue));

      for (final g in gestures) {
        await g.up();
      }
      await tester.pump();
      expect([for (final p in game.padDown) p.value], everyElement(isFalse));
    });

    testWidgets('jari yang dibatalkan melepas pad', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pad_2'))));
      await tester.pump();
      expect(game.padDown[2].value, isTrue);
      await g.cancel();
      await tester.pump();
      expect(game.padDown[2].value, isFalse);
    });

    testWidgets('sentuhan pad di luar tahap bermain tidak menilai apa pun', (tester) async {
      await _bigScreen(tester);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      await tester.tap(find.byKey(const ValueKey('pad_0')));
      await tester.pump();
      expect(game.run.phase, RhythmPhase.idle);
      expect(game.run.judge, isNull);
    });

    testWidgets('tidak ada overflow di layar kecil', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      game.showBanner.value = true;
      game.combo.value = 12;
      game.bossSay.value = 'Ketukanmu harus tepat!';
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RhythmHud(game: game))));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Panel offset di layar jeda', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      RhythmCalibration.instance.init(await SharedPreferences.getInstance());
    });

    tearDown(() async {
      await RhythmCalibration.instance.setOffset(0);
    });

    testWidgets('tombol + dan - menggeser 10 ms dan label mengikuti', (tester) async {
      await _bigScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: RhythmOffsetControl()))));
      Text label() => tester.widget<Text>(find.byKey(const ValueKey('offset_label')));
      expect(label().data, '0 ms');

      await tester.tap(find.byKey(const ValueKey('offset_plus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('offset_plus')));
      await tester.pump();
      expect(label().data, '+20 ms');
      expect(RhythmCalibration.instance.offsetMs.value, 20);

      await tester.tap(find.byKey(const ValueKey('offset_minus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('offset_minus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('offset_minus')));
      await tester.pump();
      expect(label().data, '-10 ms');
    });

    testWidgets('tidak bisa melewati batas +150 ms', (tester) async {
      await _bigScreen(tester);
      await RhythmCalibration.instance.setOffset(150);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: RhythmOffsetControl()))));
      await tester.tap(find.byKey(const ValueKey('offset_plus')));
      await tester.pump();
      expect(RhythmCalibration.instance.offsetMs.value, 150);
      expect(tester.widget<Text>(find.byKey(const ValueKey('offset_label'))).data, '+150 ms');
    });
  });

  group('Permainan', () {
    test('pad menilai not lewat jam permainan: ketukan tepat waktu = PERFECT', () {
      final session = LevelSession();
      final game = RhythmGame(session, chartFor: _tiny, offsetMs: () => 0);
      game.run.beginStep(1);
      var t = 0.0;
      while (game.run.phase != RhythmPhase.playing && t < 30) {
        game.run.update(1 / 60);
        t += 1 / 60;
      }
      expect(game.run.phase, RhythmPhase.playing);
      game.run.tap(0, at: 1.0);
      expect(game.run.judge!.perfects, 1);
      expect(game.run.judge!.resultOf(0), Judgment.perfect);
    });

    test('pressPad dan releasePad menyalakan dan memadamkan pad, indeks tidak valid diabaikan', () {
      final game = RhythmGame(LevelSession(), chartFor: _tiny);
      game.pressPad(1);
      expect(game.padDown[1].value, isTrue);
      game.releasePad(1);
      expect(game.padDown[1].value, isFalse);
      game.pressPad(-1);
      game.pressPad(9);
      game.releasePad(9);
      expect([for (final p in game.padDown) p.value], everyElement(isFalse));
    });
  });
}
