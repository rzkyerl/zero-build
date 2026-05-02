import 'package:path/path.dart' as p;
import 'package:saver_gallery/saver_gallery.dart';

class FileUtils {
  /// Format bytes into human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Build a unique output filename.
  static String outputFileName(String inputPath, String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'zero_output_$ts.$ext';
  }

  /// Save file to device gallery (Pictures/Zero or Movies/Zero).
  /// Throws on failure.
  static Future<void> saveToGallery(String filePath, String ext) async {
    final isVideo = _isVideo(ext);
    final fileName = 'Zero_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final result = await SaverGallery.saveFile(
      filePath: filePath,
      fileName: fileName,
      androidRelativePath: isVideo ? 'Movies/Zero' : 'Pictures/Zero',
      skipIfExists: false,
    );

    if (!result.isSuccess) {
      throw Exception(result.errorMessage ?? 'Unknown save error');
    }
  }

  static String extension(String path) => p.extension(path).toLowerCase();

  static bool _isVideo(String ext) {
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext.toLowerCase());
  }
}
