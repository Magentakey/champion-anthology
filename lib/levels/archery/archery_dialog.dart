/// Dialog Bima the Shooter. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
class ArcheryDialog {
  const ArcheryDialog._();

  static const String intro = 'Hmph, kau kira bisa membidik secepat aku?\nBuktikan di lapangan panahan!';

  static const String tip =
      'Tahan tombol untuk menarik busur sampai penuh, lalu lepas saat bidikan tepat di tengah. '
      'Makin lama ditahan, makin gemetar! Bidikan kuning = kena emas.';

  /// Saat step dimulai (indeks = step - 1).
  static const List<String> stepIntro = [
    'Papan diam dulu. Jangan sampai meleset!',
    'Angin mulai bertiup. Tetap tenang!',
    'Papan bergerak dan angin kencang. Mustahil!',
  ];

  /// Kena emas (skor 10).
  static const List<String> bullseye = [
    'Kena tepat di tengah?!',
    'Beruntung saja!',
    'Hah?! Itu kebetulan!',
  ];

  /// Bagus (skor 6 sampai 8).
  static const List<String> good = [
    'Lumayan...',
    'Hmph, tidak buruk.',
    'Masih kalah dariku.',
  ];

  /// Biasa saja (skor 2 sampai 4).
  static const List<String> meh = [
    'Itu pun disebut membidik?',
    'Pinggir papan, hahaha!',
    'Tanganmu gemetar, ya?',
  ];

  /// Meleset.
  static const List<String> miss = [
    'Meleset! Hahaha!',
    'Kau menembak langit?',
    'Papannya di sebelah sana!',
  ];

  static const List<String> lastArrow = [
    'Tinggal satu anak panah!',
    'Anak panah terakhir. Gugup?',
  ];

  /// Satu step selesai dan masih ada step berikutnya.
  static const List<String> stepClear = [
    'Hmph, kau memenuhi targetku...',
    'Hah?! Dengan angin begitu?!',
    'Mustahil!',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Anak panahmu habis di step pertama? Hahaha!',
      'Pulang dan belajar membidik dulu!',
    ],
    [
      'Satu step lolos. Itu baru pemanasan!',
      'Jangan sombong dulu.',
    ],
    [
      'Hampir! Papan bergerak terlalu cepat untukmu?',
      'Sayang sekali, tinggal beberapa poin lagi!',
    ],
    [
      'Mustahil... kau mengalahkan pemanah terbaik!',
      'Baiklah... kau jago memanah hari ini.',
    ],
  ];
}
