import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/hit_effect.dart';
import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'cooking_checks.dart';
import 'cooking_config.dart';
import 'cooking_game.dart';
import 'cooking_models.dart';

/// HUD bergaya piksel di atas arena Flame: info step dan waktu, gelembung ucapan Chef, kartu pesanan,
/// tiga stasiun (target geser), baki bahan, dan panel cooking check.
class CookingHud extends StatelessWidget {
  const CookingHud({super.key, required this.game});

  final CookingGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return HitEffect(
      trigger: game.wrongCount,
      child: LayoutBuilder(builder: (context, c) {
        final h = c.maxHeight;
        return ListenableBuilder(
          listenable: Listenable.merge([
            game.session,
            game.bossSay,
            game.secondsLeft,
            game.showBanner,
            game.order,
            game.tray,
            game.done,
            game.activeCheck,
          ]),
          builder: (context, _) {
            final step = game.session.step;
            final order = game.order.value;
            final check = game.activeCheck.value;
            const side = CookingLayout.sideMargin;
            return Stack(
              children: [
                Positioned(
                  top: topPad + 8,
                  left: 16,
                  child: _TopBar(step: step, seconds: game.secondsLeft.value, unit: u),
                ),
                Positioned(
                  top: topPad + 4,
                  left: 170,
                  child: _TimePopup(event: game.timeEvent, unit: u),
                ),
                Positioned(
                  top: h * CookingLayout.bubbleTop,
                  left: c.maxWidth * CookingLayout.bubbleLeft,
                  right: 12,
                  height: h * CookingLayout.bubbleHeight,
                  child: BossSpeechBubble(text: game.bossSay.value),
                ),
                if (order != null) ...[
                  Positioned(
                    top: h * CookingLayout.orderTop,
                    left: side,
                    right: side,
                    height: h * CookingLayout.orderHeight,
                    child: _OrderCard(order: order, done: game.done.value, unit: u),
                  ),
                  Positioned(
                    top: h * CookingLayout.lowerTop,
                    left: side,
                    right: side,
                    height: h * CookingLayout.stationsHeight,
                    child: Row(
                      children: [
                        for (final s in Station.values) ...[
                          if (s != Station.chop) SizedBox(width: 6 * u),
                          Expanded(child: _StationTile(station: s, game: game, unit: u)),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * CookingLayout.trayTop,
                    left: side,
                    right: side,
                    bottom: h * CookingLayout.lowerBottom,
                    child: _Tray(ids: game.tray.value, canDrag: game.canAct, unit: u),
                  ),
                ],
                if (check != null)
                  Positioned(
                    top: h * CookingLayout.lowerTop,
                    left: side,
                    right: side,
                    bottom: h * CookingLayout.lowerBottom,
                    child: _CheckPanel(game: game, check: check, unit: u),
                  ),
                if (game.showBanner.value)
                  Positioned(
                    top: h * CookingLayout.lowerTop,
                    left: side,
                    right: side,
                    bottom: h * CookingLayout.lowerBottom,
                    child: StepBannerCard(
                      step: step,
                      label: cookingStepLabels[(step - 1).clamp(0, cookingStepLabels.length - 1).toInt()],
                    ),
                  ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.seconds, required this.unit});

  final int step;
  final int seconds;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= CookingTuning.hurrySeconds;
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

/// "-3s" merah (penalti) atau "+1s" hijau (bonus) yang melayang naik dan memudar.
class _TimePopup extends StatelessWidget {
  const _TimePopup({required this.event, required this.unit});

  final ValueNotifier<TimeEvent?> event;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimeEvent?>(
      valueListenable: event,
      builder: (context, e, _) {
        if (e == null) return const SizedBox.shrink();
        final bonus = e.seconds > 0;
        return TweenAnimationBuilder<double>(
          key: ValueKey(e.id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          builder: (context, t, _) => Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -18 * t),
              child: Text(
                '${bonus ? '+' : ''}${e.seconds}s',
                style: PixelUi.text(
                  unit,
                  scale: 2,
                  color: bonus ? const Color(0xFF7DE08A) : const Color(0xFFFF6A5E),
                  outline: PixelUi.outline,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _stationColor(Station s) => switch (s) {
      Station.chop => const Color(0xFFA5D6A7),
      Station.boil => const Color(0xFF90CAF9),
      Station.fry => const Color(0xFFFFCC80),
    };

/// Kartu pesanan: nama masakan dan bahan yang harus dimasak (dicentang jika sudah).
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.done, required this.unit});

  final Order order;
  final Set<String> done;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.paper,
        padding: EdgeInsets.symmetric(horizontal: 6 * u, vertical: 4 * u),
        child: Column(
          children: [
            Text(
              'PESANAN: ${order.recipe.name.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PixelUi.text(u, color: PixelUi.ink),
            ),
            SizedBox(height: 3 * u),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (final i in order.ingredients) _OrderChip(ingredient: i, finished: done.contains(i.id), unit: u),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderChip extends StatelessWidget {
  const _OrderChip({required this.ingredient, required this.finished, required this.unit});

  final Ingredient ingredient;
  final bool finished;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox(
      width: 46 * u,
      child: Opacity(
        opacity: finished ? 0.5 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  ingredient.imageAsset,
                  width: 20 * u,
                  height: 20 * u,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
                if (finished)
                  PixelIcon(
                    rows: PixelPatterns.check,
                    size: 14 * u,
                    color: const Color(0xFF3FBF55),
                  ),
              ],
            ),
            Text(ingredient.name, style: PixelUi.text(u, color: PixelUi.ink)),
            SizedBox(height: u),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2 * u),
              color: _stationColor(ingredient.station),
              child: Text(ingredient.station.verb, style: PixelUi.text(u, color: PixelUi.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stasiun masak: target jatuhnya bahan.
class _StationTile extends StatelessWidget {
  const _StationTile({required this.station, required this.game, required this.unit});

  final Station station;
  final CookingGame game;
  final double unit;

  String get _asset => 'assets/images/cooking/station_${station.name}.png';

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => game.canAct,
      onAcceptWithDetails: (d) => game.drop(d.data, station),
      builder: (context, candidates, rejected) {
        final hot = candidates.isNotEmpty;
        return SizedBox.expand(
          child: PixelFrame(
            unit: u,
            fill: hot ? const Color(0xFFFFD98A) : PixelUi.paper,
            padding: EdgeInsets.all(3 * u),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    _asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
                Text(station.label, style: PixelUi.text(u, color: PixelUi.ink)),
                Text('(${station.verb})', style: PixelUi.text(u, color: const Color(0xFF6E5A96))),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Baki bahan (bahan pesanan + pengecoh). Tiap bahan bisa digeser ke stasiun.
class _Tray extends StatelessWidget {
  const _Tray({required this.ids, required this.canDrag, required this.unit});

  final List<String> ids;
  final bool canDrag;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.panelDark,
        padding: EdgeInsets.all(3 * u),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 4 * 76,
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 4,
                children: [
                  for (final id in ids) _TrayItem(ingredient: ingredientById(id), canDrag: canDrag, unit: u),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrayItem extends StatelessWidget {
  const _TrayItem({required this.ingredient, required this.canDrag, required this.unit});

  final Ingredient ingredient;
  final bool canDrag;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            ingredient.imageAsset,
            width: 56,
            height: 56,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
          Text(ingredient.name, style: PixelUi.text(unit)),
        ],
      ),
    );
    return Draggable<String>(
      data: ingredient.id,
      maxSimultaneousDrags: canDrag ? 1 : 0,
      // ikon di bawah jari agar posisi jatuhnya jelas
      dragAnchorStrategy: (draggable, context, position) => const Offset(34, 34),
      feedback: Material(
        type: MaterialType.transparency,
        child: Image.asset(
          ingredient.imageAsset,
          width: 68,
          height: 68,
          filterQuality: FilterQuality.none,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }
}

// ---------------- panel cooking check ----------------
class _CheckPanel extends StatelessWidget {
  const _CheckPanel({required this.game, required this.check, required this.unit});

  final CookingGame game;
  final CookingCheck check;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final ingredient = game.checkingId == null ? null : ingredientById(game.checkingId!);
    final title = switch (check.station) {
      Station.chop => 'Iris ${ingredient?.name ?? ''}!',
      Station.boil => 'Rebus ${ingredient?.name ?? ''}!',
      Station.fry => 'Goreng ${ingredient?.name ?? ''}!',
    };
    final hint = switch (check.station) {
      Station.chop => 'Ketuk terus sampai bar penuh!',
      Station.boil => 'Tahan api untuk naik, lepas untuk turun. Jaga di zona hijau!',
      Station.fry => 'Ketuk BALIK! saat jarum di zona emas!',
    };
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.paper,
        padding: EdgeInsets.all(6 * u),
        child: Column(
          children: [
            Row(
              children: [
                if (ingredient != null)
                  Image.asset(
                    ingredient.imageAsset,
                    width: 24 * u,
                    height: 24 * u,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                SizedBox(width: 6 * u),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PixelUi.text(u, scale: 2, color: PixelUi.ink),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3 * u),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(hint, style: PixelUi.text(u, color: const Color(0xFF6E5A96), height: 1.15)),
            ),
            SizedBox(height: 6 * u),
            Expanded(
              child: ListenableBuilder(
                listenable: game.checkTick,
                builder: (context, _) => switch (check) {
                  final ChopCheck c => _ChopBody(game: game, check: c, unit: u),
                  final BoilCheck c => _BoilBody(game: game, check: c, unit: u),
                  final FryCheck c => _FryBody(game: game, check: c, unit: u),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol besar piksel yang bereaksi pada sentuhan awal (tanpa menunggu deteksi ketuk).
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.unit,
    required this.onDown,
    this.onUp,
    this.pressed = false,
    this.icon,
  });

  final String label;
  final Color color;
  final double unit;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final bool pressed;
  final List<String>? icon;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp?.call(),
      onPointerCancel: (_) => onUp?.call(),
      child: Transform.translate(
        offset: Offset(0, pressed ? 3 * u : 0),
        child: SizedBox.expand(
          child: PixelFrame(
            unit: u,
            fill: color,
            padding: EdgeInsets.all(4 * u),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      PixelIcon(rows: icon!, size: 28 * u, color: const Color(0xFFE65100)),
                      SizedBox(height: 4 * u),
                    ],
                    Text(label, style: PixelUi.text(u, scale: 2, color: PixelUi.ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChopBody extends StatelessWidget {
  const _ChopBody({required this.game, required this.check, required this.unit});

  final CookingGame game;
  final ChopCheck check;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PixelBar(value: check.progress, color: const Color(0xFF3FBF55), unit: unit),
        SizedBox(height: 8 * unit),
        Expanded(
          child: _BigButton(
            label: 'KETUK TERUS!',
            color: const Color(0xFF8FD48F),
            unit: unit,
            pressed: check.tapCount.isOdd,
            onDown: game.tapCheck,
          ),
        ),
      ],
    );
  }
}

class _BoilBody extends StatelessWidget {
  const _BoilBody({required this.game, required this.check, required this.unit});

  final CookingGame game;
  final BoilCheck check;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Column(
      children: [
        PixelBar(value: check.progress, color: const Color(0xFF3C7CE0), unit: u),
        SizedBox(height: 8 * u),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _ThermometerPainter(check, u),
                      ),
                    ),
                    SizedBox(height: 4 * u),
                    Text(
                      check.danger ? 'AWAS MELUAP!' : (check.inZone ? 'Pas!' : 'Atur suhu'),
                      style: PixelUi.text(
                        u,
                        color: check.danger ? const Color(0xFFD62828) : PixelUi.ink,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * u),
              Expanded(
                flex: 3,
                child: _BigButton(
                  label: 'TAHAN API',
                  color: check.holding ? const Color(0xFFF08A80) : const Color(0xFFFFCC80),
                  unit: u,
                  icon: PixelPatterns.fire,
                  pressed: check.holding,
                  onDown: () => game.holdCheck(true),
                  onUp: () => game.holdCheck(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  _ThermometerPainter(this.check, this.unit);

  final BoilCheck check;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width.clamp(0.0, 60.0);
    final left = (size.width - w) / 2;
    final t = unit.clamp(1.0, 5.0);

    paint.color = PixelUi.outline;
    canvas.drawRect(Rect.fromLTWH(left - t, -t, w + 2 * t, size.height + 2 * t), paint);
    paint.color = const Color(0xFFD6D0E4);
    canvas.drawRect(Rect.fromLTWH(left, 0, w, size.height), paint);

    double yOf(double v) => size.height * (1 - v);
    final p = check.params;
    paint.color = const Color(0xFF4CAF50);
    canvas.drawRect(Rect.fromLTRB(left, yOf(p.zoneHigh), left + w, yOf(p.zoneLow)), paint);
    paint.color = check.danger ? const Color(0xFFE03C3C) : const Color(0xFFFF7043);
    canvas.drawRect(Rect.fromLTRB(left + w * 0.3, yOf(check.temperature), left + w * 0.7, size.height), paint);
    paint.color = PixelUi.outline;
    canvas.drawRect(
      Rect.fromLTWH(left - 3 * t, yOf(check.temperature) - t, w + 6 * t, 2 * t),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) => true;
}

class _FryBody extends StatelessWidget {
  const _FryBody({required this.game, required this.check, required this.unit});

  final CookingGame game;
  final FryCheck check;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final p = check.params;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < p.hitsNeeded; i++) ...[
              if (i > 0) SizedBox(width: 2 * u),
              PixelStar(filled: i < check.hits, size: 11 * u),
            ],
            SizedBox(width: 16 * u),
            for (var i = 0; i <= p.missesAllowed; i++) ...[
              if (i > 0) SizedBox(width: 2 * u),
              PixelHeart(filled: i >= check.misses, size: 8 * u),
            ],
          ],
        ),
        SizedBox(height: 8 * u),
        SizedBox(
          height: 24 * u,
          width: double.infinity,
          child: CustomPaint(painter: _FryBarPainter(check, u)),
        ),
        SizedBox(height: 8 * u),
        Expanded(
          child: _BigButton(
            label: 'BALIK!',
            color: const Color(0xFFFFCC80),
            unit: u,
            pressed: check.tapCount.isOdd,
            onDown: game.tapCheck,
          ),
        ),
      ],
    );
  }
}

class _FryBarPainter extends CustomPainter {
  _FryBarPainter(this.check, this.unit);

  final FryCheck check;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final t = unit.clamp(1.0, 5.0);
    paint.color = PixelUi.outline;
    canvas.drawRect(Offset.zero & size, paint);
    final inner = Rect.fromLTWH(t, t, size.width - 2 * t, size.height - 2 * t);
    paint.color = const Color(0xFFD6D0E4);
    canvas.drawRect(inner, paint);

    final half = check.params.zoneWidth / 2;
    paint.color = const Color(0xFFFFC107);
    canvas.drawRect(
      Rect.fromLTRB(
        inner.left + inner.width * (check.center - half),
        inner.top,
        inner.left + inner.width * (check.center + half),
        inner.bottom,
      ),
      paint,
    );

    final x = inner.left + inner.width * check.needle;
    paint.color = PixelUi.outline;
    canvas.drawRect(Rect.fromLTWH(x - t, -t, 2 * t, size.height + 2 * t), paint);
  }

  @override
  bool shouldRepaint(covariant _FryBarPainter oldDelegate) => true;
}
