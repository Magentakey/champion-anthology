# Panduan Rilis

## Sebelum rilis (di laptop)

```bash
git pull
flutter pub get
dart run flutter_launcher_icons      # hanya jika ikon berubah, lalu uninstall app lama di HP
flutter analyze                      # harus bersih (info pun dianggap gagal oleh workflow)
flutter test                         # semua lulus
flutter run                          # coba alur penuh di HP: menu, cerita, 8 level, jeda, hasil
```

Daftar cek singkat di HP:

- Menu dan cerita tampil, tombol Main, Lewati, dan Lanjut bekerja.
- Pilih level: bintang tersimpan, level terkunci menampilkan pesan.
- Level 1 sampai 7 bisa dimainkan sampai menang dan kalah; jeda, Ulangi, dan Keluar bekerja.
- Suara (SFX dan musik) dan getar masuk akal; tombol suara di jeda bekerja.
- Tidak ada layar putih atau teks terpotong di layar kecil.

## Menyiapkan versi

1. `pubspec.yaml`: naikkan `version:` (mis. `1.4.0+5`; nomor setelah `+` naik tiap rilis).
2. `CHANGELOG.md`: tambah bagian `## [1.4.0] - tanggal` di atas bagian lama. Workflow memakai bagian ini sebagai catatan rilis.
3. Commit:

```bash
git add .
git commit -m "chore: rilis 1.4.0"
git push
```

## Membuat rilis

```bash
git tag v1.4.0
git push --tags
```

Tag harus sama dengan versi di `pubspec.yaml` (tanpa `+nomorBuild`), kalau tidak workflow berhenti dengan pesan yang jelas.
Buka tab **Actions** di GitHub dan tunggu "Release APK" selesai (beberapa menit). Hasilnya muncul di **Releases** dengan nama
`champion-anthology-v1.4.0.apk` dan catatan dari `CHANGELOG.md`.

## Jika workflow gagal

| Gejala | Sebab dan perbaikan |
|---|---|
| "Versi di pubspec.yaml ... tidak sama dengan tag" | Naikkan versi di `pubspec.yaml`, commit, lalu pindahkan tag (di bawah) |
| `flutter analyze` merah | Jalankan lokal, perbaiki (info pun dihitung), commit, pindahkan tag |
| `flutter test` merah | Jalankan lokal dan perbaiki, commit, pindahkan tag |
| Rilis gagal dibuat (izin) | Settings, Actions, General, Workflow permissions: pilih "Read and write permissions" |

Memindahkan tag ke commit baru:

```bash
git tag -d v1.4.0
git push origin :refs/tags/v1.4.0
git tag v1.4.0
git push --tags
```

Jika sempat muncul rilis setengah jadi di halaman Releases, hapus dulu di sana.

## Catatan

- APK ditandatangani dengan kunci debug bawaan Flutter: bisa dipasang manual (izinkan sumber tidak dikenal), tetapi **tidak bisa diunggah ke Play Store**. Untuk Play Store perlu keystore rilis, `key.properties`, dan konfigurasi `signingConfigs` di `android/app/build.gradle.kts`.
- Jangan commit file keystore atau `key.properties` ke repositori.
