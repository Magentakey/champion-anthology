# Panduan Gaya Seni (Art Style)

Gaya yang dikunci: **kartun stickman** (kepala bulat putih besar, garis hitam tegas, badan dari garis, emosi lewat mata dan alis), dengan latar warna datar atau gradasi lembut dan lantai abu-abu.

## Aturan gambar

1. **Kepala**: lingkaran putih dengan garis tepi hitam tebal, besar dibanding badan (pemain r=150, bos r=190 dan badannya lebih pendek).
2. **Badan dan anggota gerak**: garis hitam berujung bulat dengan ketebalan sama di seluruh gambar. Jari hanya digambar pada tangan terbuka (menopang bola dunia). Tangan mengepal digambar sebagai lingkaran putih kecil dengan tiga garis jari.
3. **Wajah**: mata oval putih dengan pupil kecil, tampak 3/4 ke arah hadap. Emosi ditentukan mata, alis, dan mulut:

| Ekspresi | Mata | Alis | Mulut | Tambahan |
|---|---|---|---|---|
| Sombong | setengah terpejam, pupil melirik | satu naik, satu turun | senyum miring | |
| Bertekad | terbuka | miring ke dalam (marah) | senyum lebar | |
| Semangat menang (`mc_hype`, wajah utama pemain) | besar, pupil berkilau | tajam, turun ke arah hidung | terbuka lebar, gigi dan lidah | tiga garis semangat di atas kepala |
| Kaget | sangat lebar | naik | bulat "O" | tetes keringat |
| Tertawa | tertutup (^ ^) | naik lembut | terbuka lebar, lidah merah | air mata |
| Kalah | tanda X | naik di sisi dalam (sedih) | bergelombang | bintang pusing, kacamata retak |

4. **Warna**: dasarnya hitam dan putih; warna hanya sebagai aksen.

| Elemen | Warna | Hex |
|---|---|---|
| Pemain: ikat kepala | merah | `#D62828` |
| Bob: dasi kupu-kupu | biru | `#1E64C8` |
| Sepatu | cokelat | `#8D5C2E` |
| Lantai | abu-abu | `#9E9E9E` |
| Latar menu / ikon | merah muda | `#FFEBEE` |
| Bola dunia | biru muda dan hijau | `#90CAF9`, `#66BB6A` |
| Piala | emas | `#FFC107` |

5. **Bayangan**: elips abu-abu transparan di bawah kaki (tidak dipakai pada sprite game yang bergerak naik-turun).
6. **Latar**: warna datar atau gradasi lembut; lantai abu-abu dengan garis hitam di tepi atasnya; sinar (rays) untuk momen dramatis.

## Karakter

- **Pemain**: stickman dengan **ikat kepala merah** berekor dua yang melambai. Selalu bersemangat dan ingin menang; wajah sombong (smug) hanya untuk lawan seperti Bob. Di menu utama setengah badan (sampai pinggang), menghadap **kiri**, telapak terbuka menopang bola dunia (gambar yang sama dipakai sebagai ikon), wajah semangat ingin menang dengan senyum tipis (`mc_hype`, bukan sombong), tangan lain di pinggang, dan diletakkan di lapisan paling belakang (di belakang judul dan tombol). Karakter ini dipakai di semua gambar.
- **Bob the Genius**: rambut runcing hitam, kacamata bulat, dasi kupu-kupu biru, kepala besar. Menghadap kanan di game (ke arah pemain). Empat ekspresi: `idle`, `shock`, `laugh`, `defeat`.
- **Champion lain**: tokoh dengan atribut khas, bukan warna besar. Asep membawa papan labirin; Chef memakai topi koki.

## Daftar aset gambar

| Aset | Berkas | Ukuran |
|---|---|---|
| Karakter menu utama | `assets/images/home/mc_home.png` | sekitar 650 x 990, latar transparan |
| Ekspresi Bob | `assets/images/genius/boss_idle/shock/laugh/defeat.png` | 512 x 512 (persegi) |
| Panel cerita | `assets/images/story/panel_1..4.png` | 1000x400, 600x600, 600x600, 600x900 |
| Ikon aplikasi | `assets/icon/app_icon.png`, `app_icon_fg.png` | 1024 x 1024 |

## Membuat ulang aset

Semua gambar dihasilkan oleh `tools/art/generate_art.py`, sehingga gayanya selalu seragam.

```bash
pip install pillow
python tools/art/generate_art.py
```

- Pose ada di `POSES` (koordinat sendi pada bingkai 1000 x 1400, menghadap kanan; `flip=True` membalik arah).
- Wajah ada di `FACES`; aksesori (ikat kepala, kacamata, rambut, topi koki) berupa fungsi `draw_*`.
- Tambah karakter atau pose baru dengan menambah entri pose dan wajah, lalu panggil `draw_figure(...)` di fungsi `gen_*` yang sesuai.
- Setelah diubah, jalankan skrip lagi. Jika nanti ada art digital buatan tangan, cukup timpa file PNG dengan nama sama.
