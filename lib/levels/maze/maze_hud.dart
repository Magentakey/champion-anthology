import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import 'maze_config.dart';
import 'maze_game.dart';
import 'maze_grid.dart';

/// HUD Flutter di atas arena Flame: info step dan waktu, gelembung ucapan Asep,
/// banner step, dan tombol arah. Layout mengikuti Bob the Genius.
class MazeHud extends StatelessWidget {
  const MazeHud({super.key, required this.game});

  final MazeGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

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
                child: _TopBar(step: step, seconds: game.secondsLeft.value),
              ),
              Positioned(
                top: h * MazeLayout.bubbleTop,
                left: c.maxWidth * MazeLayout.bubbleLeft,
                right: 12,
                height: h * MazeLayout.bubbleHeight,
                child: _SpeechBubble(text: game.bossSay.value),
              ),
              if (game.showBanner.value)
                Positioned(
                  top: h * MazeLayout.mazeTop,
                  left: MazeLayout.sideMargin,
                  right: MazeLayout.sideMargin,
                  height: h * MazeLayout.mazeHeight,
                  child: _StepBanner(step: step),
                ),
              Positioned(
                top: h * MazeLayout.padTop,
                left: 0,
                right: 0,
                bottom: h * MazeLayout.padBottom,
                child: _DirPad(game: game),
              ),
            ],
          );
        },
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.seconds});

  final int step;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= MazeTuning.hurrySeconds;
    return Row(
      children: [
        Text(
          'Step $step/${StarCalculator.totalSteps}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 12),
        Icon(Icons.timer_outlined, size: 20, color: urgent ? Colors.red : Colors.black87),
        const SizedBox(width: 4),
        Text(
          '${seconds}s',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: urgent ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Tombol arah berbentuk salib. Tiap tombol memakai Listener agar respons langsung
/// (tanpa menunggu deteksi ketuk) dan bisa ditahan.
class _DirPad extends StatelessWidget {
  const _DirPad({required this.game});

  final MazeGame game;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final b = math.min(math.min((c.maxHeight - 2 * gap) / 3, c.maxWidth / 4), 76.0);
      final side = 3 * b + 2 * gap;
      Widget button(Dir d, IconData icon, double left, double top) => Positioned(
            left: left,
            top: top,
            width: b,
            height: b,
            child: _DirButton(
              dir: d,
              icon: icon,
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
              button(Dir.up, Icons.keyboard_arrow_up, b + gap, 0),
              button(Dir.left, Icons.keyboard_arrow_left, 0, b + gap),
              button(Dir.right, Icons.keyboard_arrow_right, 2 * (b + gap), b + gap),
              button(Dir.down, Icons.keyboard_arrow_down, b + gap, 2 * (b + gap)),
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
    required this.icon,
    required this.onPress,
    required this.onRelease,
  });

  final Dir dir;
  final IconData icon;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: _down ? Colors.grey.shade500 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, c) => Icon(
            widget.icon,
            size: c.maxWidth * 0.8,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Banner besar saat pergantian step (menutupi labirin sebelum waktu mulai).
class _StepBanner extends StatelessWidget {
  const _StepBanner({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final label = mazeStepLabels[(step - 1).clamp(0, mazeStepLabels.length - 1).toInt()];
    return TweenAnimationBuilder<double>(
      key: ValueKey(step),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STEP $step',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

/// Gelembung ucapan Asep di sebelah kanan karakternya.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, alignment: Alignment.centerLeft, child: child),
        ),
        child: text == null
            ? const SizedBox.shrink(key: ValueKey('none'))
            : _BubbleBody(key: ValueKey(text), text: text!),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.grey.shade500);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(border),
          ),
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        // Ekor gelembung menunjuk ke Asep (kiri).
        Positioned(
          left: -6,
          top: 20,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: border, bottom: border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
