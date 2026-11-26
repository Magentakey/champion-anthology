# Kunci Art Style: Pixel Art 48 px

> **Status: TERKUNCI.** Semua aset visual baru mengikuti dokumen ini. Mengubah aturan di sini harus disengaja
> dan diikuti pembuatan ulang semua aset yang terdampak. Seluruh game (menu, cerita, empat level, ikon)
> kini memakai gaya ini; gaya stickman lama sudah dihapus.
>
> Sumber kebenaran angka dan bentuk: `tools/art/pixel_kit.py` (karakter, warna, pose, wajah) dan
> `tools/art/pixel_scenes.py` (font, latar, adegan, UI). Jika dokumen dan kode berbeda, kode yang benar;
> perbarui dokumen.

## 1. Prinsip

1. **Piksel keras.** Semua gambar dibuat di kisi kecil tanpa antialiasing, lalu diperbesar dengan *nearest neighbour* pada kelipatan bilangan bulat. Tidak ada gradasi halus, blur, atau rotasi sprite.
2. **Chibi kepala besar.** Kepala sekitar setengah tinggi tubuh; wajah ekspresif dengan mata besar berkilau.
3. **Garis tepi gelap 1 piksel di semua bentuk**, termasuk batas antar bagian tubuh (rambut/kepala, lengan/badan, dst.).
4. **Warna datar tiga nada** per bahan (dasar, terang, gelap), cahaya dari **kiri atas**.
5. **Satu karakter, satu ciri khas** yang terbaca dari siluet (ikat kepala, kacamata, topi koki, papan labirin, rambut kotak).
6. **Konsisten antar aset.** Karakter, latar, UI, dan teks memakai kisi dan palet yang sama.

## 2. Kanvas, skala, dan ukuran

| Hal | Aturan |
|---|---|
| Tinggi sprite karakter | **48 px** (dari ujung rambut sampai sol sepatu sekitar 47 px) |
| Titik tumpu sprite | tengah sela kaki, di dasar sol (koordinat karakter x=24, y=47) |
| Kanvas kerja sprite | 112×112 px dengan margin untuk rambut, topi, bola, dan lengan terangkat |
| Skala tampil | **1×** (default), **2×** hanya untuk karakter utama di home dan close-up panel cerita |
| Memperbesar ke layar | integer saja (mockup memakai 3×). Jangan skala pecahan |
| Mencampur skala dalam satu adegan | boleh untuk karakter utama 2× di atas latar 1×; tidak boleh ada tepi miring atau antialiasing |
| Kisi layar penuh (mockup) | 240×426 logis → 720×1278 px |
| Menampilkan di Flutter | pakai `FilterQuality.none` dan `isAntiAlias: false` saat menampilkan PNG piksel |

## 3. Proporsi karakter (S = 48)

Semua nilai relatif terhadap S = 48; `cx = 24`.

| Bagian | Nilai |
|---|---|
| Kepala | pusat y = 0,36·S (≈17), radius x = 0,27·S (≈13), radius y = 0,245·S (≈12) |
| Garis rambut | 0,58·radius-y di atas pusat kepala |
| Ikat kepala | dari 0,58 sampai 0,36·radius-y di atas pusat; melengkung ke bawah di tengah; ekor melambai di sisi kanan, digambar **di belakang** kepala |
| Badan (kaos) | y 0,50–0,70·S, setengah lebar 0,125·S (Chef 0,15·S, Rock 0,16·S) |
| Celana pendek | y 0,66–0,775·S, setengah lebar 0,145·S |
| Celana panjang | blok pinggul y 0,66–0,80·S (bukan tabung panjang); kaki yang terlihat tetap pendek |
| Kaki | dari y 0,74·S sampai ≈0,895·S |
| Sepatu | elips 0,075·S × 0,05·S + sol putih 2 px |
| Lebar kepala | ±26 px (jangan melebihi, atau karakter jadi tidak muat di panel) |

Aturan proporsi tambahan: kaki yang terlihat harus **pendek** (kaki tinggi dianggap salah; lihat koreksi Bob),
dan lengan **tidak merentang jauh**; pose angkat bola dunia menaruh bola tepat di atas kepala.

## 4. Palet

Setiap bahan punya tiga nada: **dasar / terang (tepi kiri-atas) / gelap (tepi kanan-bawah)**.
Bahan baru dibuat dengan `pal((r,g,b))` di `pixel_kit.py` (terang ×1,28, gelap ×0,68).

| Bahan | Dasar | Terang | Gelap |
|---|---|---|---|
| Kulit | `#FFD6AA` | `#FFEED0` | `#DE9C76` |
| Rambut gelap (pemain) | `#362E4A` | `#68608C` | `#221C32` |
| Merah (ikat kepala, sepatu, garis) | `#E23636` | `#FF7C68` | `#961C2C` |
| Putih (kaos, sol, gigi) | `#F2F6FC` | `#FFFFFF` | `#AAB8D4` |
| Navy (celana pemain) | `#384C94` | `#5C76BE` | `#223064` |
| Cokelat (sepatu Asep) | `#784E34` | `#AA7654` | `#503226` |
| Oranye (sabuk Rock) | `#F08C1E` | `#FFB326` | `#A35F14` |
| Hijau (kaus Asep) | `#4CA05A` | `#61CC73` | `#336C3D` |
| Biru (dasi Bob) | `#2864C8` | `#3380FF` | `#1B4488` |
| Abu-abu | `#787C8C` | `#999EB3` | `#51545F` |
| Abu gelap (celana Bob) | `#3A3C48` | `#4A4C5C` | `#272830` |
| Hitam kebiruan (sepatu, Rock) | `#282834` | `#333342` | `#1B1B23` |
| Khaki (celana Asep) | `#C4A870` | `#FAD78F` | `#85724C` |
| Rambut cokelat (Asep) | `#6E4630` | `#8C593D` | `#4A2F20` |
| Emas | `#FFC828` | `#FFFF33` | `#AD881B` |
| Krem | `#FFF4D6` | `#FFFFFF` | `#ADA591` |

Warna tunggal:

| Fungsi | Warna |
|---|---|
| Garis tepi (OUT) | `#181222` |
| Iris mata | `#5C3828` |
| Pupil / kelopak | `#160E18` |
| Dalam mulut | `#801A2C` |
| Lidah | `#F47680` |
| Pipi merona | `#FF968C` |
| Kilau mata | `#FFFFFF` |
| Lensa kacamata | `#CEE8FF` |

Larangan warna: tidak ada hitam murni `#000000` untuk garis (pakai garis tepi di atas), tidak ada warna di luar palet bahan
tanpa menambahkannya ke dokumen ini terlebih dahulu.

## 5. Teknik menggambar

**Bentuk berisi.** Tiap bagian = himpunan piksel (elips, persegi, poligon, atau "selang" dengan ujung bulat), digambar dari belakang ke depan.

**Bayangan (3 nada).**
- piksel tepi atas atau kiri bagian → warna *terang*
- piksel tepi bawah atau kanan bagian → warna *gelap*
- sisanya → dasar
- bagian kecil (kurang dari 15 piksel) tidak diberi bayangan

**Garis tepi.** Setelah bagian terisi, tiap piksel tetangga (4 arah) di luar bagian diberi warna garis tepi. Karena digambar belakang ke depan, garis bagian depan otomatis menjadi garis dalam di atas bagian belakang.

**Urutan menggambar karakter:** ekor ikat kepala → kaki dan sepatu → celana → badan → aksesori leher → lengan dan tangan → kepala → rambut/topi → ikat kepala → wajah → bola (jika pose bola dunia) → tangan digambar ulang di atas bola.

**Tanpa antialiasing, tanpa transparansi sebagian.** Piksel hanya penuh atau kosong (kecuali bayangan tanah, lihat bagian 8).

## 6. Wajah (pola piksel buatan tangan)

Wajah **tidak** dibuat prosedural. Tiap ekspresi adalah pola teks yang ditempel pada kepala (kunci: `O` garis, `e` iris,
`p` pupil, `y` kilau, `k` dalam mulut, `w` gigi, `t` lidah, `l` lensa, `.` kosong). Mata kiri di x=14, mata kanan di x=28 (atau cermin), y=16; mulut di y=24, tengah di x=24.

Ekspresi baku:

| Ekspresi | Dipakai | Ciri |
|---|---|---|
| `hype` | Pemain | mata besar 6×7 dengan dua kilau, sudut luar kelopak naik 1 px, mulut berteriak lebar, pipi merona |
| `smug` | Bob | kacamata bulat berlensa biru muda, kelopak setengah turun, senyum miring |
| `cheer` | Chef | mata menutup bahagia (busur), senyum lebar, pipi merona |
| `calm` | Asep | mata kecil 4×5, senyum tipis |
| `angry` | Rock | alis tebal menukik, mata kecil putih, gigi mengatup |

Ekspresi boss di game (idle, kaget, tertawa, kalah) memakai wajah yang sama dengan variasi: kaget = mata dan mulut membulat, tertawa = mata menutup + mulut terbuka lebar, kalah = mata silang + mulut bergelombang.

## 7. Karakter

| Karakter | Rambut / topi | Pakaian | Wajah | Ciri khas |
|---|---|---|---|---|
| Pemain | jabrik navy gelap | kaos putih garis merah, celana pendek navy, sepatu merah-putih | hype | ikat kepala merah dengan ekor melambai |
| Bob | jabrik hitam tinggi (6 duri) | kemeja putih + rompi biru keabuan, celana panjang abu gelap, sepatu hitam | smug | kacamata bulat, dasi kupu-kupu biru |
| Asep | menyapu cokelat (jambul ke kanan) | kaus hijau, celana khaki, sepatu cokelat | calm | papan labirin di dada |
| Chef | topi koki putih bertingkat | celemek putih, syal merah, celana gelap | cheer | topi koki, badan lebih lebar |
| Bima | topi pemanah hijau berbulu merah (tanpa rambut terlihat) | tunik hijau, celana khaki, sabuk dan sepatu cokelat, kulit sawo `#E2B280` | fighter | busur kayu (dipegang saat diam, tergeletak saat bereaksi) |
| Rock | rambut kotak abu-abu | tank top hitam, sabuk oranye, celana hitam | angry | kepalan berperban putih, bekas luka di pipi |

Tokoh baru: pilih **satu ciri khas** yang terbaca di siluet, kembangkan dari spesifikasi di `pixel_kit.py`
(`HERO`, `BOB`, `ASEP`, `CHEF`, `ROCK`).

### Pose (koordinat relatif terhadap S, x dari pusat)

`stand_fist`, `stand`, `cheer`, `run`, `reach`, `globe_up`, `cross`, `fight`, `board`; kaki: `stand`, `stride`, `wide`.
Definisi lengkap ada di kamus `poses` pada `pixel_kit.py`.

**Pose bola dunia (`globe_up`).** Bola (jari-jari 8 px) bertumpu **tepat di atas kepala** (pusat y = -4), menutupi ujung rambut.
Lengan hanya melengkung pendek di samping kepala; kedua tangan memegang sisi bola dan digambar di atas bola.
Bola adalah bagian dari sprite, bukan elemen terpisah.

## 8. Latar dan adegan

- **Langit:** pita warna vertikal 5 sampai 7 nada dengan **dithering papan catur 2 baris** pada batas antar pita. Tanpa gradasi halus.
- **Awan:** gabungan elips putih (atau warna senja), satu baris bayangan di bawah.
- **Bintang/kilau:** bentuk plus 5 piksel (`star4`) dan titik tunggal.
- **Tanah:** garis atas bergaris tepi gelap + satu baris terang di bawahnya; pola garis putus untuk detail.
- **Bayangan karakter:** elips rata 2 baris di bawah kaki dengan warna lebih gelap dari tanah (bukan transparan).
- **Sinar matahari (panel):** sektor sudut bergantian dua warna oranye; pusat di wajah/subjek.
- **Barang pendukung:** bola dunia (biru, benua hijau, kilau), piala emas, podium abu terang dengan angka, papan labirin putih.
- **Bingkai panel cerita:** pinggiran krem 1 px, garis dalam gelap 1 px, kotak keterangan krem dengan teks gelap di bawah panel.

Palet langit bawaan:

- Siang (panel 1): `#265CB0 #3E7ACC #629EE2 #8CC0F4 #B8DEFA`
- Senja (home): `#1E1C56 #342870 #583686 #8C448C #CC5A80 #F47E70 #FFB06C`

## 9. Teks dan UI

**Font:** bitmap **5×7**, huruf besar saja, jarak antarhuruf 1 piksel (lebar per huruf = 6·skala). Definisi di `GLYPH` pada `pixel_scenes.py`.

| Penggunaan | Skala | Warna | Tepi / bayangan |
|---|---|---|---|
| Judul baris 1 ("THE WORLD IN") | 2× | krem `#FFF4D6` | tepi gelap `#1A142C` + bayangan ungu |
| Judul baris 2 ("MY HANDS!") | 3× | emas `#FFD640` | tepi merah gelap `#961E32` + bayangan gelap |
| Label tombol | 2× | krem | tepi garis tepi gelap |
| Keterangan panel, hint | 1× | gelap `#281E3C` di atas krem, atau krem di atas gelap | tidak ada |

Aturan teks: **tebal tepi sama dengan skala huruf** (tepi 2× setebal 2 piksel). Hanya huruf besar, angka, dan tanda baca dasar (`. , ! ? - >`).

**Tombol:** 104×26 logis; garis tepi gelap, isi dasar, pita terang 2 piksel di atas, pita gelap 3 piksel di bawah, bayangan jatuh 2 piksel ke kanan-bawah.
Utama (Main): merah `#E24038` / terang `#FF826C` / gelap `#A01E2C`. Sekunder (Keluar): biru `#3C68CC` / `#78A4F0` / `#223A8C`.

## 10. Layout layar rujukan

- **Home (240×426):** judul di atas, tombol di tengah-atas, pemain 2× memegang bola dunia di panggung bundar dengan matahari terbit di belakang, bukit dan tanah gelap di bawah, versi di dasar.
- **Pilih level (240×426):** latar malam `ui/bg_night.png`, "< Kembali" kiri atas, judul emas, grid 3×3 (kotak 64×64 berbingkai; terbuka = krem dengan angka 3×, terkunci = gelap dengan gembok), tiga bintang di atas tiap kotak.
- **Intro boss (240×426):** bingkai nama boss (huruf 2×, atau 1× jika nama lebih dari 16 huruf), potret boss 120×120, bingkai dialog krem, bingkai tips gelap, tombol Mulai.
- **Overlay jeda dan hasil:** latar gelap tanpa blur, satu bingkai pusat dengan judul (3× emas, atau 2× untuk "Kalah di Step N"), bintang, kutipan boss pada bingkai krem, dan tombol lebar bertumpuk.
- **Storyboard (240×426):** "Lewati >>" kanan atas; panel 1 lebar; panel 2 lebar (barisan master dan pemain); panel 3 dan 4 berdampingan; "Ketuk untuk lanjut" dan empat penanda halaman di bawah.

Ukuran panel cerita (logis → PNG 3×): panel 1 = 216×87 → 648×261; panel 2 = 216×100 → 648×300; panel 3 dan 4 = 106×137 → 318×411.

## 11. Cara membuat aset

```bash
python tools/art/pixel_all.py         # SEMUA aset sekaligus (font, menu, bos, Level 4, ikon, Level 1)
python tools/art/pixel_font.py        # font: assets/fonts/PixelChampion.ttf (butuh: pip install fonttools)
python tools/art/pixel_export.py      # aset game: home_bg, btn_* (+wide), ui/bg_night, panel_1..4 (diperbesar 3x) -> assets/images/
python tools/art/pixel_bosses.py      # boss Bob, Asep, Chef (4 ekspresi, 512x512, sprite 8x) -> assets/images/{genius,maze,cooking}/
python tools/art/pixel_cooking.py     # Level 4: 16 ikon bahan, 3 stasiun, latar dapur -> assets/images/cooking/
python tools/art/pixel_icon.py        # ikon aplikasi -> assets/icon/ (lalu: dart run flutter_launcher_icons)
python tools/art/pixel_scenes.py      # mockup penuh + lembar karakter -> docs/preview/ (tidak masuk game)
python tools/art/pixel_ui_mock.py     # perkiraan layar pilih level dan intro boss -> docs/preview/
python tools/art/pixel_hud_mock.py    # perkiraan HUD Level 1 sampai 4 -> docs/preview/
python tools/art/pixel_fighters.py    # Level 1: sprite pemain dan Rock per pose, potret HUD, bos Rock -> assets/images/fight/
python tools/art/pixel_arena.py       # Level 1: latar Colosseum -> assets/images/fight/arena.png
python tools/art/pixel_archery.py     # Level 5: latar lapangan panahan -> assets/images/archery/archery_bg.png
python tools/audio/generate_archery_audio.py   # Level 5: efek suara (butuh numpy)
python tools/art/pixel_gambler.py     # Level 6: latar stan, kartu, koin, cangkir, bola, chip -> assets/images/gambler/
python tools/audio/generate_gambler_audio.py   # Level 6: efek suara (butuh numpy)
python tools/art/pixel_rhythm.py      # Level 7: panggung, not, pad, garis ketuk -> assets/images/rhythm/
python tools/audio/generate_rhythm_audio.py    # Level 7: tiga lagu dan efek suara (butuh numpy)
python tools/art/fight_poses.py       # data pose -> lib/levels/fight/pose_library.dart (lalu jalankan pixel_fighters.py)
python tools/art/pixel_preview.py     # pratinjau pemain 32/48 px (eksperimen awal)
```

Aset baru dibuat dengan menambah spesifikasi karakter atau fungsi adegan, **bukan** dengan menggambar manual di luar generator,
supaya aturan di atas otomatis terpenuhi dan mudah diubah serempak.

### Memakai di Flutter

- Semua layar piksel memakai kisi rujukan **240×426 piksel logis**. `PixelUi.unit(context)` (di `lib/shared/widgets/pixel_ui.dart`) memberi ukuran 1 piksel logis dalam dp; seluruh layout dihitung dari unit ini.
- Teks: `PixelUi.text(u, scale: 1|2|3, outline: ..., shadow: ...)`. Font `PixelChampion` hanya punya huruf besar; huruf kecil tampil sebagai huruf besar, jadi teks di `strings.dart` tidak perlu diubah. `fontSize = 10 × skala × unit`. Tebal tepi = skala.
- Tombol: `PixelButton` (gambar `btn_primary` / `btn_secondary`, atau `wide: true` untuk `btn_wide_*` 160 piksel, + label teks, sehingga mudah diuji dan terbaca pembaca layar). Parameter `unit` mengganti ukuran piksel (dipakai overlay).
- Pola piksel dari teks ada di `pixel_pattern.dart`: `PixelPatterns` (bintang, gembok, hati, panah, centang, api, kepala pemain), `drawPixelPattern` (dipakai juga oleh komponen Flame labirin), `PixelIcon`, `PixelBar` (bar progres berblok), dan `PixelHeart`.
- Di Flame: `drawPixelTimeBar` (bar waktu berblok, dipakai semua level), `CoverBackground` (gambar latar cover tanpa penghalusan), dan `BossSprite`/komponen boss yang memakai `FilterQuality.none`. Level Bob dan Asep memakai latar `ui/bg_night.png`, Level Chef memakai latar dapur.
- Komponen lain di `pixel_ui.dart`: `PixelFrame` (bingkai krem + garis gelap + isi), `PixelStar` dan `StarRow` (bintang), `PixelLock` (gembok), `PixelTextButton` (mis. "< Kembali"), `PixelPauseButton` (tombol jeda).
- Layar portrait memakai `PixelUi.unit` (kisi 240×426). Overlay dan layar landscape memakai `PixelUi.overlayUnit` (sisi terpendek ÷ 240, dijepit 1,4 sampai 3) supaya tombol tetap besar.
- Pesan singkat (SnackBar) bergaya piksel lewat `snackBarTheme` di `theme.dart`.
- Gambar: selalu `filterQuality: FilterQuality.none`. Rasio gambar harus sama dengan kotaknya (panel cerita memakai `BoxFit.fill`).
- Home: latar `home_bg.png` (tanpa teks) dengan `BoxFit.cover` dan `Alignment.bottomCenter`; judul dan tombol berupa widget.
- Storyboard: panel di `_panelRects` (`storyboard_screen.dart`) pada kisi 240×426; ukuran PNG panel = ukuran kotak × 3.

## 12. Daftar periksa aset baru

- [ ] Kisi kecil, tanpa antialiasing, skala integer saja
- [ ] Semua bentuk punya garis tepi gelap 1 piksel
- [ ] Hanya warna dari palet (tiga nada per bahan)
- [ ] Bayangan dari kiri atas
- [ ] Karakter punya satu ciri khas terbaca di siluet; kepala tidak melebihi ±26 px
- [ ] Kaki pendek, lengan tidak merentang; bola dunia di atas kepala jika pose `globe_up`
- [ ] Wajah dari pola buatan tangan (bukan prosedural)
- [ ] Teks memakai font 5×7, tebal tepi = skala huruf
- [ ] Dilihat sebagai gambar utuh sebelum dipasang ke game

## 13. Yang dilarang

- Stickman garis tipis, garis berketebalan berbeda dalam satu sprite
- Antialiasing, blur, gradasi halus, skala pecahan
- Mencampur gaya lama (stickman) dan gaya baru dalam satu adegan setelah migrasi selesai
- Tokoh tanpa garis tepi, atau tanpa ciri khas
- Menambah warna di luar palet tanpa memperbarui dokumen ini

## 14. Status migrasi

| Aset | Status |
|---|---|
| Karakter Pemain, Bob, Asep, Chef, Rock (berdiri, 48 px) | Selesai (generator) |
| Font piksel `PixelChampion.ttf` dan widget `PixelUi` / `PixelButton` | Selesai |
| Menu utama (latar, judul, tombol) | **Terpasang di game** |
| Storyboard (4 panel, bingkai, keterangan, penanda halaman) | **Terpasang di game** |
| Gambar boss Bob, Asep, Chef (4 ekspresi: idle, kaget, tertawa, kalah) | **Terpasang (aset)** |
| Ikon bahan, stasiun, latar dapur, chef (Level 4) | **Terpasang (aset)** |
| Pilih level, intro boss, overlay jeda dan hasil, tombol jeda, bintang dan gembok | **Terpasang di game** |
| HUD Level 2 sampai 4 (kartu soal dan tombol jawaban Bob, tombol arah dan labirin Asep, kartu pesanan, stasiun, baki, dan panel cooking check Chef, bar waktu, gelembung, banner step) | **Terpasang di game** |
| Level 5 (Bima): boss 4 ekspresi, latar lapangan, papan sasaran piksel, bidikan, HUD, efek suara | **Terpasang di game** |
| Level 6 (Mr. Lexi): boss 4 ekspresi, latar stan pasar malam, kartu, koin, cangkir, bola, chip, HUD, efek suara | **Terpasang di game** |
| Level 7 (Rhea): boss 4 ekspresi, panggung, not, pad dua bingkai, garis ketuk, HUD, lagu, efek suara | **Terpasang di game (belum dirilis)** |
| Level 1 (Rock): sprite pemain dan Rock per pose, arena, obor, percikan, pisau, bar HP, tombol kontrol, potret | **Terpasang di game** |
| Ikon aplikasi (wajah pemain + sinar matahari; latar adaptif `#FFAA38`) | **Terpasang (aset)** |

### Ekspresi boss

Empat keadaan baku untuk boss: `idle` (pose dan wajah asli), `shock` (pose `surprise`, mata bulat putih, mulut "o", tetes keringat),
`laugh` (pose `hips`, mata menutup, air mata, mulut lebar), `defeat` (pose `stand`, mata X, mulut bergelombang, bintang pusing).
Aksesori khas tetap terlihat di semua ekspresi (kacamata Bob, topi koki Chef, papan labirin Asep jatuh ke lantai saat bereaksi).

## 15. Level 1 (pertarungan): sprite per pose

Animasi Level 1 memakai **sprite per bingkai**: satu gambar piksel untuk tiap pose, bukan stickman yang digambar dari sendi.
Logika tidak berubah: kamus pose (`pose_library.dart`, dihasilkan `fight_poses.py`) dan klip (`pose_clips.dart`) tetap menentukan
**waktu** fase serangan; hanya tampilannya yang diganti. `PoseClip.sampleStepped` memilih pose kunci yang ditampilkan (tanpa campuran),
`FighterBody.frameIndex` memberi nomor bingkai, dan `Fighter` menggambar bingkai itu dari lembar sprite.

| Hal | Aturan |
|---|---|
| Lembar sprite | `assets/images/fight/player_sheet.png` dan `rock_sheet.png`: 21 bingkai 96×96 berjajar mendatar, urutan = urutan pose di `pose_library.dart` |
| Titik tanah bingkai | (40, 68) piksel, tepat di bawah pinggul; pose menghadap kanan, game membalik saat menghadap kiri |
| Skala | 1 piksel sprite = 18 satuan ruang pose; Rock digambar 1,12× lebih besar |
| Pemetaan sendi stickman ke chibi | kaki dipendekkan ×0,60, badan ×0,50, lengan ×1,0, kepala besar 10,5 piksel di atas leher (nilai `LEG`, `TORSO`, `ARM`, `HEAD_RISE` di `pixel_fighters.py`) |
| Wajah per pose | pemain: diam/tangkis `fighter`, serang/ejek `hype`, terkena `shock`, KO `defeat`, menang `laugh`. Rock: diam/tangkis `angry`, serang/ejek `angry_shout`, lalu sama. Kepala dicerminkan agar ekor ikat kepala di belakang; pose rebah memutar kepala 90° |
| Pemain | kaus putih garis merah, celana pendek navy, sepatu merah, lengan dan kaki kulit |
| Rock | kulit lebih gelap `#D6A076`, tank top hitam, sabuk oranye, celana abu gelap, sepatu hitam, kepalan berperban putih, bekas luka |
| Arena | `arena.png` 1600×720 (kisi 400×180 ×4): dinding dan penonton 140 baris, pasir 40 baris (garis potong 560/720 dijaga untuk lonjakan penonton) |
| Efek | percikan = kotak piksel berlapis garis tepi gelap; pisau = persegi panjang bertangga, berputar langkah 45°; aura aba-aba = tiga oval berpita; obor = tiga bingkai api bergantian; cahaya obor = tiga cincin berpita |
| HUD | bar HP berblok dengan penanda fase, bintang fase, potret 256×256 dalam bingkai, tombol kontrol bersudut siku dengan ikon piksel (kepalan, sepatu, perisai, pisau, panah), bar jeda pisau berblok, kilat merah berbentuk bingkai |

Menambah pose: edit `FIGHT_POSES` di `fight_poses.py`, jalankan `fight_poses.py`, lalu `pixel_fighters.py`, dan tambahkan pose ke daftar di `pose_frames.dart`
(`pose_frames_test.dart` memastikan urutannya sama).

## 16. Level 5 (panahan)

- **Papan sasaran:** lingkaran bergerigi piksel dari kisi 20×20 sel (tiap cincin 2 sel), garis tepi gelap 1 sel; warna dari tengah: emas `#FFD640`, merah `#E03C3C`, biru `#3C7CE0`, hitam `#282232`, putih `#FAFAFA`. Dua kaki dan satu penyangga kayu di belakang papan.
- **Bidikan:** tanda plus piksel (empat lengan dan titik tengah, tepi gelap); krem `#FFF4D6`, berubah emas saat anak panah akan kena cincin 10.
- **Anak panah:** ikon kecil 3×8 (mata abu, batang cokelat, bulu merah) untuk sisa panah; yang menancap di papan 5×5 dilihat dari belakang; yang terbang berupa garis cokelat dengan mata dan bulu.
- **HUD:** meter kekuatan berblok (oranye sebelum cukup, hijau sesudah, penanda kekuatan minimum), penunjuk angin 1 sampai 3 panah, skor melayang berwarna per cincin, tombol TARIK/LEPAS besar.
- **Boss:** Bima dengan topi pemanah; busur dibuat oleh `bow_big` di `pixel_bosses.py`.

## 17. Level 6 (gambler)

- **Latar stan:** `table.png` 720x1278 (kisi 240x426 x3): langit malam, dinding papan kayu, kanopi belang merah-krem, untaian lampu, papan nama "MR. LEXI", dan kain hijau meja (y 151 sampai 300) tempat kartu, koin, dan cangkir digambar. Lantai papan di bawah meja untuk panel kontrol.
- **Kartu:** kisi 20x28 x3. Punggung merah berpola dengan belah ketupat emas, muka aman (bintang hijau), muka sial (bom hitam bersumbu).
- **Koin:** kisi 24x24 x3. Kepala (lambang topi tinggi Mr. Lexi), ekor (bintang), dan bingkai tipis 8x24 untuk koin yang sedang berputar tegak lurus.
- **Cangkir:** kisi 22x26 x3, terbalik, belang merah dan krem, bibir merah gelap. **Bola** 10x10, **chip** 12x12 (merah dengan takik krem).
- **Boss:** Mr. Lexi dengan topi tinggi hitam berpita merah, rompi marun, dasi kupu-kupu merah; `hat='tophat'` di `pixel_kit.py`.
- **HUD:** label peluang emas di antara meja dan panel kontrol, tombol KEPALA dan EKOR (emas saat terpilih), bingkai emas di slot terpilih, tombol BUKA atau LEMPAR hijau (kelabu saat belum ada pilihan), tiga chip di bilah atas (redup sampai dimenangkan).

## 18. Level 7 (rhythm)

- **Panggung:** `stage.png` 720x1278 (kisi 240x426 x3): dinding belakang gelap, tirai beludru, tumpukan speaker, rangka lampu dan sorot, drum kecil di belakang Rhea, lantai papan dengan tepi LED, dan area bar semangat serta pad yang gelap di bawah. Letak jalur, garis ketuk, bar semangat, dan pad ada di `RhythmLayout` (`rhythm_stage.dart`).
- **Not:** `note_0..3.png` 60x36 (kisi 20x12 x3), satu warna per jalur (merah, biru, hijau, emas) dengan kilau atas dan kiri, bayangan bawah dan kanan, serta belah ketupat krem di tengah.
- **Pad:** `pad_0..3.png` 120x96, dua bingkai 60x96 berdampingan (kiri normal, kanan menyala dengan percikan di sudut), huruf papan ketik (D F J K) di tengah. HUD memotong bingkai yang dipakai.
- **Garis ketuk:** `hit_line.png` 720x12, titik terang berkala dan ujung dibulatkan.
- **Boss:** Rhea berambut runcing merah muda dengan ikat kepala biru muda, jaket gelap berlis emas, celana ungu; spesifikasi `RHEA` di `pixel_kit.py`, empat ekspresi (`boss_idle`, `boss_shock`, `boss_laugh`, `boss_defeat`).
- **HUD:** bilah atas "Round n/3" dan akurasi sementara, gelembung Rhea, banner ronde dengan target akurasi, hitung mundur besar, tulisan PERFECT/GOOD/MISS dekat garis ketuk, bar semangat berblok dengan garis ambang emas, hitungan combo, dan empat pad.
