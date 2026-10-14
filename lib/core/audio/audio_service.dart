import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daftar SFX. File ada di assets/audio/ (ganti dengan menimpa file bernama sama).
enum Sfx {
  correct('correct.wav'),
  wrong('wrong.wav'),
  tick('tick.wav'),
  stepUp('step_up.wav'),
  win('win.wav'),
  lose('lose.wav');

  const Sfx(this.file);
  final String file;
}

/// Pemutar SFX berlatensi rendah (AudioPool / SoundPool) dengan tombol mute tersimpan.
/// Pool dibuat sekali saat aplikasi mulai, jadi tidak ada jeda saat pertama diputar.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();
  static const _mutedKey = 'audio_muted';

  final ValueNotifier<bool> muted = ValueNotifier(false);
  final Map<Sfx, Future<void> Function()> _starters = {};
  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    muted.value = prefs.getBool(_mutedKey) ?? false;

    for (final sfx in Sfx.values) {
      try {
        final pool = await FlameAudio.createPool(
          sfx.file,
          minPlayers: 1,
          maxPlayers: 4,
        );
        _starters[sfx] = () async {
          await pool.start();
        };
      } catch (e) {
        debugPrint('Gagal membuat pool SFX ${sfx.file}: $e');
      }
    }
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    await _prefs?.setBool(_mutedKey, value);
  }

  void play(Sfx sfx) {
    if (muted.value) return;
    final start = _starters[sfx];
    if (start == null) return;
    unawaited(_safeStart(start));
  }

  Future<void> _safeStart(Future<void> Function() start) async {
    try {
      await start();
    } catch (e) {
      debugPrint('SFX gagal diputar: $e');
    }
  }
}
