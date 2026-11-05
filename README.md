# Champion Anthology — *The World in My Hands!*

Game mobile (Android) bergenre **minigame anthology dengan alur cerita**. Karakter utama menantang para juara di berbagai bidang untuk merebut gelar juara utama. Dibuat dengan **Flutter** (UI, cerita, navigasi) dan **Flame Engine** (gameplay 2D).

## Status

| Level | Boss | Status |
|---|---|---|
| 1 | Rock the Fighter (pertarungan, 3 fase menurut batas HP) | Dapat dimainkan (tempur, 3 fase, AI Rock, efek, suara); tuning berdasarkan uji di HP menyusul |
| 2 | Bob the Genius (kuis pengetahuan) | Selesai, bisa dimainkan |
| 3 | Asep the Mazelogist (labirin, tombol arah, batas waktu) | Selesai, bisa dimainkan |
| 4 | Cooking Champion (ritme dan waktu) | Direncanakan |

## Unduh dan pasang

APK terbaru ada di halaman **Releases** repositori ini. Setelah mengunduh, izinkan "Instal aplikasi dari sumber tidak dikenal" di HP Anda. Jika muncul peringatan Play Protect, pilih "Tetap instal" (APK ini belum dipublikasikan lewat Play Store).

## Cara bermain

- Setiap kali menekan **Main**, cerita pembuka tampil dulu (bisa dilewati dengan tombol Lewati).
- Setiap level terdiri dari **3 step berurutan** (Mudah → Sedang → Sulit) yang dimainkan langsung dalam satu sesi, tanpa kembali ke menu.
- Jawab soal sebelum waktu habis. Jawaban salah atau terlambat mengurangi nyawa; nyawa habis berarti kalah.
- Bintang sama dengan jumlah step yang berhasil dimenangkan:

| Hasil | Bintang |
|---|---|
| Kalah di Step 1 | 0 |
| Menang Step 1, kalah di Step 2 | 1 |
| Menang Step 2, kalah di Step 3 | 2 |
| Menang Step 3 | 3 (Sempurna) |

- **Level 1 (Rock the Fighter)** dimainkan landscape: tombol gerak kiri/kanan, pukul, tendang, tangkis, dan lempar pisau. Rock punya 3 fase menurut batas HP-nya, dan tiap fase yang kamu menangkan memberi 1 bintang. Saat Rock memberi aba-aba merah, siapkan tangkisan atau menghindar. (Papan ketik untuk uji di emulator: A/D gerak, J pukul, K tendang, I pisau, L atau S tangkis.)
- **Level 3 (Asep the Mazelogist)**: temukan jalan dari titik start (hijau, kiri atas) ke bintang emas (kanan bawah) memakai tombol arah di layar. Tahan tombol untuk jalan terus, ketuk untuk satu langkah. Tiap step hanya berbeda ukuran labirin dan batas waktu (Step 1 kecil, Step 3 besar); waktu habis berarti kalah. (Papan ketik untuk uji di emulator: panah atau WASD.)
- **Level 4 (Cooking Champion)**: tiap step ada satu pesanan masakan acak. Geser bahan dari baki ke stasiun yang tepat: **Talenan** (iris: ketuk terus sampai bar penuh), **Panci** (rebus: tahan tombol api untuk naik suhu, lepas untuk turun, jaga di zona hijau), **Wajan** (goreng: ketuk saat jarum di zona emas). Bahan di luar pesanan atau salah stasiun mengurangi 3 detik, cooking check yang gagal mengurangi 4 detik, check yang mulus menambah 1 detik. Semua bahan selesai sebelum waktu habis = menang. Step 1 sampai 3 beda jumlah bahan, pengecoh, dan ketatnya check.
- Level berikutnya terbuka jika level sebelumnya sudah mendapat minimal 1 bintang. Bintang terbaik tersimpan di perangkat.

## Menjalankan dari kode

Prasyarat: [Flutter SDK](https://docs.flutter.dev/get-started/install), Android SDK, dan perangkat Android (atau emulator).

```bash
git clone <url-repositori-ini>
cd champion_anthology
flutter pub get
flutter run            # mode debug
flutter run --profile  # untuk menguji performa
```

Perintah lain:

```bash
flutter analyze
flutter test
flutter build apk --release   # hasil: build/app/outputs/flutter-apk/app-release.apk
```

## Struktur proyek

```
lib/
├── main.dart                 # titik masuk (SharedPreferences + audio)
├── app/                      # app.dart, router.dart, theme.dart, strings.dart (semua teks UI)
├── core/                     # inti yang dipakai semua level
│   ├── level/                # LevelSession, LevelGame, LevelDefinition, StarCalculator
│   ├── assets/               # AssetLoader (muat/bersihkan aset per level)
│   ├── audio/                # AudioService (SFX latensi rendah, musik latar BGM, mute)
│   └── save/                 # ProgressRepository (bintang tersimpan)
├── levels/
│   ├── level_registry.dart   # daftar semua level
│   ├── fight/                # Level 1: arena, petarung stickman, pose, animasi
│   └── genius/               # Level 2: game, HUD, konfigurasi, soal, dialog
├── screens/                  # menu, storyboard, pilih level, intro boss, gameplay
└── shared/widgets/           # StarRow, overlay jeda/hasil, efek getar
assets/
├── images/home/              # latar menu piksel (home_bg.png) dan tombol (btn_*.png)
├── images/genius/            # ekspresi Bob (boss_*.png)
├── images/maze/              # ekspresi Asep (boss_*.png)
├── images/cooking/           # chef, ikon bahan, stasiun, latar dapur
├── images/story/             # panel storyboard piksel (panel_*.png)
├── fonts/                    # PixelChampion.ttf (font piksel 5x7, huruf besar)
├── data/genius_questions.json
├── audio/                    # SFX dan BGM (.wav)
└── icon/                     # ikon aplikasi
test/                         # unit dan widget test
tools/art/generate_art.py     # generator aset gambar (gaya stickman)
tools/audio/generate_fight_audio.py  # generator SFX dan BGM Level 1 (butuh numpy)
tools/audio/generate_cooking_audio.py  # generator SFX Level 4 (potong, desis, gelembung, gosong)
docs/PANDUAN_PENGEMBANGAN.md  # panduan menambah level, soal, dan mengganti aset
docs/PIXEL_ART_STYLE.md       # kunci art style pixel 48 px (gaya baru)
docs/ART_STYLE.md             # gaya stickman lama (aset yang belum dimigrasi)
```

Pembagian tugas: **Flutter** untuk menu, dialog, dan HUD; **Flame** hanya aktif saat gameplay (boss, time bar, efek). Aset dimuat per level dan dibersihkan saat level ditutup agar ringan di perangkat spesifikasi rendah.

## Panduan pengembangan

Lihat [`docs/PANDUAN_PENGEMBANGAN.md`](docs/PANDUAN_PENGEMBANGAN.md) untuk:

- menambah level baru,
- menambah atau mengubah soal,
- mengatur tingkat kesulitan,
- mengganti gambar dan suara dengan aset final,
- mengubah teks dan dialog.

## Aset dan lisensi

- Gambar dibuat sendiri lewat skrip. Menu utama dan storyboard sudah bergaya pixel art 48 px (`python tools/art/pixel_font.py` lalu `python tools/art/pixel_export.py`, aturan di [`docs/PIXEL_ART_STYLE.md`](docs/PIXEL_ART_STYLE.md)); boss, level, dan ikon masih gaya stickman lama (`tools/art/generate_art.py`, [`docs/ART_STYLE.md`](docs/ART_STYLE.md)) dan akan dimigrasi bertahap. Semua gambar bisa diganti art final dengan menimpa file bernama sama.
- Efek suara dan musik latar Level 1 dibuat sendiri secara sintetis lewat `tools/audio/generate_fight_audio.py`; tidak ada file audio dari pihak lain.
- Lisensi proyek: belum ditentukan.

## Performa

Efek berat sengaja dihindari agar tetap lancar di HP spesifikasi rendah: cahaya aba-aba dan obor memakai gradien yang dibuat sekali (bukan blur tiap frame), `Paint` dipakai ulang, dan aset gambar serta audio per level dibersihkan saat level ditutup. Jika masih terasa berat, uji dengan `flutter run --profile`.

## Rilis

Versi ada di `pubspec.yaml` (`version: nama+nomorBuild`). Untuk membuat APK:

```bash
flutter pub get
flutter analyze && flutter test
flutter build apk --release
```

APK ada di `build/app/outputs/flutter-apk/app-release.apk`. Buat tag (`git tag v1.1.0 && git push --tags`) lalu unggah APK ke halaman Releases. Workflow `.github/workflows/release.yml` membuat APK otomatis dan melampirkannya ke Release saat tag `v*` di-push.
