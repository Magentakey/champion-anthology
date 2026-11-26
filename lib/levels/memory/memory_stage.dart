import 'dart:ui';

import 'package:flame/components.dart';

import 'memory_config.dart';

/// Warna tiap pad (indeks 0..8): merah, biru, hijau, emas, ungu, merah muda, teal, oranye, krem.
const List<Color> memoryPadColors = [
  Color(0xFFE84048),
  Color(0xFF408CF0),
  Color(0xFF54C864),
  Color(0xFFFFC830),
  Color(0xFF9858E0),
  Color(0xFFF078B8),
  Color(0xFF30C0B0),
  Color(0xFFF08A30),
  Color(0xFFFFF0D0),
];

/// Bentuk tiap pad (dipakai juga untuk label pembaca layar). Bentuk, warna, dan nada sama di semua step.
const List<String> memoryPadShapes = [
  'Lingkaran merah',
  'Segitiga biru',
  'Persegi hijau',
  'Berlian emas',
  'Bintang ungu',
  'Hati merah muda',
  'Salib teal',
  'Bulan sabit oranye',
  'Segi enam krem',
];

/// Nada tiap pad (pentatonik C) dan frekuensinya dalam Hz; berkas suara `memory_note_<indeks>.wav`.
const List<String> memoryPadNotes = ['C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5', 'E5', 'G5'];
const List<int> memoryPadFrequencies = [262, 294, 330, 392, 440, 523, 587, 659, 784];

/// Posisi dan ukuran (pecahan layar) yang dipakai bersama oleh Flame dan HUD Flutter.
/// Bos dan gelembung sama dengan level lain.
class MemoryLayout {
  const MemoryLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.09;
  static const double bubbleHeight = 0.16;
  static const double bubbleLeft = 0.52;

  /// Zona vertikal (pecahan tinggi layar): bilah atas, boss, status, bar timer, area pad, dan margin bawah.
  static const double topBarBottom = 0.07;
  static const double bossTop = 0.08;
  static const double bossBottom = 0.27;
  static const double statusTop = 0.28;
  static const double statusBottom = 0.36;
  static const double timerTop = 0.36;
  static const double timerBottom = 0.39;
  static const double padAreaTop = 0.40;
  static const double padAreaBottom = 0.92;

  /// Jarak area pad dari tepi layar dan celah antar-pad (dp).
  static const double sideMargin = 16;
  static const double padGap = 6;

  /// Ukuran ketuk terkecil (dp) yang dijaga pada layar selebar 360.
  static const double minPadSize = 56;

  /// Kotak area pad di layar berukuran [size].
  static Rect padArea(Size size) => Rect.fromLTRB(
        sideMargin,
        padAreaTop * size.height,
        size.width - sideMargin,
        padAreaBottom * size.height,
      );

  /// Sisi satu pad (persegi) pada [step] di layar berukuran [size]: sisi terkecil sel kisi.
  static double padSide(int step, Size size) {
    final area = padArea(size);
    final cols = memoryColumnsOf(step);
    final rows = memoryRowsOf(step);
    final cellW = (area.width - padGap * (cols - 1)) / cols;
    final cellH = (area.height - padGap * (rows - 1)) / rows;
    return cellW < cellH ? cellW : cellH;
  }

  /// Kotak pad ke-[index] pada [step]; kisi persegi di tengah area pad, urut kiri-kanan lalu atas-bawah.
  static Rect padRect(int step, int index, Size size) {
    final area = padArea(size);
    final cols = memoryColumnsOf(step);
    final rows = memoryRowsOf(step);
    final side = padSide(step, size);
    final gridW = side * cols + padGap * (cols - 1);
    final gridH = side * rows + padGap * (rows - 1);
    final left = area.left + (area.width - gridW) / 2;
    final top = area.top + (area.height - gridH) / 2;
    final col = index % cols;
    final row = index ~/ cols;
    return Rect.fromLTWH(left + col * (side + padGap), top + row * (side + padGap), side, side);
  }

  /// Zona status (judul fase, "Ingat r/R", penghitung, nyawa) di layar berukuran [size].
  static Rect statusRect(Size size) => Rect.fromLTRB(
        sideMargin,
        statusTop * size.height,
        size.width - sideMargin,
        statusBottom * size.height,
      );

  /// Zona bar timer di layar berukuran [size].
  static Rect timerRect(Size size) => Rect.fromLTRB(
        sideMargin,
        timerTop * size.height,
        size.width - sideMargin,
        timerBottom * size.height,
      );
}

/// Efek di belakang HUD: cahaya di sekeliling pad yang menyala dan kilat merah tipis satu kali saat salah.
/// Tidak ada logika nilai di sini; semua keadaan diberikan oleh game.
class MemoryStage extends PositionComponent {
  MemoryStage();

  /// Langkah sedang berjalan (menentukan kisi pad).
  int step = 1;

  /// Pad yang sedang menyala; null = tidak ada.
  int? litPad;

  /// Sisa kilat merah (0..1); turun sendiri.
  double flash = 0;

  final Paint _paint = Paint();

  /// Memulai satu kilat merah. Tidak berulang cepat: hanya memudar satu kali.
  void startFlash() => flash = 1;

  @override
  void update(double dt) {
    super.update(dt);
    if (flash > 0) {
      flash -= dt * 1000 / MemoryTuning.wrongFlashMs;
      if (flash < 0) flash = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final pad = litPad;
    if (pad != null && pad >= 0 && pad < memoryPadsOf(step)) {
      final rect = MemoryLayout.padRect(step, pad, Size(size.x, size.y)).inflate(10);
      final color = memoryPadColors[pad];
      for (var i = 3; i >= 1; i--) {
        _paint.color = color.withValues(alpha: 0.12 * (4 - i));
        canvas.drawRect(rect.inflate(i * 3.0), _paint);
      }
    }
    if (flash > 0) {
      _paint.color = Color.fromRGBO(232, 48, 48, 0.22 * flash);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
    }
  }
}
