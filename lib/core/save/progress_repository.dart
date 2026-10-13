import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../levels/level_registry.dart';
import '../level/level_definition.dart';

/// Di-override di main.dart dengan instance SharedPreferences asli.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider di main()'),
);

/// State: peta levelId -> bintang terbaik (0..3).
final progressProvider =
    NotifierProvider<ProgressNotifier, Map<String, int>>(ProgressNotifier.new);

class ProgressNotifier extends Notifier<Map<String, int>> {
  static String _key(String levelId) => 'stars_$levelId';

  @override
  Map<String, int> build() {
    final prefs = ref.read(sharedPrefsProvider);
    return {
      for (final level in levelRegistry) level.id: prefs.getInt(_key(level.id)) ?? 0,
    };
  }

  /// Simpan hanya jika lebih tinggi dari rekor sebelumnya.
  Future<void> submitStars(String levelId, int stars) async {
    final value = stars.clamp(0, 3).toInt();
    final best = state[levelId] ?? 0;
    if (value <= best) return;
    state = {...state, levelId: value};
    await ref.read(sharedPrefsProvider).setInt(_key(levelId), value);
  }

  /// Level terbuka jika sudah tersedia dan level sebelumnya minimal 1 bintang.
  bool isUnlocked(LevelDefinition level) {
    if (!level.available) return false;
    final index = levelRegistry.indexOf(level);
    if (index <= 0) return true;
    final previous = levelRegistry[index - 1];
    return (state[previous.id] ?? 0) >= 1;
  }
}
