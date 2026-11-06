# Kunci Art Style: Pixel Art 48 px

> **Status: TERKUNCI.** Semua aset visual baru mengikuti dokumen ini. Mengubah aturan di sini harus disengaja
> dan diikuti pembuatan ulang semua aset yang terdampak. Dokumen ini menggantikan `docs/ART_STYLE.md`
> (gaya stickman) untuk aset baru; gaya lama tetap dipakai hanya sampai aset terkait dimigrasi.
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
- **Storyboard (240×426):** "Lewati >>" kanan atas; panel 1 lebar; panel 2 lebar (barisan master dan pemain); panel 3 dan 4 berdampingan; "Ketuk untuk lanjut" dan empat penanda halaman di bawah.

Ukuran panel cerita (logis → PNG 3×): panel 1 = 216×87 → 648×261; panel 2 = 216×100 → 648×300; panel 3 dan 4 = 106×137 → 318×411.

## 11. Cara membuat aset

```bash
python tools/art/pixel_font.py        # font: assets/fonts/PixelChampion.ttf (butuh: pip install fonttools)
python tools/art/pixel_export.py      # aset game: home_bg, btn_*, panel_1..4 (diperbesar 3x) -> assets/images/
python tools/art/pixel_bosses.py      # boss Bob, Asep, Chef (4 ekspresi, 512x512, sprite 8x) -> assets/images/{genius,maze,cooking}/
python tools/art/pixel_cooking.py     # Level 4: 16 ikon bahan, 3 stasiun, latar dapur -> assets/images/cooking/
python tools/art/pixel_icon.py        # ikon aplikasi -> assets/icon/ (lalu: dart run flutter_launcher_icons)
python tools/art/pixel_scenes.py      # mockup penuh + lembar karakter -> docs/preview/ (tidak masuk game)
python tools/art/pixel_preview.py     # pratinjau pemain 32/48 px (eksperimen awal)
```

Aset baru dibuat dengan menambah spesifikasi karakter atau fungsi adegan, **bukan** dengan menggambar manual di luar generator,
supaya aturan di atas otomatis terpenuhi dan mudah diubah serempak.

### Memakai di Flutter

- Semua layar piksel memakai kisi rujukan **240×426 piksel logis**. `PixelUi.unit(context)` (di `lib/shared/widgets/pixel_ui.dart`) memberi ukuran 1 piksel logis dalam dp; seluruh layout dihitung dari unit ini.
- Teks: `PixelUi.text(u, scale: 1|2|3, outline: ..., shadow: ...)`. Font `PixelChampion` hanya punya huruf besar; huruf kecil tampil sebagai huruf besar, jadi teks di `strings.dart` tidak perlu diubah. `fontSize = 10 × skala × unit`. Tebal tepi = skala.
- Tombol: `PixelButton` (gambar `btn_primary.png` / `btn_secondary.png` + label teks, sehingga mudah diuji dan terbaca pembaca layar).
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
| Rock sebagai sprite per frame untuk pertarungan (dan pemain, arena, potret Level 1) | Belum (dikerjakan paling akhir) |
| Ikon bahan, stasiun, latar dapur, chef (Level 4) | **Terpasang (aset)** |
| Pilih level, intro boss, jeda dan hasil, HUD level (gaya teks dan tombol) | Belum |
| Ikon aplikasi (wajah pemain + sinar matahari; latar adaptif `#FFAA38`) | **Terpasang (aset)** |

### Ekspresi boss

Empat keadaan baku untuk boss: `idle` (pose dan wajah asli), `shock` (pose `surprise`, mata bulat putih, mulut "o", tetes keringat),
`laugh` (pose `hips`, mata menutup, air mata, mulut lebar), `defeat` (pose `stand`, mata X, mulut bergelombang, bintang pusing).
Aksesori khas tetap terlihat di semua ekspresi (kacamata Bob, topi koki Chef, papan labirin Asep jatuh ke lantai saat bereaksi).
