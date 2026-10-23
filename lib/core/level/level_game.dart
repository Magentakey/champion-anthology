import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter/widgets.dart';

import '../assets/asset_loader.dart';
import 'level_session.dart';

/// Basis semua level. Core (GameplayScreen) hanya tahu kelas ini, jadi
/// menambah level baru tidak perlu mengubah core.
abstract class LevelGame extends FlameGame {
  LevelGame(this.session);

  final LevelSession session;

  /// Cache gambar milik level ini saja (di-clear saat level ditutup).
  final Images levelImages = Images();

  /// Aset yang dimuat level ini, relatif terhadap assets/images/.
  List<String> get assetPaths => const [];

  /// HUD Flutter di atas arena Flame (soal, tombol jawaban, dll).
  Widget buildHud(BuildContext context) => const SizedBox.shrink();

  /// Orientasi layar yang dikunci selama level ini (dipulihkan ke potret saat keluar).
  /// null = tidak diubah (potret).
  List<DeviceOrientation>? get orientations => null;

  /// Posisi tombol jeda dari core. Level landscape bisa memindahkannya agar tidak
  /// menutupi HUD miliknya.
  Alignment get pauseButtonAlignment => Alignment.topRight;

  /// Sebutan satu tahap di layar hasil: "Step" (default) atau mis. "Fase".
  String get stepLabel => 'Step';

  /// Kalimat karakter boss di layar hasil (mis. ejekan). null = tidak ada.
  String? resultMessage() => null;

  /// Mulai step [step] (1..3). Panggil [LevelSession.winStep] / [LevelSession.loseStep]
  /// saat step selesai.
  void startStep(int step);

  Future<void> loadAssets() => AssetLoader.load(levelImages, assetPaths);

  void disposeAssets() => AssetLoader.unload(levelImages);
}
