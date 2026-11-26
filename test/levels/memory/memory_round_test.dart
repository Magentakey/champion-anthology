import 'dart:math';

import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/memory/memory_config.dart';
import 'package:champion_anthology/levels/memory/memory_round.dart';
import 'package:champion_anthology/levels/memory/memory_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

const double _frame = 1 / 60;

/// Urutan tetap tiap step supaya tes tidak bergantung pada acak (panjang = panjang ronde terakhir).
const Map<int, List<int>> _fixed = {
  1: [0, 1, 2, 3, 0, 1, 2],
  2: [0, 1, 2, 3, 4, 5, 0, 1, 2],
  3: [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1],
};

MemorySequence fixedSequence(int step, Random random) => MemorySequence(step, _fixed[step]!);

MemoryRound makeRun(LevelSession session) => MemoryRound(session, sequenceFor: fixedSequence);

/// Memajukan [run] sampai [target] tercapai (maksimal [limit] detik).
void advanceUntil(MemoryRound run, MemoryPhase target, {double limit = 300}) {
  var t = 0.0;
  while (run.phase != target && t < limit) {
    run.update(_frame);
    t += _frame;
  }
  expect(run.phase, target, reason: 'tidak mencapai $target dalam $limit detik');
}

/// Memajukan waktu sebanyak [ms] milidetik.
void tickMs(MemoryRound run, double ms) {
  final frames = (ms / (_frame * 1000)).round();
  for (var i = 0; i < frames; i++) {
    run.update(_frame);
  }
}

/// Mengetuk seluruh urutan ronde sekarang dengan benar (satu ketukan per frame).
void playRound(MemoryRound run) {
  for (final pad in [...run.currentSequence]) {
    expect(run.tapPad(pad), MemoryTap.correct);
    run.update(_frame);
  }
}

/// Pad yang pasti salah untuk simbol [expected].
int wrongPadFor(MemoryRound run, int expected) => (expected + 1) % run.padCount;

/// Memenangkan seluruh ronde step yang sedang berjalan tanpa kesalahan; berhenti di tahap hasil.
void winCurrentStep(MemoryRound run) {
  final rounds = memoryRoundsOf(run.step);
  for (var r = 1; r <= rounds; r++) {
    advanceUntil(run, MemoryPhase.input);
    expect(run.round, r);
    playRound(run);
  }
  expect(run.phase, MemoryPhase.result);
}

/// Menghabiskan semua nyawa step yang sedang berjalan; berhenti di tahap hasil.
void loseCurrentStep(MemoryRound run) {
  while (run.phase != MemoryPhase.result) {
    advanceUntil(run, MemoryPhase.input);
    run.tapPad(wrongPadFor(run, run.currentSequence[run.correct]));
    run.update(_frame);
  }
}

/// Melewati tahap hasil sampai sesi dilapori dan mesin berpindah ke jeda atau selesai.
void finishResult(MemoryRound run) {
  var t = 0.0;
  while (run.phase == MemoryPhase.result && t < 30) {
    run.update(_frame);
    t += _frame;
  }
  expect(run.phase, isNot(MemoryPhase.result));
}

void main() {
  group('Alur ronde', () {
    test('banner -> tonton -> giliranmu -> ronde bersih -> ronde berikutnya', () {
      final session = LevelSession();
      final run = makeRun(session);
      final phases = <MemoryPhase>[];
      run.onPhase = (from, to) => phases.add(to);

      run.beginStep(1);
      expect(run.phase, MemoryPhase.intro);
      expect(run.round, 1);
      expect(run.length, 3);
      advanceUntil(run, MemoryPhase.input);
      expect(phases, [MemoryPhase.intro, MemoryPhase.showing, MemoryPhase.input]);

      playRound(run);
      expect(run.phase, MemoryPhase.roundClear);
      advanceUntil(run, MemoryPhase.showing);
      expect(run.round, 2);
      expect(run.length, 4);
      advanceUntil(run, MemoryPhase.input);
      expect(run.correct, 0);
      expect(run.currentSequence, [0, 1, 2, 3]);
    });

    test('tahap tonton menayangkan pad satu per satu sesuai urutan, nyala lalu padam', () {
      final run = makeRun(LevelSession());
      final shown = <int>[];
      final lit = <int?>[];
      run.onShow = shown.add;
      run.onLit = lit.add;
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      expect(shown, [0, 1, 2]);
      expect(lit, [0, null, 1, null, 2, null]);
      expect(run.litPad, isNull);
    });

    test('lama tayangan = jeda awal + panjang x tempo', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.showing);
      var frames = 0;
      while (run.phase == MemoryPhase.showing) {
        run.update(_frame);
        frames++;
      }
      final expectedMs = MemoryTuning.showLeadMs + 3 * memoryShowMsOf(1);
      expect(frames * _frame * 1000, closeTo(expectedMs, 40));
    });

    test('pad menyala selama porsi nyala dari tempo, lalu padam sampai simbol berikutnya', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.showing);
      tickMs(run, (MemoryTuning.showLeadMs + 100).toDouble()); // di dalam simbol pertama, masih menyala
      expect(run.litPad, 0);
      tickMs(run, memoryLitMsOf(1).toDouble()); // lewat porsi nyala, masuk jeda
      expect(run.litPad, isNull);
      tickMs(run, (memoryShowMsOf(1) - memoryLitMsOf(1)).toDouble()); // simbol kedua menyala
      expect(run.litPad, 1);
    });

    test('ketukan saat tonton diabaikan (bukan dihitung salah)', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.showing);
      tickMs(run, 800);
      expect(run.phase, MemoryPhase.showing);
      expect(run.tapPad(0), MemoryTap.ignored);
      expect(run.tapPad(3), MemoryTap.ignored);
      expect(run.lives, 3);
      expect(run.correct, 0);
      expect(run.acceptsTaps, isFalse);
    });

    test('ketukan saat banner dan saat hasil juga diabaikan', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      expect(run.tapPad(0), MemoryTap.ignored);
      winCurrentStep(run);
      run.update(_frame);
      expect(run.tapPad(0), MemoryTap.ignored);
    });

    test('ketukan benar menaikkan penghitung; ketukan terakhir benar menyelesaikan ronde', () {
      final run = makeRun(LevelSession());
      final correct = <int>[];
      final cleared = <(int, bool)>[];
      run.onCorrect = (pad, count, length) => correct.add(count);
      run.onRoundClear = (round, clean) => cleared.add((round, clean));
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);

      expect(run.tapPad(0), MemoryTap.correct);
      expect(run.correct, 1);
      run.update(_frame);
      expect(run.tapPad(1), MemoryTap.correct);
      expect(run.correct, 2);
      expect(run.phase, MemoryPhase.input);
      run.update(_frame);
      expect(run.tapPad(2), MemoryTap.correct);
      expect(correct, [1, 2, 3]);
      expect(run.phase, MemoryPhase.roundClear);
      expect(cleared, [(1, true)]);
    });

    test('ketukan benar menyalakan pad sebentar lalu memadamkannya', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(0);
      expect(run.litPad, 0);
      tickMs(run, MemoryTuning.tapFlashMs + 100);
      expect(run.litPad, isNull);
    });

    test('ketukan di luar rentang pad diabaikan dan tidak mengurangi nyawa', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      expect(run.tapPad(-1), MemoryTap.ignored);
      expect(run.tapPad(4), MemoryTap.ignored); // Step 1 hanya punya pad 0..3
      expect(run.tapPad(9), MemoryTap.ignored);
      expect(run.lives, 3);
      expect(run.correct, 0);
    });

    test('dua ketukan dalam satu frame: hanya yang pertama diproses, sisanya diabaikan bukan salah', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      expect(run.tapPad(0), MemoryTap.correct);
      expect(run.tapPad(1), MemoryTap.ignored); // benar, tetapi frame yang sama
      expect(run.tapPad(3), MemoryTap.ignored); // salah, tetapi frame yang sama: tidak dihitung
      expect(run.correct, 1);
      expect(run.lives, 3);
      run.update(_frame);
      expect(run.tapPad(1), MemoryTap.correct);
      expect(run.correct, 2);
    });

    test('ronde bersih dilaporkan bersih; ronde dengan kesalahan dilaporkan tidak bersih', () {
      final run = makeRun(LevelSession());
      final cleared = <(int, bool)>[];
      run.onRoundClear = (round, clean) => cleared.add((round, clean));
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      playRound(run); // ronde 1 bersih
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(wrongPadFor(run, 0));
      run.update(_frame);
      advanceUntil(run, MemoryPhase.input);
      playRound(run); // ronde 2 selesai setelah satu kesalahan
      expect(cleared, [(1, true), (2, false)]);
    });
  });

  group('Kesalahan dan nyawa', () {
    test('ketukan salah: nyawa -1, urutan SAMA ditayangkan ulang dari awal, penghitung kembali 0', () {
      final run = makeRun(LevelSession());
      final mistakes = <MemoryMistake>[];
      run.onWrong = mistakes.add;
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      final before = [...run.currentSequence];

      expect(run.tapPad(before[0]), MemoryTap.correct);
      run.update(_frame);
      final wrong = wrongPadFor(run, before[1]);
      expect(run.tapPad(wrong), MemoryTap.wrong);

      expect(run.lives, 2);
      expect(run.correct, 0);
      expect(run.phase, MemoryPhase.retry);
      expect(mistakes, hasLength(1));
      expect(mistakes.single.expected, before[1]);
      expect(mistakes.single.tapped, wrong);
      expect(mistakes.single.timeout, isFalse);
      expect(mistakes.single.livesLeft, 2);

      advanceUntil(run, MemoryPhase.showing);
      expect(run.round, 1); // ronde tidak mundur
      expect(run.currentSequence, before); // urutan tidak berubah
      expect(run.length, before.length); // panjang tidak berkurang

      final shown = <int>[];
      run.onShow = shown.add;
      advanceUntil(run, MemoryPhase.input);
      expect(shown, before); // tayang ulang dari simbol pertama
      expect(run.correct, 0);
    });

    test('nyawa tidak dipulihkan antar-ronde', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(wrongPadFor(run, 0));
      run.update(_frame);
      expect(run.lives, 2);
      advanceUntil(run, MemoryPhase.input);
      playRound(run);
      advanceUntil(run, MemoryPhase.input);
      expect(run.round, 2);
      expect(run.lives, 2);
      playRound(run);
      advanceUntil(run, MemoryPhase.input);
      expect(run.round, 3);
      expect(run.lives, 2);
    });

    test('waktu habis dihitung salah: nyawa -1 dan pad yang benar dilaporkan', () {
      final run = makeRun(LevelSession());
      final mistakes = <MemoryMistake>[];
      run.onWrong = mistakes.add;
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      tickMs(run, memoryTimeoutMsOf(1) - 200);
      expect(run.phase, MemoryPhase.input);
      expect(run.lives, 3);
      tickMs(run, 400);
      expect(run.lives, 2);
      expect(run.phase, MemoryPhase.retry);
      expect(mistakes.single.timeout, isTrue);
      expect(mistakes.single.tapped, isNull);
      expect(mistakes.single.expected, 0);
    });

    test('timer diatur ulang tiap ketukan benar', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      expect(run.timerFraction, closeTo(1.0, 0.01));
      tickMs(run, memoryTimeoutMsOf(1) - 300);
      expect(run.timerFraction, lessThan(0.1));
      run.tapPad(0);
      expect(run.timerFraction, closeTo(1.0, 0.01));
      tickMs(run, memoryTimeoutMsOf(1) - 300); // total jauh melewati batas, tetapi timer sudah diatur ulang
      expect(run.phase, MemoryPhase.input);
      expect(run.lives, 3);
      run.tapPad(1);
      tickMs(run, memoryTimeoutMsOf(1) + 200);
      expect(run.lives, 2);
    });

    test('timer menyusut selama giliranmu dan bernilai 0 di luar giliran', () {
      final run = makeRun(LevelSession());
      run.beginStep(1);
      expect(run.timerFraction, 0);
      advanceUntil(run, MemoryPhase.showing);
      expect(run.timerFraction, 0);
      advanceUntil(run, MemoryPhase.input);
      final start = run.timerFraction;
      tickMs(run, 1000);
      expect(run.timerFraction, lessThan(start));
      expect(run.timerFraction, closeTo(1 - 1000 / memoryTimeoutMsOf(1), 0.03));
    });

    test('batas waktu mengikuti step: 5, 4, dan 3 detik', () {
      for (var step = 1; step <= 3; step++) {
        final run = makeRun(LevelSession());
        run.beginStep(step);
        advanceUntil(run, MemoryPhase.input);
        tickMs(run, memoryTimeoutMsOf(step) - 300);
        expect(run.phase, MemoryPhase.input, reason: 'step $step belum habis');
        tickMs(run, 500);
        expect(run.phase, MemoryPhase.retry, reason: 'step $step sudah habis');
      }
    });

    test('nyawa habis: step langsung gagal, loseStep tepat sekali, jawaban benar tidak diungkap lagi', () {
      final session = LevelSession();
      var notified = 0;
      session.addListener(() => notified++);
      final run = makeRun(session);
      final mistakes = <MemoryMistake>[];
      final results = <bool>[];
      run.onWrong = mistakes.add;
      run.onStepResult = results.add;

      run.beginStep(2); // 2 nyawa
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(wrongPadFor(run, 0));
      run.update(_frame);
      expect(run.phase, MemoryPhase.retry);
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(wrongPadFor(run, 0));

      expect(run.lives, 0);
      expect(run.phase, MemoryPhase.result);
      expect(run.passed, isFalse);
      expect(results, [false]);
      expect(mistakes.last.livesLeft, 0);
      expect(session.isPlaying, isTrue); // sesi baru dilapori setelah tahap hasil
      expect(notified, 0);

      finishResult(run);
      expect(session.isFinished, isTrue);
      expect(session.stars, 0);
      expect(run.phase, MemoryPhase.done);
      expect(notified, 1);

      for (var i = 0; i < 600; i++) {
        run.update(_frame); // tidak dilaporkan dua kali
      }
      expect(notified, 1);
      expect(results, [false]);
    });

    test('nyawa habis karena waktu habis juga menggagalkan step', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(3); // 2 nyawa
      advanceUntil(run, MemoryPhase.input);
      tickMs(run, memoryTimeoutMsOf(3) + 100);
      expect(run.phase, MemoryPhase.retry);
      advanceUntil(run, MemoryPhase.input);
      tickMs(run, memoryTimeoutMsOf(3) + 100);
      expect(run.phase, MemoryPhase.result);
      expect(run.passed, isFalse);
    });
  });

  group('Menang step dan bintang', () {
    test('ronde terakhir selesai dengan nyawa tersisa: winStep tepat sekali', () {
      final session = LevelSession();
      var notified = 0;
      session.addListener(() => notified++);
      final run = makeRun(session);
      final results = <bool>[];
      run.onStepResult = results.add;

      run.beginStep(1);
      winCurrentStep(run);
      expect(run.passed, isTrue);
      expect(run.lives, 3);
      expect(results, [true]);
      expect(session.stepsWon, 0); // belum dilapori sebelum tahap hasil selesai
      expect(notified, 0);

      finishResult(run);
      expect(session.stepsWon, 1);
      expect(session.step, 2);
      expect(notified, 1);
      expect(results, [true]);

      advanceUntil(run, MemoryPhase.intro); // jeda antar-step lalu step 2 dimulai
      expect(run.step, 2);
      expect(session.stepsWon, 1); // tidak dilaporkan dua kali
      expect(notified, 1);
    });

    test('menang dengan nyawa tersisa 1 tetap menang', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(2); // 2 nyawa
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(wrongPadFor(run, 0));
      run.update(_frame);
      expect(run.lives, 1);
      for (var r = 1; r <= memoryRoundsOf(2); r++) {
        advanceUntil(run, MemoryPhase.input);
        playRound(run);
      }
      expect(run.phase, MemoryPhase.result);
      expect(run.passed, isTrue);
      expect(run.lives, 1);
    });

    test('tiga step menang = 3 bintang dan sesi selesai', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      for (var step = 1; step <= 3; step++) {
        advanceUntil(run, MemoryPhase.intro);
        expect(run.step, step);
        winCurrentStep(run);
        finishResult(run);
      }
      expect(session.isFinished, isTrue);
      expect(session.stepsWon, 3);
      expect(session.stars, 3);
      expect(run.phase, MemoryPhase.done);
    });

    test('gagal di step 2 = 1 bintang', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      winCurrentStep(run);
      finishResult(run);
      advanceUntil(run, MemoryPhase.intro);
      expect(run.step, 2);
      loseCurrentStep(run);
      finishResult(run);
      expect(session.isFinished, isTrue);
      expect(session.stars, 1);
    });

    test('gagal di step 3 = 2 bintang', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      for (var step = 1; step <= 2; step++) {
        advanceUntil(run, MemoryPhase.intro);
        winCurrentStep(run);
        finishResult(run);
      }
      advanceUntil(run, MemoryPhase.intro);
      expect(run.step, 3);
      loseCurrentStep(run);
      finishResult(run);
      expect(session.stars, 2);
    });

    test('gagal di step 1 = 0 bintang', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      loseCurrentStep(run);
      finishResult(run);
      expect(session.isFinished, isTrue);
      expect(session.stars, 0);
    });

    test('nyawa dipulihkan penuh di awal tiap step dan tidak dibawa antar-step', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      for (var i = 0; i < 2; i++) {
        run.tapPad(wrongPadFor(run, run.currentSequence[0]));
        run.update(_frame);
        advanceUntil(run, MemoryPhase.input);
      }
      expect(run.lives, 1); // Step 1 selesai dengan sisa 1 nyawa
      for (var r = 1; r <= memoryRoundsOf(1); r++) {
        advanceUntil(run, MemoryPhase.input);
        playRound(run);
      }
      expect(run.lives, 1);
      finishResult(run);
      advanceUntil(run, MemoryPhase.intro);
      expect(run.step, 2);
      expect(run.lives, memoryLivesOf(2)); // penuh sesuai tabel, bukan 1
      winCurrentStep(run);
      finishResult(run);
      advanceUntil(run, MemoryPhase.intro);
      expect(run.step, 3);
      expect(run.lives, memoryLivesOf(3));
    });

    test('tiap step memakai pad, ronde, dan panjang sesuai tabel', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      for (var step = 1; step <= 3; step++) {
        advanceUntil(run, MemoryPhase.intro);
        expect(run.padCount, memoryPadsOf(step));
        expect(run.rounds, memoryRoundsOf(step));
        expect(run.length, memoryStartLengthOf(step));
        winCurrentStep(run);
        expect(run.length, memoryFinalLengthOf(step));
        finishResult(run);
      }
    });

    test('kalimat layar hasil siap sebelum sesi berubah (onBeforeCommit)', () {
      final session = LevelSession();
      final run = makeRun(session);
      final stepsWonAtCommit = <int>[];
      final won = <bool>[];
      run.onBeforeCommit = (w) {
        won.add(w);
        stepsWonAtCommit.add(session.stepsWon);
      };
      run.beginStep(1);
      winCurrentStep(run);
      finishResult(run);
      expect(won, [true]);
      expect(stepsWonAtCommit, [0]); // sesi belum berubah saat kait dipanggil
      expect(session.stepsWon, 1);
    });
  });

  group('Jeda dan lanjut', () {
    test('selama jeda tidak ada kemajuan: timer dan tayangan beku', () {
      final session = LevelSession();
      final run = makeRun(session);
      final shown = <int>[];
      run.onShow = shown.add;
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.showing);
      tickMs(run, (MemoryTuning.showLeadMs + 100).toDouble());
      final shownBefore = shown.length;
      final litBefore = run.litPad;

      session.pause();
      tickMs(run, 5000);
      expect(run.phase, MemoryPhase.showing);
      expect(shown.length, shownBefore);
      expect(run.litPad, litBefore);

      session.resume();
      run.resumeFromPause();
      advanceUntil(run, MemoryPhase.input);

      final before = run.timerFraction;
      session.pause();
      tickMs(run, 5000);
      expect(run.phase, MemoryPhase.input);
      expect(run.timerFraction, before);
      expect(run.lives, 3);
    });

    test('ketukan saat jeda diabaikan', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      session.pause();
      expect(run.acceptsTaps, isFalse);
      expect(run.tapPad(0), MemoryTap.ignored);
      expect(run.correct, 0);
    });

    test('lanjut saat tonton mengulang tayangan dari simbol pertama tanpa penalti', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.showing);
      tickMs(run, MemoryTuning.showLeadMs + memoryShowMsOf(1) + 100); // simbol kedua sedang tayang
      expect(run.litPad, isNotNull);

      session.pause();
      tickMs(run, 2000);
      session.resume();
      run.resumeFromPause();
      expect(run.phase, MemoryPhase.showing);
      expect(run.litPad, isNull);

      final shown = <int>[];
      run.onShow = shown.add;
      advanceUntil(run, MemoryPhase.input);
      expect(shown, [0, 1, 2]); // diulang dari awal
      expect(run.lives, 3);
      expect(run.round, 1);
    });

    test('lanjut saat giliranmu: ketukan benar tetap dihitung, timer diatur ulang penuh, tidak menambah salah', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      advanceUntil(run, MemoryPhase.input);
      run.tapPad(0);
      run.update(_frame);
      tickMs(run, 3500);
      expect(run.timerFraction, lessThan(0.4));

      session.pause();
      tickMs(run, 4000);
      session.resume();
      run.resumeFromPause();

      expect(run.phase, MemoryPhase.input);
      expect(run.correct, 1);
      expect(run.lives, 3);
      expect(run.timerFraction, 1.0);

      expect(run.tapPad(1), MemoryTap.correct);
      run.update(_frame);
      expect(run.tapPad(2), MemoryTap.correct);
      expect(run.phase, MemoryPhase.roundClear);
    });

    test('lanjut di tahap lain tidak mengubah apa pun', () {
      final session = LevelSession();
      final run = makeRun(session);
      run.beginStep(1);
      run.resumeFromPause(); // banner
      expect(run.phase, MemoryPhase.intro);
      winCurrentStep(run);
      run.resumeFromPause(); // hasil
      expect(run.phase, MemoryPhase.result);
      expect(run.passed, isTrue);
    });
  });

  group('Urutan acak yang disuntikkan', () {
    test('beginStep memakai Random yang diberikan: seed sama = urutan sama', () {
      final a = MemoryRound(LevelSession(), random: Random(11));
      final b = MemoryRound(LevelSession(), random: Random(11));
      a.beginStep(3);
      b.beginStep(3);
      expect(a.sequence!.symbols, b.sequence!.symbols);
      expect(a.sequence!.symbols, MemorySequence.generate(3, Random(11)).symbols);
    });

    test('percobaan baru memakai urutan baru (bukan seed tetap)', () {
      final session = LevelSession();
      final run = MemoryRound(session, random: Random(5));
      final seen = <String>{};
      for (var i = 0; i < 20; i++) {
        run.beginStep(2);
        seen.add(run.sequence!.symbols.join(','));
      }
      expect(seen.length, greaterThan(10));
    });

    test('tiap step mendapat urutan dengan panjang dan pad sesuai tabel', () {
      final run = MemoryRound(LevelSession(), random: Random(2));
      for (var step = 1; step <= 3; step++) {
        run.beginStep(step);
        expect(run.sequence!.length, memoryFinalLengthOf(step));
        expect(run.sequence!.padCount, memoryPadsOf(step));
      }
    });
  });
}
