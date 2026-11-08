import 'package:champion_anthology/levels/fight/pad_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('semua ikon tombol pertarungan tergambar dengan tinggi yang diminta', (tester) async {
    for (final icon in PadIcon.values) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: PadIconView(icon, size: 40)))),
      );
      expect(tester.takeException(), isNull, reason: '$icon');
      expect(tester.getSize(find.byType(PadIconView)).height, 40, reason: '$icon');
    }
  });
}
