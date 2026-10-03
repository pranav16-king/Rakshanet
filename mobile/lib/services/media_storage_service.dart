import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';

/// Keeps mesh media in private app storage so a picked image is not lost when
/// the Android picker cache is cleared and a received file can be relayed later.
class MediaStorageService {
  static const maxImageBytes = 10 * 1024 * 1024;

  Future<MediaAttachment> stageImage(String sourcePath) async {
    final source = File(sourcePath);
    final length = await source.length();
    if (length <= 0) {
      throw StateError('The selected image is empty.');
    }
    if (length > maxImageBytes) {
      throw StateError('Images must be 10 MB or smaller for offline sharing.');
    }

    final fileName = _safeName(path.basename(source.path));
    final destination = await createDestination(fileName);
    await source.copy(destination);

    return MediaAttachment(
      localPath: destination,
      fileName: fileName,
      mimeType: _mimeTypeFor(fileName),
      byteLength: length,
    );
  }

  Future<String> createDestination(String requestedName) async {
    Directory root;
    try {
      root = await getApplicationDocumentsDirectory();
    } catch (_) {
      root = Directory.systemTemp;
    }
    final mediaDirectory = Directory(path.join(root.path, 'mesh-media'));
    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }
    final name = _safeName(requestedName);
    return path.join(
      mediaDirectory.path,
      '${DateTime.now().microsecondsSinceEpoch}_$name',
    );
  }

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'image.jpg' : cleaned;
  }

  String _mimeTypeFor(String fileName) {
    switch (path.extension(fileName).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
