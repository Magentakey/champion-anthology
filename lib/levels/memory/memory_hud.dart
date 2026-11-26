import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/level/boss_sprite.dart' show drawPixelTimeBar;
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'memory_config.dart';
import 'memory_dialog.dart';
import 'memory_game.dart';
import 'memory_stage.dart';

/// HUD bergaya piksel di atas arena Flame: bilah atas (ronde), gelembung ucapan Mira, judul fase, "Ingat r/R",
/// penghitung "n/L", baris nyawa, bar timer, banner ronde, hasil step, dan kisi pad ketuk. Pad memakai [Listener]
/// (bukan GestureDetector) supaya latensi rendah. Semua teks berasal dari [MemoryDialog] dan konfigurasi.
class MemoryHud extends StatelessWidget {
  const MemoryHud({super.key, required this.game});

  final MemoryGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final h = size.height;
      return Stack(
        children: [
          // Pad paling belakang agar banner, hasil, dan gelembung tampil di atasnya.
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: game.displayStep,
              builder: (context, step, _) => Stack(
                children: [
                  for (var i = 0; i < memoryPadsOf(step); i++)
                    Positioned.fromRect(
                      rect: MemoryLayout.padRect(step, i, size),
                      child: _Pad(game: game, index: i),
                    ),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              game.bossSay,
              game.displayStep,
              game.roundNo,
              game.correct,
              game.lives,
              game.sequenceLength,
              game.statusText,
              game.showBanner,
              game.resultText,
            ]),
            builder: (context, _) {
              final step = game.displayStep.value;
              return Stack(
                children: [
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: Text(
                      MemoryDialog.roundLabel(step),
                      key: const ValueKey('round_label'),
                      style: PixelUi.text(u),
                    ),
                  ),
                  Positioned(
                    top: h * MemoryLayout.bubbleTop,
                    left: size.width * MemoryLayout.bubbleLeft,
                    right: 12,
                    height: h * MemoryLayout.bubbleHeight,
                    child: BossSpeechBubble(text: game.bossSay.value),
                  ),
                  Positioned.fromRect(
                    rect: MemoryLayout.statusRect(size),
                    child: _Status(
                      step: step,
                      round: game.roundNo.value,
                      correct: game.correct.value,
                      length: game.sequenceLength.value,
                      lives: game.lives.value,
                      status: game.statusText.value,
                      unit: u,
                    ),
                  ),
                  Positioned.fromRect(
                    rect: MemoryLayout.timerRect(size),
                    child: ValueListenableBuilder<double>(
                      valueListenable: game.timeLeft,
                      builder: (context, fraction, _) => CustomPaint(
                        key: const ValueKey('timer_bar'),
                        painter: MemoryTimerPainter(fraction),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: MemoryLayout.padArea(size),
                    child: IgnorePointer(
                      child: _Overlay(
                        step: step,
                        banner: game.showBanner.value,
                        result: game.resultText.value,
                        unit: u,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

/// Judul fase, "Ingat r/R", penghitung "n/L", dan baris nyawa.
class _Status extends StatelessWidget {
  const _Status({
    required this.step,
    required this.round,
    required this.correct,
    required this.length,
    required this.lives,
    required this.status,
    required this.unit,
  });

  final int step;
  final int round;
  final int correct;
  final int length;
  final int lives;
  final String status;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final maxLives = memoryLivesOf(step);
    final isBad = status == MemoryDialog.wrong || status == MemoryDialog.timeUp;
    final statusColor = isBad
        ? const Color(0xFFE85050)
        : status == MemoryDialog.right
            ? PixelUi.gold
            : PixelUi.cream;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              key: const ValueKey('phase_label'),
              style: PixelUi.text(u, scale: 2, color: statusColor, outline: PixelUi.outline),
            ),
            SizedBox(height: 2 * u),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MemoryDialog.rememberLabel(round, memoryRoundsOf(step)),
                  key: const ValueKey('remember_label'),
                  style: PixelUi.text(u, color: PixelUi.lavender),
                ),
                SizedBox(width: 8 * u),
                Text(
                  MemoryDialog.counterLabel(correct, length),
                  key: const ValueKey('counter_label'),
                  style: PixelUi.text(u, color: PixelUi.gold),
                ),
                SizedBox(width: 8 * u),
                Text(MemoryDialog.livesLabel, style: PixelUi.text(u)),
                SizedBox(width: 3 * u),
                for (var i = 0; i < maxLives; i++)
                  Padding(
                    padding: EdgeInsets.only(right: 2 * u),
                    child: Image.asset(
                      i < lives ? 'assets/images/memory/heart_on.png' : 'assets/images/memory/heart_off.png',
                      key: ValueKey(i < lives ? 'heart_on_$i' : 'heart_off_$i'),
                      width: 9 * u,
                      height: 9 * u,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner ronde (tahap intro) dan hasil step di atas area pad.
class _Overlay extends StatelessWidget {
  const _Overlay({required this.step, required this.banner, required this.result, required this.unit});

  final int step;
  final bool banner;
  final String? result;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Stack(
      children: [
        if (banner)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 80 * u,
            child: StepBannerCard(
              step: step,
              word: MemoryDialog.bannerWord,
              label: MemoryDialog.padsLabel(step),
              note: MemoryDialog.lengthRangeLabel(step),
            ),
          ),
        if (result != null)
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * u, vertical: 6 * u),
              color: const Color(0xCC18122A),
              child: Text(
                result!,
                key: const ValueKey('result_text'),
                style: PixelUi.text(
                  u,
                  scale: 3,
                  color: result == MemoryDialog.passed ? PixelUi.gold : const Color(0xFFE85050),
                  outline: result == MemoryDialog.passed ? PixelUi.goldOutline : PixelUi.outline,
                  shadow: PixelUi.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bar timer antar-ketukan: menyusut selama giliran pemain (memakai gaya bar waktu level lain).
class MemoryTimerPainter extends CustomPainter {
  const MemoryTimerPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) => drawPixelTimeBar(canvas, size.width, size.height, fraction);

  @override
  bool shouldRepaint(covariant MemoryTimerPainter oldDelegate) => oldDelegate.fraction != fraction;
}

/// Satu pad ketuk. [Listener] membaca sentuhan langsung dan hanya menanggapi sentuh-turun (bukan lepas), supaya
/// terasa responsif. Menyala saat jari menempel, saat ditayangkan, dan saat berkedip menunjukkan jawaban benar.
class _Pad extends StatelessWidget {
  const _Pad({required this.game, required this.index});

  final MemoryGame game;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game.padDown[index], game.litPad, game.blinkPad, game.wrongTap]),
      builder: (context, _) {
        final lit = game.padDown[index].value || game.litPad.value == index || game.blinkPad.value == index;
        final wrong = game.wrongTap.value;
        Widget sprite = _PadSprite(index: index, lit: lit);
        if (wrong != null && wrong.pad == index) {
          sprite = _Shake(key: ValueKey('shake_${wrong.serial}'), child: sprite);
        }
        return Listener(
          key: ValueKey('pad_$index'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => game.pressPad(index),
          onPointerUp: (_) => game.releasePad(index),
          onPointerCancel: (_) => game.releasePad(index),
          child: Semantics(
            button: true,
            label: 'Pad ${index + 1} ${memoryPadShapes[index]}',
            excludeSemantics: true,
            child: sprite,
          ),
        );
      },
    );
  }
}

/// Getaran singkat satu kali (tidak berulang) untuk pad yang salah diketuk.
class _Shake extends StatelessWidget {
  const _Shake({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: MemoryTuning.wrongFlashMs),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 5 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// Gambar pad: berkas 120x60 berisi dua bingkai 60x60 berdampingan (kiri redup, kanan menyala).
class _PadSprite extends StatelessWidget {
  const _PadSprite({required this.index, required this.lit});

  final int index;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 60,
        height: 60,
        child: ClipRect(
          child: OverflowBox(
            alignment: lit ? Alignment.centerRight : Alignment.centerLeft,
            minWidth: 120,
            maxWidth: 120,
            minHeight: 60,
            maxHeight: 60,
            child: Image.asset(
              'assets/images/memory/pad_$index.png',
              width: 120,
              height: 60,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}
