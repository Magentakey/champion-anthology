import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'maze_config.dart';
import 'maze_game.dart';
import 'maze_grid.dart';

/// HUD bergaya piksel di atas arena Flame: info step dan waktu, gelembung ucapan Asep,
/// banner step, dan tombol arah. Layout mengikuti Bob the Genius.
class MazeHud extends StatelessWidget {
  const MazeHud({super.key, required this.game});

  final MazeGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      return ListenableBuilder(
        listenable: Listenable.merge([
          game.session,
          game.bossSay,
          game.secondsLeft,
          game.showBanner,
        ]),
        builder: (context, _) {
          final step = game.session.step;
          return Stack(
            children: [
              Positioned(
                top: topPad + 8,
                left: 16,
                child: _TopBar(step: step, seconds: game.secondsLeft.value, unit: u),
              ),
              Positioned(
                top: h * MazeLayout.bubbleTop,
                left: c.maxWidth * MazeLayout.bubbleLeft,
                right: 12,
                height: h * MazeLayout.bubbleHeight,
                child: BossSpeechBubble(text: game.bossSay.value),
              ),
              if (game.showBanner.value)
                Positioned(
                  top: h * MazeLayout.mazeTop,
                  left: MazeLayout.sideMargin,
                  right: MazeLayout.sideMargin,
                  height: h * MazeLayout.mazeHeight,
                  child: StepBannerCard(
                    step: step,
                    label: mazeStepLabels[(step - 1).clamp(0, mazeStepLabels.length - 1).toInt()],
                  ),
                ),
              Positioned(
                top: h * MazeLayout.padTop,
                left: 0,
                right: 0,
                bottom: h * MazeLayout.padBottom,
                child: _DirPad(game: game, unit: u),
              ),
            ],
          );
        },
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.seconds, required this.unit});

  final int step;
  final int seconds;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= MazeTuning.hurrySeconds;
    final color = urgent ? const Color(0xFFFF6A5E) : PixelUi.cream;
    return Row(
      children: [
        Text('Step $step/${StarCalculator.totalSteps}', style: PixelUi.text(unit)),
        SizedBox(width: 12 * unit),
        Text('${seconds}s', style: PixelUi.text(unit, scale: 2, color: color, outline: PixelUi.outline)),
      ],
    );
  }
}

/// Tombol arah berbentuk salib. Tiap tombol memakai Listener agar respons langsung
/// (tanpa menunggu deteksi ketuk) dan bisa ditahan.
class _DirPad extends StatelessWidget {
  const _DirPad({required this.game, required this.unit});

  final MazeGame game;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final b = math.min(math.min((c.maxHeight - 2 * gap) / 3, c.maxWidth / 4), 76.0);
      final side = 3 * b + 2 * gap;
      Widget button(Dir d, List<String> arrow, double left, double top) => Positioned(
            left: left,
            top: top,
            width: b,
            height: b,
            child: _DirButton(
              dir: d,
              arrow: arrow,
              unit: unit,
              onPress: game.press,
              onRelease: game.release,
            ),
          );
      return Center(
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            children: [
              button(Dir.up, PixelPatterns.arrowUp, b + gap, 0),
              button(Dir.left, PixelPatterns.arrowLeft, 0, b + gap),
              button(Dir.right, PixelPatterns.arrowRight, 2 * (b + gap), b + gap),
              button(Dir.down, PixelPatterns.arrowDown, b + gap, 2 * (b + gap)),
            ],
          ),
        ),
      );
    });
  }
}

class _DirButton extends StatefulWidget {
  const _DirButton({
    required this.dir,
    required this.arrow,
    required this.unit,
    required this.onPress,
    required this.onRelease,
  });

  final Dir dir;
  final List<String> arrow;
  final double unit;
  final void Function(Dir) onPress;
  final void Function(Dir) onRelease;

  @override
  State<_DirButton> createState() => _DirButtonState();
}

class _DirButtonState extends State<_DirButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    if (down) {
      widget.onPress(widget.dir);
    } else {
      widget.onRelease(widget.dir);
    }
  }

  @override
  void dispose() {
    if (_down) widget.onRelease(widget.dir);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: PixelFrame(
        unit: widget.unit,
        fill: _down ? const Color(0xFF8A74C0) : PixelUi.panelDark,
        padding: EdgeInsets.zero,
        child: Center(
          child: LayoutBuilder(
            builder: (context, c) => PixelIcon(
              rows: widget.arrow,
              size: c.maxWidth * 0.62,
              color: PixelUi.cream,
            ),
          ),
        ),
      ),
    );
  }
}
