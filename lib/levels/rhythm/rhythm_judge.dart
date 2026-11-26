import 'rhythm_chart.dart';
import 'rhythm_config.dart';

/// Ketepatan satu ketukan.
enum Judgment { perfect, good, miss }

/// Penilai ritme murni Dart (tanpa Flame): mencocokkan ketukan ke not, menghitung akurasi dan combo.
///
/// Waktu selalu dalam detik pada jam permainan (detik sejak ketukan pertama lagu). Selisih dihitung dalam
/// satuan 0,1 ms yang dibulatkan, jadi batas tepat 50 ms dan 110 ms tidak terganggu galat pecahan.
///  - PERFECT: selisih sampai 50 ms. GOOD: di atas 50 sampai 110 ms.
///  - Ketukan memilih not belum dinilai paling awal di jalurnya; bila not itu lebih dari 110 ms dari ketukan,
///    ketukan diabaikan (tanpa hukuman). Satu ketukan hanya untuk satu not.
///  - Not yang lewat 130 ms tanpa ketukan menjadi MISS.
class RhythmJudge {
  RhythmJudge(List<RhythmNote> notes, {required this.threshold, this.offset = 0})
      : notes = List.unmodifiable(notes),
        _results = List<Judgment?>.filled(notes.length, null),
        _byLane = List.generate(rhythmLaneCount, (_) => <int>[]),
        _next = List<int>.filled(rhythmLaneCount, 0) {
    for (var i = 0; i < notes.length; i++) {
      _byLane[notes[i].lane].add(i);
    }
    for (final lane in _byLane) {
      lane.sort((a, b) => this.notes[a].time.compareTo(this.notes[b].time));
    }
  }

  /// Penilai untuk lagu [chart] pada [step].
  factory RhythmJudge.forStep(int step, {RhythmChart? chart, double offset = 0}) =>
      RhythmJudge((chart ?? RhythmChart.forStep(step)).notes, threshold: rhythmThresholdOf(step), offset: offset);

  final List<RhythmNote> notes;

  /// Ambang lulus (0..1).
  final double threshold;

  /// Pergeseran jadwal not terhadap jam (detik); positif = not tiba lebih lambat. Dari offset kalibrasi.
  double offset;

  final List<Judgment?> _results;
  final List<List<int>> _byLane;
  final List<int> _next;
  final List<int> _pendingMisses = [];

  int _perfect = 0;
  int _good = 0;
  int _miss = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _missStreak = 0;
  int _lastTapped = -1;

  static const int _unit = 10000; // detik -> satuan 0,1 ms

  static int _tenthMs(int ms) => ms * 10;

  int get total => notes.length;
  int get perfects => _perfect;
  int get goods => _good;
  int get misses => _miss;
  int get judged => _perfect + _good + _miss;
  int get remaining => total - judged;
  bool get isFinished => judged >= total;

  /// Combo berjalan: naik tiap PERFECT atau GOOD, putus saat MISS. Hanya hiasan, tidak masuk akurasi.
  int get combo => _combo;
  int get maxCombo => _maxCombo;

  /// MISS berturut-turut sampai sekarang (0 setelah ada PERFECT atau GOOD).
  int get missStreak => _missStreak;

  /// Nilai pada satuan setengah poin: PERFECT 2, GOOD 1, MISS 0.
  int get _halfPoints => 2 * _perfect + _good;

  /// Akurasi akhir = (PERFECT x 1 + GOOD x 0,5) dibagi jumlah not. Not yang belum dinilai dihitung 0,
  /// jadi nilainya naik bertahap menuju akhir lagu.
  double get accuracy => total == 0 ? 0 : (rhythmPerfectScore * _perfect + rhythmGoodScore * _good) / total;

  /// Akurasi sementara = nilai dibagi not yang sudah dinilai; yang ditampilkan di bar semangat.
  double get runningAccuracy => judged == 0 ? 0 : (rhythmPerfectScore * _perfect + rhythmGoodScore * _good) / judged;

  int get _thresholdPercent => (threshold * 100).round();

  /// Apakah nilai [halfPoints] (satuan setengah poin) mencapai ambang. Dihitung dengan bilangan bulat.
  bool _meets(int halfPoints) => 100 * halfPoints >= 2 * total * _thresholdPercent;

  /// Terkunci: sisa not tidak mungkin lagi menutup ambang walau semuanya PERFECT. Step langsung gagal.
  bool get isLocked => !_meets(_halfPoints + 2 * remaining);

  /// Lulus: semua not sudah dinilai dan akurasi mencapai ambang.
  bool get passed => isFinished && _meets(_halfPoints);

  /// Hasil not ke-[index] (null = belum dinilai).
  Judgment? resultOf(int index) => _results[index];

  /// Indeks not yang dinilai oleh [tap] terakhir (-1 bila diabaikan).
  int get lastTappedIndex => _lastTapped;

  /// Waktu not ke-[index] pada jam permainan, sudah memakai [offset].
  double timeOf(int index) => notes[index].time + offset;

  /// Ketukan pada [lane] di waktu [time]. Mengembalikan nilainya, atau null bila diabaikan.
  Judgment? tap(int lane, double time) {
    _lastTapped = -1;
    if (lane < 0 || lane >= rhythmLaneCount) return null;
    _expire(time);
    final queue = _byLane[lane];
    final pointer = _next[lane];
    if (pointer >= queue.length) return null;
    final index = queue[pointer];
    final delta = ((time - timeOf(index)) * _unit).round().abs();
    final Judgment judgment;
    if (delta <= _tenthMs(RhythmTuning.perfectWindowMs)) {
      judgment = Judgment.perfect;
    } else if (delta <= _tenthMs(RhythmTuning.goodWindowMs)) {
      judgment = Judgment.good;
    } else {
      return null;
    }
    _next[lane] = pointer + 1;
    _lastTapped = index;
    _record(index, judgment);
    return judgment;
  }

  /// Menandai MISS untuk not yang sudah lewat 130 ms pada waktu [now]. Mengembalikan indeks not yang baru
  /// menjadi MISS sejak panggilan sebelumnya (termasuk yang ditandai di dalam [tap]).
  List<int> advance(double now) {
    _expire(now);
    if (_pendingMisses.isEmpty) return const [];
    final out = List<int>.of(_pendingMisses);
    _pendingMisses.clear();
    return out;
  }

  void _expire(double now) {
    final limit = _tenthMs(RhythmTuning.missWindowMs);
    for (var lane = 0; lane < rhythmLaneCount; lane++) {
      final queue = _byLane[lane];
      while (_next[lane] < queue.length) {
        final index = queue[_next[lane]];
        final late = ((now - timeOf(index)) * _unit).round();
        if (late <= limit) break;
        _next[lane]++;
        _record(index, Judgment.miss);
        _pendingMisses.add(index);
      }
    }
  }

  void _record(int index, Judgment judgment) {
    _results[index] = judgment;
    switch (judgment) {
      case Judgment.perfect:
        _perfect++;
        _combo++;
        _missStreak = 0;
      case Judgment.good:
        _good++;
        _combo++;
        _missStreak = 0;
      case Judgment.miss:
        _miss++;
        _combo = 0;
        _missStreak++;
    }
    if (_combo > _maxCombo) _maxCombo = _combo;
  }
}
