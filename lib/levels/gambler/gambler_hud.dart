import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'gambler_config.dart';
import 'gambler_dialog.dart';
import 'gambler_game.dart';
import 'gambler_table.dart';

/// HUD bergaya piksel di atas arena Flame: info ronde dan chip, gelembung ucapan Mr. Lexi, banner ronde,
/// label peluang, area ketuk untuk kartu atau cangkir (atau tombol KEPALA dan EKOR), dan tombol BUKA atau LEMPAR.
class GamblerHud extends StatelessWidget {
  const GamblerHud({super.key, required this.game});

  final GamblerGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      return Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([game.session, game.bossSay, game.chips, game.showBanner, game.bannerStep, game.shownStep]),
            builder: (context, _) {
              final step = game.bannerStep.value;
              final shown = game.shownStep.value;
              return Stack(
                children: [
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: _TopBar(step: step, chips: game.chips.value, unit: u),
                  ),
                  Positioned(
                    top: h * GamblerLayout.bubbleTop,
                    left: c.maxWidth * GamblerLayout.bubbleLeft,
                    right: 12,
                    height: h * GamblerLayout.bubbleHeight,
                    child: BossSpeechBubble(text: game.bossSay.value),
                  ),
                  if (game.showBanner.value)
                    Positioned(
                      top: h * GamblerLayout.tableTop,
                      left: GamblerLayout.sideMargin,
                      right: GamblerLayout.sideMargin,
                      height: h * GamblerLayout.tableHeight,
                      child: StepBannerCard(
                        step: step,
                        word: 'ROUND',
                        label: gamblerStepLabels[(step - 1).clamp(0, gamblerStepLabels.length - 1).toInt()],
                      ),
                    ),
                  Positioned(
                    top: h * GamblerLayout.oddsTop,
                    left: GamblerLayout.sideMargin,
                    right: GamblerLayout.sideMargin,
                    height: h * GamblerLayout.oddsHeight,
                    child: _OddsRow(step: shown, unit: u),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: h * GamblerLayout.tableTop,
            left: GamblerLayout.sideMargin,
            right: GamblerLayout.sideMargin,
            height: h * GamblerLayout.tableHeight,
            child: _PickLayer(game: game, unit: u),
          ),
          Positioned(
            top: h * GamblerLayout.controlTop,
            left: GamblerLayout.sideMargin,
            right: GamblerLayout.sideMargin,
            bottom: h * GamblerLayout.controlBottom,
            child: _ControlPanel(game: game, unit: u),
          ),
        ],
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.chips, required this.unit});

  final int step;
  final int chips;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Row(
      children: [
        Text('Round $step/${StarCalculator.totalSteps}', style: PixelUi.text(u)),
        SizedBox(width: 10 * u),
        Text('Chip', style: PixelUi.text(u, color: PixelUi.lavender)),
        SizedBox(width: 4 * u),
        for (var i = 0; i < StarCalculator.totalSteps; i++) ...[
          if (i > 0) SizedBox(width: 2 * u),
          Opacity(
            opacity: i < chips ? 1 : 0.3,
            child: Image.asset(
              'assets/images/gambler/chip.png',
              width: 12 * u,
              height: 12 * u,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ],
    );
  }
}

/// Label peluang menang step ini. Angkanya selalu dari konfigurasi dan tidak pernah berubah.
class _OddsRow extends StatelessWidget {
  const _OddsRow({required this.step, required this.unit});

  final int step;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * u, vertical: 2 * u),
        color: const Color(0xCC18122A),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            GamblerDialog.oddsLabel(step),
            key: const ValueKey('odds_label'),
            style: PixelUi.text(u, scale: 2, color: PixelUi.gold),
          ),
        ),
      ),
    );
  }
}

/// Area ketuk di atas meja: satu area per kartu atau cangkir, atau dua tombol KEPALA dan EKOR untuk koin.
class _PickLayer extends StatelessWidget {
  const _PickLayer({required this.game, required this.unit});

  final GamblerGame game;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game.shownStep, game.phase, game.selected, game.showBanner]),
      builder: (context, _) {
        final kind = gamblerGameOf(game.shownStep.value);
        final picking = game.phase.value == GamblerPhase.choosing;
        final picked = game.selected.value;
        return LayoutBuilder(builder: (context, c) {
          final area = Size(c.maxWidth, c.maxHeight);
          final children = <Widget>[];
          if (game.showBanner.value) {
            // banner ronde sedang tampil: pilihan koin belum boleh muncul di belakang atau di atasnya
          } else if (kind == LuckGame.coin) {
            for (var side = 0; side < GamblerTuning.coinSides; side++) {
              children.add(Positioned.fromRect(
                rect: GamblerLayout.coinChoiceRect(side, area),
                child: _CoinChoice(
                  label: side == 0 ? 'KEPALA' : 'EKOR',
                  selected: picked == side,
                  enabled: picking,
                  unit: unit,
                  onTap: () => game.select(side),
                ),
              ));
            }
          } else {
            final count = kind == LuckGame.card ? GamblerTuning.cardCount : GamblerTuning.cupCount;
            final noun = kind == LuckGame.card ? 'Kartu' : 'Cangkir';
            for (var i = 0; i < count; i++) {
              children.add(Positioned.fromRect(
                rect: GamblerLayout.slotRect(kind, i, area).inflate(4),
                child: Semantics(
                  button: true,
                  label: '$noun ${i + 1}',
                  child: GestureDetector(
                    key: ValueKey('slot_$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => game.select(i),
                    child: const SizedBox.expand(),
                  ),
                ),
              ));
            }
          }
          return Stack(children: children);
        });
      },
    );
  }
}

class _CoinChoice extends StatelessWidget {
  const _CoinChoice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.unit,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final double unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: SizedBox.expand(
            child: PixelFrame(
              unit: u,
              fill: selected ? PixelUi.gold : PixelUi.paper,
              padding: EdgeInsets.all(3 * u),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: PixelUi.text(u, scale: 2, color: PixelUi.ink)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.game, required this.unit});

  final GamblerGame game;
  final double unit;

  static String hintFor(GamblerPhase phase, int step, int? picked) {
    final i = (step - 1).clamp(0, 2).toInt();
    switch (phase) {
      case GamblerPhase.intro:
        return GamblerDialog.stepIntro[i];
      case GamblerPhase.prepare:
        return GamblerDialog.hintShuffle;
      case GamblerPhase.choosing:
        return picked == null ? GamblerDialog.hintPick[i] : GamblerDialog.hintReady[i];
      case GamblerPhase.reveal:
      case GamblerPhase.result:
      case GamblerPhase.done:
        return GamblerDialog.hintReveal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.panelDark,
        padding: EdgeInsets.all(6 * u),
        child: ListenableBuilder(
          listenable: Listenable.merge([game.session, game.shownStep, game.phase, game.selected]),
          builder: (context, _) {
            final step = game.phase.value == GamblerPhase.intro ? game.session.step : game.shownStep.value;
            final enabled = game.canConfirm;
            final hint = hintFor(game.phase.value, step, game.selected.value);
            final label = GamblerDialog.confirmLabel[(step - 1).clamp(0, 2).toInt()];
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hint,
                      key: const ValueKey('hint'),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: PixelUi.text(u, color: enabled ? PixelUi.gold : PixelUi.cream, height: 1.2),
                    ),
                  ),
                ),
                SizedBox(width: 8 * u),
                Expanded(
                  flex: 4,
                  child: Semantics(
                    button: true,
                    enabled: enabled,
                    label: label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const ValueKey('confirm'),
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled ? game.confirm : null,
                      child: SizedBox.expand(
                        child: PixelFrame(
                          unit: u,
                          fill: enabled ? const Color(0xFF8FD48F) : const Color(0xFF6B6480),
                          padding: EdgeInsets.all(4 * u),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: PixelUi.text(u, scale: 3, color: enabled ? PixelUi.ink : PixelUi.lavender),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
