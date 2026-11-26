import 'dart:io';
import 'dart:math';

import 'package:champion_anthology/core/level/level_session.dart';
import 'package:champion_anthology/levels/gambler/gambler_config.dart';
import 'package:champion_anthology/levels/gambler/luck_round.dart';
import 'package:champion_anthology/levels/level_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Semua pengacak di tes ini memakai seed tetap, jadi hasilnya sama di setiap mesin dan di CI.
/// Toleransi dihitung dari simpangan baku: 10.000 putaran dengan toleransi 2 poin sekitar 4 sampai 5 simpangan baku.
const _trials = 10000;
const _tolerance = 0.02;

double _rate(int hits, int total) => hits / total;

void main() {
  group('Konstanta peluang', () {
    test('gambler_config berisi 0,75, 0,5, 0,25 persis dan tidak ada angka peluang lain di berkas', () {
      expect(gamblerWinChance, [0.75, 0.5, 0.25]);
      expect(gamblerChanceOf(1), 0.75);
      expect(gamblerChanceOf(2), 0.5);
      expect(gamblerChanceOf(3), 0.25);

      // Baca berkas sumbernya: buang komentar, lalu semua angka pecahan harus tepat tiga itu.
      final source = File('lib/levels/gambler/gambler_config.dart').readAsLinesSync();
      final code = source.map((l) => l.replaceFirst(RegExp(r'//.*$'), '')).join('\n');
      final decimals = RegExp(r'(?<![\w.])\d*\.\d+').allMatches(code).map((m) => m.group(0)).toList();
      expect(decimals, ['0.75', '0.5', '0.25']);
    });

    test('peluang sesuai jumlah kartu, sisi, dan cangkir', () {
      expect((GamblerTuning.cardCount - GamblerTuning.bombCount) / GamblerTuning.cardCount, gamblerChanceOf(1));
      expect(1 / GamblerTuning.coinSides, gamblerChanceOf(2));
      expect(1 / GamblerTuning.cupCount, gamblerChanceOf(3));
    });

    test('permainan dan persen per step', () {
      expect(gamblerGames, [LuckGame.card, LuckGame.coin, LuckGame.cup]);
      expect([for (var s = 1; s <= 3; s++) gamblerChancePercent(s)], [75, 50, 25]);
      expect(gamblerChanceOf(0), 0.75); // di luar rentang dipotong ke ujung
      expect(gamblerChanceOf(9), 0.25);
    });

    test('peluang setiap ronde sama dengan konfigurasi', () {
      final rng = Random(1);
      for (var step = 1; step <= 3; step++) {
        expect(LuckRound.forStep(step, rng).winChance, gamblerChanceOf(step));
        expect(LuckRound.forStep(step, rng).game, gamblerGameOf(step));
      }
    });
  });

  group('Frekuensi kemenangan (10.000 putaran, seed tetap)', () {
    test('kartu: pilihan acak menang 75% ± 2 poin', () {
      final rng = Random(101);
      final picker = Random(202);
      var wins = 0;
      for (var i = 0; i < _trials; i++) {
        final round = CardRound(rng);
        if (round.resolve(picker.nextInt(round.optionCount))) wins++;
      }
      expect(_rate(wins, _trials), closeTo(0.75, _tolerance));
    });

    test('koin: tebakan kepala dan ekor dihitung terpisah, masing-masing 50% ± 2 poin', () {
      for (final side in [0, 1]) {
        final rng = Random(300 + side);
        var wins = 0;
        for (var i = 0; i < _trials; i++) {
          if (CoinRound(rng).resolve(side)) wins++;
        }
        expect(_rate(wins, _trials), closeTo(0.5, _tolerance), reason: 'tebakan sisi $side');
      }
    });

    test('cangkir: pilihan acak menang 25% ± 2 poin', () {
      final rng = Random(401);
      final picker = Random(502);
      var wins = 0;
      for (var i = 0; i < _trials; i++) {
        final round = CupRound(rng);
        if (round.resolve(picker.nextInt(round.optionCount))) wins++;
      }
      expect(_rate(wins, _trials), closeTo(0.25, _tolerance));
    });

    test('pilihan tetap di satu posisi pun menang dengan peluang yang sama (pilihan tidak memengaruhi peluang)', () {
      for (var pick = 0; pick < GamblerTuning.cardCount; pick++) {
        final rng = Random(600 + pick);
        var cardWins = 0;
        var cupWins = 0;
        for (var i = 0; i < _trials; i++) {
          if (CardRound(rng).resolve(pick)) cardWins++;
          if (CupRound(rng).resolve(pick)) cupWins++;
        }
        expect(_rate(cardWins, _trials), closeTo(0.75, _tolerance), reason: 'kartu $pick');
        expect(_rate(cupWins, _trials), closeTo(0.25, _tolerance), reason: 'cangkir $pick');
      }
    });
  });

  group('Merata per posisi', () {
    test('kartu sial muncul di tiap posisi dengan frekuensi sama (25% ± 2 poin)', () {
      final rng = Random(701);
      final counts = List<int>.filled(GamblerTuning.cardCount, 0);
      for (var i = 0; i < _trials; i++) {
        counts[CardRound(rng).bombIndex]++;
      }
      for (var p = 0; p < counts.length; p++) {
        expect(_rate(counts[p], _trials), closeTo(0.25, _tolerance), reason: 'posisi $p');
      }
    });

    test('cangkir berbola muncul di tiap posisi dengan frekuensi sama (25% ± 2 poin)', () {
      final rng = Random(802);
      final counts = List<int>.filled(GamblerTuning.cupCount, 0);
      for (var i = 0; i < _trials; i++) {
        counts[CupRound(rng).ballIndex]++;
      }
      for (var p = 0; p < counts.length; p++) {
        expect(_rate(counts[p], _trials), closeTo(0.25, _tolerance), reason: 'posisi $p');
      }
    });

    test('sisi koin yang mendarat 50% kepala dan 50% ekor (± 2 poin)', () {
      final rng = Random(903);
      var heads = 0;
      for (var i = 0; i < _trials; i++) {
        if (CoinRound(rng).landed == CoinSide.head) heads++;
      }
      expect(_rate(heads, _trials), closeTo(0.5, _tolerance));
    });
  });

  group('Tanpa bonus kekalahan', () {
    // Sengaja dipaksa kalah 5 kali berturut-turut (pilihan salah yang diketahui dari penempatan), lalu satu ronde
    // dengan pilihan acak. Peluangnya harus tetap sama. Memakai 6.000 percobaan (bukan 1.000) supaya toleransi
    // 3 poin setara sekitar 4 simpangan baku dan tidak rapuh.
    const trials = 6000;
    const tolerance = 0.03;

    bool forcedLoss(LuckRound round) {
      final wrong = switch (round.game) {
        LuckGame.card => round.placement, // memilih kartu sial
        LuckGame.coin => (round.placement + 1) % round.optionCount, // sisi yang tidak mendarat
        LuckGame.cup => (round.placement + 1) % round.optionCount, // cangkir kosong
      };
      return round.resolve(wrong);
    }

    for (final step in [1, 2, 3]) {
      test('step $step: setelah 5 kali kalah beruntun peluang tetap ${gamblerChancePercent(step)}% ± 3 poin', () {
        final rng = Random(1000 + step);
        final picker = Random(2000 + step);
        var wins = 0;
        for (var i = 0; i < trials; i++) {
          for (var k = 0; k < 5; k++) {
            expect(forcedLoss(LuckRound.forStep(step, rng)), isFalse);
          }
          final round = LuckRound.forStep(step, rng);
          if (round.resolve(picker.nextInt(round.optionCount))) wins++;
        }
        expect(_rate(wins, trials), closeTo(gamblerChanceOf(step), tolerance));
      });
    }

    test('CupRound tidak punya riwayat: penempatan hanya ditentukan oleh pengacak yang diberikan', () {
      final a = CupRound(Random(7));
      final other = Random(99);
      for (var i = 0; i < 50; i++) {
        CupRound(other).resolve(0); // ronde lain, termasuk yang kalah, tidak memengaruhi ronde dengan seed sama
      }
      final b = CupRound(Random(7));
      expect(b.placement, a.placement);
      expect(b.winChance, a.winChance);
    });
  });

  group('Penempatan lebih dulu', () {
    test('resolve tidak mengubah penempatan, pilihan berbeda hanya membandingkan', () {
      final rng = Random(11);
      for (var step = 1; step <= 3; step++) {
        for (var i = 0; i < 200; i++) {
          final round = LuckRound.forStep(step, rng);
          final before = round.placement;
          final results = [for (var pick = 0; pick < round.optionCount; pick++) round.resolve(pick)];
          expect(round.placement, before);
          // jawaban setiap pilihan konsisten saat ditanya lagi
          expect([for (var pick = 0; pick < round.optionCount; pick++) round.resolve(pick)], results);
          final expectedWins = step == 1 ? round.optionCount - 1 : 1;
          expect(results.where((w) => w).length, expectedWins);
        }
      }
    });

    test('GamblerRun: penempatan tetap sejak beginStep dan mengganti pilihan setelah konfirmasi tidak mengubah hasil', () {
      for (var step = 1; step <= 3; step++) {
        final run = GamblerRun(LevelSession(), random: Random(step));
        final round = run.beginStep(step);
        final placement = round.placement;
        final first = run.confirm(0);
        final again = run.confirm(1);
        expect(identical(first, again), isTrue);
        expect(again.pick, 0);
        expect(run.round!.placement, placement);
        expect(first.placement, placement);
        expect(first.won, round.resolve(0));
      }
    });

    test('pilihan di luar rentang ditolak dan confirm sebelum beginStep gagal', () {
      final run = GamblerRun(LevelSession(), random: Random(1));
      expect(() => run.confirm(0), throwsStateError);
      final round = run.beginStep(1);
      expect(() => round.resolve(-1), throwsRangeError);
      expect(() => round.resolve(round.optionCount), throwsRangeError);
    });
  });

  group('Acakan cangkir (hanya hiasan)', () {
    test('bola selalu berakhir tepat di slot penempatan setelah dijajarkan ulang, apa pun acakannya', () {
      for (var seed = 0; seed < 300; seed++) {
        for (var finalSlot = 0; finalSlot < GamblerTuning.cupCount; finalSlot++) {
          final plan = CupShuffle.plan(Random(seed), finalSlot: finalSlot);
          expect(plan.swaps.length, GamblerTuning.shuffleSwaps);
          expect(plan.slotAfter(plan.startSlot, plan.swaps.length), plan.mergeSlot, reason: 'seed $seed slot $finalSlot');
          expect(plan.positionOf(plan.startSlot, 0).slot, plan.startSlot.toDouble());
          expect(plan.positionOf(plan.startSlot, 1).slot, plan.mergeSlot.toDouble());
          expect(plan.spreadSlot(plan.startSlot), finalSlot, reason: 'bola harus berakhir di penempatan');
        }
      }
    });

    test('tiap tukar memakai dua slot berbeda dalam rentang, dan akhirnya cangkir menempati slot berbeda', () {
      final plan = CupShuffle.plan(Random(5), finalSlot: 2);
      for (final (a, b) in plan.swaps) {
        expect(a, isNot(b));
        expect(a, inInclusiveRange(0, GamblerTuning.cupCount - 1));
        expect(b, inInclusiveRange(0, GamblerTuning.cupCount - 1));
      }
      final slots = {for (var c = 0; c < GamblerTuning.cupCount; c++) plan.slotAfter(c, plan.swaps.length)};
      expect(slots.length, GamblerTuning.cupCount);
      final spread = {for (var c = 0; c < GamblerTuning.cupCount; c++) plan.spreadSlot(c)};
      expect(spread.length, GamblerTuning.cupCount, reason: 'penjajaran ulang adalah permutasi');
    });

    test('posisi bola sebelum penyatuan tidak berkaitan dengan posisi akhirnya (merata 10.000 percobaan)', () {
      final rng = Random(77);
      var same = 0;
      const trials = 10000;
      for (var i = 0; i < trials; i++) {
        final finalSlot = rng.nextInt(GamblerTuning.cupCount);
        final plan = CupShuffle.plan(rng, finalSlot: finalSlot);
        if (plan.mergeSlot == finalSlot) same++;
      }
      // kebetulan sama = 1/4; kalau bola selalu kembali ke slot yang sama, angkanya 100%
      expect(same / trials, closeTo(0.25, 0.03));
    });

    test('posisi tampilan selalu di dalam rentang slot dan lengkungan 0 sampai 1', () {
      final plan = CupShuffle.plan(Random(8), finalSlot: 1);
      for (var c = 0; c < GamblerTuning.cupCount; c++) {
        for (var i = 0; i <= 100; i++) {
          final pos = plan.positionOf(c, i / 100);
          expect(pos.slot, inInclusiveRange(0, GamblerTuning.cupCount - 1));
          expect(pos.arc, inInclusiveRange(0, 1));
        }
      }
    });

    test('rencana acakan memakai pengacak sendiri sehingga penempatan hasil tidak berubah', () {
      final a = CupRound(Random(3));
      CupShuffle.plan(Random(1), finalSlot: a.placement);
      CupShuffle.plan(Random(2), finalSlot: a.placement);
      expect(CupRound(Random(3)).placement, a.placement);
    });
  });

  group('Pelaporan sesi', () {
    /// Memainkan step dengan hasil yang diminta lewat pilihan yang diketahui dari penempatan.
    StepOutcome play(GamblerRun run, int step, {required bool win}) {
      final round = run.beginStep(step);
      final winning = step == 1 ? (round.placement + 1) % round.optionCount : round.placement;
      final losing = step == 1 ? round.placement : (round.placement + 1) % round.optionCount;
      final outcome = run.confirm(win ? winning : losing);
      expect(outcome.won, win);
      run.commit();
      return outcome;
    }

    test('menang tiga step memberi 3 bintang dan sesi selesai', () {
      final session = LevelSession();
      final run = GamblerRun(session, random: Random(1));
      play(run, 1, win: true);
      expect(session.step, 2);
      expect(session.isPlaying, isTrue);
      play(run, 2, win: true);
      expect(session.step, 3);
      play(run, 3, win: true);
      expect(session.isFinished, isTrue);
      expect(session.stepsWon, 3);
      expect(session.stars, 3);
    });

    test('kalah di step 2 memberi 1 bintang', () {
      final session = LevelSession();
      final run = GamblerRun(session, random: Random(2));
      play(run, 1, win: true);
      play(run, 2, win: false);
      expect(session.isFinished, isTrue);
      expect(session.stars, 1);
    });

    test('kalah di step 3 memberi 2 bintang', () {
      final session = LevelSession();
      final run = GamblerRun(session, random: Random(3));
      play(run, 1, win: true);
      play(run, 2, win: true);
      play(run, 3, win: false);
      expect(session.isFinished, isTrue);
      expect(session.stars, 2);
    });

    test('kalah di step 1 memberi 0 bintang', () {
      final session = LevelSession();
      final run = GamblerRun(session, random: Random(4));
      play(run, 1, win: false);
      expect(session.isFinished, isTrue);
      expect(session.stars, 0);
    });

    test('commit hanya sekali dan tidak melapor sebelum pemain memilih', () {
      final session = LevelSession();
      final run = GamblerRun(session, random: Random(5));
      run.beginStep(1);
      run.commit(); // belum ada pilihan
      expect(session.stepsWon, 0);
      expect(session.isPlaying, isTrue);

      final round = run.round!;
      run.confirm((round.placement + 1) % round.optionCount); // kartu aman
      run.commit();
      run.commit();
      expect(session.stepsWon, 1);
      expect(run.committed, isTrue);
    });

    test('hasil sesi mengikuti peluang: 20.000 sesi dengan pilihan acak, rata-rata bintang mendekati 1,2', () {
      final rng = Random(31);
      final picker = Random(32);
      var stars = 0;
      var threeStars = 0;
      const sessions = 20000;
      for (var i = 0; i < sessions; i++) {
        final session = LevelSession();
        final run = GamblerRun(session, random: rng);
        while (session.isPlaying) {
          final round = run.beginStep(session.step);
          run.confirm(picker.nextInt(round.optionCount));
          run.commit();
        }
        stars += session.stars;
        if (session.stars == 3) threeStars++;
      }
      // 0,75 + 0,75*0,5 + 0,75*0,5*0,25 = 1,21875 bintang; 3 bintang = 0,09375
      expect(stars / sessions, closeTo(1.21875, 0.04));
      expect(threeStars / sessions, closeTo(0.09375, 0.015));
    });
  });

  group('Registri', () {
    test("levelById('gambler') ada dengan nomor 6 dan tersedia", () {
      final level = levelById('gambler');
      expect(level, isNotNull);
      expect(level!.number, 6);
      expect(level.available, isTrue);
      expect(level.bossName, 'Mr. Lexi the Gambler');
      expect(level.bossImage, 'assets/images/gambler/boss_idle.png');
      expect(levelRegistry[5].id, 'gambler'); // level ke-6; Level 7 (rhythm) menyusul di belakangnya
      expect(levelRegistry.map((l) => l.number).toList().sublist(0, 6), [1, 2, 3, 4, 5, 6]);
    });
  });
}
