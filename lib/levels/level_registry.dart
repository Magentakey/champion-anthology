import '../core/level/level_definition.dart';
import 'fight/fight_dialog.dart';
import 'fight/fight_game.dart';
import 'genius/genius_game.dart';

/// Menambah level baru = tambah satu entry di sini + satu folder di lib/levels/.
const levelRegistry = <LevelDefinition>[
  LevelDefinition(
    id: 'fight',
    number: 1,
    bossName: 'Rock the Fighter',
    introDialog: FightDialog.intro,
    bossImage: 'assets/images/fight/boss_idle.png',
    createGame: createFightGame,
  ),
  LevelDefinition(
    id: 'genius',
    number: 2,
    bossName: 'Bob the Genius',
    introDialog: 'Siapa kau?\nBerani menantangku?!\nTahu tempatmu!',
    bossImage: 'assets/images/genius/boss_idle.png',
    createGame: createGeniusGame,
  ),
  LevelDefinition(
    id: 'maze',
    number: 3,
    bossName: 'Asep the Mazelogist',
    introDialog: 'Selamat datang...\nIngin merebut gelarku?\nIkuti aku...',
  ),
  LevelDefinition(
    id: 'cooking',
    number: 4,
    bossName: 'Cooking Champion',
    introDialog: '...',
  ),
];

LevelDefinition? levelById(String id) {
  for (final level in levelRegistry) {
    if (level.id == id) return level;
  }
  return null;
}
