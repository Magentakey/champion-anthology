import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'archery_config.dart';
import 'archery_game.dart';

/// HUD bergaya piksel di atas arena Flame: info step, skor dan anak panah, gelembung ucapan Bima,
/// banner step, penunjuk angin, meter kekuatan, dan tombol tarik busur.
class ArcheryHud extends StatelessWidget {
  const ArcheryHud({super.key, required this.game});

  final ArcheryGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      return Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              game.session,
              game.bossSay,
              game.score,
              game.arrowsLeft,
              game.wind,
              game.showBanner,
            ]),
            builder: (context, _) {
              final step = game.session.step;
              return Stack(
                children: [
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: _TopBar(game: game, step: step, unit: u),
                  ),
                  Positioned(
                    top: h * ArcheryLayout.bubbleTop,
                    left: c.maxWidth * ArcheryLayout.bubbleLeft,
                    right: 12,
                    height: h * ArcheryLayout.bubbleHeight,
                    child: BossSpeechBubble(text: game.bossSay.value),
                  ),
                  if (game.showBanner.value)
                    Positioned(
                      top: h * ArcheryLayout.rangeTop,
                      left: ArcheryLayout.sideMargin,
                      right: ArcheryLayout.sideMargin,
                      height: h * ArcheryLayout.rangeHeight,
                      child: StepBannerCard(
                        step: step,
                        label: archeryStepLabels[(step - 1).clamp(0, archeryStepLabels.length - 1).toInt()],
                      ),
                    ),
                  Positioned(
                    top: h * ArcheryLayout.windTop,
                    left: ArcheryLayout.sideMargin,
                    right: ArcheryLayout.sideMargin,
                    height: h * ArcheryLayout.windHeight,
                    child: _WindRow(wind: game.wind.value, unit: u),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: h * ArcheryLayout.controlTop,
            left: ArcheryLayout.sideMargin,
            right: ArcheryLayout.sideMargin,
            bottom: h * ArcheryLayout.controlBottom,
            child: _ControlPanel(game: game, unit: u),
          ),
          Positioned(
            top: h * (ArcheryLayout.rangeTop + ArcheryLayout.rangeHeight * 0.30),
            left: 0,
            right: 0,
            child: IgnorePointer(child: _ScorePopup(popup: game.popup, unit: u)),
          ),
        ],
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.step, required this.unit});

  final ArcheryGame game;
  final int step;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final reached = game.score.value >= game.targetScore;
    final left = game.arrowsLeft.value;
    final total = game.arrowsTotal;
    return Row(
      children: [
        Text('Step $step/${StarCalculator.totalSteps}', style: PixelUi.text(u)),
        SizedBox(width: 10 * u),
        Text(
          'Skor ${game.score.value}/${game.targetScore}',
          style: PixelUi.text(u, color: reached ? PixelUi.gold : PixelUi.cream, outline: PixelUi.outline),
        ),
        SizedBox(width: 10 * u),
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: u),
          Opacity(
            opacity: i < left ? 1 : 0.3,
            child: PixelIcon(
              rows: PixelPatterns.arrowItem,
              size: 10 * u,
              colorOf: (ch) => switch (ch) {
                'k' => const Color(0xFFB98350),
                'r' => const Color(0xFFE03C3C),
                _ => const Color(0xFFCFD8DC),
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Penunjuk angin: tenang, atau 1 sampai 3 panah ke arah angin (makin banyak = makin kencang).
class _WindRow extends StatelessWidget {
  const _WindRow({required this.wind, required this.unit});

  final double wind;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final calm = wind.abs() < 0.01;
    final strength = (wind.abs() / 0.2).ceil().clamp(1, 3).toInt();
    final rows = wind < 0 ? PixelPatterns.arrowLeft : PixelPatterns.arrowRight;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * u, vertical: 2 * u),
        color: const Color(0xCC18122A),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Angin', style: PixelUi.text(u)),
            SizedBox(width: 6 * u),
            if (calm)
              Text('Tenang', style: PixelUi.text(u, color: PixelUi.lavender))
            else
              for (var i = 0; i < strength; i++) ...[
                if (i > 0) SizedBox(width: u),
                PixelIcon(rows: rows, size: 9 * u, color: PixelUi.cream),
              ],
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.game, required this.unit});

  final ArcheryGame game;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.panelDark,
        padding: EdgeInsets.all(6 * u),
        child: ValueListenableBuilder<bool>(
          valueListenable: game.drawing,
          builder: (context, drawing, _) => Row(
            children: [
              Expanded(
                flex: 5,
                child: ValueListenableBuilder<double>(
                  valueListenable: game.power,
                  builder: (context, power, _) {
                    final full = power >= ArcheryTuning.minPower;
                    final hint = !drawing
                        ? 'Tahan tombol untuk menarik busur'
                        : (full ? 'Lepas saat bidikan kuning di tengah!' : 'Tarik terus...');
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PixelUi.text(u, color: full ? PixelUi.gold : PixelUi.cream, height: 1.15),
                        ),
                        SizedBox(height: 6 * u),
                        _PowerBar(power: power, unit: u),
                        SizedBox(height: 3 * u),
                        Text('Kekuatan', style: PixelUi.text(u, color: PixelUi.lavender)),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(width: 8 * u),
              Expanded(
                flex: 4,
                child: _DrawButton(game: game, drawing: drawing, unit: u),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Meter kekuatan berblok: oranye saat belum cukup, hijau saat busur sudah cukup tegang.
class _PowerBar extends StatelessWidget {
  const _PowerBar({required this.power, required this.unit});

  final double power;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12 * unit,
      width: double.infinity,
      child: CustomPaint(painter: _PowerPainter(power, unit)),
    );
  }
}

class _PowerPainter extends CustomPainter {
  _PowerPainter(this.power, this.unit);

  final double power;
  final double unit;

  static const _segments = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final t = unit.clamp(1.0, 5.0).toDouble();
    paint.color = PixelUi.cream;
    canvas.drawRect(Offset.zero & size, paint);
    paint.color = PixelUi.outline;
    canvas.drawRect(Rect.fromLTWH(t, t, size.width - 2 * t, size.height - 2 * t), paint);
    final inner = Rect.fromLTWH(2 * t, 2 * t, size.width - 4 * t, size.height - 4 * t);
    paint.color = const Color(0xFF50466E);
    canvas.drawRect(inner, paint);

    final gap = t;
    final blockW = (inner.width - gap * (_segments - 1)) / _segments;
    final lit = (power * _segments).ceil();
    final minLit = (ArcheryTuning.minPower * _segments).ceil();
    for (var i = 0; i < lit; i++) {
      paint.color = i + 1 >= minLit ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00);
      canvas.drawRect(Rect.fromLTWH(inner.left + i * (blockW + gap), inner.top, blockW, inner.height), paint);
    }
    // penanda kekuatan minimum
    final markX = inner.left + (minLit - 1) * (blockW + gap) - gap / 2;
    paint.color = PixelUi.cream;
    canvas.drawRect(Rect.fromLTWH(markX - t / 2, 0, t, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter oldDelegate) => true;
}

/// Tombol tarik: ditahan untuk menarik, dilepas untuk menembak. Memakai Listener agar respons langsung.
class _DrawButton extends StatelessWidget {
  const _DrawButton({required this.game, required this.drawing, required this.unit});

  final ArcheryGame game;
  final bool drawing;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Semantics(
      button: true,
      label: 'Tarik busur',
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => game.pressDraw(),
        onPointerUp: (_) => game.releaseDraw(),
        onPointerCancel: (_) => game.releaseDraw(),
        child: Transform.translate(
          offset: Offset(0, drawing ? 3 * u : 0),
          child: SizedBox.expand(
            child: PixelFrame(
              unit: u,
              fill: drawing ? const Color(0xFFF08A80) : const Color(0xFF8FD48F),
              padding: EdgeInsets.all(4 * u),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    drawing ? 'LEPAS!' : 'TARIK',
                    style: PixelUi.text(u, scale: 3, color: PixelUi.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skor yang melayang naik dan memudar setelah anak panah mendarat.
class _ScorePopup extends StatelessWidget {
  const _ScorePopup({required this.popup, required this.unit});

  final ValueNotifier<ShotPopup?> popup;
  final double unit;

  static Color _colorFor(int score) => switch (score) {
        10 => const Color(0xFFFFD640),
        8 => const Color(0xFFFFA726),
        6 => const Color(0xFFFFF4D6),
        4 => const Color(0xFFBEB4DC),
        2 => const Color(0xFFB0BEC5),
        _ => const Color(0xFFFF6A5E),
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShotPopup?>(
      valueListenable: popup,
      builder: (context, p, _) {
        if (p == null) return const SizedBox.shrink();
        return TweenAnimationBuilder<double>(
          key: ValueKey(p.id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, t, _) => Opacity(
            opacity: (1 - t * t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -28 * t),
              child: Center(
                child: Text(
                  p.score > 0 ? '+${p.score}' : 'Meleset',
                  style: PixelUi.text(
                    unit,
                    scale: 3,
                    color: _colorFor(p.score),
                    outline: PixelUi.outline,
                    shadow: PixelUi.dark,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
