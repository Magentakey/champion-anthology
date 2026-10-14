import 'package:champion_anthology/core/save/progress_repository.dart';
import 'package:champion_anthology/levels/level_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> makeContainer([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return (container, prefs);
}

void main() {
  test('bintang hanya naik, tidak pernah turun, dan tersimpan', () async {
    final (container, prefs) = await makeContainer();
    final notifier = container.read(progressProvider.notifier);

    await notifier.submitStars('genius', 2);
    await notifier.submitStars('genius', 1); // hasil lebih buruk: diabaikan

    expect(container.read(progressProvider)['genius'], 2);
    expect(prefs.getInt('stars_genius'), 2);
  });

  test('bintang dibatasi 0..3', () async {
    final (container, _) = await makeContainer();
    await container.read(progressProvider.notifier).submitStars('genius', 9);
    expect(container.read(progressProvider)['genius'], 3);
  });

  test('progres dimuat dari penyimpanan saat aplikasi dibuka', () async {
    final (container, _) = await makeContainer({'stars_genius': 3});
    expect(container.read(progressProvider)['genius'], 3);
    expect(container.read(progressProvider)['maze'], 0);
  });

  test('level 1 terbuka; level yang belum dibuat tetap terkunci', () async {
    final (container, _) = await makeContainer({'stars_genius': 3});
    final notifier = container.read(progressProvider.notifier);

    expect(notifier.isUnlocked(levelById('genius')!), isTrue);
    expect(notifier.isUnlocked(levelById('maze')!), isFalse); // belum tersedia
  });
}
