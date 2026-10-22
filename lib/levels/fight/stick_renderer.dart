import 'dart:math' as math;
import 'dart:ui';

import 'pose.dart';
import 'pose_clips.dart';

const _black = Color(0xFF141418);
const _white = Color(0xFFFFFFFF);
const _red = Color(0xFFD62828);
const _brown = Color(0xFF8D5C2E);
const _orange = Color(0xFFFB8C00);
const _tongue = Color(0xFFEF5350);

/// Tampilan satu petarung: ukuran kepala, tebal garis, dan aksesori.
class FighterStyle {
  const FighterStyle({
    required this.headRadius,
    required this.lineWidth,
    this.headband = false,
    this.rock = false,
  });

  final double headRadius;
  final double lineWidth;

  /// Ikat kepala merah milik pemain.
  final bool headband;

  /// Rambut batu, sabuk oranye, dan bekas luka milik Rock.
  final bool rock;

  static const player = FighterStyle(headRadius: 150, lineWidth: 22, headband: true);
  static const rockTheFighter = FighterStyle(headRadius: 190, lineWidth: 26, rock: true);
}

enum _Eyes { open, fire, wide, happy, cross }

enum _Brows { angry, fierce, sad, upSoft }

enum _Mouth { flat, smile, o, laugh, shout, wavy }

class _FaceSpec {
  const _FaceSpec(this.eyes, this.brows, this.mouth);

  final _Eyes eyes;
  final _Brows brows;
  final _Mouth mouth;
}

_FaceSpec _faceFor(FighterStyle style, FaceState state) {
  if (style.rock) {
    switch (state) {
      case FaceState.idle:
      case FaceState.block:
        return const _FaceSpec(_Eyes.open, _Brows.angry, _Mouth.flat);
      case FaceState.attack:
      case FaceState.taunt:
        return const _FaceSpec(_Eyes.open, _Brows.fierce, _Mouth.shout);
      case FaceState.hurt:
        return const _FaceSpec(_Eyes.wide, _Brows.sad, _Mouth.o);
      case FaceState.ko:
        return const _FaceSpec(_Eyes.cross, _Brows.sad, _Mouth.wavy);
      case FaceState.win:
        return const _FaceSpec(_Eyes.happy, _Brows.upSoft, _Mouth.laugh);
    }
  }
  switch (state) {
    case FaceState.idle:
      return const _FaceSpec(_Eyes.fire, _Brows.fierce, _Mouth.smile);
    case FaceState.block:
      return const _FaceSpec(_Eyes.fire, _Brows.fierce, _Mouth.flat);
    case FaceState.attack:
    case FaceState.taunt:
      return const _FaceSpec(_Eyes.fire, _Brows.fierce, _Mouth.shout);
    case FaceState.hurt:
      return const _FaceSpec(_Eyes.wide, _Brows.sad, _Mouth.o);
    case FaceState.ko:
      return const _FaceSpec(_Eyes.cross, _Brows.sad, _Mouth.wavy);
    case FaceState.win:
      return const _FaceSpec(_Eyes.happy, _Brows.upSoft, _Mouth.laugh);
  }
}

// Alis: (u, v) relatif terhadap kepala dalam satuan jari-jari, sama dengan BROWS di generator art.
const _browSegments = <_Brows, List<List<Offset>>>{
  _Brows.angry: [
    [Offset(0.06, -0.42), Offset(0.38, -0.27)],
    [Offset(0.50, -0.27), Offset(0.82, -0.42)],
  ],
  _Brows.fierce: [
    [Offset(-0.02, -0.26), Offset(0.42, -0.06)],
    [Offset(0.46, -0.06), Offset(0.92, -0.28)],
  ],
  _Brows.sad: [
    [Offset(0.06, -0.28), Offset(0.38, -0.40)],
    [Offset(0.50, -0.40), Offset(0.82, -0.28)],
  ],
  _Brows.upSoft: [
    [Offset(0.06, -0.36), Offset(0.38, -0.40)],
    [Offset(0.50, -0.40), Offset(0.82, -0.36)],
  ],
};

/// Penggambar stickman dari sebuah [Pose]. Semua koordinat dalam ruang gambar pose;
/// pemanggil mengatur translasi, skala, dan pembalikan arah di kanvas.
abstract final class StickRenderer {
  static void paint(Canvas c, Pose p, FighterStyle style, FaceState face, double timeSec) {
    final lw = style.lineWidth;
    final r = style.headRadius;
    final shoulder = p.shoulder;
    final head = p.headCenter(r);

    final line = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = lw;

    void poly(List<Offset> pts, [Paint? paint]) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      c.drawPath(path, paint ?? line);
    }

    // lapisan: lengan belakang, kaki belakang, badan, kaki depan, lengan depan
    poly([shoulder, p.elbowB, p.handB]);
    poly([p.hip, p.kneeB, p.ankleB]);
    poly([p.neck, p.hip]);
    poly([p.hip, p.kneeF, p.ankleF]);
    if (!p.armsOver) poly([shoulder, p.elbowF, p.handF]);
    _shoe(c, p.ankleB, p.toeB);
    _shoe(c, p.ankleF, p.toeF);
    if (style.rock) _belt(c, p.neck, p.hip, lw);

    // kepala
    c.drawCircle(head, r, Paint()..color = _white);
    c.drawCircle(
      head,
      r - lw * 0.45,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.9,
    );
    if (style.rock) _rockHair(c, head, r, lw);
    _drawFace(c, head, r, lw, _faceFor(style, face), style.rock);
    if (style.headband) _headband(c, head, r, lw, timeSec);

    if (p.armsOver) {
      poly([shoulder, p.elbowB, p.handB]);
      poly([shoulder, p.elbowF, p.handF]);
    }
    if (p.fistB) _fist(c, p.handB, r, lw);
    if (p.fistF) _fist(c, p.handF, r, lw);
  }

  // ---------------- bagian tubuh ----------------
  static void _shoe(Canvas c, Offset ankle, Offset toe) {
    final ang = math.atan2(toe.dy - ankle.dy, toe.dx - ankle.dx);
    final len = (toe - ankle).distance;
    final mid = Offset((ankle.dx + toe.dx) / 2, (ankle.dy + toe.dy) / 2 + 6);
    c.save();
    c.translate(mid.dx, mid.dy);
    c.rotate(ang);
    final rect = Rect.fromCenter(center: Offset.zero, width: len + 40, height: 34);
    c.drawOval(rect, Paint()..color = _brown);
    c.drawOval(
      rect,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.restore();
  }

  static void _fist(Canvas c, Offset center, double headR, double lw) {
    final r = 0.30 * headR;
    c.drawCircle(center, r, Paint()..color = _white);
    c.drawCircle(
      center,
      r - lw * 0.35,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.7,
    );
    final finger = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lw * 0.18;
    for (final k in const [-0.35, 0.0, 0.35]) {
      c.drawLine(
        Offset(center.dx - r * 0.1, center.dy + r * k),
        Offset(center.dx + r * 0.55, center.dy + r * k),
        finger,
      );
    }
  }

  static void _belt(Canvas c, Offset neck, Offset hip, double lw) {
    final d = hip - neck;
    final len = d.distance == 0 ? 1.0 : d.distance;
    final u = Offset(d.dx / len, d.dy / len);
    final perp = Offset(-u.dy, u.dx);
    final center = hip - u * (lw * 0.9);
    final hl = lw * 1.6, ht = lw * 0.9;
    final path = Path()
      ..moveTo(center.dx + perp.dx * hl + u.dx * ht, center.dy + perp.dy * hl + u.dy * ht)
      ..lineTo(center.dx - perp.dx * hl + u.dx * ht, center.dy - perp.dy * hl + u.dy * ht)
      ..lineTo(center.dx - perp.dx * hl - u.dx * ht, center.dy - perp.dy * hl - u.dy * ht)
      ..lineTo(center.dx + perp.dx * hl - u.dx * ht, center.dy + perp.dy * hl - u.dy * ht)
      ..close();
    c.drawPath(path, Paint()..color = _orange);
    c.drawPath(
      path,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = lw * 0.18,
    );
  }

  static void _rockHair(Canvas c, Offset head, double r, double lw) {
    const uv = [
      Offset(-0.87, -0.50), Offset(-1.02, -0.80), Offset(-0.78, -1.05), Offset(-0.70, -1.30),
      Offset(-0.30, -1.20), Offset(-0.15, -1.42), Offset(0.25, -1.25), Offset(0.50, -1.38),
      Offset(0.78, -1.08), Offset(1.02, -0.78), Offset(0.87, -0.50),
    ];
    final path = Path();
    for (var i = 0; i < uv.length; i++) {
      final q = Offset(head.dx + uv[i].dx * r, head.dy + uv[i].dy * r);
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = _black);
    c.drawPath(
      path,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = lw * 0.2,
    );
  }

  // ---------------- wajah ----------------
  static void _drawFace(Canvas c, Offset head, double r, double lw, _FaceSpec f, bool scar) {
    Offset pt(double u, double v) => Offset(head.dx + u * r, head.dy + v * r);

    final stroke = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void seg(Offset a, Offset b, double w) => c.drawLine(a, b, stroke..strokeWidth = w);

    // mata
    for (final u in const [0.22, 0.64]) {
      _eye(c, pt(u, 0.04), r, lw, f.eyes);
    }
    // alis
    final brows = _browSegments[f.brows];
    if (brows != null) {
      for (final s in brows) {
        seg(pt(s[0].dx, s[0].dy), pt(s[1].dx, s[1].dy), lw * 0.5);
      }
    }
    // mulut
    switch (f.mouth) {
      case _Mouth.flat:
        seg(pt(0.25, 0.58), pt(0.75, 0.55), lw * 0.5);
      case _Mouth.smile:
        final a = pt(0.22, 0.52), m = pt(0.52, 0.64), b = pt(0.84, 0.46);
        final ctrl = Offset(2 * m.dx - (a.dx + b.dx) / 2, 2 * m.dy - (a.dy + b.dy) / 2);
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
        c.drawPath(path, stroke..strokeWidth = lw * 0.5);
        seg(b, pt(0.92, 0.38), lw * 0.4);
      case _Mouth.o:
        c.drawOval(
          Rect.fromCenter(center: pt(0.58, 0.58), width: 0.22 * r, height: 0.32 * r),
          Paint()..color = _black,
        );
      case _Mouth.shout:
        _openMouth(c, pt(0.50, 0.42), 0.42 * r, r);
      case _Mouth.laugh:
        _openMouth(c, pt(0.52, 0.40), 0.40 * r, r);
      case _Mouth.wavy:
        final path = Path();
        for (var i = 0; i <= 20; i++) {
          final q = pt(0.2 + 0.64 * i / 20, 0.62 + 0.05 * math.sin(i * 0.9));
          i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
        }
        c.drawPath(path, stroke..strokeWidth = lw * 0.5);
    }
    // bekas luka Rock
    if (scar) {
      seg(pt(0.82, 0.18), pt(0.72, 0.48), lw * 0.32);
      seg(pt(0.74, 0.28), pt(0.90, 0.33), lw * 0.26);
      seg(pt(0.72, 0.40), pt(0.88, 0.45), lw * 0.26);
    }
  }

  /// Mulut terbuka (setengah lingkaran bawah), deretan gigi atas, dan lidah.
  static void _openMouth(Canvas c, Offset center, double rad, double headR) {
    final path = Path()..moveTo(center.dx + rad, center.dy);
    path.arcTo(Rect.fromCircle(center: center, radius: rad), 0, math.pi, false);
    path.close();
    c.drawPath(path, Paint()..color = _black);
    final teeth = Path()
      ..moveTo(center.dx - rad * 0.86, center.dy + 0.02 * headR)
      ..lineTo(center.dx + rad * 0.86, center.dy + 0.02 * headR)
      ..lineTo(center.dx + rad * 0.72, center.dy + 0.12 * headR)
      ..lineTo(center.dx - rad * 0.72, center.dy + 0.12 * headR)
      ..close();
    c.drawPath(teeth, Paint()..color = _white);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 0.31 * headR),
        width: 0.40 * headR,
        height: 0.20 * headR,
      ),
      Paint()..color = _tongue,
    );
  }

  static void _eye(Canvas c, Offset center, double r, double lw, _Eyes kind) {
    final rx = 0.145 * r, ry = 0.205 * r;
    final ow = lw * 0.32;
    final fill = Paint()..color = _white;
    final ink = Paint()..color = _black;
    final ring = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = ow;

    void ellipse(double w, double h) {
      final rect = Rect.fromCenter(center: center, width: w * 2, height: h * 2);
      c.drawOval(rect, fill);
      c.drawOval(rect.deflate(ow / 2), ring);
    }

    switch (kind) {
      case _Eyes.open:
        ellipse(rx, ry);
        c.drawCircle(Offset(center.dx + 0.03 * r, center.dy + 0.02 * r), 0.065 * r, ink);
      case _Eyes.fire:
        ellipse(rx * 1.05, ry * 0.92);
        final pc = Offset(center.dx + 0.035 * r, center.dy + 0.02 * r);
        c.drawCircle(pc, 0.085 * r, ink);
        c.drawCircle(Offset(pc.dx - 0.03 * r, pc.dy - 0.04 * r), 0.025 * r, fill);
      case _Eyes.wide:
        ellipse(rx * 1.3, ry * 1.25);
        c.drawCircle(center, 0.04 * r, ink);
      case _Eyes.happy:
        final path = Path();
        for (var i = 0; i <= 16; i++) {
          final t = math.pi * (0.1 + 0.8 * i / 16);
          final q = Offset(
            center.dx + rx * 1.2 * math.cos(t),
            center.dy + 0.05 * r - ry * 0.9 * math.sin(t),
          );
          i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
        }
        c.drawPath(
          path,
          Paint()
            ..color = _black
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = lw * 0.55,
        );
      case _Eyes.cross:
        final k = 0.12 * r;
        final p = Paint()
          ..color = _black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = lw * 0.5;
        c.drawLine(Offset(center.dx - k, center.dy - k), Offset(center.dx + k, center.dy + k), p);
        c.drawLine(Offset(center.dx + k, center.dy - k), Offset(center.dx - k, center.dy + k), p);
    }
  }

  // ---------------- ikat kepala ----------------
  static List<Offset> _catmull(List<Offset> pts, int n) {
    final p = [pts.first, ...pts, pts.last];
    final out = <Offset>[];
    for (var i = 1; i < p.length - 2; i++) {
      final p0 = p[i - 1], p1 = p[i], p2 = p[i + 1], p3 = p[i + 2];
      for (var k = 0; k < n; k++) {
        final t = k / n;
        double f(double a, double b, double c0, double d0) =>
            0.5 *
            ((2 * b) +
                (-a + c0) * t +
                (2 * a - 5 * b + 4 * c0 - d0) * t * t +
                (-a + 3 * b - 3 * c0 + d0) * t * t * t);
        out.add(Offset(f(p0.dx, p1.dx, p2.dx, p3.dx), f(p0.dy, p1.dy, p2.dy, p3.dy)));
      }
    }
    out.add(pts.last);
    return out;
  }

  static Path _ribbon(List<Offset> pts, double w0, double w1) {
    final n = pts.length;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final Offset d;
      if (i == 0) {
        d = pts[1] - pts[0];
      } else if (i == n - 1) {
        d = pts[i] - pts[i - 1];
      } else {
        d = pts[i + 1] - pts[i - 1];
      }
      final len = d.distance == 0 ? 1.0 : d.distance;
      final nx = -d.dy / len, ny = d.dx / len;
      final w = (w0 + (w1 - w0) * i / (n - 1)) / 2;
      left.add(Offset(pts[i].dx + nx * w, pts[i].dy + ny * w));
      right.add(Offset(pts[i].dx - nx * w, pts[i].dy - ny * w));
    }
    final all = [...left, ...right.reversed];
    final path = Path()..moveTo(all.first.dx, all.first.dy);
    for (final q in all.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }

  static void _headband(Canvas c, Offset head, double r, double lw, double timeSec) {
    void ribbon(Path path) {
      c.drawPath(path, Paint()..color = _red);
      c.drawPath(
        path,
        Paint()
          ..color = _black
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = lw * 0.3,
      );
    }

    Offset at(double u, double v) => Offset(head.dx + u * r, head.dy + v * r);

    // ekor pita melambai di belakang kepala
    const tails = [
      [Offset(-0.90, -0.62), Offset(-1.40, -0.80), Offset(-2.00, -0.65), Offset(-2.53, -0.87), Offset(-3.07, -0.72)],
      [Offset(-0.88, -0.56), Offset(-1.47, -0.39), Offset(-2.07, -0.50), Offset(-2.67, -0.30), Offset(-3.13, -0.41)],
    ];
    const widths = [(0.20, 0.07), (0.18, 0.06)];
    for (var i = 0; i < tails.length; i++) {
      final raw = tails[i].map((q) {
        final wave = math.sin(timeSec * 7 + q.dx * 2.2 + i) * 0.07 * (-(q.dx + 0.9)).clamp(0.0, 3.0).toDouble();
        return at(q.dx, q.dy + wave);
      }).toList();
      ribbon(_ribbon(_catmull(raw, 8), widths[i].$1 * r, widths[i].$2 * r));
    }
    // pita melingkar di dahi
    const centre = [
      Offset(-0.88, -0.62), Offset(-0.45, -0.50), Offset(0.0, -0.45), Offset(0.45, -0.46), Offset(0.88, -0.52),
    ];
    ribbon(_ribbon(_catmull(centre.map((q) => at(q.dx, q.dy)).toList(), 8), 0.23 * r, 0.23 * r));
    // simpul
    final knot = at(-0.90, -0.60);
    c.drawCircle(knot, 0.12 * r, Paint()..color = _red);
    c.drawCircle(
      knot,
      0.12 * r,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.3,
    );
  }
}
