import 'package:champion_anthology/shared/widgets/boss_widgets.dart';
import 'package:champion_anthology/shared/widgets/pixel_pattern.dart';
import 'package:champion_anthology/shared/widgets/pixel_ui.dart';
import 'package:champion_anthology/shared/widgets/star_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pixelWidgetTests();
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

// ---- widget piksel tambahan ----
void pixelWidgetTests() {
  group('PixelPatterns', () {
    final all = {
      'star': PixelPatterns.star,
      'lock': PixelPatterns.lock,
      'heart': PixelPatterns.heart,
      'arrowUp': PixelPatterns.arrowUp,
      'arrowDown': PixelPatterns.arrowDown,
      'arrowLeft': PixelPatterns.arrowLeft,
      'arrowRight': PixelPatterns.arrowRight,
      'check': PixelPatterns.check,
      'fire': PixelPatterns.fire,
      'playerHead': PixelPatterns.playerHead,
    };

    test('semua pola berbentuk persegi panjang (tiap baris sama lebar)', () {
      all.forEach((name, rows) {
        expect(rows.map((r) => r.length).toSet().length, 1, reason: name);
        expect(rows, isNotEmpty, reason: name);
      });
    });

    test('kepala pemain 9x9 dan panah saling cermin', () {
      expect(PixelPatterns.playerHead.length, 9);
      expect(PixelPatterns.playerHead.first.length, 9);
      expect(PixelPatterns.arrowDown, PixelPatterns.arrowUp.reversed.toList());
      expect(
        PixelPatterns.arrowRight,
        [for (final r in PixelPatterns.arrowLeft) r.split('').reversed.join()],
      );
    });
  });

  testWidgets('gelembung ucapan dan banner step menampilkan teks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(height: 200, child: StepBannerCard(step: 2, label: 'Sedang')),
              BossSpeechBubble(text: 'Halo, juara!'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('STEP 2'), findsOneWidget);
    expect(find.text('Sedang'), findsOneWidget);
    expect(find.text('Halo, juara!'), findsOneWidget);
  });

  testWidgets('PixelBar, PixelHeart, dan PixelIcon tergambar dengan ukuran yang benar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              PixelBar(value: 0.5, color: Colors.red, unit: 1.5),
              PixelHeart(filled: true, size: 16),
              PixelIcon(rows: PixelPatterns.arrowUp, size: 18),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PixelBar)).height, 12); // 8 piksel x 1,5
    expect(tester.getSize(find.byType(PixelHeart)).height, 16);
    // PixelHeart memakai PixelIcon di dalamnya, jadi ada dua PixelIcon; yang terakhir adalah panah yang ditulis langsung.
    expect(find.byType(PixelIcon), findsNWidgets(2));
    // 7 baris + 2 garis tepi = 9 sel; lebar 7 + 2 = 9 sel -> persegi
    expect(tester.getSize(find.byType(PixelIcon).last).width, 18);
    expect(tester.takeException(), isNull);
  });

  group('StarRow dan PixelStar', () {
    testWidgets('menampilkan 3 bintang, sebanyak jumlah bintang yang terisi', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StarRow(stars: 2, size: 20))));
      expect(find.byType(PixelStar), findsNWidgets(3));
      expect(find.byWidgetPredicate((w) => w is PixelStar && w.filled), findsNWidgets(2));
    });

    testWidgets('0 dan 3 bintang', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StarRow(stars: 0))));
      expect(find.byWidgetPredicate((w) => w is PixelStar && w.filled), findsNothing);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StarRow(stars: 3))));
      expect(find.byWidgetPredicate((w) => w is PixelStar && w.filled), findsNWidgets(3));
    });
  });

  testWidgets('PixelButton lebar memanggil onPressed dan tombol teks dapat diketuk', (tester) async {
    var pressed = 0;
    var back = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PixelButton(label: 'Suara: Nyala', wide: true, unit: 2, onPressed: () => pressed++),
              PixelTextButton(label: '< Kembali', onPressed: () => back++),
              const PixelLock(size: 30),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Suara: Nyala'));
    await tester.tap(find.text('< Kembali'));
    await tester.pump();
    expect(pressed, 1);
    expect(back, 1);
    expect(find.byType(PixelLock), findsOneWidget);
  });

  testWidgets('PixelPauseButton memanggil onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: PixelPauseButton(label: 'Jeda', onPressed: () => taps++)))),
    );
    await tester.tap(find.byType(PixelPauseButton));
    expect(taps, 1);
  });

  testWidgets('overlayUnit memakai sisi terpendek layar dan dijepit antara 1,4 dan 3', (tester) async {
    double? u;
    Widget probe(Size size) => MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(builder: (context) {
            u = PixelUi.overlayUnit(context);
            return const SizedBox();
          }),
        );
    await tester.pumpWidget(probe(const Size(360, 800)));
    expect(u, 1.5);
    await tester.pumpWidget(probe(const Size(800, 360))); // landscape: sisi terpendek yang dipakai
    expect(u, 1.5);
    await tester.pumpWidget(probe(const Size(100, 100)));
    expect(u, 1.4);
    await tester.pumpWidget(probe(const Size(2000, 2000)));
    expect(u, 3.0);
  });
}
