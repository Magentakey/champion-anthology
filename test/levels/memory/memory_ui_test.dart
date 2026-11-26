import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:champion_anthology/core/audio/audio_service.dart';
import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/level_registry.dart';
import 'package:champion_anthology/levels/memory/memory_config.dart';
import 'package:champion_anthology/levels/memory/memory_dialog.dart';
import 'package:champion_anthology/levels/memory/memory_game.dart';
import 'package:champion_anthology/levels/memory/memory_hud.dart';
import 'package:champion_anthology/levels/memory/memory_round.dart';
import 'package:champion_anthology/levels/memory/memory_sequence.dart';
import 'package:champion_anthology/levels/memory/memory_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

/// Layar logis [width] x [height] dp.
void _screen(WidgetTester tester, double width, double height, {double ratio = 3}) {
  tester.view.physicalSize = Size(width * ratio, height * ratio);
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Urutan tetap tiap step (panjang = panjang ronde terakhir) supaya tes tidak bergantung pada acak.
const Map<int, List<int>> _fixed = {
  1: [0, 1, 2, 3, 0, 1, 2],
  2: [0, 1, 2, 3, 4, 5, 0, 1, 2],
  3: [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1],
};

MemorySequence _fixedSequence(int step, Random random) => MemorySequence(step, _fixed[step]!);

MemoryGame _newGame() => MemoryGame(LevelSession(), sequenceFor: _fixedSequence);

/// Memajukan mesin game (tanpa Flame) sampai [target] tercapai.
void _advance(MemoryGame game, MemoryPhase target) {
  var t = 0.0;
  while (game.run.phase != target && t < 300) {
    game.run.update(1 / 60);
    t += 1 / 60;
  }
  expect(game.run.phase, target);
}

Future<void> _pumpHud(WidgetTester tester, MemoryGame game) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: MemoryHud(game: game))));
}

String _text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  group('Dialog', () {
    test('lengkap: intro 3 step, hasil 4 bintang, dan variasi reaksi', () {
      expect(MemoryDialog.stepIntro, hasLength(3));
      expect(MemoryDialog.win, hasLength(3));
      expect(MemoryDialog.lose, hasLength(3));
      expect(MemoryDialog.resultByStars, hasLength(4));
      for (final lines in MemoryDialog.resultByStars) {
        expect(lines.length, greaterThanOrEqualTo(2));
      }
      for (final lines in [...MemoryDialog.win, ...MemoryDialog.lose]) {
        expect(lines.length, greaterThanOrEqualTo(2));
      }
      expect(MemoryDialog.correctReact.length, greaterThanOrEqualTo(3));
      expect(MemoryDialog.wrongReact.length, greaterThanOrEqualTo(3));
      expect(MemoryDialog.timeoutReact.length, greaterThanOrEqualTo(2));
      expect(MemoryDialog.cleanReact.length, greaterThanOrEqualTo(2));
    });

    test('semua teks tidak kosong dan hanya berisi karakter ASCII yang bisa digambar font piksel', () {
      final all = <String>[
        MemoryDialog.intro,
        MemoryDialog.tip,
        MemoryDialog.bannerWord,
        MemoryDialog.livesLabel,
        MemoryDialog.watch,
        MemoryDialog.yourTurn,
        MemoryDialog.right,
        MemoryDialog.wrong,
        MemoryDialog.timeUp,
        MemoryDialog.passed,
        MemoryDialog.failed,
        ...MemoryDialog.stepIntro,
        ...MemoryDialog.correctReact,
        ...MemoryDialog.wrongReact,
        ...MemoryDialog.timeoutReact,
        ...MemoryDialog.cleanReact,
        for (final l in MemoryDialog.win) ...l,
        for (final l in MemoryDialog.lose) ...l,
        for (final l in MemoryDialog.resultByStars) ...l,
        for (var s = 1; s <= 3; s++) ...[
          MemoryDialog.roundLabel(s),
          MemoryDialog.rememberLabel(1, memoryRoundsOf(s)),
          MemoryDialog.counterLabel(0, memoryLengthOf(s, 1)),
          MemoryDialog.padsLabel(s),
          MemoryDialog.lengthRangeLabel(s),
        ],
      ];
      for (final s in all) {
        expect(s.trim(), isNotEmpty);
        for (final r in s.runes) {
          expect(r == 10 || (r >= 32 && r <= 126), isTrue, reason: 'karakter di luar ASCII pada "$s"');
        }
      }
    });

    test('label berasal dari konstanta konfigurasi', () {
      expect(MemoryDialog.roundLabel(1), 'Ronde 1/3');
      expect(MemoryDialog.roundLabel(3), 'Ronde 3/3');
      expect(MemoryDialog.rememberLabel(1, memoryRoundsOf(1)), 'Ingat 1/5');
      expect(MemoryDialog.rememberLabel(6, memoryRoundsOf(2)), 'Ingat 6/6');
      expect(MemoryDialog.rememberLabel(7, memoryRoundsOf(3)), 'Ingat 7/7');
      expect(MemoryDialog.counterLabel(3, 7), '3/7');
      expect(MemoryDialog.padsLabel(1), '4 pad');
      expect(MemoryDialog.padsLabel(2), '6 pad');
      expect(MemoryDialog.padsLabel(3), '9 pad');
      expect(MemoryDialog.lengthRangeLabel(1), 'Urutan 3-7');
      expect(MemoryDialog.lengthRangeLabel(2), 'Urutan 4-9');
      expect(MemoryDialog.lengthRangeLabel(3), 'Urutan 5-11');
      expect(MemoryDialog.bannerWord, 'INGAT');
      expect(MemoryDialog.watch, 'PERHATIKAN');
      expect(MemoryDialog.yourTurn, 'GILIRANMU');
      expect(MemoryDialog.right, 'BENAR!');
      expect(MemoryDialog.wrong, 'SALAH!');
      expect(MemoryDialog.timeUp, 'WAKTU HABIS');
    });
  });

  group('Registri level', () {
    test('Level 8 terdaftar sebagai Mira the Memory Keeper, setelah Level 7', () {
      final level = levelById('memory');
      expect(level, isNotNull);
      expect(level!.number, 8);
      expect(level.bossName, 'Mira the Memory Keeper');
      expect(level.introDialog, MemoryDialog.intro);
      expect(level.tip, MemoryDialog.tip);
      expect(level.available, isTrue);
      expect(level.bossImage, 'assets/images/memory/boss_idle.png');
      expect(levelRegistry.indexOf(level), 7);
      expect(levelRegistry[6].id, 'rhythm');
    });

    test('nomor level berurutan 1 sampai 8 dan id unik', () {
      expect(levelRegistry.map((l) => l.number).toList().sublist(0, 8), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(levelRegistry.map((l) => l.id).toSet().length, levelRegistry.length);
    });
  });

  group('Tata letak', () {
    test('zona vertikal berurutan tanpa tumpang tindih', () {
      expect(MemoryLayout.topBarBottom, lessThanOrEqualTo(MemoryLayout.bossTop));
      expect(MemoryLayout.bossBottom, lessThanOrEqualTo(MemoryLayout.statusTop));
      expect(MemoryLayout.statusBottom, lessThanOrEqualTo(MemoryLayout.timerTop));
      expect(MemoryLayout.timerBottom, lessThanOrEqualTo(MemoryLayout.padAreaTop));
      expect(MemoryLayout.padAreaBottom, lessThan(1.0)); // ada margin bawah yang aman untuk gestur sistem
    });

    test('pad persegi, di dalam area pad, tidak saling menimpa, dan jumlahnya sesuai step', () {
      for (final size in const [Size(360, 640), Size(360, 800), Size(411, 891), Size(1080, 2400)]) {
        final area = MemoryLayout.padArea(size);
        for (var step = 1; step <= 3; step++) {
          final rects = [for (var i = 0; i < memoryPadsOf(step); i++) MemoryLayout.padRect(step, i, size)];
          expect(rects, hasLength(memoryPadsOf(step)));
          for (var i = 0; i < rects.length; i++) {
            expect(rects[i].width, closeTo(rects[i].height, 1e-6), reason: 'persegi step $step pad $i');
            expect(rects[i].width, closeTo(rects[0].width, 1e-6));
            expect(rects[i].left, greaterThanOrEqualTo(area.left - 1e-6));
            expect(rects[i].right, lessThanOrEqualTo(area.right + 1e-6));
            expect(rects[i].top, greaterThanOrEqualTo(area.top - 1e-6));
            expect(rects[i].bottom, lessThanOrEqualTo(area.bottom + 1e-6));
            for (var j = i + 1; j < rects.length; j++) {
              expect(rects[i].overlaps(rects[j]), isFalse, reason: 'step $step pad $i dan $j');
            }
          }
        }
      }
    });

    test('kisi mengikuti urutan kiri-kanan lalu atas-bawah', () {
      const size = Size(360, 640);
      // Step 1: 2x2
      expect(MemoryLayout.padRect(1, 1, size).left, greaterThan(MemoryLayout.padRect(1, 0, size).right));
      expect(MemoryLayout.padRect(1, 1, size).top, closeTo(MemoryLayout.padRect(1, 0, size).top, 1e-6));
      expect(MemoryLayout.padRect(1, 2, size).top, greaterThan(MemoryLayout.padRect(1, 0, size).bottom));
      expect(MemoryLayout.padRect(1, 2, size).left, closeTo(MemoryLayout.padRect(1, 0, size).left, 1e-6));
      // Step 2: 3 kolom x 2 baris; pad 3 mulai baris kedua
      expect(MemoryLayout.padRect(2, 2, size).top, closeTo(MemoryLayout.padRect(2, 0, size).top, 1e-6));
      expect(MemoryLayout.padRect(2, 3, size).top, greaterThan(MemoryLayout.padRect(2, 0, size).bottom));
      // Step 3: 3x3; pad 8 di pojok kanan bawah
      expect(MemoryLayout.padRect(3, 8, size).left, greaterThan(MemoryLayout.padRect(3, 0, size).left));
      expect(MemoryLayout.padRect(3, 8, size).top, greaterThan(MemoryLayout.padRect(3, 0, size).top));
    });

    test('ukuran ketuk pad minimal 56 dp pada layar selebar 360 (semua step)', () {
      for (final size in const [Size(360, 560), Size(360, 640), Size(360, 800)]) {
        for (var step = 1; step <= 3; step++) {
          expect(MemoryLayout.padSide(step, size), greaterThanOrEqualTo(MemoryLayout.minPadSize), reason: 'step $step $size');
        }
      }
    });

    test('warna, bentuk, nada, dan frekuensi tersedia untuk 9 pad dan tidak ada yang kembar', () {
      expect(memoryPadColors, hasLength(9));
      expect(memoryPadShapes, hasLength(9));
      expect(memoryPadNotes, hasLength(9));
      expect(memoryPadFrequencies, hasLength(9));
      expect(memoryPadColors.toSet(), hasLength(9));
      expect(memoryPadShapes.toSet(), hasLength(9));
      expect(memoryPadNotes.toSet(), hasLength(9));
      expect(memoryPadFrequencies.toSet(), hasLength(9));
      for (var i = 1; i < 9; i++) {
        expect(memoryPadFrequencies[i], greaterThan(memoryPadFrequencies[i - 1]));
      }
    });
  });

  group('Aset', () {
    test('ukuran PNG sesuai kisi piksel', () {
      expect(_pngSize('assets/images/memory/stage.png'), (720, 1278));
      for (var i = 0; i < 9; i++) {
        expect(_pngSize('assets/images/memory/pad_$i.png'), (120, 60), reason: 'pad_$i (dua bingkai 60x60)');
      }
      expect(_pngSize('assets/images/memory/heart_on.png'), (24, 24));
      expect(_pngSize('assets/images/memory/heart_off.png'), (24, 24));
    });

    test('gambar boss Mira lengkap dan folder terdaftar di pubspec', () {
      for (final f in ['boss_idle', 'boss_shock', 'boss_laugh', 'boss_defeat']) {
        expect(File('assets/images/memory/$f.png').existsSync(), isTrue, reason: f);
      }
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/images/memory/'));
    });

    test('versi aplikasi 1.9.0+10', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('version: 1.9.0+10'));
    });

    test('sembilan nada pad dan empat SFX terdaftar di Sfx dan filenya ada', () {
      final notes = [
        Sfx.memoryNote0,
        Sfx.memoryNote1,
        Sfx.memoryNote2,
        Sfx.memoryNote3,
        Sfx.memoryNote4,
        Sfx.memoryNote5,
        Sfx.memoryNote6,
        Sfx.memoryNote7,
        Sfx.memoryNote8,
      ];
      for (var i = 0; i < notes.length; i++) {
        expect(notes[i].file, 'memory_note_$i.wav');
      }
      for (final sfx in [...notes, Sfx.memoryWrong, Sfx.memoryClear, Sfx.memoryWin, Sfx.memoryLose]) {
        final file = File('assets/audio/${sfx.file}');
        expect(file.existsSync(), isTrue, reason: sfx.file);
        expect(file.lengthSync(), greaterThan(1000), reason: sfx.file);
      }
    });

    test('tanpa musik latar (default rancangan) supaya nada pad tidak terganggu', () {
      expect(File('assets/audio/memory_bgm.wav').existsSync(), isFalse);
    });
  });

  group('HUD', () {
    testWidgets('label Ronde, Ingat, dan penghitung sama dengan konstanta tiap step', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);

      for (var step = 1; step <= 3; step++) {
        game.displayStep.value = step;
        game.roundNo.value = 1;
        game.sequenceLength.value = memoryLengthOf(step, 1);
        game.correct.value = 0;
        game.lives.value = memoryLivesOf(step);
        await tester.pump();
        expect(_text(tester, 'round_label'), 'Ronde $step/3');
        expect(_text(tester, 'remember_label'), 'Ingat 1/${memoryRoundsOf(step)}');
        expect(_text(tester, 'counter_label'), '0/${memoryLengthOf(step, 1)}');

        final last = memoryRoundsOf(step);
        game.roundNo.value = last;
        game.sequenceLength.value = memoryFinalLengthOf(step);
        game.correct.value = 3;
        await tester.pump();
        expect(_text(tester, 'remember_label'), 'Ingat $last/$last');
        expect(_text(tester, 'counter_label'), '3/${memoryFinalLengthOf(step)}');
      }
      expect(find.byKey(const ValueKey('timer_bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('judul fase dan hasil ketukan tampil dari notifier', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      for (final text in [
        MemoryDialog.watch,
        MemoryDialog.yourTurn,
        MemoryDialog.right,
        MemoryDialog.wrong,
        MemoryDialog.timeUp,
      ]) {
        game.statusText.value = text;
        await tester.pump();
        expect(_text(tester, 'phase_label'), text);
      }
    });

    testWidgets('hasil LULUS dan GAGAL tampil di area pad', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      expect(find.byKey(const ValueKey('result_text')), findsNothing);
      game.resultText.value = MemoryDialog.passed;
      await tester.pump();
      expect(_text(tester, 'result_text'), 'LULUS!');
      game.resultText.value = MemoryDialog.failed;
      await tester.pump();
      expect(_text(tester, 'result_text'), 'GAGAL');
    });

    testWidgets('jumlah pad di layar 4, 6, dan 9 menurut step dan semuanya bisa diketuk', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      for (var step = 1; step <= 3; step++) {
        game.displayStep.value = step;
        await tester.pump();
        for (var i = 0; i < 9; i++) {
          final finder = find.byKey(ValueKey('pad_$i'));
          if (i < memoryPadsOf(step)) {
            expect(finder, findsOneWidget, reason: 'step $step pad $i');
            // tepat di tengah pad harus kena pad itu sendiri (tidak tertutup widget lain)
            expect(finder.hitTestable(), findsOneWidget, reason: 'step $step pad $i tertutup');
          } else {
            expect(finder, findsNothing, reason: 'step $step pad $i seharusnya tidak ada');
          }
        }
      }
    });

    testWidgets('pad persegi dan sedikitnya 56 dp pada layar selebar 360', (tester) async {
      _screen(tester, 360, 640, ratio: 2);
      final game = _newGame();
      await _pumpHud(tester, game);
      for (var step = 1; step <= 3; step++) {
        game.displayStep.value = step;
        await tester.pump();
        for (var i = 0; i < memoryPadsOf(step); i++) {
          final size = tester.getSize(find.byKey(ValueKey('pad_$i')));
          expect(size.width, closeTo(size.height, 0.01), reason: 'step $step pad $i');
          expect(size.width, greaterThanOrEqualTo(56), reason: 'step $step pad $i');
        }
      }
    });

    testWidgets('baris nyawa sesuai step dan berkurang saat salah', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      for (var step = 1; step <= 3; step++) {
        game.displayStep.value = step;
        game.lives.value = memoryLivesOf(step);
        await tester.pump();
        for (var i = 0; i < 4; i++) {
          expect(find.byKey(ValueKey('heart_on_$i')), i < memoryLivesOf(step) ? findsOneWidget : findsNothing);
        }
        expect(find.byKey(const ValueKey('heart_off_0')), findsNothing);
      }

      game.displayStep.value = 1;
      game.lives.value = 3;
      await tester.pump();
      game.lives.value = 2;
      await tester.pump();
      expect(find.byKey(const ValueKey('heart_on_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('heart_off_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('heart_on_2')), findsNothing);
    });

    testWidgets('pad tidak merespons saat tahap tonton', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      game.run.beginStep(1);
      _advance(game, MemoryPhase.showing);
      await tester.pump();
      expect(_text(tester, 'phase_label'), MemoryDialog.watch);

      await tester.tap(find.byKey(const ValueKey('pad_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pad_3')));
      await tester.pump();
      expect(game.run.phase, MemoryPhase.showing);
      expect(game.run.correct, 0);
      expect(game.run.lives, 3);
      expect(game.padDown[0].value, isFalse);
      expect(game.padDown[3].value, isFalse);
    });

    testWidgets('ketukan pad saat giliranmu: benar menaikkan penghitung, salah mengurangi nyawa dan nyawa di layar', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      await tester.pump();
      expect(_text(tester, 'phase_label'), MemoryDialog.yourTurn);
      expect(_text(tester, 'counter_label'), '0/3');

      await tester.tap(find.byKey(const ValueKey('pad_0'))); // benar
      await tester.pump();
      expect(game.run.correct, 1);
      expect(_text(tester, 'counter_label'), '1/3');

      game.run.update(1 / 60); // ketukan berikutnya di frame berikutnya
      await tester.tap(find.byKey(const ValueKey('pad_3'))); // seharusnya pad 1: salah
      await tester.pump();
      expect(game.run.lives, 2);
      expect(game.run.phase, MemoryPhase.retry);
      expect(find.byKey(const ValueKey('heart_on_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('heart_off_2')), findsOneWidget);
      expect(_text(tester, 'phase_label'), MemoryDialog.wrong);
      expect(_text(tester, 'counter_label'), '0/3');
      await tester.pumpAndSettle();
    });

    testWidgets('waktu habis menampilkan WAKTU HABIS dan mengurangi nyawa', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      for (var i = 0; i < 320; i++) {
        game.run.update(1 / 60); // sedikit melewati batas 5 detik (320 frame = 5,3 detik)
      }
      await tester.pump();
      expect(game.run.lives, 2);
      expect(_text(tester, 'phase_label'), MemoryDialog.timeUp);
      await tester.pumpAndSettle();
    });

    testWidgets('dua jari menyentuh dua pad di frame yang sama: hanya satu yang diproses', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      final a = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pad_0'))), pointer: 1);
      final b = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pad_3'))), pointer: 2);
      await tester.pump();
      expect(game.run.correct, 1); // pad 0 benar dan diterima
      expect(game.run.lives, 3); // pad 3 (salah) diabaikan, bukan dihitung salah
      expect(game.padDown[0].value, isTrue);
      expect(game.padDown[3].value, isFalse);
      await a.up();
      await b.up();
      await tester.pump();
      expect(game.padDown[0].value, isFalse);
    });

    testWidgets('jari yang dibatalkan melepas pad', (tester) async {
      _screen(tester, 360, 800);
      final game = _newGame();
      await _pumpHud(tester, game);
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pad_0'))));
      await tester.pump();
      expect(game.padDown[0].value, isTrue);
      await g.cancel();
      await tester.pump();
      expect(game.padDown[0].value, isFalse);
    });

    for (final (w, h) in const [(360.0, 640.0), (411.0, 891.0)]) {
      testWidgets('tidak ada overflow di layar ${w.round()}x${h.round()} pada Step 3 dengan banner dan ucapan boss', (tester) async {
        _screen(tester, w, h, ratio: 2);
        final game = _newGame();
        game.displayStep.value = 3;
        game.roundNo.value = 7;
        game.sequenceLength.value = 11;
        game.correct.value = 10;
        game.lives.value = 2;
        game.showBanner.value = true;
        game.statusText.value = MemoryDialog.timeUp;
        game.bossSay.value = MemoryDialog.stepIntro[2];
        await _pumpHud(tester, game);
        await tester.pump();
        expect(tester.takeException(), isNull);

        game.showBanner.value = false;
        game.resultText.value = MemoryDialog.passed;
        game.displayStep.value = 1;
        game.lives.value = 3;
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Permainan', () {
    test('pressPad dan releasePad menyalakan dan memadamkan pad hanya saat giliran pemain', () {
      final game = _newGame();
      game.pressPad(1); // belum giliran pemain
      expect(game.padDown[1].value, isFalse);

      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      game.pressPad(0);
      expect(game.padDown[0].value, isTrue);
      game.releasePad(0);
      expect(game.padDown[0].value, isFalse);
    });

    test('indeks pad tidak valid diabaikan, termasuk pad di luar jumlah pad step', () {
      final game = _newGame();
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      game.pressPad(-1);
      game.pressPad(4); // Step 1 hanya 4 pad (0..3)
      game.pressPad(9);
      game.releasePad(99);
      expect([for (final p in game.padDown) p.value], everyElement(isFalse));
      expect(game.run.lives, 3);
    });

    test('notifier HUD mengikuti mesin: banner, tonton, giliranmu, dan nyawa', () {
      final game = _newGame();
      game.run.beginStep(2);
      expect(game.showBanner.value, isTrue);
      expect(game.displayStep.value, 2);
      expect(game.lives.value, memoryLivesOf(2));
      expect(game.sequenceLength.value, memoryStartLengthOf(2));
      expect(game.bossSay.value, MemoryDialog.stepIntro[1]);

      _advance(game, MemoryPhase.showing);
      expect(game.showBanner.value, isFalse);
      expect(game.statusText.value, MemoryDialog.watch);
      _advance(game, MemoryPhase.input);
      expect(game.statusText.value, MemoryDialog.yourTurn);

      game.pressPad(5); // seharusnya pad 0: salah
      expect(game.lives.value, 1);
      expect(game.statusText.value, MemoryDialog.wrong);
      expect(game.blinkPad.value, 0); // pad yang benar berkedip
      expect(game.wrongTap.value?.pad, 5);
    });

    test('nyawa habis: jawaban benar tidak diungkap (tidak ada pad berkedip) dan hasil GAGAL', () {
      final game = _newGame();
      game.run.beginStep(2); // 2 nyawa
      _advance(game, MemoryPhase.input);
      game.pressPad(5);
      game.releasePad(5);
      game.blinkPad.value = null;
      game.run.update(1 / 60);
      _advance(game, MemoryPhase.input);
      game.pressPad(5);
      expect(game.lives.value, 0);
      expect(game.blinkPad.value, isNull);
      expect(game.resultText.value, MemoryDialog.failed);
    });

    test('waktu habis tidak menggetarkan pad mana pun (tidak ada pad yang diketuk)', () {
      final game = _newGame();
      game.run.beginStep(1);
      _advance(game, MemoryPhase.input);
      for (var i = 0; i < 320; i++) {
        game.run.update(1 / 60);
      }
      expect(game.lives.value, 2);
      expect(game.statusText.value, MemoryDialog.timeUp);
      expect(game.wrongTap.value, isNotNull);
      expect(game.wrongTap.value!.pad, isNull);
    });

    test('kalimat layar hasil siap saat sesi selesai dan sesuai bintang', () {
      final session = LevelSession();
      final game = MemoryGame(session, sequenceFor: _fixedSequence);
      game.run.beginStep(1);
      var t = 0.0;
      while (!session.isFinished && t < 600) {
        if (game.run.phase == MemoryPhase.input) {
          game.run.tapPad((game.run.currentSequence[game.run.correct] + 1) % 4); // selalu salah
        }
        game.run.update(1 / 20);
        t += 1 / 20;
      }
      expect(session.isFinished, isTrue);
      expect(session.stars, 0);
      expect(MemoryDialog.resultByStars[0], contains(game.resultMessage()));
    });

    test('sebutan tahap di layar hasil adalah Ronde', () {
      expect(_newGame().stepLabel, 'Ronde');
    });
  });
}
