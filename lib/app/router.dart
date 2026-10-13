import 'package:go_router/go_router.dart';

import '../screens/boss_intro_screen.dart';
import '../screens/gameplay_placeholder_screen.dart';
import '../screens/level_select_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/storyboard_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
    GoRoute(path: '/story', builder: (context, state) => const StoryboardScreen()),
    GoRoute(path: '/levels', builder: (context, state) => const LevelSelectScreen()),
    GoRoute(
      path: '/intro/:levelId',
      builder: (context, state) =>
          BossIntroScreen(levelId: state.pathParameters['levelId']!),
    ),
    GoRoute(
      path: '/play/:levelId',
      builder: (context, state) =>
          GameplayPlaceholderScreen(levelId: state.pathParameters['levelId']!),
    ),
  ],
);
