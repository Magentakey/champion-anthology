/// Dialog Asep the Mazelogist. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
class MazeDialog {
  const MazeDialog._();

  static const String tip =
      'Tahan tombol arah untuk jalan terus, ketuk untuk satu langkah. '
      'Capai bintang emas sebelum waktu habis!';

  /// Saat step dimulai (indeks = step - 1).
  static const List<String> stepIntro = [
    'Labirin kecil dulu. Jangan tersesat, ya!',
    'Hmm, kau cepat juga. Coba yang lebih besar!',
    'Labirin terbesarku! Belum ada yang berhasil keluar!',
  ];

  /// Saat labirin selesai dan masih ada step berikutnya.
  static const List<String> stepClear = [
    'Hmph, kau menemukan jalannya...',
    'Kebetulan saja!',
    'Hah?! Secepat itu?!',
  ];

  /// Saat sisa waktu tinggal sedikit.
  static const List<String> hurry = [
    'Waktumu hampir habis!',
    'Tik tok... tersesat, ya?',
    'Mau menyerah saja?',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Tersesat di labirin pertama? Hehe.',
      'Pulang saja, kau tidak cocok di sini!',
    ],
    [
      'Satu labirin selesai. Masih jauh dari juara!',
      'Baru pemanasan, bukan?',
    ],
    [
      'Hampir saja! Labirin terakhir terlalu besar untukmu?',
      'Sayang sekali, tinggal satu belokan lagi!',
    ],
    [
      'Mustahil... kau keluar dari semua labirinku?!',
      'Baiklah... kau pemandu terbaik hari ini.',
    ],
  ];
}
