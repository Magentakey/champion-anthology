import 'package:flutter/material.dart';

import '../../core/level/level_session.dart';
import 'fight_config.dart';
import 'fight_game.dart';
import 'pad_icons.dart';
import 'pose_clips.dart';

/// HUD Level Fight (landscape): bar HP dengan potret, banner fase, tombol kontrol,
/// dan panel uji sementara (tombol DEV) untuk memutar animasi dan memaksa hasil.
class FightHud extends StatelessWidget {
  const FightHud({super.key, required this.game});

  final FightGame game;

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              ],
            ),
          ),
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 12, bottom: 10, child: _MovePad(game: game)),
          Positioned(right: 12, bottom: 10, child: _ActionPad(game: game)),
          Align(alignment: Alignment.bottomCenter, child: _DevPanel(game: game)),
        ],
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
    this.notches = const [],
    this.phase,
  });

  final String portrait;
  final String name;
  final ValueNotifier<double> hp;
  final Color color;
  final bool mirror;
  final List<double> notches;
  final ValueNotifier<int>? phase;

  @override
  Widget build(BuildContext context) {
    final portraitWidget = Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black26),
      child: Image.asset(portrait, fit: BoxFit.cover),
    );
    final bar = Expanded(
      child: Column(
        crossAxisAlignment: mirror ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: mirror ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              if (phase != null)
                ValueListenableBuilder<int>(
                  valueListenable: phase!,
                  builder: (_, p, _) => Padding(
                    padding: const EdgeInsets.only(left: 6, right: 0),
                    child: Row(
                      children: [
                        for (var i = 1; i <= 3; i++)
                          Icon(
                            i < p ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          _HpBar(hp: hp, color: color, mirror: mirror, notches: notches),
        ],
      ),
    );
    return Row(
      children: mirror
          ? [bar, const SizedBox(width: 8), portraitWidget]
          : [portraitWidget, const SizedBox(width: 8), bar],
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({required this.hp, required this.color, required this.mirror, required this.notches});

  final ValueNotifier<double> hp;
  final Color color;
  final bool mirror;
  final List<double> notches;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LayoutBuilder(
          builder: (_, box) => Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: hp,
                builder: (_, value, _) => Align(
                  alignment: mirror ? Alignment.centerRight : Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0).toDouble(),
                    child: Container(color: color),
                  ),
                ),
              ),
              // penanda batas fase (67% dan 33%)
              for (final n in notches)
                Positioned(
                  left: mirror ? null : box.maxWidth * n,
                  right: mirror ? box.maxWidth * n : null,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- tombol kontrol ----------------
/// Tombol yang tahan banyak sentuhan sekaligus lewat Listener (bukan GestureDetector).
class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.icon,
    required this.semantic,
    required this.size,
    required this.onDown,
    this.onUp,
    this.color = const Color(0xCCFFFFFF),
    this.ready,
  });

  final PadIcon icon;

  /// Label untuk pembaca layar (tidak tampak di layar).
  final String semantic;
  final double size;
  final VoidCallback onDown;
  final VoidCallback? onUp;
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
    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _down ? Colors.orange : widget.color,
        border: Border.all(color: Colors.black87, width: 2.5),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(widget.size * 0.56),
        painter: PadIconPainter(widget.icon),
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
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: r >= 1 ? 1 : 0.55, child: face),
                  if (r < 1)
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: r,
                        strokeWidth: 5,
                        color: Colors.deepOrange,
                      ),
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
          color: const Color(0xCC90CAF9),
          onDown: () => game.setBlock(true),
          onUp: () => game.setBlock(false),
        ),
        SizedBox(width: base * 0.15),
        _PadButton(
          icon: PadIcon.kick,
          semantic: 'Tendang',
          size: base,
          color: const Color(0xCCFFE082),
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
              color: const Color(0xCCB0BEC5),
              ready: game.knifeReady,
              onDown: game.pressKnife,
            ),
            SizedBox(height: base * 0.12),
            _PadButton(
              icon: PadIcon.punch,
              semantic: 'Pukul',
              size: base * 1.2,
              color: const Color(0xCCEF9A9A),
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
