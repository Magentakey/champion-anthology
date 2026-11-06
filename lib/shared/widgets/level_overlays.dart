import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../core/audio/audio_service.dart';
import 'pixel_ui.dart';
import 'star_row.dart';

/// Latar gelap untuk overlay jeda dan hasil. Tanpa blur agar tetap bergaya piksel (dan lebih ringan).
class _Scrim extends StatelessWidget {
  const _Scrim({required this.unit, required this.child});

  final double unit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Layar landscape pendek (~360 dp): panel dibuat bisa digulir agar tidak terpotong.
    return ColoredBox(
      color: const Color(0xCC161228),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8 * unit),
            child: PixelFrame(
              unit: unit,
              padding: EdgeInsets.fromLTRB(12 * unit, 10 * unit, 12 * unit, 12 * unit),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 164 * unit),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    return _Scrim(
      unit: u,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppText.paused,
            style: PixelUi.text(u, scale: 3, color: PixelUi.gold, outline: PixelUi.goldOutline, shadow: PixelUi.dark),
          ),
          SizedBox(height: 10 * u),
          PixelButton(label: AppText.resume, onPressed: onResume, wide: true, unit: u),
          SizedBox(height: 6 * u),
          PixelButton(label: AppText.restart, onPressed: onRestart, wide: true, secondary: true, unit: u),
          SizedBox(height: 6 * u),
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.muted,
            builder: (context, muted, _) => PixelButton(
              label: muted ? AppText.soundOff : AppText.soundOn,
              onPressed: () => AudioService.instance.setMuted(!muted),
              wide: true,
              secondary: true,
              unit: u,
            ),
          ),
          SizedBox(height: 6 * u),
          PixelButton(label: AppText.exit, onPressed: onExit, wide: true, secondary: true, unit: u),
        ],
      ),
    );
  }
}

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.stars,
    required this.step,
    this.stepLabel = 'Step',
    required this.onRestart,
    required this.onExit,
    this.bossName,
    this.message,
  });

  final int stars;
  final int step;
  final String stepLabel;
  final String? bossName;
  final String? message;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final u = PixelUi.overlayUnit(context);
    final perfect = stars >= 3;
    final title = perfect ? AppText.perfectClear : AppText.lostAtStep(step, stepLabel);
    return _Scrim(
      unit: u,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Judul panjang (mis. "Kalah di Step 3") mengecil otomatis agar muat di panel.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: PixelUi.text(
                u,
                scale: perfect ? 3 : 2,
                color: perfect ? PixelUi.gold : PixelUi.cream,
                outline: perfect ? PixelUi.goldOutline : PixelUi.outline,
                shadow: PixelUi.dark,
              ),
            ),
          ),
          SizedBox(height: 10 * u),
          StarRow(stars: stars, size: 22 * u),
          if (message != null) ...[
            SizedBox(height: 10 * u),
            PixelFrame(
              unit: u,
              fill: PixelUi.paper,
              padding: EdgeInsets.all(6 * u),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  bossName == null ? '"$message"' : '$bossName:\n"$message"',
                  textAlign: TextAlign.center,
                  style: PixelUi.text(u, color: PixelUi.ink, height: 1.2),
                ),
              ),
            ),
          ],
          SizedBox(height: 12 * u),
          PixelButton(label: AppText.restart, onPressed: onRestart, wide: true, unit: u),
          SizedBox(height: 6 * u),
          PixelButton(label: AppText.toLevelSelect, onPressed: onExit, wide: true, secondary: true, unit: u),
        ],
      ),
    );
  }
}
