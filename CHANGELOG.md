# Riwayat Perubahan

Format versi mengikuti `pubspec.yaml` (`nama+nomorBuild`). Tag rilis: `v<nama>`.

## [1.4.0] - 2026-11-08

### Tampilan
- **Seluruh game kini bergaya pixel art 48 px**: menu utama, storyboard, pilih level, intro boss, jeda dan hasil, HUD Level 2 sampai 4, ikon aplikasi, dan Level 1.
- Font piksel `PixelChampion` (huruf besar) dan komponen UI bersama (bingkai, tombol, bintang, gembok, hati, bar progres).
- Boss Bob, Asep, dan Chef punya empat ekspresi (diam, kaget, tertawa, kalah) dalam gaya baru.
- Aset Level 4 (16 ikon bahan, 3 stasiun masak, latar dapur) bergaya piksel.
- Level 1: sprite pemain dan Rock per pose (21 bingkai), arena Colosseum piksel, obor, percikan, pisau, bar HP berblok, tombol kontrol dengan ikon piksel.
- Ikon aplikasi baru (wajah pemain di depan sinar matahari).

### Teknis
- Logika dan waktu pertarungan tidak berubah; hanya tampilan yang memakai sprite per bingkai (`PoseClip.sampleStepped`, `FighterBody.frameIndex`).
- Generator aset piksel di `tools/art/` (`pixel_all.py`); generator stickman lama dihapus.
- Panduan gaya terkunci di `docs/PIXEL_ART_STYLE.md`.
- Workflow rilis memeriksa versi `pubspec.yaml` sama dengan tag, menamai APK dengan versi, dan memakai catatan dari bagian ini.

## [1.3.0]

- Level 4 Cooking Champion: pesanan acak, geser bahan ke Talenan, Panci, atau Wajan, cooking check (ketuk, jaga suhu, jarum emas), penalti dan bonus waktu.

## [1.2.0]

- Level 3 Asep the Mazelogist: labirin acak tiga ukuran, tombol arah, batas waktu.

## [1.1.0]

- Level 1 dilengkapi efek suara, musik latar, getar, dan slow-motion KO.
- Optimasi performa efek dan workflow rilis APK otomatis di GitHub.

## [1.0.0]

- Rilis awal: menu, cerita, pilih level, Level 1 (tempur) dan Level 2 (kuis Bob the Genius).
