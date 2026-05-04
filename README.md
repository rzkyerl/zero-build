# Zero — Compress. Stay Sharp.

> Compress photos & videos for social media. Offline. No account. 1–2 taps.

Built by **CTRLBuild**

---

## Overview

Every time you upload a photo or video to Instagram, WhatsApp, or any other social platform, the platform re-compresses it automatically — often resulting in blurry visuals, artifacts, or files that are still too large to send quickly.

**Zero** solves that. By compressing your media *before* uploading using platform-tuned parameters, your files stay visually sharp at a fraction of the original size. Everything runs entirely on-device — no data is ever uploaded anywhere.

---

## Features

### Compression
- **Photo compression** — JPEG encoding via FFmpeg with per-preset quality control (`-q:v`).
- **Video compression** — H.264 encoding with CRF, bitrate, maxrate, bufsize, and FPS control.
- **Custom quality** — Slider from 10–100%. The output file size directly targets `quality% × original size`. Video bitrate is calculated from the target size and duration; image quality maps linearly to FFmpeg's `q:v` scale.

### Presets
Four presets available on the compress screen:

| Preset | Target | Details |
|---|---|---|
| � **Instagram Ready** | Reels & Feed | H.264, CRF 18, 6 Mbps, 192k audio. Stays sharp after IG re-encode. |
| 💬 **WhatsApp Ready** | Under 16 MB | 720p-ish, 1.5 Mbps, CRF 26, 128k audio. Fast delivery on mobile. |
| ⚡ **Smart Auto** | Any platform | Balanced, 3 Mbps, CRF 22, 160k audio. |
| 🎚️ **Custom** | User-defined | Slider-based quality %. Output size ≈ original × quality%. |

### Result Screen
- In-app video player with play/pause, progress bar, and duration badge.
- Image preview for photos.
- Before/after size comparison with reduction percentage and progress bar.
- **Save to Gallery** — saves the compressed file directly to the device gallery.
- **Share** — share the output file to any app via the system share sheet.
- **Unsaved file guard** — if the user tries to close without saving (and auto-save is off), a confirmation dialog appears.

### Settings
- **Auto Save** — when enabled, the compressed file is automatically saved to the gallery as soon as the result screen loads. The Save button is hidden since it's no longer needed.
- **Save Location** — displays the default save path (Gallery · Downloads / Zero).
- **About** — app name, version, privacy statement, and developer info.
- **Offline badge** — "100% Offline · Private" prominently shown in settings to reinforce trust.

### General
- Fully offline — no internet connection required, no account, no tracking.
- Animated splash screen with logo, tagline, and progress bar.
- Permission handling with friendly guidance dialog if permanently denied.
- Dark theme throughout, consistent with system dark mode.

---

## Tech Stack

| Component | Package |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK ^3.5.0) |
| Media compression | [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new) |
| Media picker | [image_picker](https://pub.dev/packages/image_picker) |
| Video playback | [video_player](https://pub.dev/packages/video_player) |
| Video thumbnail | [video_thumbnail](https://pub.dev/packages/video_thumbnail) |
| Save to gallery | [saver_gallery](https://pub.dev/packages/saver_gallery) |
| Share | [share_plus](https://pub.dev/packages/share_plus) |
| Permissions | [permission_handler](https://pub.dev/packages/permission_handler) |
| Persistent settings | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Path utilities | [path_provider](https://pub.dev/packages/path_provider) + [path](https://pub.dev/packages/path) |
| Icons | [lucide_icons_flutter](https://pub.dev/packages/lucide_icons_flutter) |

---

## Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── ffmpeg_service.dart         # Video & image compression logic via FFmpeg
│   │   ├── media_picker_service.dart   # Gallery access, copies media to temp dir
│   │   └── settings_service.dart       # SharedPreferences wrapper (auto-save, etc.)
│   └── utils/
│       ├── file_utils.dart             # File size formatting, save to gallery
│       └── toast_utils.dart            # Success/error toast notifications
└── features/
    ├── splash/
    │   └── splash_screen.dart          # Animated splash screen
    ├── home/
    │   └── home_screen.dart            # Home screen — pick photo or video
    ├── compress/
    │   ├── compress_screen.dart        # Preset selection & compression trigger
    │   └── preset_model.dart           # Preset enum, FFmpeg params, icon/label/description
    ├── result/
    │   └── result_screen.dart          # Result preview, size comparison, save & share
    └── settings/
        └── settings_screen.dart        # App settings — auto-save, about, offline badge
```

---

## Getting Started

**Requirements:** Flutter SDK ^3.5.0, Android SDK (min API 24)

```bash
# Clone the repo
git clone https://github.com/rzkyerl/zero-build.git
cd zero-build/zero

# Install dependencies
flutter pub get

# Run on a connected Android device or emulator
flutter run
```

> iOS is not configured (`ios: false` in launcher icons). Android is the primary target.

---

## Developer

Built with ❤️ by **CTRLBuild**
