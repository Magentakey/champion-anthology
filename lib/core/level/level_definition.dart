import 'level_game.dart';
import 'level_session.dart';

typedef LevelGameFactory = LevelGame Function(LevelSession session);

/// Data statis satu level. Logika gameplay-nya hidup di folder `lib/levels/<id>/`.
class LevelDefinition {
  final String id;
  final int number;
  final String bossName;
  final String introDialog;

  /// null = level belum dibuat (tampil terkunci / "segera hadir").
  final LevelGameFactory? createGame;

  /// Gambar boss untuk layar intro (path aset penuh). null = ikon placeholder.
  final String? bossImage;

  const LevelDefinition({
    required this.id,
    required this.number,
    required this.bossName,
    required this.introDialog,
    this.createGame,
    this.bossImage,
  });

  bool get available => createGame != null;
}
