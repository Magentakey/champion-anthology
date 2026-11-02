import 'dart:io';

import 'package:champion_anthology/core/audio/audio_service.dart';
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
}
