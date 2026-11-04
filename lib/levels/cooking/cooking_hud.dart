import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/hit_effect.dart';
import 'cooking_checks.dart';
import 'cooking_config.dart';
import 'cooking_game.dart';
import 'cooking_models.dart';

/// HUD Flutter di atas arena Flame: info step dan waktu, gelembung ucapan Chef, kartu pesanan,
/// tiga stasiun (target geser), baki bahan, dan panel cooking check.
class CookingHud extends StatelessWidget {
  const CookingHud({super.key, required this.game});

  final CookingGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

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
                  child: _TopBar(step: step, seconds: game.secondsLeft.value),
                ),
                Positioned(
                  top: topPad + 4,
                  left: 160,
                  child: _TimePopup(event: game.timeEvent),
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
                    child: _OrderCard(order: order, done: game.done.value),
                  ),
                  Positioned(
                    top: h * CookingLayout.lowerTop,
                    left: side,
                    right: side,
                    height: h * CookingLayout.stationsHeight,
                    child: Row(
                      children: [
                        for (final s in Station.values) ...[
                          if (s != Station.chop) const SizedBox(width: 10),
                          Expanded(child: _StationTile(station: s, game: game)),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * CookingLayout.trayTop,
                    left: side,
                    right: side,
                    bottom: h * CookingLayout.lowerBottom,
                    child: _Tray(ids: game.tray.value, canDrag: game.canAct),
                  ),
                ],
                if (check != null)
                  Positioned(
                    top: h * CookingLayout.lowerTop,
                    left: side,
                    right: side,
                    bottom: h * CookingLayout.lowerBottom,
                    child: _CheckPanel(game: game, check: check),
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
  const _TopBar({required this.step, required this.seconds});

  final int step;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= CookingTuning.hurrySeconds;
    final color = urgent ? Colors.red : Colors.black87;
    return Row(
      children: [
        Text(
          'Step $step/${StarCalculator.totalSteps}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 12),
        Icon(Icons.timer_outlined, size: 20, color: color),
        const SizedBox(width: 4),
        Text('${seconds}s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}

/// "-3s" merah (penalti) atau "+1s" hijau (bonus) yang melayang naik dan memudar.
class _TimePopup extends StatelessWidget {
  const _TimePopup({required this.event});

  final ValueNotifier<TimeEvent?> event;

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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: bonus ? Colors.green.shade700 : Colors.red.shade700,
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
      Station.chop => Colors.green.shade200,
      Station.boil => Colors.blue.shade200,
      Station.fry => Colors.orange.shade200,
    };

/// Kartu pesanan: nama masakan dan bahan yang harus dimasak (dicentang jika sudah).
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.done});

  final Order order;
  final Set<String> done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'PESANAN: ${order.recipe.name.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  for (final i in order.ingredients) _OrderChip(ingredient: i, finished: done.contains(i.id)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderChip extends StatelessWidget {
  const _OrderChip({required this.ingredient, required this.finished});

  final Ingredient ingredient;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Opacity(
        opacity: finished ? 0.45 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(ingredient.imageAsset, width: 36, height: 36, gaplessPlayback: true),
                if (finished) const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
            Text(ingredient.name, style: const TextStyle(fontSize: 11, color: Colors.black87)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _stationColor(ingredient.station),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ingredient.station.verb.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stasiun masak: target jatuhnya bahan.
class _StationTile extends StatelessWidget {
  const _StationTile({required this.station, required this.game});

  final Station station;
  final CookingGame game;

  String get _asset => 'assets/images/cooking/station_${station.name}.png';

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => game.canAct,
      onAcceptWithDetails: (d) => game.drop(d.data, station),
      builder: (context, candidates, rejected) {
        final hot = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: hot ? Colors.amber.shade100 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hot ? Colors.orange.shade700 : Colors.transparent, width: 3),
          ),
          child: Column(
            children: [
              Expanded(child: Image.asset(_asset, fit: BoxFit.contain, gaplessPlayback: true)),
              Text(
                station.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text('(${station.verb})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        );
      },
    );
  }
}

/// Baki bahan (bahan pesanan + pengecoh). Tiap bahan bisa digeser ke stasiun.
class _Tray extends StatelessWidget {
  const _Tray({required this.ids, required this.canDrag});

  final List<String> ids;
  final bool canDrag;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 4 * 76,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 0,
            runSpacing: 4,
            children: [for (final id in ids) _TrayItem(ingredient: ingredientById(id), canDrag: canDrag)],
          ),
        ),
      ),
    );
  }
}

class _TrayItem extends StatelessWidget {
  const _TrayItem({required this.ingredient, required this.canDrag});

  final Ingredient ingredient;
  final bool canDrag;

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(ingredient.imageAsset, width: 56, height: 56, gaplessPlayback: true),
          Text(ingredient.name, style: const TextStyle(fontSize: 11, color: Colors.black87)),
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
        child: Image.asset(ingredient.imageAsset, width: 68, height: 68),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }
}

// ---------------- panel cooking check ----------------
class _CheckPanel extends StatelessWidget {
  const _CheckPanel({required this.game, required this.check});

  final CookingGame game;
  final CookingCheck check;

  @override
  Widget build(BuildContext context) {
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade500, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (ingredient != null) Image.asset(ingredient.imageAsset, width: 40, height: 40, gaplessPlayback: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: game.checkTick,
              builder: (context, _) => switch (check) {
                final ChopCheck c => _ChopBody(game: game, check: c),
                final BoilCheck c => _BoilBody(game: game, check: c),
                final FryCheck c => _FryBody(game: game, check: c),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 22,
        child: Stack(
          children: [
            Container(color: Colors.grey.shade400),
            FractionallySizedBox(widthFactor: value.clamp(0.0, 1.0), child: Container(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Tombol besar yang bereaksi pada sentuhan awal (tanpa menunggu deteksi ketuk).
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.onDown,
    this.onUp,
    this.pressed = false,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final bool pressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp?.call(),
      onPointerCancel: (_) => onUp?.call(),
      child: AnimatedScale(
        scale: pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 70),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 44, color: Colors.black87),
              Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChopBody extends StatelessWidget {
  const _ChopBody({required this.game, required this.check});

  final CookingGame game;
  final ChopCheck check;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressBar(value: check.progress, color: Colors.green.shade500),
        const SizedBox(height: 12),
        Expanded(
          child: _BigButton(
            label: 'KETUK TERUS!',
            color: Colors.green.shade300,
            icon: Icons.touch_app,
            pressed: check.tapCount.isOdd,
            onDown: game.tapCheck,
          ),
        ),
      ],
    );
  }
}

class _BoilBody extends StatelessWidget {
  const _BoilBody({required this.game, required this.check});

  final CookingGame game;
  final BoilCheck check;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressBar(value: check.progress, color: Colors.blue.shade500),
        const SizedBox(height: 12),
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
                        painter: _ThermometerPainter(check),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      check.danger ? 'AWAS MELUAP!' : (check.inZone ? 'Pas!' : 'Atur suhu'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: check.danger ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _BigButton(
                  label: 'TAHAN API',
                  color: check.holding ? Colors.red.shade300 : Colors.orange.shade200,
                  icon: Icons.local_fire_department,
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
  _ThermometerPainter(this.check);

  final BoilCheck check;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.clamp(0.0, 70.0);
    final left = (size.width - w) / 2;
    final tube = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, size.height), const Radius.circular(12));
    canvas.drawRRect(tube, Paint()..color = Colors.grey.shade300);

    double yOf(double v) => size.height * (1 - v);
    final p = check.params;
    canvas.drawRect(
      Rect.fromLTRB(left, yOf(p.zoneHigh), left + w, yOf(p.zoneLow)),
      Paint()..color = Colors.green.shade400,
    );
    final fill = Rect.fromLTRB(left + w * 0.3, yOf(check.temperature), left + w * 0.7, size.height);
    canvas.drawRect(fill, Paint()..color = check.danger ? Colors.red : Colors.deepOrange);
    canvas.drawLine(
      Offset(left - 6, yOf(check.temperature)),
      Offset(left + w + 6, yOf(check.temperature)),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      tube,
      Paint()
        ..color = check.danger ? Colors.red : Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) => true;
}

class _FryBody extends StatelessWidget {
  const _FryBody({required this.game, required this.check});

  final CookingGame game;
  final FryCheck check;

  @override
  Widget build(BuildContext context) {
    final p = check.params;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < p.hitsNeeded; i++)
              Icon(
                i < check.hits ? Icons.star : Icons.star_border,
                size: 30,
                color: i < check.hits ? Colors.amber.shade700 : Colors.grey,
              ),
            const SizedBox(width: 24),
            for (var i = 0; i <= p.missesAllowed; i++)
              Icon(
                Icons.close,
                size: 26,
                color: i < check.misses ? Colors.red : Colors.grey.shade400,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          width: double.infinity,
          child: CustomPaint(painter: _FryBarPainter(check)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _BigButton(
            label: 'BALIK!',
            color: Colors.orange.shade300,
            icon: Icons.flip,
            pressed: check.tapCount.isOdd,
            onDown: game.tapCheck,
          ),
        ),
      ],
    );
  }
}

class _FryBarPainter extends CustomPainter {
  _FryBarPainter(this.check);

  final FryCheck check;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(bar, Paint()..color = Colors.grey.shade300);

    final half = check.params.zoneWidth / 2;
    final zone = Rect.fromLTRB(
      size.width * (check.center - half),
      0,
      size.width * (check.center + half),
      size.height,
    );
    canvas.drawRect(zone, Paint()..color = Colors.amber.shade400);

    final x = size.width * check.needle;
    canvas.drawLine(
      Offset(x, -4),
      Offset(x, size.height + 4),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      bar,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _FryBarPainter oldDelegate) => true;
}
