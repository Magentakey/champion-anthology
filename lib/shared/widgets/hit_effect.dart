import 'dart:math';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// Getar singkat + kilat merah setiap kali [trigger] berubah (mis. jawaban salah).
class HitEffect extends StatefulWidget {
  const HitEffect({super.key, required this.trigger, required this.child});

  final ValueListenable<int> trigger;
  final Widget child;

  @override
  State<HitEffect> createState() => _HitEffectState();
}

class _HitEffectState extends State<HitEffect>
    with SingleTickerProviderStateMixin {
  // value: 1 = animasi selesai (tidak ada getar / kilat saat idle).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_play);
  }

  void _play() => _c.forward(from: 0);

  @override
  void didUpdateWidget(HitEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_play);
      widget.trigger.addListener(_play);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_play);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dx = sin(t * pi * 8) * 10 * (1 - t);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(offset: Offset(dx, 0), child: child),
            IgnorePointer(
              child: ColoredBox(
                color: Color.fromRGBO(244, 67, 54, 0.35 * (1 - t)),
              ),
            ),
          ],
        );
      },
    );
  }
}
