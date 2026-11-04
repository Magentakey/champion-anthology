/// Dialog Cooking Champion. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
class CookingDialog {
  const CookingDialog._();

  static const String intro = 'Hmph... berani masuk dapurku?\nBuktikan kau bisa memasak!';

  static const String tip =
      'Geser bahan ke stasiun yang tepat: Talenan (iris), Panci (rebus), Wajan (goreng). '
      'Salah stasiun atau gagal masak mengurangi waktu!';

  /// Saat step dimulai (indeks = step - 1).
  static const List<String> stepIntro = [
    'Pesanan mudah dulu. Jangan sampai gosong!',
    'Dapurku makin ramai. Bisa mengimbangi?',
    'Pesanan spesial! Hanya juara sejati yang bisa!',
  ];

  /// Cooking check berhasil.
  static const List<String> checkOk = [
    'Hmph, lumayan.',
    'Tidak buruk...',
    'Hah? Kok bisa pas?',
    'Beruntung saja!',
  ];

  /// Cooking check gagal (gosong, meluap, kehabisan waktu).
  static const List<String> checkFail = [
    'Gosong! Hahaha!',
    'Dasar koki amatir!',
    'Bahannya terbuang, tuh!',
    'Masak apa itu?!',
  ];

  /// Bahan salah stasiun / bukan pesanan.
  static const List<String> wrong = [
    'Salah tempat!',
    'Baca pesanannya dulu!',
    'Itu bukan pesanan, bodoh!',
    'Mau masak apa, sih?',
  ];

  static const List<String> hurry = [
    'Pelanggan sudah menunggu!',
    'Cepat, cepat! Waktu hampir habis!',
    'Tik tok... pesanan telat!',
  ];

  /// Satu pesanan selesai, masih ada step berikutnya.
  static const List<String> stepClear = [
    'Pesanan jadi... lumayan.',
    'Hmph, kau cepat juga.',
    'Hah?! Pesanan rumit begitu?!',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Pesanan pertama saja gagal? Keluar dari dapurku!',
      'Hahaha! Coba lagi kalau sudah belajar masak!',
    ],
    [
      'Satu pesanan jadi. Masih jauh dari juara!',
      'Baru pemanasan, bukan?',
    ],
    [
      'Hampir! Pesanan terakhir terlalu rumit untukmu?',
      'Sayang sekali, tinggal sedikit lagi!',
    ],
    [
      'Mustahil... masakanmu lebih enak dariku?!',
      'Baiklah... kau juara dapur hari ini.',
    ],
  ];
}
