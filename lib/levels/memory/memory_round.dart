import 'dart:math';

import '../../core/level/level_session.dart';
import 'memory_config.dart';
import 'memory_sequence.dart';

/// Tahap satu step: banner ronde, tayangan urutan, giliran pemain, ronde bersih, ulang setelah salah,
/// hasil, dan jeda sebelum step berikutnya.
enum MemoryPhase { idle, intro, showing, input, roundClear, retry, result, gap, done }

/// Hasil satu ketukan pemain: diabaikan, benar, atau salah.
enum MemoryTap { ignored, correct, wrong }

/// Keterangan satu kesalahan (ketukan salah atau waktu habis).
class MemoryMistake {
  const MemoryMistake({required this.expected, required this.tapped, required this.timeout, required this.livesLeft});

  /// Pad yang seharusnya diketuk.
  final int expected;

  /// Pad yang diketuk; null bila kesalahan karena waktu habis.
  final int? tapped;
  final bool timeout;

  /// Nyawa yang tersisa setelah kesalahan ini. Bila 0, step langsung gagal dan jawaban benar tidak diungkap.
  final int livesLeft;
}

/// Mesin tahap Level 8 yang murni Dart (tanpa Flame, mudah dites): urutan, ketukan, nyawa, timer, dan pelaporan
/// ke [LevelSession]. [LevelSession.winStep] atau [LevelSession.loseStep] dipanggil tepat sekali per step.
///
/// Aturan inti: tonton urutan, ulangi dengan mengetuk pad. Ketukan salah atau waktu habis mengurangi satu nyawa dan
/// urutan yang SAMA ditayangkan ulang dari awal (ronde tidak mundur). Nyawa habis = step gagal. Menyelesaikan
/// ronde terakhir dengan nyawa tersisa = step menang. Nyawa tidak dipulihkan antar-ronde.
class MemoryRound {
  MemoryRound(this.session, {Random? random, MemorySequence Function(int step, Random random)? sequenceFor})
      : _random = random ?? Random(),
        _sequenceFor = sequenceFor ?? MemorySequence.generate;

  final LevelSession session;
  final Random _random;
  final MemorySequence Function(int step, Random random) _sequenceFor;

  int _step = 1;
  int _round = 1;
  int _lives = 0;
  int _correct = 0;
  int _roundMistakes = 0;
  MemorySequence? _sequence;
  MemoryPhase _phase = MemoryPhase.idle;
  double _phaseMs = 0;
  double _inputMs = 0;
  int? _lit;
  double _litLeftMs = 0;
  int _showCursor = -1;
  bool _tappedThisFrame = false;
  bool _passed = false;

  /// Dipanggil saat tahap berganti (dari, ke).
  void Function(MemoryPhase from, MemoryPhase to)? onPhase;

  /// Dipanggil saat pad [index] mulai ditayangkan pada tahap tonton.
  void Function(int index)? onShow;

  /// Dipanggil saat pad yang menyala berubah (null = semua padam).
  void Function(int? pad)? onLit;

  /// Dipanggil tiap ketukan benar ([pad], ketukan benar sejauh ini, panjang urutan).
  void Function(int pad, int correct, int length)? onCorrect;

  /// Dipanggil tiap kesalahan, sebelum urutan ditayangkan ulang atau step gagal.
  void Function(MemoryMistake mistake)? onWrong;

  /// Dipanggil saat satu ronde selesai ([round] mulai 1, [clean] = tanpa kesalahan di ronde itu).
  void Function(int round, bool clean)? onRoundClear;

  /// Dipanggil saat hasil step sudah pasti (menang atau gagal), sebelum jeda hasil.
  void Function(bool passed)? onStepResult;

  /// Dipanggil tepat sebelum sesi dilapori; kalimat layar hasil harus siap di sini.
  void Function(bool won)? onBeforeCommit;

  int get step => _step;

  /// Ronde sekarang (mulai 1).
  int get round => _round;
  int get rounds => memoryRoundsOf(_step);
  int get padCount => memoryPadsOf(_step);
  int get lives => _lives;

  /// Ketukan benar pada percobaan sekarang.
  int get correct => _correct;
  MemoryPhase get phase => _phase;
  MemorySequence? get sequence => _sequence;

  /// Urutan yang harus diingat pada ronde sekarang (kosong sebelum step dimulai).
  List<int> get currentSequence => _sequence == null ? const [] : _sequence!.forRound(_round);

  /// Panjang urutan pada ronde sekarang.
  int get length => memoryLengthOf(_step, _round);

  /// Pad yang sedang menyala (tayangan atau kilat setelah ketukan benar).
  int? get litPad => _lit;

  /// Sisa waktu antar-ketukan (0..1); 0 di luar giliran pemain.
  double get timerFraction {
    if (_phase != MemoryPhase.input) return 0;
    return (1 - _inputMs / memoryTimeoutMsOf(_step)).clamp(0.0, 1.0).toDouble();
  }

  /// Hasil step yang sedang atau baru selesai (menang bila true).
  bool get passed => _passed;

  /// Ketukan hanya diproses pada giliran pemain dan saat sesi berjalan.
  bool get acceptsTaps => _phase == MemoryPhase.input && session.isPlaying;

  /// Memulai step [step] (1..3): membuat urutan baru, mengisi nyawa penuh, lalu menampilkan banner ronde.
  void beginStep(int step) {
    _step = step.clamp(1, memoryPadCount.length).toInt();
    _sequence = _sequenceFor(_step, _random);
    _round = 1;
    _lives = memoryLivesOf(_step);
    _correct = 0;
    _roundMistakes = 0;
    _phaseMs = 0;
    _inputMs = 0;
    _passed = false;
    _showCursor = -1;
    _setLit(null);
    _litLeftMs = 0;
    _setPhase(MemoryPhase.intro);
  }

  /// Dipanggil setelah jeda berakhir. Saat tonton, tayangan diulang dari simbol pertama; saat giliran pemain,
  /// ketukan yang sudah benar tetap dihitung, timer diatur ulang penuh, dan tidak ada penalti.
  void resumeFromPause() {
    switch (_phase) {
      case MemoryPhase.showing:
        _startShowing(announce: false);
      case MemoryPhase.input:
        _inputMs = 0;
      case MemoryPhase.idle:
      case MemoryPhase.intro:
      case MemoryPhase.roundClear:
      case MemoryPhase.retry:
      case MemoryPhase.result:
      case MemoryPhase.gap:
      case MemoryPhase.done:
        break;
    }
  }

  /// Ketukan pada pad [pad]. Hanya satu ketukan diproses per frame; yang lain diabaikan (bukan dihitung salah).
  MemoryTap tapPad(int pad) {
    if (!acceptsTaps || _tappedThisFrame) return MemoryTap.ignored;
    if (pad < 0 || pad >= padCount) return MemoryTap.ignored;
    _tappedThisFrame = true;

    final expected = currentSequence[_correct];
    if (pad != expected) {
      _mistake(tapped: pad, timeout: false);
      return MemoryTap.wrong;
    }
    _correct++;
    _inputMs = 0;
    _setLit(pad);
    _litLeftMs = MemoryTuning.tapFlashMs.toDouble();
    onCorrect?.call(pad, _correct, length);
    if (_correct >= length) _roundDone();
    return MemoryTap.correct;
  }

  /// Memajukan permainan sebesar [dt] detik. Tidak berbuat apa-apa saat sesi dijeda atau selesai.
  void update(double dt) {
    _tappedThisFrame = false;
    if (!session.isPlaying) return;
    final ms = dt * 1000;
    _decayLit(ms);
    switch (_phase) {
      case MemoryPhase.idle:
      case MemoryPhase.done:
        return;
      case MemoryPhase.intro:
        _phaseMs += ms;
        if (_phaseMs >= MemoryTuning.introMs) _startShowing();
      case MemoryPhase.showing:
        _phaseMs += ms;
        _advanceShowing();
      case MemoryPhase.input:
        _inputMs += ms;
        if (_inputMs >= memoryTimeoutMsOf(_step)) _mistake(tapped: null, timeout: true);
      case MemoryPhase.roundClear:
        _phaseMs += ms;
        if (_phaseMs >= MemoryTuning.roundClearMs) {
          _round++;
          _roundMistakes = 0;
          _startShowing();
        }
      case MemoryPhase.retry:
        _phaseMs += ms;
        if (_phaseMs >= MemoryTuning.retryMs) _startShowing();
      case MemoryPhase.result:
        _phaseMs += ms;
        if (_phaseMs >= MemoryTuning.resultMs) _commit();
      case MemoryPhase.gap:
        _phaseMs += ms;
        if (_phaseMs >= MemoryTuning.stepGapMs) beginStep(session.step);
    }
  }

  // ---------------- tayangan ----------------
  void _startShowing({bool announce = true}) {
    _phaseMs = 0;
    _showCursor = -1;
    _correct = 0;
    _setLit(null);
    _litLeftMs = 0;
    if (announce || _phase != MemoryPhase.showing) {
      _setPhase(MemoryPhase.showing);
    }
  }

  /// Tayangan: [MemoryTuning.showLeadMs] diam, lalu tiap simbol memakai satu tempo (nyala lalu jeda).
  void _advanceShowing() {
    final seq = currentSequence;
    final showMs = memoryShowMsOf(_step);
    final litMs = memoryLitMsOf(_step);
    final t = _phaseMs - MemoryTuning.showLeadMs;
    if (t >= 0) {
      final index = t ~/ showMs;
      if (index < seq.length) {
        while (_showCursor < index) {
          _showCursor++;
          _setLit(seq[_showCursor]);
          onShow?.call(seq[_showCursor]);
        }
        if (t - index * showMs >= litMs && _lit != null) _setLit(null);
        return;
      }
    }
    if (t >= seq.length * showMs) {
      _setLit(null);
      _correct = 0;
      _inputMs = 0;
      _setPhase(MemoryPhase.input);
    }
  }

  void _decayLit(double ms) {
    if (_phase == MemoryPhase.showing || _litLeftMs <= 0) return;
    _litLeftMs -= ms;
    if (_litLeftMs <= 0) {
      _litLeftMs = 0;
      _setLit(null);
    }
  }

  void _setLit(int? pad) {
    if (_lit == pad) return;
    _lit = pad;
    onLit?.call(pad);
  }

  // ---------------- giliran pemain ----------------
  void _mistake({required int? tapped, required bool timeout}) {
    final expected = currentSequence[_correct];
    _lives--;
    _roundMistakes++;
    _correct = 0;
    final mistake = MemoryMistake(expected: expected, tapped: tapped, timeout: timeout, livesLeft: _lives);
    onWrong?.call(mistake);
    _phaseMs = 0;
    if (_lives <= 0) {
      _finish(false);
    } else {
      _setPhase(MemoryPhase.retry);
    }
  }

  void _roundDone() {
    final clean = _roundMistakes == 0;
    onRoundClear?.call(_round, clean);
    if (_round >= rounds) {
      _finish(true);
    } else {
      _phaseMs = 0;
      _setPhase(MemoryPhase.roundClear);
    }
  }

  void _finish(bool passed) {
    _passed = passed;
    _phaseMs = 0;
    _setPhase(MemoryPhase.result);
    onStepResult?.call(passed);
  }

  /// Lapor ke sesi tepat sekali: tahap keluar dari [MemoryPhase.result] sebelum sesi diubah.
  void _commit() {
    final won = _passed;
    _phaseMs = 0;
    _setPhase(MemoryPhase.gap);
    onBeforeCommit?.call(won);
    if (won) {
      session.winStep();
    } else {
      session.loseStep();
    }
    if (!session.isPlaying) _setPhase(MemoryPhase.done);
  }

  void _setPhase(MemoryPhase to) {
    final from = _phase;
    _phase = to;
    onPhase?.call(from, to);
  }
}
