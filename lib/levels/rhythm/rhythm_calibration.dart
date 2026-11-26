import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import 'rhythm_config.dart';

/// Offset kalibrasi suara: menggeser jadwal not terhadap musik, supaya pemain bisa memperbaiki bila musik
/// terlambat atau terlalu cepat di perangkatnya. Diatur dari layar jeda dan disimpan di perangkat
/// (SharedPreferences, sama seperti bintang terbaik). Rentang -150 sampai +150 ms, langkah 10 ms.
class RhythmCalibration {
  RhythmCalibration._();

  static final RhythmCalibration instance = RhythmCalibration._();

  static const String prefsKey = 'rhythm_offset_ms';

  /// Offset sekarang dalam milidetik. Positif = not tiba lebih lambat (untuk musik yang terdengar terlambat).
  final ValueNotifier<int> offsetMs = ValueNotifier(RhythmTuning.defaultOffsetMs);

  SharedPreferences? _prefs;

  /// Membulatkan ke kelipatan langkah terdekat lalu memotong ke rentang yang diizinkan.
  static int normalize(int ms) {
    final snapped = (ms / RhythmTuning.offsetStepMs).round() * RhythmTuning.offsetStepMs;
    return snapped.clamp(RhythmTuning.minOffsetMs, RhythmTuning.maxOffsetMs).toInt();
  }

  /// Memuat nilai tersimpan. Dipanggil sekali di main() setelah SharedPreferences siap.
  void init(SharedPreferences prefs) {
    _prefs = prefs;
    offsetMs.value = normalize(prefs.getInt(prefsKey) ?? RhythmTuning.defaultOffsetMs);
  }

  /// Mengubah offset ke [ms] (dinormalkan) dan menyimpannya.
  Future<void> setOffset(int ms) async {
    final value = normalize(ms);
    offsetMs.value = value;
    await _prefs?.setInt(prefsKey, value);
  }

  /// Menggeser offset sebanyak [steps] langkah (negatif = ke kiri).
  Future<void> nudge(int steps) => setOffset(offsetMs.value + steps * RhythmTuning.offsetStepMs);
}
