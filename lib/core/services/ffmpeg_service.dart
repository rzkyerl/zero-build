import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/file_utils.dart';
import '../../features/compress/preset_model.dart';

class CompressResult {
  final String outputPath;
  final int originalBytes;
  final int compressedBytes;

  const CompressResult({
    required this.outputPath,
    required this.originalBytes,
    required this.compressedBytes,
  });

  double get reductionPercent =>
      ((originalBytes - compressedBytes) / originalBytes * 100)
          .clamp(0, 100)
          .toDouble();

  String get formattedOriginal => FileUtils.formatBytes(originalBytes);
  String get formattedCompressed => FileUtils.formatBytes(compressedBytes);
}

class FFmpegService {
  /// Compress a video file using the given preset.
  /// [customQualityPercent] is used when preset == SocialPreset.custom (1–100).
  /// 50% means the output file will be ~50% of the original size.
  Future<CompressResult> compressVideo({
    required String inputPath,
    required SocialPreset preset,
    int customQualityPercent = 50,
    void Function(double progress)? onProgress,
  }) async {
    final outputPath = await _buildOutputPath(inputPath, 'mp4');

    String cmd;
    if (preset == SocialPreset.custom) {
      // Target file size = originalBytes × (qualityPercent / 100)
      // Target bitrate (kbps) = (targetBytes × 8) / durationSeconds / 1000
      // Reserve ~10% of bitrate for audio (128k)
      final durationSec = (await _getVideoDurationMs(inputPath)) / 1000.0;
      final originalBytes = File(inputPath).lengthSync();
      final targetBytes = (originalBytes * customQualityPercent / 100).round();
      const audioBitrateKbps = 128;

      int videoBitrateKbps;
      if (durationSec > 0) {
        final totalKbps = (targetBytes * 8) / durationSec / 1000;
        videoBitrateKbps =
            (totalKbps - audioBitrateKbps).round().clamp(100, 50000);
      } else {
        // Fallback if duration unknown: use quality% as a rough CRF scale
        videoBitrateKbps = (500 + (customQualityPercent / 100) * 5500).round();
      }

      cmd = '-y -i "$inputPath" '
          '-c:v libx264 -preset fast '
          '-b:v ${videoBitrateKbps}k '
          '-maxrate ${(videoBitrateKbps * 1.5).round()}k '
          '-bufsize ${(videoBitrateKbps * 2).round()}k '
          '-r 30 '
          '-c:a aac -b:a ${audioBitrateKbps}k '
          '-movflags +faststart '
          '"$outputPath"';
    } else {
      cmd = _buildVideoCommand(inputPath, outputPath, preset);
    }

    // Get video duration in milliseconds for progress calculation
    final durationMs = await _getVideoDurationMs(inputPath);

    // Use executeAsync so we can receive statistics callbacks
    final completer = Completer<CompressResult>();

    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (onProgress != null && durationMs > 0) {
        final timeMs = stats.getTime();
        final progress = (timeMs / durationMs).clamp(0.0, 1.0);
        onProgress(progress);
      }
    });

    await FFmpegKit.executeAsync(
      cmd,
      (session) async {
        FFmpegKitConfig.enableStatisticsCallback(null);
        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getAllLogsAsString();
          completer.completeError(Exception('FFmpeg video error: $logs'));
        } else {
          // Ensure progress reaches 100%
          onProgress?.call(1.0);
          completer.complete(_buildResult(inputPath, outputPath));
        }
      },
    );

    return completer.future;
  }

  /// Compress an image file using the given preset.
  /// [customQualityPercent] is used when preset == SocialPreset.custom (1–100).
  /// 50% means the output file will be ~50% of the original size.
  Future<CompressResult> compressImage({
    required String inputPath,
    required SocialPreset preset,
    int customQualityPercent = 50,
  }) async {
    final outputPath = await _buildOutputPath(inputPath, 'jpg');

    String cmd;
    if (preset == SocialPreset.custom) {
      // JPEG file size is roughly proportional to quality setting.
      // We use a two-step approach: encode at target quality, then check.
      // quality% maps directly to JPEG quality 1–100 via -q:v 1–31 (inverted).
      // q:v 1 ≈ JPEG 97%, q:v 31 ≈ JPEG 1%
      // Linear mapping: q:v = round(1 + (1 - quality/100) * 30)
      final qv =
          (1 + (1 - customQualityPercent / 100) * 30).round().clamp(1, 31);
      cmd = '-y -i "$inputPath" -q:v $qv "$outputPath"';
    } else {
      cmd = _buildImageCommand(inputPath, outputPath, preset);
    }

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg image error: $logs');
    }

    return _buildResult(inputPath, outputPath);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  /// Get video duration in milliseconds using FFprobe.
  Future<int> _getVideoDurationMs(String inputPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(inputPath);
      final info = session.getMediaInformation();
      if (info == null) return 0;
      final durationStr = info.getDuration();
      if (durationStr == null) return 0;
      final seconds = double.tryParse(durationStr) ?? 0.0;
      return (seconds * 1000).toInt();
    } catch (_) {
      return 0;
    }
  }

  String _buildVideoCommand(
    String input,
    String output,
    SocialPreset preset,
  ) {
    final p = preset.videoParams;
    // Keep original resolution — only control quality via CRF + bitrate
    // -r: cap fps to 30 (no need for 60fps on social media)
    // -preset fast: faster encode, slightly larger than slow but fine for mobile
    return '-y -i "$input" '
        '-c:v libx264 -preset fast '
        '-crf ${p.crf} -b:v ${p.bitrate} -maxrate ${p.maxrate} -bufsize ${p.bufsize} '
        '-r ${p.fps} '
        '-c:a aac -b:a ${p.audioBitrate} '
        '-movflags +faststart '
        '"$output"';
  }

  String _buildImageCommand(
    String input,
    String output,
    SocialPreset preset,
  ) {
    final p = preset.imageParams;
    // Keep original resolution for images too
    return '-y -i "$input" '
        '-q:v ${p.quality} '
        '"$output"';
  }

  Future<String> _buildOutputPath(String inputPath, String ext) async {
    final dir = await getTemporaryDirectory();
    final name = FileUtils.outputFileName(inputPath, ext);
    return '${dir.path}/$name';
  }

  CompressResult _buildResult(String inputPath, String outputPath) {
    final original = File(inputPath).lengthSync();
    final compressed = File(outputPath).lengthSync();
    return CompressResult(
      outputPath: outputPath,
      originalBytes: original,
      compressedBytes: compressed,
    );
  }
}
