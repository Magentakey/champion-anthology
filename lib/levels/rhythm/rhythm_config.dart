/// Konfigurasi Level 7 (Rhea the Drummer): tiga lagu ritme, satu per step.
///
/// Berkas ini hanya memuat angka tetap: tempo, panjang lagu, jumlah not, jendela waktu, dan ambang lulus.
/// Tidak ada angka acak yang menentukan hasil; not dan lagu selalu sama setiap kali main. Tes
/// `rhythm_test.dart` memastikan satu-satunya angka pecahan di berkas ini adalah ambang lulus (0,6, 0,7, 0,78)
/// dan nilai setengah untuk GOOD (0,5); ukuran tata letak ada di `rhythm_stage.dart`.
library;

/// Jumlah jalur (dan pad) not.
const int rhythmLaneCount = 4;

/// Tempo tiap step (ketukan per menit, indeks = step - 1).
const List<int> rhythmBpm = [90, 110, 128];

/// Panjang lagu dalam bar, 4 ketukan per bar (indeks = step - 1).
const List<int> rhythmBars = [16, 20, 24];

/// Jumlah not tiap step, termasuk not bersamaan (indeks = step - 1).
const List<int> rhythmNoteCount = [32, 48, 72];

/// Jumlah pasangan not bersamaan (dua not di waktu yang sama) tiap step (indeks = step - 1).
const List<int> rhythmDoubleCount = [0, 6, 12];

/// Akurasi minimal agar step lulus (indeks = step - 1): 60%, 70%, dan 78%.
const List<double> rhythmPassThreshold = [0.6, 0.7, 0.78];

/// Nilai akurasi satu not: PERFECT satu penuh, GOOD setengah, MISS nol.
const double rhythmPerfectScore = 1;
const double rhythmGoodScore = 0.5;

/// Judul lagu tiap step, tampil di banner ronde (indeks = step - 1).
const List<String> rhythmSongTitles = ['Warm-up Groove', 'Street Beat', 'Final Encore'];

/// Berkas lagu pengiring tiap step di assets/audio/ (indeks = step - 1).
const List<String> rhythmSongFiles = ['rhythm_step1.wav', 'rhythm_step2.wav', 'rhythm_step3.wav'];

/// Seed generator not tiap step (indeks = step - 1). Mengubah seed mengubah susunan not.
const List<int> rhythmSeeds = [7101, 7202, 7303];

/// Tempo (ketukan per menit) pada [step] (1..3); di luar rentang dipotong ke ujung.
int rhythmBpmOf(int step) => rhythmBpm[_index(step)];

/// Panjang lagu dalam bar pada [step].
int rhythmBarsOf(int step) => rhythmBars[_index(step)];

/// Jumlah not pada [step].
int rhythmNoteCountOf(int step) => rhythmNoteCount[_index(step)];

/// Ambang lulus (0..1) pada [step].
double rhythmThresholdOf(int step) => rhythmPassThreshold[_index(step)];

/// Ambang lulus dalam persen bulat (60, 70, atau 78), dipakai untuk label di layar.
int rhythmThresholdPercent(int step) => (rhythmThresholdOf(step) * 100).round();

/// Lama satu ketukan dalam detik pada [step].
double rhythmBeatSeconds(int step) => 60 / rhythmBpmOf(step);

/// Lama lagu dalam detik pada [step]: bar x 4 ketukan x lama satu ketukan.
double rhythmSongSeconds(int step) => rhythmBarsOf(step) * RhythmTuning.beatsPerBar * rhythmBeatSeconds(step);

int _index(int step) => step.clamp(1, rhythmBpm.length).toInt() - 1;

/// Jendela waktu, kecepatan jatuh, dan durasi tahap (milidetik). Semua nilai tetap.
class RhythmTuning {
  const RhythmTuning._();

  /// PERFECT: selisih sampai 50 ms dari waktu not. GOOD: di atas 50 sampai 110 ms.
  static const int perfectWindowMs = 50;
  static const int goodWindowMs = 110;

  /// Not yang lewat 130 ms tanpa ketukan dinilai MISS. Ketukan hanya memilih not dalam jendela GOOD;
  /// ketukan di luar jendela diabaikan tanpa hukuman.
  static const int missWindowMs = 130;

  /// Lama not jatuh dari atas jalur ke garis ketuk. Sama di semua step; yang berubah hanya kerapatan not.
  static const int fallMs = 1400;

  /// Ketukan per bar dan lama hitung mundur: satu bar sebelum lagu, tiga ketukan setelah jeda.
  static const int beatsPerBar = 4;
  static const int countdownBeats = 4;
  static const int resumeCountdownBeats = 3;

  /// Offset kalibrasi: menggeser jadwal not terhadap musik (milidetik). Default 0.
  static const int defaultOffsetMs = 0;
  static const int minOffsetMs = -150;
  static const int maxOffsetMs = 150;
  static const int offsetStepMs = 10;

  /// Banner ronde sebelum hitung mundur, jeda memperlihatkan hasil, dan jeda antar step.
  static const int introMs = 2200;
  static const int resultMs = 1800;
  static const int stepGapMs = 800;

  /// Batas kerapatan penilaian MISS beruntun yang membuat bos tertawa, dan kelipatan combo yang membuat bos kagum.
  static const int laughMissStreak = 3;
  static const int awedComboEvery = 10;
}
