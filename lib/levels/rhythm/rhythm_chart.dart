import 'dart:math';

import 'rhythm_config.dart';

/// Satu not: waktu jatuh di garis ketuk (detik sejak ketukan pertama lagu) dan jalur (0..3).
class RhythmNote {
  const RhythmNote(this.time, this.lane);

  final double time;
  final int lane;

  @override
  bool operator ==(Object other) => other is RhythmNote && other.time == time && other.lane == lane;

  @override
  int get hashCode => Object.hash(time, lane);

  @override
  String toString() => 'RhythmNote($time, $lane)';
}

/// Aturan pembuatan not yang tidak berubah-ubah. Dipisah dari konfigurasi karena ini aturan generator.
class ChartRules {
  const ChartRules._();

  /// Tidak ada not dalam 1 detik pertama dan 1 detik terakhir lagu.
  static const int edgeSeconds = 1;

  /// Jarak minimal dua not di jalur yang sama, supaya bisa diketuk dua kali dengan jari yang sama.
  static const double sameLaneGapSeconds = 0.25;

  /// Jarak minimal antar waktu not (tidak ada tumpukan not yang terlalu rapat).
  static const double onsetGapSeconds = 0.2;

  /// Paling banyak dua not berurutan di jalur yang sama.
  static const int maxSameLaneRun = 2;

  /// Peluang not jatuh di posisi seperempat ketukan (hanya Step 3, kisi 4 per ketukan).
  static const double sixteenthChance = 0.3;

  /// Batas percobaan ulang dengan seed turunan bila satu susunan tak memenuhi aturan.
  static const int maxAttempts = 200;
}

/// Kecenderungan perpindahan jalur antar not.
enum LaneBias { near, neutral, far }

/// Satu lagu: tempo, panjang, dan daftar not yang TETAP (dibuat generator deterministik dengan seed).
/// Hasilnya sama setiap kali, jadi pemain bisa berlatih. Tidak ada pengacak saat bermain.
class RhythmChart {
  const RhythmChart({required this.bpm, required this.bars, required this.notes, required this.gridPerBeat});

  final int bpm;
  final int bars;

  /// Kisi waktu: 2 = ketukan penuh dan setengah ketukan, 4 = sampai seperempat ketukan.
  final int gridPerBeat;

  /// Urut menurut waktu, lalu jalur.
  final List<RhythmNote> notes;

  double get beatSeconds => 60 / bpm;
  double get duration => bars * RhythmTuning.beatsPerBar * 60 / bpm;
  int get noteCount => notes.length;

  /// Jumlah pasangan not bersamaan.
  int get doubleCount {
    var count = 0;
    for (var i = 1; i < notes.length; i++) {
      if (notes[i].time == notes[i - 1].time) count++;
    }
    return count;
  }

  static final Map<int, RhythmChart> _cache = {};

  /// Lagu untuk [step] (1..3), dibuat sekali dari konfigurasi lalu disimpan.
  static RhythmChart forStep(int step) {
    final s = step.clamp(1, rhythmBpm.length).toInt();
    return _cache.putIfAbsent(
      s,
      () => RhythmChart.generate(
        bpm: rhythmBpmOf(s),
        bars: rhythmBarsOf(s),
        noteCount: rhythmNoteCountOf(s),
        doubles: rhythmDoubleCount[s - 1],
        seed: rhythmSeeds[s - 1],
        gridPerBeat: s >= 3 ? 4 : 2,
        maxLaneJump: s == 1 ? 2 : 3,
        bias: s == 1
            ? LaneBias.near
            : s == 2
                ? LaneBias.neutral
                : LaneBias.far,
      ),
    );
  }

  /// Membuat lagu dengan aturan:
  ///  1. Not hanya di kisi ketukan ([gridPerBeat] 2 = penuh dan setengah, 4 = sampai seperempat).
  ///  2. Paling banyak 2 not berurutan di jalur yang sama; lompatan antar jalur paling jauh [maxLaneJump].
  ///  3. Pasangan not bersamaan sebanyak [doubles], tidak pernah di jalur yang sama.
  ///  4. Jarak minimal 0,25 detik antar not di jalur yang sama.
  ///  5. Tidak ada not dalam 1 detik pertama dan 1 detik terakhir.
  ///  6. Jumlah not tepat [noteCount] (satu pasangan bersamaan menyumbang dua not).
  /// Seed yang sama selalu menghasilkan lagu yang sama.
  factory RhythmChart.generate({
    required int bpm,
    required int bars,
    required int noteCount,
    required int doubles,
    required int seed,
    int gridPerBeat = 2,
    int maxLaneJump = 3,
    LaneBias bias = LaneBias.neutral,
  }) {
    final onsets = noteCount - doubles;
    if (onsets < 1 || doubles < 0 || doubles > onsets) {
      throw ArgumentError('noteCount dan doubles tidak cocok: $noteCount, $doubles');
    }
    for (var attempt = 0; attempt < ChartRules.maxAttempts; attempt++) {
      final rng = Random(seed + attempt * 7919);
      final notes = _tryBuild(rng, bpm, bars, onsets, doubles, gridPerBeat, maxLaneJump, bias);
      if (notes != null) {
        return RhythmChart(bpm: bpm, bars: bars, notes: List.unmodifiable(notes), gridPerBeat: gridPerBeat);
      }
    }
    throw StateError('Gagal membuat lagu dari seed $seed setelah ${ChartRules.maxAttempts} percobaan');
  }

  static int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

  /// Satu percobaan; null bila aturan tak terpenuhi (generator lalu mencoba seed turunan).
  static List<RhythmNote>? _tryBuild(
    Random rng,
    int bpm,
    int bars,
    int onsets,
    int doubles,
    int grid,
    int maxJump,
    LaneBias bias,
  ) {
    final slotsPerSecondDen = bpm * grid; // waktu = indeks * 60 / (bpm * grid)
    final total = bars * RhythmTuning.beatsPerBar * grid;
    final edgeSlots = _ceilDiv(slotsPerSecondDen * ChartRules.edgeSeconds, 60);
    final minSlot = edgeSlots;
    final maxSlot = total - edgeSlots;
    final usable = maxSlot - minSlot + 1;
    if (usable < onsets) return null;

    // jarak minimal antar waktu not dan antar not sejalur, dalam jumlah slot
    var minGap = 1;
    while (minGap * 60 / slotsPerSecondDen < ChartRules.onsetGapSeconds) {
      minGap++;
    }
    var sameLaneGap = 1;
    while (sameLaneGap * 60 / slotsPerSecondDen < ChartRules.sameLaneGapSeconds - 1e-9) {
      sameLaneGap++;
    }

    // 1) waktu: satu not per segmen sama panjang, supaya tersebar merata
    final slots = <int>[];
    var prev = minSlot - minGap;
    for (var k = 0; k < onsets; k++) {
      final lo = minSlot + (usable * k) ~/ onsets;
      final hi = minSlot + (usable * (k + 1)) ~/ onsets; // eksklusif
      var slot = lo + rng.nextInt(max(1, hi - lo));
      if (grid == 4 && slot.isOdd && rng.nextDouble() >= ChartRules.sixteenthChance) {
        slot = slot > lo ? slot - 1 : slot + 1;
      }
      slot = max(slot, prev + minGap);
      if (slot > maxSlot) return null;
      slots.add(slot);
      prev = slot;
    }

    // 2) onset mana yang berpasangan: satu per segmen, tidak di tiga onset pertama
    final isDouble = List<bool>.filled(onsets, false);
    if (doubles > 0) {
      const skip = 3;
      final span = onsets - skip;
      if (span < doubles) return null;
      for (var d = 0; d < doubles; d++) {
        final lo = skip + (span * d) ~/ doubles;
        final hi = skip + (span * (d + 1)) ~/ doubles;
        isDouble[lo + rng.nextInt(max(1, hi - lo))] = true;
      }
    }

    // 3) jalur untuk tiap onset
    final lastSlot = List<int>.filled(rhythmLaneCount, -1000000);
    final run = List<int>.filled(rhythmLaneCount, 0);
    var prevLanes = <int>[];
    final result = <RhythmNote>[];
    for (var i = 0; i < onsets; i++) {
      final slot = slots[i];
      final allowed = <int>[];
      for (var lane = 0; lane < rhythmLaneCount; lane++) {
        if (slot - lastSlot[lane] < sameLaneGap) continue;
        if (run[lane] >= ChartRules.maxSameLaneRun) continue;
        if (prevLanes.isNotEmpty) {
          var nearest = rhythmLaneCount;
          for (final p in prevLanes) {
            nearest = min(nearest, (lane - p).abs());
          }
          if (nearest > maxJump) continue;
        }
        allowed.add(lane);
      }
      final need = isDouble[i] ? 2 : 1;
      if (allowed.length < need) return null;

      final chosen = <int>[];
      final pool = [...allowed];
      for (var n = 0; n < need; n++) {
        final lane = _weightedPick(rng, pool, prevLanes, bias);
        chosen.add(lane);
        pool.remove(lane);
      }
      chosen.sort();
      for (var lane = 0; lane < rhythmLaneCount; lane++) {
        if (chosen.contains(lane)) {
          run[lane]++;
          lastSlot[lane] = slot;
        } else {
          run[lane] = 0;
        }
      }
      final time = slot * 60 / slotsPerSecondDen;
      for (final lane in chosen) {
        result.add(RhythmNote(time, lane));
      }
      prevLanes = chosen;
    }
    return result;
  }

  static int _weightedPick(Random rng, List<int> pool, List<int> prevLanes, LaneBias bias) {
    if (pool.length == 1 || bias == LaneBias.neutral || prevLanes.isEmpty) {
      return pool[rng.nextInt(pool.length)];
    }
    final weights = <int>[];
    var sum = 0;
    for (final lane in pool) {
      var jump = rhythmLaneCount;
      for (final p in prevLanes) {
        jump = min(jump, (lane - p).abs());
      }
      final w = bias == LaneBias.near ? max(1, 4 - jump) : 1 + jump;
      weights.add(w);
      sum += w;
    }
    var pick = rng.nextInt(sum);
    for (var i = 0; i < pool.length; i++) {
      pick -= weights[i];
      if (pick < 0) return pool[i];
    }
    return pool.last;
  }
}
