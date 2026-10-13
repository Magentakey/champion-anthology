import 'package:flame/cache.dart';

/// Load aset hanya untuk level aktif, dan bersihkan saat level ditutup.
/// Path relatif terhadap assets/images/ (mis. 'genius/boss.png').
class AssetLoader {
  const AssetLoader._();

  static Future<void> load(Images images, List<String> paths) async {
    if (paths.isEmpty) return;
    await images.loadAll(paths);
  }

  static void unload(Images images) => images.clearCache();
}
