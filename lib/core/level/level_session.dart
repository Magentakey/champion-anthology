import 'package:flutter/foundation.dart';

import 'star_calculator.dart';

enum SessionState { playing, paused, finished }

/// Satu kali percobaan level (Step 1 -> 3 dalam satu sesi, tanpa ulang dari awal).
/// Level (game Flame) hanya melapor [winStep] / [loseStep]; sisanya diurus di sini.
class LevelSession extends ChangeNotifier {
  int _step = 1;
  int _stepsWon = 0;
  SessionState _state = SessionState.playing;

  /// Step aktif (1..3). Saat selesai, menunjukkan step terakhir yang dimainkan.
  int get step => _step;
  int get stepsWon => _stepsWon;
  SessionState get state => _state;
  bool get isPlaying => _state == SessionState.playing;
  bool get isFinished => _state == SessionState.finished;
  int get stars => StarCalculator.fromStepsWon(_stepsWon);

  void winStep() {
    if (_state != SessionState.playing) return;
    _stepsWon++;
    if (_step >= StarCalculator.totalSteps) {
      _state = SessionState.finished; // menang Step 3 = selesai
    } else {
      _step++;
    }
    notifyListeners();
  }

  void loseStep() {
    if (_state != SessionState.playing) return;
    _state = SessionState.finished;
    notifyListeners();
  }

  void pause() {
    if (_state != SessionState.playing) return;
    _state = SessionState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != SessionState.paused) return;
    _state = SessionState.playing;
    notifyListeners();
  }
}
