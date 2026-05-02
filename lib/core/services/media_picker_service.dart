import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum MediaType { image, video }

class PickedMedia {
  final String path;
  final MediaType type;
  final int sizeBytes;

  const PickedMedia({
    required this.path,
    required this.type,
    required this.sizeBytes,
  });

  String get formattedSize => _formatBytes(sizeBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class MediaPickerService {
  final _picker = ImagePicker();

  Future<PickedMedia?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // no re-compression at pick stage
    );
    if (file == null) return null;
    final realPath = await _saveToTemp(file, 'img', 'jpg');
    return _toPickedMedia(realPath, MediaType.image);
  }

  Future<PickedMedia?> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    final realPath = await _saveToTemp(file, 'vid', ext.isEmpty ? 'mp4' : ext);
    return _toPickedMedia(realPath, MediaType.video);
  }

  /// Read via XFile bytes API (works with content:// URIs on all Android versions)
  /// then write to a real temp file path that FFmpeg can access.
  Future<String> _saveToTemp(XFile xfile, String prefix, String ext) async {
    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dest = '${tmp.path}/${prefix}_$ts.$ext';

    // Use readAsBytes — works regardless of content:// or file:// URI
    final bytes = await xfile.readAsBytes();
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
  }

  PickedMedia _toPickedMedia(String path, MediaType type) {
    final size = File(path).lengthSync();
    return PickedMedia(path: path, type: type, sizeBytes: size);
  }
}
