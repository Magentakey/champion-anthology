import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Satu pose petarung dalam "ruang gambar": satuan = piksel bingkai 1000x1400 di generator art,
/// titik (0, 0) = tanah tepat di bawah pinggul saat berdiri, x positif ke depan, y positif ke bawah.
/// Pose selalu menghadap kanan; Fighter yang membalik gambar saat menghadap kiri.
class Pose {
  const Pose({
    required this.neck,
    required this.headDir,
    required this.hip,
    required this.elbowF,
    required this.handF,
    required this.elbowB,
    required this.handB,
    required this.kneeF,
    required this.ankleF,
    required this.toeF,
    required this.kneeB,
    required this.ankleB,
    required this.toeB,
    this.armsOver = false,
    this.fistF = true,
    this.fistB = true,
  });

  final Offset neck;

  /// Vektor satuan dari leher ke pusat kepala.
  final Offset headDir;
  final Offset hip;
  final Offset elbowF, handF, elbowB, handB;
  final Offset kneeF, ankleF, toeF, kneeB, ankleB, toeB;

  /// Lengan digambar di atas kepala (dipakai pose tangkis).
  final bool armsOver;
  final bool fistF, fistB;

  /// Bahu = 18% dari leher ke pinggul.
  Offset get shoulder => neck + (hip - neck) * 0.18;

  /// Pusat kepala untuk jari-jari [radius] tertentu.
  Offset headCenter(double radius) => neck + headDir * radius;

  /// Campuran dua pose, [t] 0..1.
  static Pose lerp(Pose a, Pose b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    Offset l(Offset p, Offset q) => Offset(p.dx + (q.dx - p.dx) * t, p.dy + (q.dy - p.dy) * t);
    final hd = l(a.headDir, b.headDir);
    final len = math.sqrt(hd.dx * hd.dx + hd.dy * hd.dy);
    return Pose(
      neck: l(a.neck, b.neck),
      headDir: len < 1e-6 ? a.headDir : Offset(hd.dx / len, hd.dy / len),
      hip: l(a.hip, b.hip),
      elbowF: l(a.elbowF, b.elbowF),
      handF: l(a.handF, b.handF),
      elbowB: l(a.elbowB, b.elbowB),
      handB: l(a.handB, b.handB),
      kneeF: l(a.kneeF, b.kneeF),
      ankleF: l(a.ankleF, b.ankleF),
      toeF: l(a.toeF, b.toeF),
      kneeB: l(a.kneeB, b.kneeB),
      ankleB: l(a.ankleB, b.ankleB),
      toeB: l(a.toeB, b.toeB),
      armsOver: t < 0.5 ? a.armsOver : b.armsOver,
      fistF: t < 0.5 ? a.fistF : b.fistF,
      fistB: t < 0.5 ? a.fistB : b.fistB,
    );
  }
}
