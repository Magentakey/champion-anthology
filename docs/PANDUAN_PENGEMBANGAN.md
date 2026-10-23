# Panduan Pengembangan

## 1. Menambah level baru

Level baru tidak perlu mengubah inti game. Alurnya: buat kelas game, daftarkan di registry.

### Langkah

1. **Buat folder** `lib/levels/<id>/` (contoh `lib/levels/maze/`).
2. **Buat kelas game** turunan `LevelGame` (lihat kerangka di bawah).
3. **Buat fungsi pabrik** `LevelGame createXGame(LevelSession session) => XGame(session);`.
4. **Daftarkan** di `lib/levels/level_registry.dart`: isi `createGame` (dan `bossImage` jika ada) pada entri level tersebut. Entri level 3 (Maze) dan 4 (Cooking) sudah ada tanpa `createGame`, cukup ditambahkan.
5. **Tambah aset** di `assets/images/<id>/` dan daftarkan foldernya di `pubspec.yaml` (folder tidak rekursif, tiap subfolder ditulis sendiri).
6. Jalankan `flutter analyze` dan `flutter test`.

Bintang tersimpan otomatis dengan kunci `stars_<id>`. Level terbuka jika level sebelumnya minimal 1 bintang. Layar jeda, hasil, penyimpanan bintang, dan tombol back sudah ditangani `GameplayScreen`.

### Kerangka

```dart
import 'package:flame/components.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';

LevelGame createMazeGame(LevelSession session) => MazeGame(session);

class MazeGame extends LevelGame {
  MazeGame(super.session);

  @override
  List<String> get assetPaths => const ['maze/player.png']; // relatif ke assets/images/

  @override
  Future<void> onLoad() async {
    await loadAssets();
    // ... buat komponen Flame di sini
    startStep(session.step);
  }

  @override
  void startStep(int step) {
    // Siapkan tantangan untuk step 1..3 (ukuran labirin, kecepatan, dll.)
  }

  void _onStepWon() {
    session.winStep();               // pindah ke step berikutnya, atau selesai jika Step 3
    if (session.isPlaying) {
      // jeda singkat lalu lanjutkan step berikutnya
      add(TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () => startStep(session.step),
      ));
    }
  }

  void _onStepLost() => session.loseStep(); // game berhenti, bintang = step yang dimenangkan
}
```

### Aturan yang perlu diikuti

- Level **hanya** melapor `session.winStep()` dan `session.loseStep()`. Penghitungan bintang dan layar hasil diurus inti.
- Gunakan `TimerComponent` untuk jeda, karena otomatis berhenti saat game dijeda.
- Muat gambar lewat `loadAssets()` dan `assetPaths` (cache gambar khusus level, dibersihkan saat level ditutup).
- Untuk HUD Flutter di atas arena (tombol, soal, dll.), override `buildHud(BuildContext)`.
- Untuk kalimat boss di layar hasil, override `resultMessage()`.
- Efek suara: `AudioService.instance.play(Sfx.xxx)`. Tambah SFX baru di enum `Sfx` dan taruh file `.wav` di `assets/audio/`.

## 2. Menambah atau mengubah soal (Level 2, Bob)

Semua soal ada di `assets/data/genius_questions.json`. Satu soal:

```json
{ "category": "Sains", "text": "Apa lambang kimia untuk emas?", "correct": "Au", "wrong": ["Ag", "Go", "Gd"] }
```

Aturan (dicek otomatis saat game memuat dan oleh `flutter test`):

- Tepat **3 pengecoh** dan 4 pilihan yang **unik**.
- Tidak ada soal ganda di seluruh bank.
- Minimal 15 soal per step, dan tiap step minimal 3 kategori berbeda.
- Urutan jawaban diacak otomatis; jawaban benar tidak perlu di posisi tertentu.

Step 1 = Mudah (umum), Step 2 = Sedang (sains dan sejarah), Step 3 = Sulit (pengetahuan khusus).

## 3. Mengatur kesulitan (Level 2, Bob)

Ubah angka di `lib/levels/genius/genius_config.dart`:

| Pengaturan | Arti | Nilai awal (Step 1 / 2 / 3) |
|---|---|---|
| `targetCorrect` | jawaban benar untuk menang step | 3 / 4 / 5 |
| `secondsPerQuestion` | waktu per soal (detik) | 12 / 9 / 7 |
| `lives` | kesalahan yang boleh sebelum kalah | 3 / 3 / 2 |

Ubah satu hal dalam satu waktu. `lives: 1` berarti salah sekali langsung kalah.

## 4. Mengganti aset dengan versi final

Cukup **timpa file bernama sama**, tanpa mengubah kode:

| Aset | Lokasi |
|---|---|
| Ekspresi Bob (idle, shock, laugh, defeat) | `assets/images/genius/boss_*.png` |
| Arena Colosseum, gambar intro Rock, potret HUD | `assets/images/fight/*.png` |
| Karakter menu utama (pemain) | `assets/images/home/mc_home.png` |
| Panel storyboard | `assets/images/story/panel_1.png` … `panel_4.png` |
| Efek suara | `assets/audio/*.wav` |
| Ikon aplikasi | `assets/icon/app_icon.png` dan `app_icon_fg.png`, lalu `dart run flutter_launcher_icons` |

Ukuran gambar boss sebaiknya persegi (512×512). Semua gambar bisa dibuat ulang dengan `python tools/art/generate_art.py` (butuh Pillow); aturan gayanya ada di [`ART_STYLE.md`](ART_STYLE.md). Jika menambah file baru atau subfolder baru, daftarkan di `pubspec.yaml`.

## 5. Mengubah teks dan dialog

- **Teks antarmuka** (tombol, judul, pesan): `lib/app/strings.dart`.
- **Dialog Bob** (ucapan awal step, reaksi benar/salah/waktu habis, kalimat hasil): `lib/levels/genius/genius_dialog.dart`.
- **Dialog intro boss**: `introDialog` di `lib/levels/level_registry.dart`.
- **Cerita**: `lib/screens/story_data.dart` (kalimat panel).

## 6. Rilis versi baru

1. Naikkan `version` di `pubspec.yaml` (mis. `1.0.1+2`).
2. `flutter analyze` dan `flutter test` harus bersih.
3. `flutter build apk --release`.
4. Commit, lalu buat Release di GitHub dan lampirkan APK (lihat bagian rilis di README atau catatan tim).

## 5. Level Fight (Level 1): pose, animasi, dan orientasi

- **Landscape**: level mengunci orientasi lewat `LevelGame.orientations` (dipulihkan ke potret saat keluar). Tombol jeda bisa dipindah lewat `pauseButtonAlignment`, dan layar hasil menyebut "Fase" lewat `stepLabel`. Level lain tidak perlu mengubah apa pun (nilai bawaan = potret).
- **Pose** ditulis di `tools/art/fight_poses.py` (satu sumber untuk gambar dan game). Setelah mengubah pose, jalankan `python tools/art/fight_poses.py` (tambah `--sheet` untuk lembar pratinjau di `/tmp/fight_poses.png`). Skrip menulis ulang `lib/levels/fight/pose_library.dart`; **jangan edit file itu manual**.
- **Klip animasi** (urutan pose dan durasi, termasuk waktu persiapan/aktif/pemulihan serangan) ada di `lib/levels/fight/pose_clips.dart`.
- **Tampilan petarung** (kepala, garis, rambut, sabuk, ikat kepala, wajah) digambar kode di `stick_renderer.dart`; warna dan proporsinya sama dengan generator art.
- **Tuning** fase, HP, kecepatan, dan sifat Rock per fase: `lib/levels/fight/fight_config.dart`. Damage, dorongan, dan lama terhenti tiap serangan: `attacks.dart` (jendela waktu hantam otomatis mengikuti klip animasinya). Kalimat Rock: `fight_dialog.dart`.
- **Arsitektur tempur**: `fighter_body.dart` (satu petarung: HP, mesin keadaan, serangan, tangkis, animasi) dan `fight_arena.dart` (dua petarung, pisau, penyelesaian hit) adalah Dart murni tanpa Flame sehingga bisa di-unit-test (`test/levels/fight/combat_test.dart`). `fight_game.dart` menghubungkannya ke Flame, HUD, dan sesi core.
- **Alur fase**: Rock hanya punya satu bar HP; saat HP-nya menyentuh batas fase (67% dan 33%), `FightGame` memanggil `session.winStep()` lalu `startStep(next)` tanpa memutus pertarungan. KO Rock di fase 3 memanggil `winStep()` terakhir; KO pemain memanggil `loseStep()`.
- **Kontrol di desktop** (untuk uji cepat di Windows): panah atau A/D untuk gerak, J pukul, K tendang, L atau S tangkis, I pisau.
- **Panel uji**: tombol `DEV` di bawah layar membuka panel untuk memutar animasi, mengatur Rock diam atau menyerang, dan memaksa menang fase atau kalah. Bersifat sementara; dihapus sebelum rilis.
- **AI Rock** ada di `enemy_ai.dart` (Dart murni, bisa di-test dengan `Random` ber-seed). Angka per fase (kecepatan, jeda reaksi, jeda serang, damage, peluang menangkis, membalas, menghukum) ada di `rockPhaseStats` pada `fight_config.dart`. Susunan combo dan pilihan serangan khusus tiap fase ada di `_choosePlan`. Serangan khusus (`Attacks.roundhouse`, `heavy`, `dash`) didefinisikan di `attacks.dart` dengan aba-aba (`telegraphMs`), terjang (`lunge`), armor, dan faktor tembus saat ditangkis (`blockedFactor`).
