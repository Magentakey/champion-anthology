import 'dart:math';

import '../../core/level/level_session.dart';
import 'rhythm_chart.dart';
import 'rhythm_config.dart';
import 'rhythm_judge.dart';

/// Tahap satu step: banner ronde, hitung mundur satu bar, bermain, hitung mundur setelah jeda,
/// hasil, dan jeda sebelum step berikutnya.
enum RhythmPhase { idle, intro, countdown, playing, resuming, result, gap, done }

/// Mesin tahap Level 7 yang murni Dart (tanpa Flame, mudah dites): jam permainan, penilai, dan pelaporan
/// ke [LevelSession]. [LevelSession.winStep] atau [LevelSession.loseStep] dipanggil tepat sekali per step.
///
/// Jam permainan ([clock]) adalah acuan penilaian: detik sejak ketukan pertama lagu. Jam mulai negatif
/// (selama hitung mundur satu bar) dan bernilai 0 saat lagu dimulai. Posisi pemutar audio tidak dipakai.
class RhythmRun {
  RhythmRun(this.session, {int Function()? offsetMs, RhythmChart Function(int step)? chartFor})
      : _offsetMs = offsetMs ?? (() => RhythmTuning.defaultOffsetMs),
        _chartFor = chartFor ?? RhythmChart.forStep;

  final LevelSession session;
  final int Function() _offsetMs;
  final RhythmChart Function(int step) _chartFor;

  int _step = 1;
  RhythmChart? _chart;
  RhythmJudge? _judge;
  RhythmPhase _phase = RhythmPhase.idle;
  double _clock = 0;
  double _phaseTime = 0;
  int _lastBeat = -1;
  bool _passed = false;

  /// Dipanggil saat tahap berganti (dari, ke).
  void Function(RhythmPhase from, RhythmPhase to)? onPhase;

  /// Dipanggil tiap not selesai dinilai, baik oleh ketukan maupun karena lewat (MISS).
  void Function(int index, Judgment judgment)? onJudged;

  /// Dipanggil tiap ketukan hitung mundur ([beat] mulai 0, dari [total] ketukan).
  void Function(int beat, int total)? onCountBeat;

  /// Dipanggil saat hasil step sudah pasti (lulus atau gagal), sebelum jeda hasil.
  void Function(bool passed)? onStepResult;

  /// Dipanggil tepat sebelum sesi dilapori; kalimat layar hasil harus siap di sini.
  void Function(bool won)? onBeforeCommit;

  int get step => _step;
  RhythmChart? get chart => _chart;
  RhythmJudge? get judge => _judge;
  RhythmPhase get phase => _phase;

  /// Jam permainan (detik). Negatif selama hitung mundur awal.
  double get clock => _clock;

  /// Hasil step yang sedang atau baru selesai (lulus bila true).
  bool get passed => _passed;

  /// Lama hitung mundur awal dalam detik (satu bar).
  double get countdownSeconds => (_chart?.beatSeconds ?? 0) * RhythmTuning.countdownBeats;

  /// Ketukan hanya dinilai pada tahap bermain dan saat sesi berjalan.
  bool get acceptsTaps => _phase == RhythmPhase.playing && session.isPlaying;

  /// Memulai step [step] (1..3): memuat lagu dan penilai, lalu menampilkan banner ronde.
  void beginStep(int step) {
    _step = step.clamp(1, rhythmBpm.length).toInt();
    final chart = _chartFor(_step);
    _chart = chart;
    _judge = RhythmJudge(
      chart.notes,
      threshold: rhythmThresholdOf(_step),
      offset: _offsetMs() / 1000,
    );
    _clock = -countdownSeconds;
    _phaseTime = 0;
    _lastBeat = -1;
    _passed = false;
    _setPhase(RhythmPhase.intro);
  }

  /// Dipanggil setelah jeda berakhir. Bila sedang bermain, lagu dilanjutkan setelah hitung mundur 3 ketukan.
  void resumeFromPause() {
    if (_phase != RhythmPhase.playing) return;
    _phaseTime = 0;
    _lastBeat = -1;
    _setPhase(RhythmPhase.resuming);
  }

  /// Ketukan pada [lane]. [at] = waktu jam permainan saat peristiwa diterima (default: jam frame terakhir).
  /// Di luar tahap bermain ketukan tidak berpengaruh.
  Judgment? tap(int lane, {double? at}) {
    final judge = _judge;
    if (judge == null || !acceptsTaps) return null;
    final result = judge.tap(lane, at ?? _clock);
    _flushMisses(); // MISS yang ditemukan saat mencocokkan lebih tua daripada ketukan ini
    if (result != null) onJudged?.call(judge.lastTappedIndex, result);
    return result;
  }

  /// Memajukan permainan sebesar [dt] detik. Tidak berbuat apa-apa saat sesi dijeda atau selesai.
  void update(double dt) {
    if (!session.isPlaying) return;
    switch (_phase) {
      case RhythmPhase.idle:
      case RhythmPhase.done:
        return;
      case RhythmPhase.intro:
        _phaseTime += dt;
        if (_phaseTime * 1000 >= RhythmTuning.introMs) {
          _clock = -countdownSeconds;
          _lastBeat = -1;
          _setPhase(RhythmPhase.countdown);
        }
      case RhythmPhase.countdown:
        _clock += dt;
        final beat = _chart!.beatSeconds;
        final index = min(RhythmTuning.countdownBeats - 1, max(0, ((_clock + countdownSeconds) / beat).floor()));
        _tickBeats(index, RhythmTuning.countdownBeats);
        if (_clock >= 0) {
          _clock = 0; // lagu dan jam mulai bersama; kelebihan waktu frame dibuang
          _setPhase(RhythmPhase.playing);
        }
      case RhythmPhase.playing:
        _clock += dt;
        _judge!.offset = _offsetMs() / 1000;
        _flushMisses();
        if (_judge!.isLocked) {
          _finish(false); // mustahil lulus lagi: langsung gagal, tanpa menunggu lagu habis
        } else if (_clock >= _chart!.duration) {
          _judge!.advance(_clock + 1); // not yang tersisa dinilai MISS
          _flushMisses();
          _finish(_judge!.passed);
        }
      case RhythmPhase.resuming:
        _phaseTime += dt;
        final beat = _chart!.beatSeconds;
        final index = min(RhythmTuning.resumeCountdownBeats - 1, (_phaseTime / beat).floor());
        _tickBeats(index, RhythmTuning.resumeCountdownBeats);
        if (_phaseTime >= beat * RhythmTuning.resumeCountdownBeats) {
          _setPhase(RhythmPhase.playing);
        }
      case RhythmPhase.result:
        _phaseTime += dt;
        if (_phaseTime * 1000 >= RhythmTuning.resultMs) _commit();
      case RhythmPhase.gap:
        _phaseTime += dt;
        if (_phaseTime * 1000 >= RhythmTuning.stepGapMs) beginStep(session.step);
    }
  }

  void _tickBeats(int index, int total) {
    while (_lastBeat < index) {
      _lastBeat++;
      onCountBeat?.call(_lastBeat, total);
    }
  }

  void _flushMisses() {
    final judge = _judge;
    if (judge == null) return;
    for (final index in judge.advance(_clock)) {
      onJudged?.call(index, Judgment.miss);
    }
  }

  void _finish(bool passed) {
    _passed = passed;
    _phaseTime = 0;
    _setPhase(RhythmPhase.result);
    onStepResult?.call(passed);
  }

  /// Lapor ke sesi tepat sekali: tahap keluar dari [RhythmPhase.result] sebelum sesi diubah.
  void _commit() {
    final won = _passed;
    _phaseTime = 0;
    _setPhase(RhythmPhase.gap);
    onBeforeCommit?.call(won);
    if (won) {
      session.winStep();
    } else {
      session.loseStep();
    }
    if (!session.isPlaying) _setPhase(RhythmPhase.done);
  }

  void _setPhase(RhythmPhase to) {
    final from = _phase;
    _phase = to;
    onPhase?.call(from, to);
  }
}
