/// Data statis satu level. Logika gameplay-nya hidup di folder lib/levels/<id>/.
class LevelDefinition {
  final String id;
  final int number;
  final String bossName;
  final String introDialog;

  /// false = belum dibuat (tampil terkunci / "segera hadir").
  final bool available;

  const LevelDefinition({
    required this.id,
    required this.number,
    required this.bossName,
    required this.introDialog,
    this.available = false,
  });
}
