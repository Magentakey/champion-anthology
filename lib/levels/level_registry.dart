import '../core/level/level_definition.dart';
import 'cooking/cooking_dialog.dart';
import 'cooking/cooking_game.dart';
import 'fight/fight_dialog.dart';
import 'fight/fight_game.dart';
import 'genius/genius_game.dart';
import 'maze/maze_dialog.dart';
import 'maze/maze_game.dart';

/// Menambah level baru = tambah satu entry di sini + satu folder di lib/levels/.
const levelRegistry = <LevelDefinition>[
  LevelDefinition(
    id: 'fight',
    number: 1,
    bossName: 'Rock the Fighter',
    introDialog: FightDialog.intro,
    tip: FightDialog.tip,
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
    tip: MazeDialog.tip,
    bossImage: 'assets/images/maze/boss_idle.png',
    createGame: createMazeGame,
  ),
  LevelDefinition(
    id: 'cooking',
    number: 4,
    bossName: 'Cooking Champion',
    introDialog: CookingDialog.intro,
    tip: CookingDialog.tip,
    bossImage: 'assets/images/cooking/boss_idle.png',
    createGame: createCookingGame,
  ),
];

LevelDefinition? levelById(String id) {
  for (final level in levelRegistry) {
    if (level.id == id) return level;
  }
  return null;
}
