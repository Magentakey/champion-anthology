import 'dart:math' show min;

import 'rhythm_config.dart';

/// Dialog Rhea the Drummer. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
/// Font piksel hanya punya huruf besar, angka, dan tanda baca dasar (. , ! ? : - / ( ) ' " % + = *).
class RhythmDialog {
  const RhythmDialog._();

  static const String intro =
      'Selamat datang di panggungku!\nIkuti irama drumku.\nKetukanmu harus tepat!';

  static const String tip =
      'Ketuk pad di bawah saat not menyentuh garis (papan ketik: D F J K). Makin tepat makin tinggi akurasi; capai '
      'target akurasi untuk lulus. Lagu dan not selalu sama, jadi bisa dilatih.';

  /// Label target di layar, mis. "Target akurasi 60%". Angkanya selalu dari [rhythmThresholdPercent].
  static String targetLabel(int step) => 'Target akurasi ${rhythmThresholdPercent(step)}%';

  /// Akurasi sementara di bilah atas, mis. "Akurasi 75%".
  static String accuracyLabel(double accuracy) => 'Akurasi ${(accuracy * 100).round()}%';

  /// Hitungan combo di layar, mis. "12 COMBO".
  static String comboLabel(int combo) => '$combo COMBO';

  /// Kata hitung mundur. [total] 4 = sebelum lagu ("3 2 1 MULAI"), 3 = setelah jeda ("3 2 1").
  static String countWord(int beat, int total) {
    const words = ['3', '2', '1', 'MULAI'];
    return words[beat.clamp(0, min(total, words.length) - 1).toInt()];
  }

  /// Nama penilaian di layar.
  static const String perfect = 'PERFECT';
  static const String good = 'GOOD';
  static const String miss = 'MISS';

  /// Hasil satu step di layar.
  static const String passed = 'LULUS!';
  static const String failed = 'GAGAL';

  /// Kalimat pada panel offset di layar jeda.
  static const String offsetTitle = 'Offset suara';
  static const String offsetHint = 'Geser bila ketukan terasa meleset';
  static String offsetLabel(int ms) => '${ms > 0 ? '+' : ''}$ms ms';

  /// Pembuka tiap step (indeks = step - 1).
  static const List<String> stepIntro = [
    'Pemanasan dulu. Ikuti ketukannya!',
    'Iramanya makin cepat. Siap?',
    'Lagu penutup! Ikuti kalau mampu!',
  ];

  /// Saat pemain lulus satu step (indeks = step - 1).
  static const List<List<String>> win = [
    [
      'Hah?! Ketukanmu lumayan!',
      'Itu baru pemanasan!',
    ],
    [
      'Hebat! Tanganmu cepat juga!',
      'Jangan bangga dulu, kawan!',
    ],
    [
      'Mustahil! Irama terakhirku?!',
      'Kau memang punya irama juara!',
    ],
  ];

  /// Saat pemain gagal satu step (indeks = step - 1).
  static const List<List<String>> lose = [
    [
      'Ketukanmu melenceng, hahaha!',
      'Dengarkan iramanya, kawan!',
    ],
    [
      'Terlalu lambat! Coba lagi!',
      'Tanganmu ketinggalan irama!',
    ],
    [
      'Hampir! Tapi belum cukup!',
      'Final Encore belum menerimamu!',
    ],
  ];

  /// Saat combo kelipatan 10, dan saat banyak MISS beruntun.
  static const List<String> comboPraise = [
    'Wah! Combo-mu panjang!',
    'Ketukanmu rapi sekali!',
  ];
  static const List<String> missTaunt = [
    'Hahaha! Meleset lagi!',
    'Kau kehilangan iramanya!',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Lagu pertama saja sudah kacau! Hahaha!',
      'Belajar dulu mendengar irama, kawan!',
    ],
    [
      'Satu lagu lulus. Itu cuma pemanasan!',
      'Iramaku terlalu cepat untukmu!',
    ],
    [
      'Hampir! Tinggal satu lagu lagi!',
      'Final Encore menunggumu, sayang sekali!',
    ],
    [
      'Tiga lagu tanpa cela?! Mustahil!',
      'Baiklah... panggung ini milikmu, juara!',
    ],
  ];
}
