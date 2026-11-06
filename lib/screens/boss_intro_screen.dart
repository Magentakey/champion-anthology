import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../levels/level_registry.dart';
import '../shared/widgets/pixel_ui.dart';

/// Intro boss bergaya pixel art pada kisi 240x426: nama, potret, dialog, tips, dan tombol Mulai.
class BossIntroScreen extends StatelessWidget {
  final String levelId;

  const BossIntroScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    final level = levelById(levelId);
    if (level == null) {
      return Scaffold(
        backgroundColor: PixelUi.night,
        body: Center(
          child: Text(AppText.levelNotFound, style: PixelUi.text(PixelUi.overlayUnit(context))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PixelUi.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/bg_night.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final u = PixelUi.unitFor(Size(c.maxWidth, c.maxHeight));
                // Nama panjang (mis. "Asep the Mazelogist") memakai huruf skala 1 agar muat.
                final nameScale = level.bossName.length * 12 <= 200 ? 2.0 : 1.0;
                return Center(
                  child: SizedBox(
                    width: PixelUi.gridWidth * u,
                    height: PixelUi.gridHeight * u,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 6 * u,
                          top: 4 * u,
                          child: PixelTextButton(
                            label: AppText.back,
                            unit: u,
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Positioned(
                          left: 12 * u,
                          right: 12 * u,
                          top: 30 * u,
                          child: PixelFrame(
                            unit: u,
                            padding: EdgeInsets.symmetric(vertical: 6 * u, horizontal: 4 * u),
                            child: Center(
                              child: Text(
                                level.bossName,
                                textAlign: TextAlign.center,
                                style: PixelUi.text(
                                  u,
                                  scale: nameScale,
                                  color: PixelUi.gold,
                                  outline: PixelUi.goldOutline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 72 * u,
                          height: 120 * u,
                          child: Center(
                            child: level.bossImage != null
                                ? Image.asset(
                                    level.bossImage!,
                                    width: 120 * u,
                                    height: 120 * u,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    gaplessPlayback: true,
                                  )
                                : Icon(Icons.accessibility_new, size: 100 * u, color: PixelUi.lavender),
                          ),
                        ),
                        Positioned(
                          left: 12 * u,
                          right: 12 * u,
                          top: 198 * u,
                          child: PixelFrame(
                            unit: u,
                            fill: PixelUi.paper,
                            padding: EdgeInsets.all(6 * u),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                level.introDialog,
                                textAlign: TextAlign.center,
                                style: PixelUi.text(u, color: PixelUi.ink, height: 1.2),
                              ),
                            ),
                          ),
                        ),
                        if (level.tip != null)
                          Positioned(
                            left: 12 * u,
                            right: 12 * u,
                            top: 262 * u,
                            child: PixelFrame(
                              unit: u,
                              padding: EdgeInsets.all(6 * u),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  level.tip!,
                                  textAlign: TextAlign.center,
                                  style: PixelUi.text(u, color: PixelUi.cream, height: 1.2),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 366 * u,
                          child: Center(
                            child: PixelButton(
                              label: AppText.start,
                              onPressed: () => context.pushReplacement('/play/${level.id}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
