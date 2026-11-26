import 'dart:io';

import 'package:champion_anthology/core/audio/audio_service.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semua file SFX dan BGM terdaftar ada di assets/audio dan tidak kosong', () {
    for (final sfx in Sfx.values) {
      final file = File('assets/audio/${sfx.file}');
      expect(file.existsSync(), isTrue, reason: 'hilang: ${sfx.file}');
      expect(file.lengthSync(), greaterThan(1000), reason: 'terlalu kecil: ${sfx.file}');
    }
    final bgm = File('assets/audio/${AudioService.fightBgm}');
    expect(bgm.existsSync(), isTrue);
    expect(bgm.lengthSync(), greaterThan(100000));
  });

  test('sembilan nada pad dan empat SFX Level 8 ada di assets/audio', () {
    final memory = Sfx.values.where((s) => s.name.startsWith('memory')).toList();
    expect(memory, hasLength(13));
    for (final sfx in memory) {
      final file = File('assets/audio/${sfx.file}');
      expect(file.existsSync(), isTrue, reason: 'hilang: ${sfx.file}');
      expect(file.lengthSync(), greaterThan(1000), reason: 'terlalu kecil: ${sfx.file}');
    }
  });

  test('tiga lagu Level 7 ada di assets/audio dan berukuran wajar', () {
    for (final name in rhythmSongFiles) {
      final file = File('assets/audio/$name');
      expect(file.existsSync(), isTrue, reason: 'hilang: $name');
      expect(file.lengthSync(), greaterThan(100000), reason: 'terlalu kecil: $name');
    }
  });
}
