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

    // bayangan di tanah
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 14), width: 520, height: 44),
      Paint()..color = const Color(0x33000000),
    );

    StickRenderer.paint(canvas, body.pose, style, body.face, _timeSec);
    canvas.restore();
  }
}
