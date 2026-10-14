/// Semua teks antarmuka di satu tempat (bahasa Indonesia).
/// Ingin ganti bahasa atau gaya? Cukup ubah file ini.
class AppText {
  const AppText._();

  static const gameTitle = 'The World in\nMy Hands!';

  // Menu utama
  static const play = 'Main';
  static const quit = 'Keluar';
  static const viewStory = 'Lihat cerita';

  // Storyboard
  static const storySkip = 'Lewati';
  static const storyTapHint = 'Ketuk layar untuk lanjut';
  static const storyContinue = 'Lanjut';

  // Navigasi umum
  static const back = '< Kembali';
  static const backButton = 'Kembali';
  static const start = 'Mulai';

  // Pilih level
  static const levelSelectTitle = 'Kalahkan mereka!';
  static const comingSoon = 'Segera hadir';
  static const finishPreviousLevel = 'Selesaikan level sebelumnya dulu';
  static const levelNotFound = 'Level tidak ditemukan';
  static const levelUnavailable = 'Level belum tersedia';

  // Pause & hasil
  static const paused = 'Jeda';
  static const resume = 'Lanjut';
  static const restart = 'Ulangi';
  static const exit = 'Keluar';
  static const soundOn = 'Suara: Nyala';
  static const soundOff = 'Suara: Mati';
  static const perfectClear = 'Sempurna!';
  static const toLevelSelect = 'Pilih Level';
  static String lostAtStep(int step) => 'Kalah di Step $step';
}
