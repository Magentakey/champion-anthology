import 'package:flutter/widgets.dart';

enum PadIcon { left, right, punch, kick, block, knife }

/// Ikon tombol kontrol yang digambar sendiri (kotak 100 x 100), bergaya garis tebal hitam
/// seperti stickman, supaya tidak bergantung pada font ikon.
class PadIconPainter extends CustomPainter {
  const PadIconPainter(this.icon, {this.color = const Color(0xFF141418)});

  final PadIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..color = color;
    final white = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (icon) {
      case PadIcon.left:
      case PadIcon.right:
        final d = icon == PadIcon.left ? -1.0 : 1.0;
        final path = Path()
          ..moveTo(50 - d * 14, 18)
          ..lineTo(50 + d * 18, 50)
          ..lineTo(50 - d * 14, 82);
        canvas.drawPath(path, line..strokeWidth = 16);
      case PadIcon.punch:
        // pergelangan, kepalan, dan empat jari menghadap kanan
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(6, 40, 18, 26), const Radius.circular(4)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(20, 27, 54, 48), const Radius.circular(12)),
          fill,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(64, 29 + i * 11.5, 24, 10),
              const Radius.circular(5),
            ),
            fill,
          );
        }
        for (final y in const [39.5, 51.0, 62.5]) {
          canvas.drawLine(Offset(50, y), Offset(70, y), white..strokeWidth = 3);
        }
      case PadIcon.kick:
        // stickman menendang: kaki tumpu, badan, kepala, dan kaki tendang berujung sepatu
        canvas.drawPath(
          Path()
            ..moveTo(34, 44)
            ..lineTo(30, 68)
            ..lineTo(26, 90),
          line..strokeWidth = 9,
        );
        canvas.drawPath(
          Path()
            ..moveTo(34, 44)
            ..lineTo(62, 40)
            ..lineTo(82, 38),
          line,
        );
        canvas.drawLine(const Offset(34, 44), const Offset(28, 22), line);
        canvas.drawCircle(const Offset(27, 12), 9, fill);
        canvas.drawOval(Rect.fromCenter(center: const Offset(88, 36), width: 24, height: 15), fill);
      case PadIcon.block:
        final shield = Path()
          ..moveTo(50, 8)
          ..lineTo(86, 22)
          ..lineTo(86, 48)
          ..quadraticBezierTo(86, 78, 50, 94)
          ..quadraticBezierTo(14, 78, 14, 48)
          ..lineTo(14, 22)
          ..close();
        canvas.drawPath(shield, fill);
        white.strokeWidth = 6;
        canvas.drawLine(const Offset(50, 26), const Offset(50, 76), white);
        canvas.drawLine(const Offset(32, 44), const Offset(68, 44), white);
      case PadIcon.knife:
        canvas.translate(50, 50);
        canvas.rotate(-0.7);
        canvas.translate(-21, 0);
        canvas.scale(0.85, 0.85);
        final blade = Path()
          ..moveTo(0, -9)
          ..lineTo(52, -9)
          ..lineTo(78, 0)
          ..lineTo(52, 9)
          ..lineTo(0, 9)
          ..close();
        canvas.drawPath(blade, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTRB(-36, -7, -4, 7), const Radius.circular(4)),
          fill,
        );
        canvas.drawRect(const Rect.fromLTRB(-5, -13, 3, 13), fill);
        canvas.drawLine(const Offset(8, 0), const Offset(58, 0), white..strokeWidth = 3);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PadIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
