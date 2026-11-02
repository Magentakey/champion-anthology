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
  lose('lose.wav'),

  // Level Fight (dibuat oleh tools/audio/generate_fight_audio.py)
  punch('punch.wav'),
  kick('kick.wav'),
  heavy('heavy.wav'),
  block('block.wav'),
  hurt('hurt.wav'),
  ko('ko.wav'),
  whoosh('whoosh.wav'),
  knifeHit('knife_hit.wav'),
  bell('bell.wav'),
  crowd('crowd.wav'),
  warning('warning.wav');

  const Sfx(this.file);
  final String file;
}

/// Pemutar SFX berlatensi rendah (AudioPool / SoundPool) dengan tombol mute tersimpan.
/// Pool dibuat sekali saat aplikasi mulai, jadi tidak ada jeda saat pertama diputar.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();
  static const _mutedKey = 'audio_muted';

  /// Musik latar Level Fight (berulang).
  static const fightBgm = 'fight_bgm.wav';

  final ValueNotifier<bool> muted = ValueNotifier(false);
  final Map<Sfx, Future<void> Function()> _starters = {};
  SharedPreferences? _prefs;

  String? _bgmFile;
  double _bgmVolume = 0.35;
  bool _bgmPaused = false;
  Object? _bgmOwner;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    muted.value = prefs.getBool(_mutedKey) ?? false;
    // otomatis menjeda musik saat aplikasi masuk latar belakang
    FlameAudio.bgm.initialize();

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
    final file = _bgmFile;
    if (value) {
      if (file != null) unawaited(_safeStart(() => FlameAudio.bgm.pause()));
    } else if (file != null && !_bgmPaused) {
      unawaited(_safeStart(() => FlameAudio.bgm.play(file, volume: _bgmVolume)));
    }
  }

  /// Memutar musik latar berulang. [owner] dipakai agar level lama yang dibuang tidak
  /// menghentikan musik milik level baru (mis. saat main ulang).
  Future<void> playBgm(String file, {double volume = 0.35, Object? owner}) async {
    _bgmFile = file;
    _bgmVolume = volume;
    _bgmPaused = false;
    _bgmOwner = owner;
    if (muted.value) return;
    await _safeStart(() => FlameAudio.bgm.play(file, volume: volume));
  }

  void pauseBgm({Object? owner}) {
    if (_bgmFile == null || (owner != null && !identical(owner, _bgmOwner))) return;
    _bgmPaused = true;
    unawaited(_safeStart(() => FlameAudio.bgm.pause()));
  }

  void resumeBgm({Object? owner}) {
    if (_bgmFile == null || (owner != null && !identical(owner, _bgmOwner))) return;
    _bgmPaused = false;
    if (muted.value) return;
    unawaited(_safeStart(() => FlameAudio.bgm.resume()));
  }

  void stopBgm({Object? owner}) {
    if (owner != null && !identical(owner, _bgmOwner)) return;
    _bgmFile = null;
    _bgmOwner = null;
    unawaited(_safeStart(() => FlameAudio.bgm.stop()));
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
