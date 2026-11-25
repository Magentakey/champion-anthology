# Champion Anthology — *The World in My Hands!*

Game mobile (Android) bergenre **minigame anthology dengan alur cerita**. Karakter utama menantang para juara di berbagai bidang untuk merebut gelar juara utama. Dibuat dengan **Flutter** (UI, cerita, navigasi) dan **Flame Engine** (gameplay 2D).

## Status

| Level | Boss | Status |
|---|---|---|
| 1 | Rock the Fighter (pertarungan, 3 fase menurut batas HP) | Selesai, bisa dimainkan (tempur, 3 fase, AI Rock, efek, suara, musik, getar) |
| 2 | Bob the Genius (kuis pengetahuan) | Selesai, bisa dimainkan |
| 3 | Asep the Mazelogist (labirin, tombol arah, batas waktu) | Selesai, bisa dimainkan |
| 4 | Cooking Champion (geser bahan ke stasiun masak, cooking check, batas waktu) | Selesai, bisa dimainkan |
| 5 | Bima the Shooter (panahan: tarik busur, bidik, angin, papan bergerak) | Selesai, bisa dimainkan |
| 6 | Mr. Lexi the Gambler (tiga permainan peluang pasar malam: tebak kartu 75%, lempar koin 50%, cangkir tebak bola 25%) | Selesai, bisa dimainkan (belum dirilis) |

Versi terbaru: **1.7.0** (seluruh game bergaya pixel art 48 px). Riwayat perubahan ada di [`CHANGELOG.md`](CHANGELOG.md).

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

- **Level 1 (Rock the Fighter)** dimainkan landscape: tombol gerak kiri/kanan, pukul, tendang, tangkis, dan lempar pisau. Rock punya 3 fase menurut batas HP-nya, dan tiap fase yang kamu menangkan memberi 1 bintang. Ketuk pukul beruntun untuk combo pukul, silang, uppercut; pukul, silang, lalu tendang untuk tendangan putar; tendang dua kali untuk tendangan tinggi. Tahan tombol pukul lalu lepas untuk serangan tenaga (makin lama makin kuat, rentan selama mengisi). Saat Rock memberi aba-aba merah, siapkan tangkisan atau menghindar. (Papan ketik untuk uji di emulator: A/D gerak, J pukul, K tendang, I pisau, L atau S tangkis.)
- **Level 3 (Asep the Mazelogist)**: temukan jalan dari titik start (hijau, kiri atas) ke bintang emas (kanan bawah) memakai tombol arah di layar. Tahan tombol untuk jalan terus, ketuk untuk satu langkah. Tiap step hanya berbeda ukuran labirin dan batas waktu (Step 1 kecil, Step 3 besar); waktu habis berarti kalah. (Papan ketik untuk uji di emulator: panah atau WASD.)
- **Level 4 (Cooking Champion)**: tiap step ada satu pesanan masakan acak. Geser bahan dari baki ke stasiun yang tepat: **Talenan** (iris: ketuk terus sampai bar penuh), **Panci** (rebus: tahan tombol api untuk naik suhu, lepas untuk turun, jaga di zona hijau), **Wajan** (goreng: ketuk saat jarum di zona emas). Bahan di luar pesanan atau salah stasiun mengurangi 3 detik, cooking check yang gagal mengurangi 4 detik, check yang mulus menambah 1 detik. Semua bahan selesai sebelum waktu habis = menang. Step 1 sampai 3 beda jumlah bahan, pengecoh, dan ketatnya check.
- **Level 5 (Bima the Shooter)**: tahan tombol TARIK untuk menarik busur sampai penuh (meter hijau), lalu lepas saat bidikan tepat di tengah papan. Bidikan terus bergoyang dan makin gemetar kalau ditahan lama setelah penuh; bidikan berwarna kuning = kena emas (10). Skor dari tengah ke tepi: 10, 8, 6, 4, 2. Capai skor target sebelum anak panah habis. Step 1 papan diam, Step 2 ada angin (mendorong bidikan), Step 3 angin kencang dan papan bergerak. Tiap tembakan dibatasi 9 detik. (Papan ketik untuk uji di emulator: spasi tahan = tarik, lepas = tembak.)
- **Level 6 (Mr. Lexi the Gambler)**: tiga permainan murni peluang di stan pasar malam, tanpa uang sungguhan (hanya chip bohongan). Step 1 **Tebak Kartu** (4 kartu, 1 kartu sial, peluang menang 75%), Step 2 **Lempar Koin** (pilih kepala atau ekor, 50%), Step 3 **Cangkir Tebak Bola** (bola disembunyikan lalu cangkir diacak, 25%). Pilih, lalu tekan BUKA atau LEMPAR. Peluang selalu tampil di layar dan tidak pernah berubah: tidak ada bonus setelah kalah dan tidak ada kesulitan dinamis. Hasil ditentukan sebelum kamu memilih; animasi hanya hiasan. Menang ketiganya berturut-turut = 3 bintang (sekitar 9,4%), kalah mengakhiri sesi. (Papan ketik untuk uji di emulator: angka 1 sampai 4 memilih, spasi atau Enter mengonfirmasi.)
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
│   ├── fight/                # Level 1: arena piksel, sprite petarung per pose, klip animasi
│   └── genius/               # Level 2: game, HUD, konfigurasi, soal, dialog
├── screens/                  # menu, storyboard, pilih level, intro boss, gameplay
└── shared/widgets/           # StarRow, overlay jeda/hasil, efek getar
assets/
├── images/home/              # latar menu piksel (home_bg.png) dan tombol (btn_*.png)
├── images/ui/                # latar malam untuk pilih level dan intro boss (bg_night.png)
├── images/genius/            # ekspresi Bob (boss_*.png)
├── images/maze/              # ekspresi Asep (boss_*.png)
├── images/cooking/           # chef, ikon bahan, stasiun, latar dapur
├── images/archery/           # Bima (4 ekspresi) dan latar lapangan panahan
├── images/gambler/           # Mr. Lexi (4 ekspresi), latar stan, kartu, koin, cangkir, bola, chip
├── images/story/             # panel storyboard piksel (panel_*.png)
├── fonts/                    # PixelChampion.ttf (font piksel 5x7, huruf besar)
├── data/genius_questions.json
├── audio/                    # SFX dan BGM (.wav)
└── icon/                     # ikon aplikasi
test/                         # unit dan widget test
tools/art/pixel_*.py          # generator semua aset gambar bergaya piksel (jalankan pixel_all.py)
tools/audio/generate_fight_audio.py  # generator SFX dan BGM Level 1 (butuh numpy)
tools/audio/generate_cooking_audio.py  # generator SFX Level 4 (potong, desis, gelembung, gosong)
tools/audio/generate_archery_audio.py  # generator SFX Level 5 (tarik busur, lepas, tancap, kena emas)
tools/audio/generate_gambler_audio.py  # generator SFX Level 6 (balik kartu, lempar koin, geser cangkir, menang, kalah)
docs/PANDUAN_PENGEMBANGAN.md  # panduan menambah level, soal, dan mengganti aset
docs/PIXEL_ART_STYLE.md       # kunci art style pixel 48 px
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

- Semua gambar dibuat sendiri lewat skrip bergaya pixel art 48 px (`python tools/art/pixel_all.py`, aturan di [`docs/PIXEL_ART_STYLE.md`](docs/PIXEL_ART_STYLE.md)) dan bisa diganti art final dengan menimpa file bernama sama.
- Efek suara dan musik latar Level 1 dibuat sendiri secara sintetis lewat `tools/audio/generate_fight_audio.py`; tidak ada file audio dari pihak lain.
- Lisensi proyek: belum ditentukan.

## Performa

Efek berat sengaja dihindari agar tetap lancar di HP spesifikasi rendah: seluruh gambar piksel digambar tanpa antialiasing dan tanpa blur, cahaya aba-aba dan obor memakai cincin berpita (bukan gradasi tiap frame), `Paint` dipakai ulang, dan aset gambar serta audio per level dibersihkan saat level ditutup. Jika masih terasa berat, uji dengan `flutter run --profile`.

## Rilis

Langkah lengkap ada di [`docs/RILIS.md`](docs/RILIS.md). Ringkasnya:

1. Naikkan `version:` di `pubspec.yaml` (`nama+nomorBuild`, mis. `1.4.0+5`) dan tambah bagian baru di `CHANGELOG.md`.
2. Pastikan `flutter analyze` dan `flutter test` bersih.
3. Commit, lalu buat tag yang **sama dengan versi**: `git tag v1.4.0 && git push --tags`.
4. Workflow `.github/workflows/release.yml` membangun APK, menamainya `champion-anthology-v1.4.0.apk`, dan melampirkannya ke halaman Releases dengan catatan dari `CHANGELOG.md`.

Build manual: `flutter build apk --release` (hasil di `build/app/outputs/flutter-apk/app-release.apk`).
