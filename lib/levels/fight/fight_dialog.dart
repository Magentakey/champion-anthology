/// Semua kalimat Rock (bahasa Indonesia). Ubah teks di sini saja.
abstract final class FightDialog {
  static const intro = 'Hmph. Kau datang untuk gelarku?\nBuktikan di arena, bocah!';

  /// Ejekan saat fase 1, 2, 3 dimulai.
  static const phaseLines = <String>[
    'Pemanasan dulu, bocah.',
    'Lumayan... Sekarang aku serius!',
    'AAARGH! Kau memaksaku!',
  ];

  /// Kalimat di layar hasil menurut jumlah bintang (0..3).
  static String resultLine(int stars) {
    switch (stars) {
      case 0:
        return 'Baru begitu saja sudah tumbang?';
      case 1:
        return 'Satu langkah... masih jauh dariku.';
      case 2:
        return 'Hampir! Tapi hampir tidak ada artinya.';
      default:
        return 'Tidak mungkin... Kau pantas jadi juara.';
    }
  }
}
