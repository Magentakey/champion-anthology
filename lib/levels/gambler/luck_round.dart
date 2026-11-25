import 'dart:math';

import '../../core/level/level_session.dart';
import 'gambler_config.dart';

/// Satu ronde permainan peluang. Logika murni (tanpa Flame, tanpa Flutter), sehingga mudah diuji.
///
/// Aturan keadilan:
///  1. Penempatan ([placement]) ditentukan di konstruktor, sebelum pemain memilih, dan tidak pernah berubah.
///  2. [resolve] hanya membandingkan pilihan dengan penempatan. Pilihan mana pun punya peluang menang yang sama.
///  3. Tidak ada status riwayat: satu-satunya masukan adalah `Random` yang diberikan dari luar.
abstract class LuckRound {
  const LuckRound();

  /// Ronde untuk [step] (1..3) dengan pengacak [rng].
  factory LuckRound.forStep(int step, Random rng) => switch (gamblerGameOf(step)) {
        LuckGame.card => CardRound(rng),
        LuckGame.coin => CoinRound(rng),
        LuckGame.cup => CupRound(rng),
      };

  LuckGame get game;

  /// Jumlah pilihan (kartu, sisi koin, atau cangkir).
  int get optionCount;

  /// Hasil yang sudah ditempatkan. Kartu: indeks kartu sial. Koin: sisi yang mendarat (0 kepala, 1 ekor).
  /// Cangkir: indeks cangkir yang berbola (posisi akhir setelah diacak).
  int get placement;

  /// Peluang menang yang ditampilkan di layar.
  double get winChance;

  /// True jika pilihan [pick] menang. Tidak mengubah apa pun.
  bool resolve(int pick);

  void checkPick(int pick) {
    if (pick < 0 || pick >= optionCount) {
      throw RangeError.range(pick, 0, optionCount - 1, 'pick');
    }
  }
}

/// Step 1: 4 kartu tertutup, satu kartu sial. Menang jika bukan kartu sial (peluang 3 dari 4).
class CardRound extends LuckRound {
  CardRound(Random rng) : placement = rng.nextInt(GamblerTuning.cardCount);

  @override
  final int placement;

  @override
  LuckGame get game => LuckGame.card;

  @override
  int get optionCount => GamblerTuning.cardCount;

  @override
  double get winChance => gamblerChanceOf(1);

  /// Indeks kartu sial.
  int get bombIndex => placement;

  @override
  bool resolve(int pick) {
    checkPick(pick);
    return pick != placement;
  }
}

/// Sisi koin.
enum CoinSide { head, tail }

/// Step 2: koin dilempar. Menang jika sisi pilihan sama dengan sisi yang mendarat (peluang 1 dari 2).
class CoinRound extends LuckRound {
  CoinRound(Random rng) : placement = rng.nextInt(GamblerTuning.coinSides);

  @override
  final int placement;

  @override
  LuckGame get game => LuckGame.coin;

  @override
  int get optionCount => GamblerTuning.coinSides;

  @override
  double get winChance => gamblerChanceOf(2);

  /// Sisi yang mendarat.
  CoinSide get landed => CoinSide.values[placement];

  @override
  bool resolve(int pick) {
    checkPick(pick);
    return pick == placement;
  }
}

/// Step 3: bola di bawah satu dari 4 cangkir. Menang jika cangkir pilihan berbola (peluang 1 dari 4).
class CupRound extends LuckRound {
  CupRound(Random rng) : placement = rng.nextInt(GamblerTuning.cupCount);

  @override
  final int placement;

  @override
  LuckGame get game => LuckGame.cup;

  @override
  int get optionCount => GamblerTuning.cupCount;

  @override
  double get winChance => gamblerChanceOf(3);

  /// Indeks cangkir berbola.
  int get ballIndex => placement;

  @override
  bool resolve(int pick) {
    checkPick(pick);
    return pick == placement;
  }
}

/// Rencana acakan cangkir yang hanya hiasan. Bola SELALU berakhir di [finalSlot] (= penempatan yang sudah
/// ditentukan), tetapi jalannya sengaja tidak bisa diikuti: setelah tukar-tukar cangkir ada tahap
/// penyatuan (semua cangkir menumpuk di tengah), dan saat dijajarkan lagi cangkir berbola dikirim ke
/// [finalSlot] sedangkan tiga lainnya diacak ke slot sisa. Posisi bola sebelum penyatuan ([mergeSlot])
/// dipilih acak dan tidak berhubungan dengan [finalSlot].
class CupShuffle {
  const CupShuffle._(this.swaps, this.startSlot, this.mergeSlot, this.finalSlot, this.cups, this._spread);

  /// Pasangan slot yang ditukar berurutan (sebelum penyatuan).
  final List<(int, int)> swaps;

  /// Slot awal cangkir yang menutupi bola, slot cangkir itu tepat sebelum penyatuan, dan slot akhirnya.
  final int startSlot;
  final int mergeSlot;
  final int finalSlot;
  final int cups;
  final List<int> _spread;

  /// Membuat rencana. [rng] hanya untuk tampilan (tidak mengubah hasil).
  factory CupShuffle.plan(
    Random rng, {
    required int finalSlot,
    int cups = GamblerTuning.cupCount,
    int swapCount = GamblerTuning.shuffleSwaps,
  }) {
    final swaps = <(int, int)>[];
    for (var i = 0; i < swapCount; i++) {
      final a = rng.nextInt(cups);
      var b = rng.nextInt(cups - 1);
      if (b >= a) b++; // dijamin berbeda dari a
      swaps.add((a, b));
    }
    // Susunan sebelum penyatuan dibuat acak (bebas dari finalSlot); rencana tukar dihitung mundur darinya.
    final mergeSlot = rng.nextInt(cups);
    var slot = mergeSlot;
    for (var i = swaps.length - 1; i >= 0; i--) {
      slot = _swapSlot(slot, swaps[i]);
    }
    final start = slot;

    // Penjajaran ulang: cangkir berbola -> finalSlot, cangkir lain -> slot sisa dalam urutan acak.
    final rest = [for (var s = 0; s < cups; s++) if (s != finalSlot) s]..shuffle(rng);
    final spread = List<int>.filled(cups, 0);
    var k = 0;
    for (var c = 0; c < cups; c++) {
      spread[c] = c == start ? finalSlot : rest[k++];
    }
    return CupShuffle._(List.unmodifiable(swaps), start, mergeSlot, finalSlot, cups, List.unmodifiable(spread));
  }

  static int _swapSlot(int slot, (int, int) swap) {
    if (slot == swap.$1) return swap.$2;
    if (slot == swap.$2) return swap.$1;
    return slot;
  }

  /// Slot cangkir yang semula di [initialSlot] setelah [count] tukar pertama (sebelum penyatuan).
  int slotAfter(int initialSlot, int count) {
    var slot = initialSlot;
    for (var i = 0; i < count && i < swaps.length; i++) {
      slot = _swapSlot(slot, swaps[i]);
    }
    return slot;
  }

  /// Slot akhir (setelah dijajarkan ulang) cangkir yang semula di [initialSlot].
  int spreadSlot(int initialSlot) => _spread[initialSlot];

  /// Posisi tampilan cangkir yang semula di [initialSlot] pada kemajuan [progress] (0..1):
  /// `slot` pecahan (dari satu slot ke slot lain) dan `arc` 0..1 untuk lengkung naik saat bergeser.
  ({double slot, double arc}) positionOf(int initialSlot, double progress) {
    final n = swaps.length;
    if (n == 0) return (slot: initialSlot.toDouble(), arc: 0.0);
    final p = progress.clamp(0.0, 1.0).toDouble() * n;
    final k = min(n - 1, p.floor());
    final u = p - k;
    final from = slotAfter(initialSlot, k);
    final to = slotAfter(initialSlot, k + 1);
    if (from == to) return (slot: from.toDouble(), arc: 0.0);
    final eased = u * u * (3 - 2 * u);
    return (slot: from + (to - from) * eased, arc: sin(pi * u));
  }
}

/// Hasil satu step setelah pemain memilih.
class StepOutcome {
  const StepOutcome({
    required this.step,
    required this.game,
    required this.pick,
    required this.placement,
    required this.won,
  });

  final int step;
  final LuckGame game;
  final int pick;
  final int placement;
  final bool won;
}

/// Satu percobaan level: membuat ronde tiap step dan melapor menang atau kalah ke [LevelSession].
/// Logika murni di luar Flame, jadi pelaporan sesi bisa diuji tanpa mesin game.
class GamblerRun {
  GamblerRun(this.session, {Random? random}) : _rng = random ?? Random();

  final LevelSession session;
  final Random _rng;

  LuckRound? _round;
  StepOutcome? _outcome;
  bool _committed = false;
  int _step = 1;

  LuckRound? get round => _round;
  StepOutcome? get outcome => _outcome;
  bool get committed => _committed;

  /// Mulai ronde baru untuk [step]. Penempatan sudah tetap setelah baris ini, sebelum pemain memilih.
  LuckRound beginStep(int step) {
    final round = LuckRound.forStep(step, _rng);
    _round = round;
    _outcome = null;
    _committed = false;
    _step = step;
    return round;
  }

  /// Pemain memilih [pick]. Hanya pilihan pertama yang dihitung; panggilan berikutnya mengembalikan
  /// hasil yang sama, jadi mengganti pilihan setelah konfirmasi tidak mengubah apa pun.
  StepOutcome confirm(int pick) {
    final existing = _outcome;
    if (existing != null) return existing;
    final round = _round;
    if (round == null) throw StateError('beginStep belum dipanggil');
    final outcome = StepOutcome(
      step: _step,
      game: round.game,
      pick: pick,
      placement: round.placement,
      won: round.resolve(pick),
    );
    _outcome = outcome;
    return outcome;
  }

  /// Lapor hasil ke sesi: menang = [LevelSession.winStep], kalah = [LevelSession.loseStep].
  void commit() {
    final outcome = _outcome;
    if (outcome == null || _committed) return;
    _committed = true;
    if (outcome.won) {
      session.winStep();
    } else {
      session.loseStep();
    }
  }
}
