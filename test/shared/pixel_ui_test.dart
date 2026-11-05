import 'package:champion_anthology/shared/widgets/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PixelUi', () {
    test('ukuran piksel mengikuti sisi layar yang lebih sempit', () {
      expect(PixelUi.unitFor(const Size(360, 800)), 1.5); // lebar menentukan
      expect(PixelUi.unitFor(const Size(800, 600)), closeTo(600 / 426, 1e-9)); // tinggi menentukan
    });

    test('ukuran font = 10 x skala x unit, tepi setebal skala, bayangan di urutan pertama', () {
      final s = PixelUi.text(2, scale: 3, outline: PixelUi.outline, shadow: Colors.black);
      expect(s.fontFamily, PixelUi.fontFamily);
      expect(s.fontSize, 60);
      expect(s.shadows!.length, 9); // 1 bayangan jatuh + 8 arah tepi
      // tepi 3 piksel logis x 2 dp = 6 dp
      expect(s.shadows!.skip(1).map((e) => e.offset.dx.abs()).toSet(), {0.0, 6.0});
      // bayangan jatuh: kanan 1 skala, bawah 2 skala (skala > 1)
      expect(s.shadows!.first.offset, const Offset(6, 12));
    });

    test('teks skala 1 tanpa tepi tidak punya bayangan', () {
      expect(PixelUi.text(1.5).shadows, isEmpty);
    });
  });

  testWidgets('PixelButton menampilkan label dan memanggil onPressed saat diketuk', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PixelButton(label: 'Main', onPressed: () => taps++),
          ),
        ),
      ),
    );
    expect(find.text('Main'), findsOneWidget);
    await tester.tap(find.text('Main'));
    await tester.pump();
    expect(taps, 1);
  });
}
