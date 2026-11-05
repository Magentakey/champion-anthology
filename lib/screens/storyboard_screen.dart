import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../shared/widgets/pixel_ui.dart';
import 'story_data.dart';

/// Posisi dan ukuran panel pada kisi piksel logis 240x426 (sama dengan mockup).
class _PanelRect {
  const _PanelRect(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;
}

const _panelRects = <_PanelRect>[
  _PanelRect(12, 30, 216, 87), // 1: lebar, atas
  _PanelRect(12, 121, 216, 100), // 2: lebar, tengah (barisan para master)
  _PanelRect(12, 225, 106, 137), // 3: kiri bawah
  _PanelRect(122, 225, 106, 137), // 4: kanan bawah
];

/// Storyboard 4 panel bergaya pixel art. Ketuk layar untuk memunculkan panel berikutnya.
/// Tampil setiap kali Main ditekan. Urutan baca: 1 (atas), 2 (tengah), 3 (kiri bawah), 4 (kanan bawah).
class StoryboardScreen extends StatefulWidget {
  const StoryboardScreen({super.key});

  @override
  State<StoryboardScreen> createState() => _StoryboardScreenState();
}

class _StoryboardScreenState extends State<StoryboardScreen> {
  int _revealed = 1;

  bool get _allRevealed => _revealed >= storyPanels.length;

  void _advance() {
    if (!_allRevealed) setState(() => _revealed++);
  }

  void _finish() => context.go('/levels');

  Widget _panel(int index, double u) {
    final panel = storyPanels[index];
    final r = _panelRects[index];
    final visible = index < _revealed;
    return Positioned(
      left: (r.x - 2) * u,
      top: (r.y - 2) * u,
      width: (r.w + 4) * u,
      height: (r.h + 4) * u,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        child: AnimatedScale(
          scale: visible ? 1 : 0.92,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          // Bingkai krem 1 piksel di luar, garis gelap 1 piksel di dalam.
          child: Container(
            color: PixelUi.cream,
            padding: EdgeInsets.all(u),
            child: Container(
              color: PixelUi.dark,
              padding: EdgeInsets.all(u),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    panel.image,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFFE0E0E0)),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(2 * u, 0, 2 * u, 2 * u),
                      padding: EdgeInsets.all(u),
                      color: PixelUi.dark,
                      child: Container(
                        width: double.infinity,
                        color: PixelUi.paper,
                        padding: EdgeInsets.fromLTRB(3 * u, 2 * u, 3 * u, 2 * u),
                        child: Text(
                          panel.caption,
                          style: PixelUi.text(u, color: PixelUi.ink, height: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelUi.night,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final u = PixelUi.unitFor(Size(c.maxWidth, c.maxHeight));
              return Center(
                child: SizedBox(
                  width: PixelUi.gridWidth * u,
                  height: PixelUi.gridHeight * u,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 12 * u,
                        top: 6 * u,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _finish,
                          child: Padding(
                            padding: EdgeInsets.all(3 * u),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppText.storySkip,
                                  style: PixelUi.text(u, color: const Color(0xFFBEB4DC)),
                                ),
                                Text(
                                  ' >>',
                                  style: PixelUi.text(u, color: const Color(0xFFBEB4DC)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < storyPanels.length; i++) _panel(i, u),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 364 * u,
                        child: Center(
                          child: _allRevealed
                              ? PixelButton(label: AppText.storyContinue, onPressed: _finish)
                              : Padding(
                                  padding: EdgeInsets.only(top: 14 * u),
                                  child: Text(AppText.storyTapHint, style: PixelUi.text(u)),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 400 * u,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < storyPanels.length; i++)
                              Container(
                                width: 8 * u,
                                height: 6 * u,
                                margin: EdgeInsets.symmetric(horizontal: 2 * u),
                                color: i < _revealed ? PixelUi.cream : const Color(0xFF50466E),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
