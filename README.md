# ZERO — Compress. Stay Sharp.

> Aplikasi kompresi foto & video untuk media sosial. Offline. Tanpa akun. 1–2 klik.

Dibuat oleh **CTRLBuild**

---

## Latar Belakang

Setiap kali kita mengunggah foto atau video ke Instagram, WhatsApp, atau platform media sosial lainnya, platform tersebut akan melakukan kompresi ulang secara otomatis — hasilnya sering kali buram, pecah, atau ukuran file tetap besar sehingga lambat dikirim.

**ZERO** hadir untuk menyelesaikan masalah itu. Dengan mengompresi file *sebelum* diunggah menggunakan parameter yang sudah disesuaikan per platform, kualitas visual tetap tajam dan ukuran file jauh lebih kecil. Semua proses berjalan sepenuhnya di perangkat — tidak ada data yang dikirim ke server manapun.

---

## Fitur

- **Kompresi Foto** — Kompres gambar dengan kualitas optimal menggunakan FFmpeg, tanpa perlu resize manual.
- **Kompresi Video** — Kompres video dengan encoding H.264, kontrol bitrate, CRF, dan frame rate secara otomatis.
- **Preset Media Sosial** — Tiga preset siap pakai yang sudah dikalibrasi:
  - 📸 **Instagram Ready** — H.264, CRF 18, 6 Mbps. Kualitas tinggi agar tetap tajam setelah re-encode Instagram.
  - 💬 **WhatsApp Ready** — 720p, 1.5 Mbps, target di bawah 16 MB. Cepat terkirim, tetap jernih di layar mobile.
  - ⚡ **Smart Auto** — Balanced, 3 Mbps, CRF 22. Cocok untuk platform apapun.
- **Preview Media** — Tampilkan preview foto atau thumbnail video sebelum kompresi dimulai.
- **Video Player** — Putar hasil kompresi video langsung di dalam aplikasi sebelum disimpan.
- **Perbandingan Ukuran** — Tampilkan ukuran file sebelum dan sesudah kompresi beserta persentase penghematan.
- **Simpan ke Galeri** — Simpan hasil kompresi langsung ke galeri perangkat.
- **Bagikan Langsung** — Share file hasil kompresi ke aplikasi lain tanpa perlu keluar dari ZERO.
- **Fully Offline** — Tidak memerlukan koneksi internet. Tidak ada akun. Tidak ada data yang dikirim keluar.
- **Splash Screen Animasi** — Tampilan pembuka yang smooth dengan animasi logo, tagline, dan progress bar.

---

## Teknologi

| Komponen | Detail |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart SDK ^3.5.0) |
| **Kompresi Media** | [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new) — FFmpeg engine untuk encoding video & image |
| **Media Picker** | [image_picker](https://pub.dev/packages/image_picker) — Akses galeri foto & video |
| **Video Player** | [video_player](https://pub.dev/packages/video_player) — Playback video hasil kompresi |
| **Video Thumbnail** | [video_thumbnail](https://pub.dev/packages/video_thumbnail) — Generate thumbnail dari video |
| **Simpan ke Galeri** | [saver_gallery](https://pub.dev/packages/saver_gallery) — Menyimpan file ke galeri perangkat |
| **Share** | [share_plus](https://pub.dev/packages/share_plus) — Berbagi file ke aplikasi lain |
| **Permission** | [permission_handler](https://pub.dev/packages/permission_handler) — Manajemen izin akses media |
| **Path Utilities** | [path_provider](https://pub.dev/packages/path_provider) + [path](https://pub.dev/packages/path) |
| **Icons** | [lucide_icons_flutter](https://pub.dev/packages/lucide_icons_flutter) |

---

## Struktur Proyek

```
lib/
├── core/
│   ├── services/
│   │   ├── ffmpeg_service.dart       # Logika kompresi video & image via FFmpeg
│   │   └── media_picker_service.dart # Akses & copy media dari galeri ke temp dir
│   └── utils/
│       ├── file_utils.dart           # Helper format ukuran file & simpan ke galeri
│       └── toast_utils.dart          # Notifikasi toast
└── features/
    ├── splash/
    │   └── splash_screen.dart        # Splash screen dengan animasi
    ├── home/
    │   └── home_screen.dart          # Halaman utama, pilih foto atau video
    ├── compress/
    │   ├── compress_screen.dart      # Pilih preset & mulai kompresi
    │   └── preset_model.dart         # Definisi preset & parameter FFmpeg
    └── result/
        └── result_screen.dart        # Tampilkan hasil, preview, simpan & share
```

---

## Cara Menjalankan

**Prasyarat:** Flutter SDK ^3.5.0, Android SDK (min API 24)

```bash
# Clone repo
git clone <repo-url>
cd zero

# Install dependencies
flutter pub get

# Jalankan di perangkat/emulator Android
flutter run
```

> iOS saat ini belum dikonfigurasi (`ios: false` pada launcher icons). Target utama adalah Android.

---

## Tim

Dikembangkan dengan ❤️ oleh **CTRLBuild**
