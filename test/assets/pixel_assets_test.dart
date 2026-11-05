import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Lebar dan tinggi PNG dari header (byte 16..23).
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

void main() {
  test('font piksel dan gambar home ada, dan font terdaftar di pubspec', () {
    for (final f in [
      'assets/fonts/PixelChampion.ttf',
      'assets/images/home/home_bg.png',
      'assets/images/home/btn_primary.png',
      'assets/images/home/btn_secondary.png',
    ]) {
      final file = File(f);
      expect(file.existsSync(), isTrue, reason: 'Tidak ada: $f');
      expect(file.lengthSync(), greaterThan(0), reason: 'Kosong: $f');
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: PixelChampion'));
    expect(pubspec, contains('assets/fonts/PixelChampion.ttf'));
  });

  test('ukuran PNG sesuai kisi piksel (kelipatan 3 dari 240x426 dan 106x28)', () {
    expect(pngSize('assets/images/home/home_bg.png'), (720, 1278));
    expect(pngSize('assets/images/home/btn_primary.png'), (318, 84));
    expect(pngSize('assets/images/home/btn_secondary.png'), (318, 84));
  });

  test('panel cerita berukuran sama dengan kotaknya di layar storyboard (rasio terjaga)', () {
    // Kotak panel pada kisi 240x426: 216x87, 216x100, 106x137, 106x137 (diperbesar 3x).
    const expected = [(648, 261), (648, 300), (318, 411), (318, 411)];
    for (var i = 0; i < expected.length; i++) {
      expect(pngSize('assets/images/story/panel_${i + 1}.png'), expected[i], reason: 'panel_${i + 1}.png');
    }
  });
}
