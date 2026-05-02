import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
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
  Future<CompressResult> compressVideo({
    required String inputPath,
    required SocialPreset preset,
    void Function(double progress)? onProgress,
  }) async {
    final outputPath = await _buildOutputPath(inputPath, 'mp4');
    final cmd = _buildVideoCommand(inputPath, outputPath, preset);

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg video error: $logs');
    }

    return _buildResult(inputPath, outputPath);
  }

  /// Compress an image file using the given preset.
  Future<CompressResult> compressImage({
    required String inputPath,
    required SocialPreset preset,
  }) async {
    final outputPath = await _buildOutputPath(inputPath, 'jpg');
    final cmd = _buildImageCommand(inputPath, outputPath, preset);

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg image error: $logs');
    }

    return _buildResult(inputPath, outputPath);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

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
