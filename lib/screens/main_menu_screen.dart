import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../shared/widgets/pixel_ui.dart';

/// Menu utama bergaya pixel art: latar fajar dengan pemain memegang bola dunia (gambar),
/// judul dan tombol berupa widget supaya teks tetap bisa diubah di strings.dart.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.unit(context);
    final lines = AppText.gameTitle.split('\n');
    final line1 = PixelUi.text(
      u,
      scale: 2,
      color: PixelUi.cream,
      outline: PixelUi.dark,
      shadow: const Color(0xFF5A286E),
      height: 1.5,
    );
    final line2 = PixelUi.text(
      u,
      scale: 3,
      color: const Color(0xFFFFD640),
      outline: const Color(0xFF961E32),
      shadow: const Color(0xFF280A28),
      height: 1.2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E1C56),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar piksel; bagian bawah (panggung dan pemain) selalu terlihat.
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/home_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 18 * u),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${lines.first}\n', style: line1),
                      TextSpan(text: lines.skip(1).join('\n'), style: line2),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 36 * u),
                PixelButton(
                  // Setiap menekan Main, cerita tampil lagi.
                  label: AppText.play,
                  onPressed: () => context.go('/story'),
                ),
                SizedBox(height: 8 * u),
                PixelButton(
                  label: AppText.quit,
                  secondary: true,
                  onPressed: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
