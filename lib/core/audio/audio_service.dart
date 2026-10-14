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

/// Pemutar SFX sederhana dengan tombol mute yang tersimpan.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();
  static const _mutedKey = 'audio_muted';

  final ValueNotifier<bool> muted = ValueNotifier(false);
  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    muted.value = prefs.getBool(_mutedKey) ?? false;
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    await _prefs?.setBool(_mutedKey, value);
  }

  /// Muat semua SFX ke cache supaya tidak ada jeda saat pertama diputar.
  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll([for (final s in Sfx.values) s.file]);
    } catch (e) {
      debugPrint('Preload SFX gagal: $e');
    }
  }

  void play(Sfx sfx) {
    if (muted.value) return;
    unawaited(_play(sfx.file));
  }

  Future<void> _play(String file) async {
    try {
      await FlameAudio.play(file);
    } catch (e) {
      debugPrint('SFX gagal diputar: $e');
    }
  }

  /// Bersihkan cache audio saat keluar dari level.
  void unload() => FlameAudio.audioCache.clearAll();
}
