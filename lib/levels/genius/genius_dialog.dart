/// Dialog Bob the Genius. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
class GeniusDialog {
  const GeniusDialog._();

  /// Saat step dimulai (indeks = step - 1).
  static const List<String> stepIntro = [
    'Pemanasan dulu ya, anak baru!',
    'Hmm, ternyata kau lumayan. Sekarang kubuat lebih sulit!',
    'Ini soal para jenius sejati! Bersiaplah menyerah!',
  ];

  static const List<String> correct = [
    'Hmph, kebetulan!',
    'Tidak buruk...',
    'Kau lumayan juga!',
    'Hah?! Bagaimana kau tahu?!',
    'Beruntung saja!',
  ];

  static const List<String> wrong = [
    'Hahaha! Salah!',
    'Segitu saja?',
    'Belajar lagi sana!',
    'Itu soal gampang, lho!',
    'Kena kau!',
  ];

  static const List<String> timeout = [
    'Terlalu lambat!',
    'Waktumu habis! Hehe.',
    'Kelamaan mikir!',
    'Tik tok tik tok... habis!',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Baru begitu saja sudah menyerah? Tahu tempatmu!',
      'Hahaha! Kembali belajar sana!',
    ],
    [
      'Baru selangkah. Jangan sombong dulu!',
      'Pemula memang begitu, hehe.',
    ],
    [
      'Hampir saja... tapi gelar ini tetap milikku!',
      'Satu langkah lagi, sayang sekali!',
    ],
    [
      'Tidak mungkin... akulah sang jenius... kalah?!',
      'Baiklah... hari ini kau lebih jenius dariku.',
    ],
  ];
}
