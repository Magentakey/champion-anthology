import 'package:champion_anthology/app/app.dart';
import 'package:champion_anthology/app/router.dart';
import 'package:champion_anthology/app/strings.dart';
import 'package:champion_anthology/core/save/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> initial) async {
  // Ukuran layar HP (360x800 dp) agar layout sama seperti di perangkat.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();

  appRouter.go('/'); // router global: selalu mulai dari menu
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const ChampionApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pertama kali: Main -> storyboard -> Lanjut -> pilih level',
      (tester) async {
    await pumpApp(tester, {});

    await tester.tap(find.text(AppText.play));
    await tester.pumpAndSettle();
    expect(find.text(AppText.storyTapHint), findsOneWidget);

    // Panel 1 sudah tampil; 3 ketukan memunculkan panel 2, 3, dan 4.
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(const Offset(180, 400));
      await tester.pumpAndSettle();
    }
    expect(find.text(AppText.storyContinue), findsOneWidget);

    await tester.tap(find.text(AppText.storyContinue));
    await tester.pumpAndSettle();
    expect(find.text(AppText.levelSelectTitle), findsOneWidget);
  });

  testWidgets('cerita sudah dilihat: Main langsung ke pilih level, bintang & kunci tampil, intro boss terbuka',
      (tester) async {
    await pumpApp(tester, {'story_seen': true, 'stars_genius': 2});

    await tester.tap(find.text(AppText.play));
    await tester.pumpAndSettle();
    expect(find.text(AppText.levelSelectTitle), findsOneWidget);

    expect(find.byIcon(Icons.star), findsNWidgets(2)); // 2 bintang level 1
    expect(find.byIcon(Icons.lock), findsNWidgets(2)); // level 2 & 3 belum tersedia

    await tester.tap(find.byIcon(Icons.lock).first);
    await tester.pump();
    expect(find.text(AppText.comingSoon), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('Bob the Genius'), findsOneWidget);
    expect(find.text(AppText.start), findsOneWidget);
  });
}
