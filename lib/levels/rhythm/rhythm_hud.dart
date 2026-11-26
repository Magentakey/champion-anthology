import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'rhythm_calibration.dart';
import 'rhythm_config.dart';
import 'rhythm_dialog.dart';
import 'rhythm_game.dart';
import 'rhythm_judge.dart';
import 'rhythm_stage.dart';

/// Huruf papan ketik tiap pad (sama dengan yang tergambar di pad).
const List<String> rhythmPadKeys = ['D', 'F', 'J', 'K'];

/// HUD bergaya piksel di atas arena Flame: bilah atas (ronde dan akurasi), gelembung ucapan Rhea, banner ronde,
/// hitung mundur, penilaian dekat garis ketuk, bar semangat dengan garis ambang, hitungan combo, dan empat pad
/// ketuk multi-sentuh. Pad memakai [Listener] (bukan GestureDetector) supaya latensi rendah dan beberapa jari
/// dikenali bersamaan.
class RhythmHud extends StatelessWidget {
  const RhythmHud({super.key, required this.game});

  final RhythmGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final h = size.height;
      return Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              game.bossSay,
              game.displayStep,
              game.accuracy,
              game.combo,
              game.showBanner,
              game.countText,
              game.resultText,
            ]),
            builder: (context, _) {
              final step = game.displayStep.value;
              return Stack(
                children: [
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: _TopBar(step: step, accuracy: game.accuracy.value, unit: u),
                  ),
                  Positioned(
                    top: h * RhythmLayout.bubbleTop,
                    left: size.width * RhythmLayout.bubbleLeft,
                    right: 12,
                    height: h * RhythmLayout.bubbleHeight,
                    child: BossSpeechBubble(text: game.bossSay.value),
                  ),
                  Positioned(
                    top: h * RhythmLayout.laneTop,
                    left: RhythmLayout.sideMargin,
                    right: RhythmLayout.sideMargin,
                    height: h * (RhythmLayout.laneBottom - RhythmLayout.laneTop),
                    child: IgnorePointer(
                      child: _LaneOverlay(
                        step: step,
                        banner: game.showBanner.value,
                        count: game.countText.value,
                        result: game.resultText.value,
                        accuracy: game.accuracy.value,
                        unit: u,
                      ),
                    ),
                  ),
                  Positioned(
                    top: h * RhythmLayout.barTop,
                    left: RhythmLayout.sideMargin,
                    right: RhythmLayout.sideMargin,
                    height: h * (RhythmLayout.barBottom - RhythmLayout.barTop),
                    child: _SpiritBar(step: step, accuracy: game.accuracy.value, combo: game.combo.value, unit: u),
                  ),
                ],
              );
            },
          ),
          ValueListenableBuilder<RhythmPopup?>(
            valueListenable: game.popup,
            builder: (context, popup, _) {
              if (popup == null) return const SizedBox.shrink();
              final laneW = RhythmLayout.laneWidth(size.width);
              return Positioned(
                key: const ValueKey('popup'),
                left: RhythmLayout.laneCenterX(popup.lane, size.width) - laneW,
                width: laneW * 2,
                top: RhythmLayout.hitY(h) - 44 * u,
                height: 22 * u,
                child: IgnorePointer(child: _JudgmentText(popup: popup, unit: u)),
              );
            },
          ),
          for (var lane = 0; lane < rhythmLaneCount; lane++)
            Positioned.fromRect(
              rect: RhythmLayout.padRect(lane, size),
              child: _Pad(game: game, lane: lane),
            ),
        ],
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.accuracy, required this.unit});

  final int step;
  final double accuracy;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Row(
      children: [
        Text('Round $step/${StarCalculator.totalSteps}', style: PixelUi.text(u)),
        SizedBox(width: 10 * u),
        Text(
          RhythmDialog.accuracyLabel(accuracy),
          key: const ValueKey('accuracy_label'),
          style: PixelUi.text(u, color: PixelUi.gold),
        ),
      ],
    );
  }
}

/// Banner ronde, hitung mundur, dan hasil step di atas jalur.
class _LaneOverlay extends StatelessWidget {
  const _LaneOverlay({
    required this.step,
    required this.banner,
    required this.count,
    required this.result,
    required this.accuracy,
    required this.unit,
  });

  final int step;
  final bool banner;
  final String? count;
  final String? result;
  final double accuracy;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final idx = (step - 1).clamp(0, rhythmSongTitles.length - 1).toInt();
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
              word: 'ROUND',
              label: rhythmSongTitles[idx],
              note: RhythmDialog.targetLabel(step),
            ),
          ),
        if (count != null)
          Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('count_$count'),
              tween: Tween(begin: 1.6, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Text(
                count!,
                key: const ValueKey('count_text'),
                style: PixelUi.text(u, scale: 3, color: PixelUi.gold, outline: PixelUi.goldOutline, shadow: PixelUi.outline),
              ),
            ),
          ),
        if (result != null)
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * u, vertical: 6 * u),
              color: const Color(0xCC18122A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result!,
                    key: const ValueKey('result_text'),
                    style: PixelUi.text(
                      u,
                      scale: 3,
                      color: result == RhythmDialog.passed ? PixelUi.gold : const Color(0xFFE85050),
                      outline: result == RhythmDialog.passed ? PixelUi.goldOutline : PixelUi.outline,
                      shadow: PixelUi.outline,
                    ),
                  ),
                  SizedBox(height: 4 * u),
                  Text(RhythmDialog.accuracyLabel(accuracy), style: PixelUi.text(u, scale: 2, color: PixelUi.cream)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Bar semangat: akurasi sementara dengan garis ambang lulus, label target, dan hitungan combo.
class _SpiritBar extends StatelessWidget {
  const _SpiritBar({required this.step, required this.accuracy, required this.combo, required this.unit});

  final int step;
  final double accuracy;
  final int combo;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1 * u),
            child: CustomPaint(
              key: const ValueKey('spirit_bar'),
              painter: SpiritBarPainter(fraction: accuracy, threshold: rhythmThresholdOf(step)),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  RhythmDialog.targetLabel(step),
                  key: const ValueKey('target_label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PixelUi.text(u, color: PixelUi.lavender),
                ),
              ),
              if (combo >= 2)
                Text(
                  RhythmDialog.comboLabel(combo),
                  key: const ValueKey('combo_label'),
                  style: PixelUi.text(u, color: PixelUi.gold),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Menggambar bar semangat piksel: bingkai gelap, blok-blok akurasi (hijau bila sudah di atas ambang, biru bila
/// belum), dan garis emas di posisi ambang lulus.
class SpiritBarPainter extends CustomPainter {
  const SpiritBarPainter({required this.fraction, required this.threshold});

  final double fraction;
  final double threshold;

  static const int segments = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fraction.clamp(0.0, 1.0).toDouble();
    final paint = Paint()..isAntiAlias = false;
    paint.color = const Color(0xFF18122A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    final t = (size.height / 6).roundToDouble().clamp(1.0, 4.0).toDouble();
    final inner = Rect.fromLTWH(t, t, size.width - 2 * t, size.height - 2 * t);
    paint.color = const Color(0xFF50466E);
    canvas.drawRect(inner, paint);
    final gap = t;
    final blockW = (inner.width - gap * (segments - 1)) / segments;
    final lit = (f * segments).round();
    paint.color = f >= threshold ? const Color(0xFF54C864) : const Color(0xFF3C7CE0);
    for (var i = 0; i < lit; i++) {
      canvas.drawRect(Rect.fromLTWH(inner.left + i * (blockW + gap), inner.top, blockW, inner.height), paint);
    }
    // garis ambang lulus
    final x = inner.left + inner.width * threshold;
    paint.color = const Color(0xFFFFD640);
    canvas.drawRect(Rect.fromLTWH(x - t / 2, 0, t, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant SpiritBarPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.threshold != threshold;
}

/// Penilaian terbaru dekat garis ketuk: naik pelan dan memudar.
class _JudgmentText extends StatelessWidget {
  const _JudgmentText({required this.popup, required this.unit});

  final RhythmPopup popup;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final String text;
    final Color color;
    final Color outline;
    switch (popup.judgment) {
      case Judgment.perfect:
        text = RhythmDialog.perfect;
        color = PixelUi.gold;
        outline = PixelUi.goldOutline;
      case Judgment.good:
        text = RhythmDialog.good;
        color = PixelUi.cream;
        outline = PixelUi.outline;
      case Judgment.miss:
        text = RhythmDialog.miss;
        color = const Color(0xFFE85050);
        outline = PixelUi.outline;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(popup.serial),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 520),
      builder: (context, t, child) => Opacity(
        opacity: (1 - t * t).clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(offset: Offset(0, -14 * u * t), child: child),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            key: const ValueKey('popup_text'),
            style: PixelUi.text(u, scale: 2, color: color, outline: outline),
          ),
        ),
      ),
    );
  }
}

/// Satu pad ketuk. [Listener] membaca sentuhan langsung, jadi tidak menunggu arena gestur dan tiap pad
/// menerima jarinya sendiri.
class _Pad extends StatelessWidget {
  const _Pad({required this.game, required this.lane});

  final RhythmGame game;
  final int lane;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.padDown[lane],
      builder: (context, down, _) => Listener(
        key: ValueKey('pad_$lane'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => game.pressPad(lane),
        onPointerUp: (_) => game.releasePad(lane),
        onPointerCancel: (_) => game.releasePad(lane),
        child: Semantics(
          button: true,
          label: 'Pad ${rhythmPadKeys[lane]}',
          excludeSemantics: true,
          child: _PadSprite(lane: lane, lit: down),
        ),
      ),
    );
  }
}

/// Gambar pad: berkas 120x96 berisi dua bingkai 60x96 berdampingan (kiri normal, kanan menyala).
class _PadSprite extends StatelessWidget {
  const _PadSprite({required this.lane, required this.lit});

  final int lane;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 60,
        height: 96,
        child: ClipRect(
          child: OverflowBox(
            alignment: lit ? Alignment.centerRight : Alignment.centerLeft,
            minWidth: 120,
            maxWidth: 120,
            minHeight: 96,
            maxHeight: 96,
            child: Image.asset(
              'assets/images/rhythm/pad_$lane.png',
              width: 120,
              height: 96,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel offset suara di layar jeda: tombol - dan + menggeser jadwal not terhadap musik (langkah 10 ms,
/// -150 sampai +150). Tersimpan di perangkat.
class RhythmOffsetControl extends StatelessWidget {
  const RhythmOffsetControl({super.key});

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    final calibration = RhythmCalibration.instance;
    return ValueListenableBuilder<int>(
      valueListenable: calibration.offsetMs,
      builder: (context, ms, _) => PixelFrame(
        unit: u,
        fill: PixelUi.panelDark,
        padding: EdgeInsets.all(5 * u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(RhythmDialog.offsetTitle, style: PixelUi.text(u, color: PixelUi.gold)),
            SizedBox(height: 4 * u),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OffsetButton(
                  key: const ValueKey('offset_minus'),
                  label: '-',
                  enabled: ms > RhythmTuning.minOffsetMs,
                  unit: u,
                  onTap: () => calibration.nudge(-1),
                ),
                SizedBox(width: 6 * u),
                SizedBox(
                  width: 62 * u,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        RhythmDialog.offsetLabel(ms),
                        key: const ValueKey('offset_label'),
                        style: PixelUi.text(u, scale: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6 * u),
                _OffsetButton(
                  key: const ValueKey('offset_plus'),
                  label: '+',
                  enabled: ms < RhythmTuning.maxOffsetMs,
                  unit: u,
                  onTap: () => calibration.nudge(1),
                ),
              ],
            ),
            SizedBox(height: 4 * u),
            Text(
              RhythmDialog.offsetHint,
              textAlign: TextAlign.center,
              style: PixelUi.text(u, color: PixelUi.lavender, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffsetButton extends StatelessWidget {
  const _OffsetButton({super.key, required this.label, required this.enabled, required this.unit, required this.onTap});

  final String label;
  final bool enabled;
  final double unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label == '+' ? 'Tambah offset' : 'Kurangi offset',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 24 * u,
          height: 24 * u,
          child: PixelFrame(
            unit: u,
            fill: enabled ? PixelUi.paper : PixelUi.panelDark,
            padding: EdgeInsets.zero,
            child: Center(
              child: Text(label, style: PixelUi.text(u, scale: 3, color: enabled ? PixelUi.ink : PixelUi.lavender)),
            ),
          ),
        ),
      ),
    );
  }
}
