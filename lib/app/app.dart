import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class ChampionApp extends StatelessWidget {
  const ChampionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'The World in My Hands!',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: appRouter,
    );
  }
}
