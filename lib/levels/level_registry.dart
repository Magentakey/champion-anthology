import '../core/level/level_definition.dart';

/// Menambah level baru = tambah satu entry di sini + satu folder di lib/levels/.
const levelRegistry = <LevelDefinition>[
  LevelDefinition(
    id: 'math',
    number: 1,
    bossName: 'Bob the Mathematics',
    introDialog: 'Who are you?\nChallenge me?!\nKnow your place!',
    available: true,
  ),
  LevelDefinition(
    id: 'maze',
    number: 2,
    bossName: 'Asep the Mazelogist',
    introDialog: 'Welcome...\nTake my title?\nFollow me...',
  ),
  LevelDefinition(
    id: 'cooking',
    number: 3,
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
