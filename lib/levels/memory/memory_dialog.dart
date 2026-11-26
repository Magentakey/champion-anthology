import '../../core/level/star_calculator.dart';
import 'memory_config.dart';

/// Dialog Mira the Memory Keeper. Edit / tambah kalimat di sini; tidak perlu ubah kode lain.
/// Font piksel hanya punya huruf besar, angka, dan tanda baca dasar (. , ! ? : - / ( ) ' " % + = *).
class MemoryDialog {
  const MemoryDialog._();

  static const String intro = 'Selamat datang di perpustakaanku! Perhatikan urutannya, lalu ulangi.';

  static const String tip =
      'Perhatikan urutan pad yang menyala, lalu ketuk dengan urutan yang sama. Tiap ronde makin panjang. '
      'Nyawa habis = ronde gagal. Pad punya bentuk dan nada berbeda untuk membantumu.';

  /// Kata di banner ronde: "INGAT 1", "INGAT 2", "INGAT 3".
  static const String bannerWord = 'INGAT';

  /// Label di bilah atas, mis. "Ronde 2/3".
  static String roundLabel(int step) => 'Ronde $step/${StarCalculator.totalSteps}';

  /// Label kemajuan ronde, mis. "Ingat 1/5". Angkanya selalu dari konfigurasi.
  static String rememberLabel(int round, int rounds) => 'Ingat $round/$rounds';

  /// Penghitung ketukan benar dari panjang urutan, mis. "3/7".
  static String counterLabel(int correct, int length) => '$correct/$length';

  /// Judul kecil di banner ronde, mis. "4 pad".
  static String padsLabel(int step) => '${memoryPadsOf(step)} pad';

  /// Baris catatan di banner ronde, mis. "Urutan 3-7".
  static String lengthRangeLabel(int step) => 'Urutan ${memoryStartLengthOf(step)}-${memoryFinalLengthOf(step)}';

  /// Label nyawa di layar.
  static const String livesLabel = 'Nyawa';

  /// Judul fase dan hasil ketukan di layar.
  static const String watch = 'PERHATIKAN';
  static const String yourTurn = 'GILIRANMU';
  static const String right = 'BENAR!';
  static const String wrong = 'SALAH!';
  static const String timeUp = 'WAKTU HABIS';

  /// Hasil satu step di layar.
  static const String passed = 'LULUS!';
  static const String failed = 'GAGAL';

  /// Pembuka tiap step (indeks = step - 1).
  static const List<String> stepIntro = [
    'Pemanasan dulu. Empat pad saja!',
    'Enam pad sekarang. Awas lupa!',
    'Sembilan pad! Ingatanmu diuji!',
  ];

  /// Saat pemain lulus satu step (indeks = step - 1).
  static const List<List<String>> win = [
    [
      'Hmm, ingatanmu lumayan!',
      'Itu baru pemanasan!',
    ],
    [
      'Hebat! Matamu jeli juga!',
      'Jangan bangga dulu, kawan!',
    ],
    [
      'Mustahil! Semua urutan hafal?!',
      'Kau memang penjaga ingatan sejati!',
    ],
  ];

  /// Saat pemain gagal satu step (indeks = step - 1).
  static const List<List<String>> lose = [
    [
      'Lupa secepat itu? Hahaha!',
      'Perhatikan baik-baik, kawan!',
    ],
    [
      'Urutannya terlalu panjang untukmu!',
      'Ingatanmu bocor, hahaha!',
    ],
    [
      'Hampir! Tapi belum cukup!',
      'Sembilan pad belum menerimamu!',
    ],
  ];

  /// Saat pemain menyelesaikan ronde dengan beberapa kesalahan (minimal 3 variasi).
  static const List<String> correctReact = [
    'Benar! Lanjut ke urutan berikutnya.',
    'Bagus, ingatanmu tajam!',
    'Hmm, kau berhasil kali ini.',
  ];

  /// Saat pemain salah mengetuk (minimal 3 variasi).
  static const List<String> wrongReact = [
    'Salah! Hahaha, perhatikan lagi!',
    'Bukan itu urutannya!',
    'Ingatanmu mulai kabur!',
  ];

  /// Saat waktu antar-ketukan habis (minimal 2 variasi).
  static const List<String> timeoutReact = [
    'Terlalu lama berpikir!',
    'Waktumu habis, kawan!',
  ];

  /// Saat satu ronde selesai tanpa kesalahan (minimal 2 variasi).
  static const List<String> cleanReact = [
    'Tanpa salah sedikit pun?!',
    'Ronde bersih! Ingatan yang rapi!',
  ];

  /// Layar hasil. Indeks = bintang yang didapat (0..3).
  static const List<List<String>> resultByStars = [
    [
      'Ronde pertama saja sudah lupa! Hahaha!',
      'Latih ingatanmu dulu, kawan!',
    ],
    [
      'Satu ronde lulus. Itu cuma pemanasan!',
      'Urutanku terlalu panjang untukmu!',
    ],
    [
      'Hampir! Tinggal sembilan pad lagi!',
      'Ronde terakhir menunggumu, sayang sekali!',
    ],
    [
      'Tiga ronde tanpa lupa?! Mustahil!',
      'Baiklah... perpustakaan ini milikmu, juara!',
    ],
  ];
}
