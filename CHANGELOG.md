# Riwayat Perubahan

Format versi mengikuti `pubspec.yaml` (`nama+nomorBuild`). Tag rilis: `v<nama>`.

## [1.8.0] - 2026-11-26

### Ditambahkan
- Level 7: Rhea the Drummer, game ritme empat jalur dengan tiga lagu tetap (Warm-up Groove 90 BPM, Street Beat 110 BPM, Final Encore 128 BPM) yang selalu sama dan bisa dilatih.
- Not jatuh 1,4 detik menuju garis ketuk. Empat pad menerima sentuhan serentak (multi-sentuh); papan ketik untuk uji di emulator: D F J K.
- Penilaian: PERFECT (selisih paling jauh 50 ms) bernilai 1, GOOD (paling jauh 110 ms) bernilai 0,5, MISS (lewat 130 ms) bernilai 0. Akurasi = jumlah nilai dibagi jumlah not. Ketukan yang tidak cocok dengan not mana pun diabaikan; satu ketukan hanya untuk satu not.
- Target akurasi lulus 60%, 70%, 78% (32, 48, 72 not; 0, 6, 12 pasangan bersamaan). Begitu target mustahil dicapai lagi, step langsung gagal tanpa menunggu lagu habis. Menang tiga step = 3 bintang.
- Combo hanya hiasan (komentar Rhea dan tampilan), tidak memengaruhi skor. Tanpa kemampuan tambahan dan tanpa kesulitan dinamis.
- Layar jeda punya pengatur offset suara (-150 sampai +150 ms, langkah 10 ms) yang tersimpan di perangkat. Setelah jeda, lagu dilanjutkan lewat hitung mundur 3 ketukan.
- Karakter Rhea (4 ekspresi), panggung, not, pad dua bingkai, dan garis ketuk lewat `tools/art/pixel_rhythm.py`; tiga lagu dan empat efek suara lewat `tools/audio/generate_rhythm_audio.py` (butuh numpy).
- Kunci level: terbuka setelah Mr. Lexi the Gambler mendapat minimal 1 bintang.

### Catatan penafsiran rancangan
- Jendela cocok 110 ms dan batas MISS 130 ms dipakai bersamaan: ketukan lebih dari 110 ms dari not terdekat di jalurnya diabaikan, dan not baru ditandai MISS setelah lewat 130 ms.
- Step 1 membatasi lompatan antar jalur paling jauh 2 supaya mudah dibaca.
- Akurasi sementara (dari not yang sudah dinilai) tampil di layar bersama garis ambang. Mengetuk asal tetap gagal di Step 1 (diuji), tetapi pemain yang menekan semua pad terus-menerus belum dibatasi khusus.

### Teknis
- Logika murni dan terpisah dari Flame: `rhythm_chart.dart` (pembuat lagu dengan seed tetap dan aturan), `rhythm_judge.dart` (penilai, satuan 0,1 ms agar batas tepat), `rhythm_run.dart` (mesin tahap dan pelaporan sesi), `rhythm_calibration.dart` (offset tersimpan), konstanta di `rhythm_config.dart`.
- Tes baru di `test/levels/rhythm/`: konstanta (termasuk angka desimal di sumber), batas jendela 50/110/130 ms, satu ketukan satu not, akurasi dan ambang, gagal dini, aturan lagu untuk ratusan seed, determinisme, pemain simulasi (galat 45, 60, 80 ms dan pengetuk asal), alur tahap dan sesi (3, 2, 1 bintang), jeda dan lanjut, kalibrasi, HUD, empat pad serentak, panel offset, dialog, tata letak, dan aset. `test/app/app_flow_test.dart`, `test/core/progress_test.dart`, dan `test/core/audio_assets_test.dart` disesuaikan untuk level ke-7.
- Kait baru di inti: `LevelGame.buildPauseExtras`, parameter `extra` pada `PauseOverlay`, dan baris `note` pada `StepBannerCard`.
- `pixel_kit.py` mendapat spesifikasi Rhea dan `pixel_bosses.py` memuatnya; boss lain tidak berubah. Berkas kosong `lib/levels/fight/1` dihapus.

## [1.7.0] - 2026-11-26

### Ditambahkan
- Level 6: Mr. Lexi the Gambler, tiga permainan peluang bertema pasar malam dengan chip bohongan (tanpa uang sungguhan).
- Step 1 Tebak Kartu (4 kartu, 1 kartu sial, peluang menang 75%), Step 2 Lempar Koin (kepala atau ekor, 50%), Step 3 Cangkir Tebak Bola (bola diacak di bawah 4 cangkir, 25%).
- Peluang tetap dan selalu tampil di layar: tidak ada bonus setelah kalah, tidak ada kesulitan dinamis, dan tidak ada riwayat yang dibaca. Menang tiga step berturut-turut memberi 3 bintang (peluang 9,4%), kalah di satu step mengakhiri sesi.
- Hasil ditentukan sebelum pemain memilih; animasi balik kartu, lemparan koin, dan acakan cangkir hanya hiasan. Pengacak diberikan dari luar sehingga bisa diuji dengan seed tetap.
- Karakter Mr. Lexi (topi tinggi, empat ekspresi), latar stan pasar malam, kartu (punggung, aman, sial), koin (kepala, ekor, putar), cangkir, bola, dan chip, semua dibuat lewat `tools/art/pixel_gambler.py`.
- Lima efek suara baru: balik kartu, lempar koin, geser cangkir, nada menang, dan dengung kalah (`tools/audio/generate_gambler_audio.py`).
- Akhir acakan cangkir: keempat cangkir menyatu jadi satu tumpukan di tengah (tak mungkin dilacak lagi), ditahan sebentar, lalu dijajarkan kembali dengan urutan diacak (bola tidak kembali ke posisi semula), sehingga ronde ini murni peluang.
- Istilah "Step" di Level 6 diganti "Round" (Round 1 sampai 3) dan pilihan KEPALA/EKOR baru muncul setelah banner ronde hilang.
- Kunci level: terbuka setelah Bima the Shooter mendapat minimal 1 bintang.
- Papan ketik untuk uji di emulator: angka 1 sampai 4 memilih, spasi atau Enter mengonfirmasi.

### Teknis
- Logika peluang murni di `luck_round.dart` (`CardRound`, `CoinRound`, `CupRound`, `CupShuffle`, `GamblerRun`) dan konstanta di `gambler_config.dart`, terpisah dari Flame supaya mudah dites.
- Tes baru di `test/levels/gambler/`: konstanta peluang, frekuensi 10.000 putaran per permainan, pemerataan posisi, tanpa bonus kekalahan, penempatan lebih dulu, pelaporan sesi (3, 2, 1, dan 0 bintang), registri, label peluang di HUD, tata letak meja, animasi, dan aset. `test/app/app_flow_test.dart` dan `test/core/progress_test.dart` disesuaikan untuk level ke-6.
- `pixel_kit.py` mendapat topi tinggi (`hat='tophat'`) dan `pixel_bosses.py` memuat Mr. Lexi; boss lain tidak berubah.

## [1.6.0] - 2026-11-25

### Ditambahkan
- Level 1: combo lebih variatif. Pukul, silang, lalu penutup kini berupa uppercut sungguhan (jongkok, melompat, tinju naik) dan bukan jab yang diulang.
- Pukul, silang, lalu tendang: tendangan yang ditekan setelah silang menjadi tendangan putar penutup yang menyambung langsung dan melempar lawan.
- Tendang + tendang: tendangan kedua yang ditekan di pemulihan atau jendela combo menjadi tendangan tinggi (9 damage, dorong 300, melempar lawan).
- Serangan tenaga: tahan tombol pukul (J di papan ketik) untuk menarik tinju dengan aura emas dan bar isi, lalu lepas. Isi minimal 0,5 detik (14 damage), penuh 1 detik (22 damage, gerak lambat singkat). Ayunannya sama dengan hantaman berat Rock dan berarmor, tetapi pemain rentan selama mengisi; terkena saat mengisi membatalkan isi.
- Reaksi Rock berbeda per pukulan: kepala tersentak (jab), tubuh terpukul (silang), dan terlempar (penutup, tendangan penutup, serangan berat).
- Rock punya animasi sendiri untuk Tendangan Putar dan pukulan terjang, lengkap dengan pose aba-abanya.
- Efek per pukulan: hit-stop, getar layar, dan percikan makin besar seiring combo; penutup combo diberi gerak lambat singkat, suara baru (`finisher.wav`), dan debu di kaki lawan.
- Hitungan combo di layar (x2 COMBO, x3 COMBO!) yang direset bila tidak mengenai selama 1,2 detik atau saat pemain terkena.
- 12 pose baru (total 33 bingkai): uppercut (3), reaksi ringan dan terhuyung, Tendangan Putar (2), terjang (2), tendangan tinggi, napas diam ketiga, dan langkah jalan keempat.

### Diubah
- Pinggul dan kaki petarung digambar ulang di seluruh pose: celana pendek selebar baju dengan sisi lurus sampai sekitar paha tengah, dua sendi pinggul terpisah, kaki keluar dari sudut bawah.
- Jalan kini 5 bingkai dan diam bernapas lewat 3 bingkai, lebih halus.
- Tombol pukul kini dijalankan saat dilepas (ketuk singkat di bawah 0,2 detik = pukulan biasa) agar bisa dibedakan dari tahan; batas ada di `chargeTapMs`.
- Angka pertarungan (damage, dorongan, lama terhenti, jendela waktu serangan) tidak berubah; klip baru memakai waktu yang sama dengan klip yang digantikan, dan uppercut mendapat maju 30 satuan agar jangkauan efektifnya sama.

### Diperbaiki
- Piksel kepala pada beberapa pose bolong atau bergaris karena pembulatan `round()` Python (.5 dibulatkan ke genap); kini dibulatkan tetap.

### Teknis
- Pose baru ditambahkan lewat `tools/art/fight_poses.py` lalu `pose_library.dart` dan lembar sprite dibuat ulang (`tools/art/pixel_fighters.py`); `finisher.wav` memakai generator acak sendiri sehingga SFX lain tidak berubah.
- Logika rasa pukulan dipisah ke `hit_feel.dart` dan logika ketuk atau tahan ke `punch_input.dart` agar bisa diuji; tes baru di `test/levels/fight/combo_test.dart`.

## [1.5.0] - 2026-11-25

### Ditambahkan
- Level 5: Bima the Shooter (panahan). Tahan tombol TARIK sampai meter penuh, lalu lepas untuk menembak.
- Bidikan yang terus bergoyang dan makin gemetar jika ditahan terlalu lama, dengan indikator kuning saat akan kena emas.
- Skor cincin 10, 8, 6, 4, 2 dengan batas 9 detik per tembakan.
- Tiga step kesulitan: Mudah (6 panah, target 44), Sedang (7 panah, target 46, angin), Sulit (8 panah, target 50, angin kencang dan papan bergerak).
- Karakter Bima dengan empat ekspresi, latar lapangan panahan, HUD piksel, penunjuk angin, dan dialog.
- Empat efek suara baru: tarik busur, lepas, tancap, dan kena emas.
- Kunci level: terbuka setelah Cooking Champion mendapat minimal 1 bintang.
- Tes untuk skor cincin, fisika tembakan, simulasi bot, dialog, dan aset.
- Panduan tuning di PANDUAN_PENGEMBANGAN.md dan bagian 16 di PIXEL_ART_STYLE.md.

### Diubah
- Registry level kini berisi 5 level; tes progres dan tes alur disesuaikan.

### Diperbaiki
- Layar error merah sesaat saat Level 5 dimulai, diulang ("Main lagi"), atau di-restart: HUD membaca konfigurasi step sebelum game selesai dimuat (`LateInitializationError` pada `ArcheryGame._config`).
- Menghapus import `dart:ui` yang tidak perlu di `archery_test.dart`.

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
