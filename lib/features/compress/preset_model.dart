// Defines the social media presets and their FFmpeg parameters.

enum SocialPreset { instagram, whatsapp, smartAuto }

extension SocialPresetInfo on SocialPreset {
  String get label {
    switch (this) {
      case SocialPreset.instagram:
        return 'Instagram Ready';
      case SocialPreset.whatsapp:
        return 'WhatsApp Ready';
      case SocialPreset.smartAuto:
        return 'Smart Auto';
    }
  }

  String get emoji {
    switch (this) {
      case SocialPreset.instagram:
        return '📸';
      case SocialPreset.whatsapp:
        return '💬';
      case SocialPreset.smartAuto:
        return '⚡';
    }
  }

  String get description {
    switch (this) {
      case SocialPreset.instagram:
        return 'Reels & Feed · H.264 · 5–8 Mbps\nSharp quality after IG re-encode';
      case SocialPreset.whatsapp:
        return 'Under 16MB · 720p · 1.5 Mbps\nFast delivery, stays clear on mobile';
      case SocialPreset.smartAuto:
        return 'Balanced · H.264 · 3 Mbps\nGood quality for any platform';
    }
  }

  VideoParams get videoParams {
    switch (this) {
      case SocialPreset.instagram:
        // Instagram recommends ≥3500 kbps, sweet spot 5000–8000 kbps
        // CRF 18 = visually lossless, gives IG encoder enough detail to work with
        // No scale — keep original resolution (IG handles cropping itself)
        return const VideoParams(
          crf: 18,
          bitrate: '6000k',
          maxrate: '8000k',
          bufsize: '12000k',
          audioBitrate: '192k',
          fps: 30,
        );
      case SocialPreset.whatsapp:
        // WA limit: 16MB. Target 720p-ish, 1–1.5 Mbps for clips under 90s
        // CRF 26 = good quality at smaller size
        return const VideoParams(
          crf: 26,
          bitrate: '1500k',
          maxrate: '2000k',
          bufsize: '3000k',
          audioBitrate: '128k',
          fps: 30,
        );
      case SocialPreset.smartAuto:
        // Balanced: 3 Mbps, CRF 22 — good for most platforms
        return const VideoParams(
          crf: 22,
          bitrate: '3000k',
          maxrate: '4000k',
          bufsize: '6000k',
          audioBitrate: '160k',
          fps: 30,
        );
    }
  }

  ImageParams get imageParams {
    switch (this) {
      case SocialPreset.instagram:
        // IG recommends sRGB, high quality JPEG
        return const ImageParams(quality: 2); // FFmpeg q:v 1–5, lower = better
      case SocialPreset.whatsapp:
        // WA compresses anyway, medium quality is fine
        return const ImageParams(quality: 4);
      case SocialPreset.smartAuto:
        return const ImageParams(quality: 3);
    }
  }
}

class VideoParams {
  final int crf;
  final String bitrate;
  final String maxrate;
  final String bufsize;
  final String audioBitrate;
  final int fps;

  const VideoParams({
    required this.crf,
    required this.bitrate,
    required this.maxrate,
    required this.bufsize,
    required this.audioBitrate,
    required this.fps,
  });
}

class ImageParams {
  /// FFmpeg -q:v quality (1=best, 31=worst for JPEG)
  final int quality;

  const ImageParams({required this.quality});
}
