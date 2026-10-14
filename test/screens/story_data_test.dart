import 'dart:io';

import 'package:champion_anthology/screens/story_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storyboard punya 4 panel dengan caption dan gambar yang ada', () {
    expect(storyPanels.length, 4);
    for (final p in storyPanels) {
      expect(p.caption.trim(), isNotEmpty);
      expect(File(p.image).existsSync(), isTrue, reason: 'Tidak ada: ${p.image}');
    }
  });
}
