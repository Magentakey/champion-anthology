import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../core/save/progress_repository.dart';
import '../levels/level_registry.dart';
import '../shared/widgets/pixel_ui.dart';
import '../shared/widgets/star_row.dart';

/// Pilih level bergaya pixel art: grid 3x3 pada kisi 240x426 piksel logis (sama dengan home dan storyboard).
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  static const _slotCount = 9; // grid 3x3 sesuai sketsa

  // Tata letak pada kisi piksel logis.
  static const _left = 12.0;
  static const _top = 80.0;
  static const _tile = 64.0;
  static const _gapX = 12.0;
  static const _rowStep = 90.0; // bintang (9) + jarak (3) + kotak (64) + jarak antar baris (14)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

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
                            onPressed: () => context.go('/'),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 32 * u,
                          child: Center(
                            child: Text(
                              AppText.levelSelectTitle,
                              style: PixelUi.text(
                                u,
                                scale: 2,
                                color: PixelUi.gold,
                                outline: PixelUi.goldOutline,
                                shadow: PixelUi.dark,
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < _slotCount; i++)
                          Positioned(
                            left: (_left + (i % 3) * (_tile + _gapX)) * u,
                            top: (_top + (i ~/ 3) * _rowStep) * u,
                            width: _tile * u,
                            child: _slot(context, i, u, progress, notifier),
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

  Widget _slot(BuildContext context, int i, double u, Map<String, int> progress, ProgressNotifier notifier) {
    if (i >= levelRegistry.length) {
      return _Slot(unit: u, label: '', stars: 0, locked: true, onTap: () {});
    }
    final level = levelRegistry[i];
    final unlocked = notifier.isUnlocked(level);
    return _Slot(
      unit: u,
      label: '${level.number}',
      stars: progress[level.id] ?? 0,
      locked: !unlocked,
      onTap: () {
        if (unlocked) {
          context.push('/intro/${level.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(level.available ? AppText.finishPreviousLevel : AppText.comingSoon),
            ),
          );
        }
      },
    );
  }
}

class _Slot extends StatefulWidget {
  const _Slot({
    required this.unit,
    required this.label,
    required this.stars,
    required this.locked,
    required this.onTap,
  });

  final double unit;
  final String label;
  final int stars;
  final bool locked;
  final VoidCallback onTap;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final locked = widget.locked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRow(stars: widget.stars, size: 9 * u),
        SizedBox(height: 3 * u),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setDown(true),
          onTapUp: (_) => _setDown(false),
          onTapCancel: () => _setDown(false),
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, _down ? 2 * u : 0),
            child: SizedBox(
              width: LevelSelectScreen._tile * u,
              height: LevelSelectScreen._tile * u,
              child: PixelFrame(
                unit: u,
                fill: locked ? PixelUi.panelDark : PixelUi.paper,
                padding: EdgeInsets.zero,
                child: Center(
                  child: locked
                      ? (widget.label.isNotEmpty ? PixelLock(size: 26 * u) : const SizedBox.shrink())
                      : Text(widget.label, style: PixelUi.text(u, scale: 3, color: PixelUi.ink)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
