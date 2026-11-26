import 'dart:math';

import 'memory_config.dart';

/// Urutan pad satu step. Dibuat dari [Random] yang diberikan dari luar (injeksi), jadi tes memakai seed tetap,
/// sedangkan game asli memakai urutan baru tiap percobaan. Ronde r memakai awalan sepanjang
/// [memoryLengthOf]; tiap ronde menambah satu simbol baru di belakang urutan sebelumnya.
///
/// Aturan: (1) tiga simbol sama berturut-turut dilarang, dua boleh; (2) semua pad muncul sedikitnya sekali pada
/// urutan ronde terakhir.
class MemorySequence {
  MemorySequence(this.step, List<int> symbols)
      : padCount = memoryPadsOf(step),
        symbols = List<int>.unmodifiable(symbols);

  final int step;
  final int padCount;

  /// Seluruh simbol sampai ronde terakhir.
  final List<int> symbols;

  /// Panjang sampai ronde terakhir.
  int get length => symbols.length;

  /// Panjang urutan pada ronde [round] (mulai 1).
  int lengthOfRound(int round) => memoryLengthOf(step, round);

  /// Urutan yang harus diingat pada ronde [round] (mulai 1).
  List<int> forRound(int round) => symbols.sublist(0, lengthOfRound(round));

  /// Membuat urutan lengkap untuk [step] dari [random].
  factory MemorySequence.generate(int step, Random random) {
    final total = memoryFinalLengthOf(step);
    final pads = memoryPadsOf(step);
    final symbols = <int>[];
    while (symbols.length < total) {
      symbols.add(nextSymbol(symbols, pads, total, random));
    }
    return MemorySequence(step, symbols);
  }

  /// Memilih satu simbol baru setelah [soFar]. [total] = panjang urutan akhir (untuk menjamin semua pad muncul).
  /// Simbol baru tidak membuat tiga simbol sama berturut-turut; bila sisa tempat hanya cukup untuk pad yang belum
  /// pernah muncul, pilihannya dibatasi ke pad itu.
  static int nextSymbol(List<int> soFar, int padCount, int total, Random random) {
    final seen = soFar.toSet();
    final unseen = [for (var p = 0; p < padCount; p++) if (!seen.contains(p)) p];
    final slotsAfter = total - soFar.length - 1;

    // Bila memilih pad yang sudah pernah muncul membuat pad yang belum muncul tak lagi muat, wajib pilih yang baru.
    if (unseen.isNotEmpty && unseen.length > slotsAfter) {
      return unseen[random.nextInt(unseen.length)];
    }

    final candidates = <int>[];
    for (var p = 0; p < padCount; p++) {
      if (!_makesRun(soFar, p)) candidates.add(p);
    }
    return candidates[random.nextInt(candidates.length)];
  }

  /// Menambah [symbol] membuat lebih dari [memoryMaxRepeat] simbol sama berturut-turut.
  static bool _makesRun(List<int> soFar, int symbol) {
    if (soFar.length < memoryMaxRepeat) return false;
    for (var i = 1; i <= memoryMaxRepeat; i++) {
      if (soFar[soFar.length - i] != symbol) return false;
    }
    return true;
  }

  /// Memeriksa aturan urutan; dipakai tes.
  static bool followsRules(List<int> symbols, int padCount) {
    for (var i = memoryMaxRepeat; i < symbols.length; i++) {
      var same = true;
      for (var j = 1; j <= memoryMaxRepeat; j++) {
        if (symbols[i - j] != symbols[i]) same = false;
      }
      if (same) return false;
    }
    for (final s in symbols) {
      if (s < 0 || s >= padCount) return false;
    }
    return symbols.toSet().length == padCount;
  }
}
