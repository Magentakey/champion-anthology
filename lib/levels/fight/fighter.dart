import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'fighter_body.dart';
import 'stick_renderer.dart';

/// Tampilan satu petarung di layar. Logikanya ada di [FighterBody]; komponen ini hanya
/// mengubah satuan ruang gambar ke piksel dan menggambar pose yang sedang aktif.
class Fighter extends Component {
  Fighter({required this.body, required this.style});

  final FighterBody body;
  final FighterStyle style;

  /// Piksel layar per satuan ruang gambar, dan garis tanah di layar.
  double unit = 1;
  double groundY = 0;

  double _timeSec = 0;

  /// Cahaya aba-aba: gradien radial dibuat sekali (bukan blur besar tiap frame, yang berat
  /// di HP spesifikasi rendah). Intensitas diatur lewat [_glowPaint.colorFilter].
  static final Paint _glowPaint = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      675,
      const [Color(0xFFFF2828), Color(0xD9FF2828), Color(0x00FF2828)],
      const [0.0, 0.55, 1.0],
    );

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

    // aba-aba serangan khusus: cahaya merah berdenyut di belakang petarung
    if (body.telegraphing) {
      final pulse = 0.5 + 0.5 * math.sin(_timeSec * 22);
      _glowPaint.colorFilter = ColorFilter.mode(
        Color.fromARGB((70 + 90 * pulse).round(), 255, 255, 255),
        BlendMode.modulate,
      );
      canvas.save();
      canvas.translate(0, -560);
      canvas.scale(980 / 1350, 1); // lingkaran 675 jadi oval 980x1350
      canvas.drawCircle(Offset.zero, 675, _glowPaint);
      canvas.restore();
    }

    // bayangan di tanah
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 14), width: 520, height: 44),
      Paint()..color = const Color(0x33000000),
    );

    StickRenderer.paint(canvas, body.pose, style, body.face, _timeSec);
    canvas.restore();
  }
}
