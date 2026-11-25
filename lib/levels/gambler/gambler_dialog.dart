import 'gambler_config.dart';

/// Dialog Mr. Lexi the Gambler. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
/// Font piksel hanya punya huruf besar, angka, dan tanda baca dasar (. , ! ? : - / ( ) ' " % + = *).
class GamblerDialog {
  const GamblerDialog._();

  static const String intro =
      'Selamat datang di stanku!\nTiga permainan, satu keberuntungan.\nBerani mencoba?';

  static const String tip =
      'Pilih kartu, sisi koin, atau cangkir, lalu tekan tombol konfirmasi. Semua murni peluang, angkanya tampil di '
      'layar. Chip bohongan, tanpa uang nyata!';

  /// Label peluang di layar, mis. "PELUANG MENANG 75%". Angkanya selalu dari [gamblerChanceOf].
  static String oddsLabel(int step) => 'Peluang menang ${gamblerChancePercent(step)}%';

  /// Petunjuk di panel kontrol tiap permainan (indeks = step - 1).
  static const List<String> hintPick = [
    'Pilih satu kartu',
    'Pilih kepala atau ekor',
    'Pilih satu cangkir',
  ];

  /// Petunjuk setelah ada pilihan, dan saat cangkir masih diacak.
  static const List<String> hintReady = [
    'Tekan BUKA untuk membuka kartu',
    'Tekan LEMPAR untuk melempar koin',
    'Tekan BUKA untuk mengangkat cangkir',
  ];
  static const String hintShuffle = 'Awasi bolanya...';
  static const String hintReveal = 'Hasilnya...';

  /// Tombol konfirmasi tiap permainan (indeks = step - 1).
  static const List<String> confirmLabel = ['BUKA', 'LEMPAR', 'BUKA'];

  /// Pembuka tiap step (indeks = step - 1).
  static const List<String> stepIntro = [
    'Empat kartu, satu kartu sial. Pilih dengan hati-hati!',
    'Kepala atau ekor? Setengah-setengah, kawan!',
    'Awasi bolanya... kalau bisa!',
  ];

  /// Saat pemain menang satu step (indeks = step - 1).
  static const List<List<String>> win = [
    [
      'Hah?! Kartu aman?',
      'Beruntung! Cuma pemanasan!',
    ],
    [
      'Koinku berkhianat?!',
      'Ini pasti kebetulan!',
    ],
    [
      'Mustahil! Bolanya ketemu?!',
      'Kau mengintip, ya?!',
    ],
  ];

  /// Saat pemain kalah satu step (indeks = step - 1).
  static const List<List<String>> lose = [
    [
      'Kartu sial! Hahaha!',
      'Satu dari empat, dan kau kena!',
    ],
    [
      'Koin tidak pernah bohong!',
      'Sisi yang salah, kawan!',
    ],
    [
      'Bolanya di sebelah sana!',
      'Mata kurang awas, ya?',
    ],
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Kartu pertama saja kena bom! Hahaha!',
      'Keberuntunganmu habis di pintu masuk!',
    ],
    [
      'Satu kemenangan. Itu pun cuma pemanasan!',
      'Koin ini hanya setengah baik padamu.',
    ],
    [
      'Hampir! Satu cangkir lagi dari kejayaan!',
      'Tinggal satu tebakan, sayang sekali!',
    ],
    [
      'Tiga kali menang berturut-turut?! Mustahil!',
      'Baiklah... hari ini dewi fortuna milikmu.',
    ],
  ];
}
