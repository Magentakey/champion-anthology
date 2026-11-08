import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/level/level_session.dart';
import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'fight_config.dart';
import 'fight_game.dart';
import 'pad_icons.dart';
import 'pose_clips.dart';

/// HUD Level Fight (landscape) bergaya piksel: bar HP dengan potret, banner fase, tombol kontrol,
/// dan panel uji (tombol DEV, hanya di build debug) untuk memutar animasi dan memaksa hasil.
class FightHud extends StatelessWidget {
  const FightHud({super.key, required this.game});

  final FightGame game;

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    return SafeArea(
      child: Stack(
        children: [
          // bar HP (kiri pemain, kanan Rock); ruang tengah untuk tombol jeda dari core
          Positioned(
            left: 8,
            right: 8,
            top: 6,
            child: Row(
              children: [
                Expanded(
                  child: _Fighter(
                    portrait: 'assets/images/fight/portrait_player.png',
                    name: 'KAMU',
                    hp: game.playerHp,
                    color: const Color(0xFFFF7043),
                    mirror: false,
                    unit: u,
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(
                  child: _Fighter(
                    portrait: 'assets/images/fight/portrait_rock.png',
                    name: 'ROCK',
                    hp: game.rockHp,
                    color: const Color(0xFFFFB300),
                    mirror: true,
                    notches: [for (final p in fightPhases.take(2)) p.hpFloor],
                    phase: game.phase,
                    unit: u,
                  ),
                ),
              ],
            ),
          ),
          // kilat merah tepi layar saat pemain terkena
          Positioned.fill(child: IgnorePointer(child: _HurtFlash(counter: game.hurtFlash, unit: u))),
          // banner fase
          Align(
            alignment: const Alignment(0, -0.35),
            child: ValueListenableBuilder<String?>(
              valueListenable: game.banner,
              builder: (_, text, _) => AnimatedOpacity(
                opacity: text == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  text ?? '',
                  textAlign: TextAlign.center,
                  style: PixelUi.text(u, scale: 2, color: PixelUi.cream, outline: PixelUi.outline, shadow: PixelUi.dark),
                ),
              ),
            ),
          ),
          // teks besar tengah layar (K.O.!)
          Align(
            alignment: const Alignment(0, -0.1),
            child: IgnorePointer(child: _Callout(text: game.callout, unit: u)),
          ),
          Positioned(left: 12, bottom: 10, child: _MovePad(game: game)),
          Positioned(right: 12, bottom: 10, child: _ActionPad(game: game)),
          // panel uji hanya ada di build debug (flutter run), tidak di APK rilis
          if (kDebugMode)
            Align(alignment: Alignment.bottomCenter, child: _DevPanel(game: game)),
        ],
      ),
    );
  }
}

// ---------------- efek layar ----------------
/// Kilat merah di tepi layar saat pemain terkena: bingkai tebal bersudut siku (bukan gradasi halus).
class _HurtFlash extends StatelessWidget {
  const _HurtFlash({required this.counter, required this.unit});

  final ValueNotifier<int> counter;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counter,
      builder: (_, n, _) => n == 0
          ? const SizedBox.shrink()
          : TweenAnimationBuilder<double>(
              key: ValueKey(n),
              tween: Tween(begin: 0.7, end: 0),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE03C3C).withValues(alpha: v), width: 8 * unit),
                ),
              ),
            ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text, required this.unit});

  final ValueNotifier<String?> text;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: text,
      builder: (_, t, _) => t == null
          ? const SizedBox.shrink()
          : TweenAnimationBuilder<double>(
              key: ValueKey(t),
              tween: Tween(begin: 2.4, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Text(
                t,
                style: PixelUi.text(
                  unit,
                  scale: 4,
                  color: PixelUi.gold,
                  outline: PixelUi.goldOutline,
                  shadow: PixelUi.dark,
                ),
              ),
            ),
    );
  }
}

// ---------------- bar HP ----------------
class _Fighter extends StatelessWidget {
  const _Fighter({
    required this.portrait,
    required this.name,
    required this.hp,
    required this.color,
    required this.mirror,
    required this.unit,
    this.notches = const [],
    this.phase,
  });

  final String portrait;
  final String name;
  final ValueNotifier<double> hp;
  final Color color;
  final bool mirror;
  final double unit;
  final List<double> notches;
  final ValueNotifier<int>? phase;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final portraitWidget = SizedBox(
      width: 30 * u,
      height: 30 * u,
      child: PixelFrame(
        unit: u,
        fill: PixelUi.panelDark,
        padding: EdgeInsets.zero,
        child: Image.asset(portrait, fit: BoxFit.cover, filterQuality: FilterQuality.none),
      ),
    );
    final bar = Expanded(
      child: Column(
        crossAxisAlignment: mirror ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: mirror ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(name, style: PixelUi.text(u, outline: PixelUi.outline)),
              if (phase != null)
                ValueListenableBuilder<int>(
                  valueListenable: phase!,
                  builder: (_, p, _) => Padding(
                    padding: EdgeInsets.only(left: 6 * u),
                    child: Row(
                      children: [
                        for (var i = 1; i <= 3; i++) ...[
                          if (i > 1) SizedBox(width: u),
                          PixelStar(filled: i < p, size: 9 * u),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2 * u),
          _HpBar(hp: hp, color: color, mirror: mirror, notches: notches, unit: u),
        ],
      ),
    );
    return Row(
      children: mirror
          ? [bar, SizedBox(width: 6 * u), portraitWidget]
          : [portraitWidget, SizedBox(width: 6 * u), bar],
    );
  }
}

/// Bar HP piksel: bingkai gelap, blok-blok berwarna yang berkurang dari sisi dalam, dan
/// penanda batas fase (garis krem).
class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.hp,
    required this.color,
    required this.mirror,
    required this.notches,
    required this.unit,
  });

  final ValueNotifier<double> hp;
  final Color color;
  final bool mirror;
  final List<double> notches;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10 * unit,
      width: double.infinity,
      child: ValueListenableBuilder<double>(
        valueListenable: hp,
        builder: (_, value, _) => CustomPaint(
          painter: _HpPainter(value.clamp(0.0, 1.0).toDouble(), color, mirror, notches, unit),
        ),
      ),
    );
  }
}

class _HpPainter extends CustomPainter {
  _HpPainter(this.value, this.color, this.mirror, this.notches, this.unit);

  final double value;
  final Color color;
  final bool mirror;
  final List<double> notches;
  final double unit;

  static const _segments = 24;

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
    final lit = (value * _segments).ceil();
    paint.color = color;
    for (var i = 0; i < lit; i++) {
      final slot = mirror ? _segments - 1 - i : i;
      canvas.drawRect(
        Rect.fromLTWH(inner.left + slot * (blockW + gap), inner.top, blockW, inner.height),
        paint,
      );
    }
    // penanda batas fase
    paint.color = PixelUi.cream;
    for (final n in notches) {
      final x = mirror ? inner.right - inner.width * n : inner.left + inner.width * n;
      canvas.drawRect(Rect.fromLTWH(x - t / 2, 0, t, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HpPainter oldDelegate) => true;
}

// ---------------- tombol kontrol ----------------
/// Tombol piksel yang tahan banyak sentuhan sekaligus lewat Listener (bukan GestureDetector).
class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.icon,
    required this.semantic,
    required this.size,
    required this.onDown,
    this.onUp,
    this.color = const Color(0xFF3A3050),
    this.ready,
  });

  final PadIcon icon;

  /// Label untuk pembaca layar (tidak tampak di layar).
  final String semantic;
  final double size;
  final VoidCallback onDown;
  final VoidCallback? onUp;

  /// Warna isi tombol (bingkai krem tetap).
  final Color color;

  /// Kesiapan (0..1) untuk tombol dengan jeda, mis. pisau.
  final ValueNotifier<double>? ready;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    v ? widget.onDown() : widget.onUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    final fill = _down ? Color.lerp(widget.color, Colors.white, 0.35)! : widget.color;
    final face = Transform.translate(
      offset: Offset(0, _down ? 2 * u : 0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: PixelFrame(
          unit: u,
          fill: fill,
          padding: EdgeInsets.zero,
          child: Center(child: PadIconView(widget.icon, size: widget.size * 0.56)),
        ),
      ),
    );
    final ready = widget.ready;
    return Semantics(
      label: widget.semantic,
      button: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: ready == null
            ? face
            : ValueListenableBuilder<double>(
                valueListenable: ready,
                builder: (_, r, _) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Opacity(opacity: r >= 1 ? 1 : 0.55, child: face),
                    if (r < 1)
                      Positioned(
                        left: 4 * u,
                        right: 4 * u,
                        bottom: 4 * u,
                        child: PixelBar(value: r, color: const Color(0xFFFF7043), unit: u, height: 5, segments: 8),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MovePad extends StatelessWidget {
  const _MovePad({required this.game});

  final FightGame game;

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).height * 0.22).clamp(56.0, 84.0).toDouble();
    return Row(
      children: [
        _PadButton(
          icon: PadIcon.left,
          semantic: 'Kiri',
          size: size,
          onDown: () => game.setMoveLeft(true),
          onUp: () => game.setMoveLeft(false),
        ),
        SizedBox(width: size * 0.2),
        _PadButton(
          icon: PadIcon.right,
          semantic: 'Kanan',
          size: size,
          onDown: () => game.setMoveRight(true),
          onUp: () => game.setMoveRight(false),
        ),
      ],
    );
  }
}

class _ActionPad extends StatelessWidget {
  const _ActionPad({required this.game});

  final FightGame game;

  @override
  Widget build(BuildContext context) {
    final base = (MediaQuery.sizeOf(context).height * 0.22).clamp(56.0, 84.0).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PadButton(
          icon: PadIcon.block,
          semantic: 'Tangkis',
          size: base,
          color: const Color(0xFF2E5C8A),
          onDown: () => game.setBlock(true),
          onUp: () => game.setBlock(false),
        ),
        SizedBox(width: base * 0.15),
        _PadButton(
          icon: PadIcon.kick,
          semantic: 'Tendang',
          size: base,
          color: const Color(0xFF8A6A1E),
          onDown: game.pressKick,
        ),
        SizedBox(width: base * 0.15),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PadButton(
              icon: PadIcon.knife,
              semantic: 'Lempar pisau',
              size: base * 0.85,
              color: const Color(0xFF4A5560),
              ready: game.knifeReady,
              onDown: game.pressKnife,
            ),
            SizedBox(height: base * 0.12),
            _PadButton(
              icon: PadIcon.punch,
              semantic: 'Pukul',
              size: base * 1.2,
              color: const Color(0xFFA83A3A),
              onDown: game.pressPunch,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- panel uji sementara ----------------
class _DevPanel extends StatefulWidget {
  const _DevPanel({required this.game});

  final FightGame game;

  @override
  State<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<_DevPanel> {
  bool _open = false;
  bool _forPlayer = true;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (!_open) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _Chip(label: 'DEV', onTap: () => setState(() => _open = true)),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _Chip(label: 'Tutup', onTap: () => setState(() => _open = false)),
                ValueListenableBuilder<bool>(
                  valueListenable: game.rockAttacks,
                  builder: (_, on, _) => _Chip(
                    label: on ? 'Rock: menyerang' : 'Rock: diam',
                    onTap: () => game.rockAttacks.value = !on,
                  ),
                ),
                ListenableBuilder(
                  listenable: game.session,
                  builder: (_, _) => game.session.state == SessionState.playing
                      ? Wrap(
                          spacing: 4,
                          children: [
                            _Chip(label: '[DEV] Menang fase', onTap: game.devWinPhase),
                            _Chip(label: '[DEV] Kalah', onTap: game.devLose),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(
                  label: _forPlayer ? 'Uji: Pemain' : 'Uji: Rock',
                  onTap: () => setState(() => _forPlayer = !_forPlayer),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final name in Clips.all.keys)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _Chip(
                              label: name,
                              onTap: () => game.devPlay(forPlayer: _forPlayer, clipName: name),
                            ),
                          ),
                      ],
                    ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
}
