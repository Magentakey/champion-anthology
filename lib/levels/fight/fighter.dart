import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'fighter_body.dart';
import 'pose_frames.dart';

/// Tampilan satu petarung di layar (sprite piksel, satu gambar per pose). Logikanya ada di
/// [FighterBody]; komponen ini hanya mengubah satuan ruang gambar ke piksel layar dan
/// menggambar bingkai pose yang sedang aktif dari [sheet].
class Fighter extends Component {
  Fighter({required this.body, required this.sheet, this.spriteScale = 1});

  final FighterBody body;

  /// Lembar sprite (lihat [PoseFrames]).
  final Image sheet;

  /// Pembesar sprite (Rock sedikit lebih besar dari pemain).
  final double spriteScale;

  /// Piksel layar per satuan ruang gambar, dan garis tanah di layar.
  double unit = 1;
  double groundY = 0;

  double _timeSec = 0;

  // Paint dipakai ulang; tanpa antialiasing dan tanpa penghalusan gambar (pixel art).
  static final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  static final Paint _shadowPaint = Paint()
    ..isAntiAlias = false
    ..color = const Color(0x40000000);
  static final Paint _glowPaint = Paint()..isAntiAlias = false;

  @override
  void update(double dt) {
    super.update(dt);
    _timeSec += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(body.x * unit, groundY);
    canvas.scale(unit * body.facing, unit);

    // aba-aba serangan khusus: aura merah berpita (3 lapis) berdenyut di belakang petarung
    if (body.telegraphing) {
      final pulse = 0.5 + 0.5 * math.sin(_timeSec * 22);
      const bands = <(double, int)>[(1.0, 38), (0.74, 54), (0.48, 74)];
      for (final (k, base) in bands) {
        _glowPaint.color = Color.fromARGB((base + 50 * pulse).round(), 255, 40, 40);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -560), width: 980 * k, height: 1350 * k),
          _glowPaint,
        );
      }
    }

    // mengisi serangan tenaga: aura emas yang makin terang dan cepat berdenyut sampai penuh
    if (body.charging) {
      final f = body.chargeFraction;
      final pulse = 0.5 + 0.5 * math.sin(_timeSec * (10 + 18 * f));
      const bands = <(double, int)>[(0.8, 30), (0.55, 46), (0.34, 64)];
      for (final (k, base) in bands) {
        _glowPaint.color = Color.fromARGB(((base + 60 * pulse) * (0.35 + 0.65 * f)).round(), 255, 214, 64);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -560), width: 980 * k, height: 1350 * k),
          _glowPaint,
        );
      }
    }

    // bayangan di tanah
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 14), width: 520 * spriteScale, height: 44),
      _shadowPaint,
    );

    canvas.scale(spriteScale);
    const size = PoseFrames.frameSize;
    const u = PoseFrames.unitsPerPixel;
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH(body.frameIndex * size, 0, size, size),
      Rect.fromLTWH(-PoseFrames.originX * u, -PoseFrames.originY * u, size * u, size * u),
      _spritePaint,
    );
    canvas.restore();
  }
}
