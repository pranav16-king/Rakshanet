import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/missing_person.dart';

/// Detected type of photo source
enum PhotoSourceType {
  file,
  network,
  base64,
  none,
}

/// Robust Photo Thumbnail parser and renderer for Missing Persons
///
/// Supports:
/// 1. Local filesystem path (`FileImage`)
/// 2. Remote HTTP/HTTPS network URL (`NetworkImage`)
/// 3. Inlined Base64 data (raw or `data:image/...;base64,...` data URI) (`MemoryImage`)
/// 4. Graceful tactical fallback (initials or person icon)
class MissingPersonPhotoThumbnail extends StatelessWidget {
  final MissingPerson person;
  final double size;
  final double borderRadius;
  final bool? isFound;

  const MissingPersonPhotoThumbnail({
    super.key,
    required this.person,
    this.size = 48.0,
    this.borderRadius = 8.0,
    this.isFound,
  });

  /// Detects the storage/transport type of a given photo source string
  static PhotoSourceType detectSourceType(String? source) {
    if (source == null || source.trim().isEmpty) {
      return PhotoSourceType.none;
    }
    final trimmed = source.trim();

    if (trimmed.startsWith('data:image/') || _isPureBase64(trimmed)) {
      return PhotoSourceType.base64;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return PhotoSourceType.network;
    }

    // Local file path (starts with /, file://, or Windows drive letter / path separator)
    if (trimmed.startsWith('file://') ||
        trimmed.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(trimmed) ||
        trimmed.contains('/') ||
        trimmed.contains('\\')) {
      return PhotoSourceType.file;
    }

    // Fallback: check if valid base64
    if (_tryDecodeBase64(trimmed) != null) {
      return PhotoSourceType.base64;
    }

    return PhotoSourceType.none;
  }

  /// Parses and decodes Base64 image bytes from raw string or data URI
  static Uint8List? decodeBase64Photo(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final trimmed = source.trim();
    return _tryDecodeBase64(trimmed);
  }

  static bool _isPureBase64(String s) {
    if (s.startsWith('data:image/')) return true;
    if (s.length < 16) return false;
    final clean = s.replaceAll(RegExp(r'\s+'), '');
    if (clean.length % 4 != 0) return false;
    return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(clean);
  }

  static Uint8List? _tryDecodeBase64(String s) {
    try {
      String clean = s.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last.trim();
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      if (clean.isEmpty) return null;
      final bytes = base64Decode(clean);
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFound = isFound ?? person.isFound;
    final photoSource = (person.photoPath != null && person.photoPath!.trim().isNotEmpty)
        ? person.photoPath!.trim()
        : (person.photoUrl != null && person.photoUrl!.trim().isNotEmpty)
            ? person.photoUrl!.trim()
            : null;

    final sourceType = detectSourceType(photoSource);

    String? resolvedNetworkUrl;
    if (sourceType == PhotoSourceType.network && photoSource != null) {
      if (photoSource.startsWith('http://localhost:8000')) {
        resolvedNetworkUrl = photoSource.replaceFirst('http://localhost:8000', AppConfig.backendBaseUrl);
      } else {
        resolvedNetworkUrl = photoSource;
      }
    } else if (photoSource != null && photoSource.startsWith('/media/')) {
      resolvedNetworkUrl = '${AppConfig.backendBaseUrl}$photoSource';
    }

    Widget? imageWidget;

    if (sourceType == PhotoSourceType.base64 && photoSource != null) {
      final bytes = decodeBase64Photo(photoSource);
      if (bytes != null) {
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(effectiveFound),
        );
      }
    } else if (resolvedNetworkUrl != null) {
      imageWidget = Image.network(
        resolvedNetworkUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(effectiveFound),
      );
    } else if (sourceType == PhotoSourceType.file && photoSource != null) {
      final cleanPath = photoSource.startsWith('file://')
          ? photoSource.replaceFirst('file://', '')
          : photoSource;
      try {
        if (!kIsWeb) {
          final file = File(cleanPath);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(effectiveFound),
            );
          }
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showFullScreenPhoto(context, photoSource, resolvedNetworkUrl, effectiveFound),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          color: effectiveFound
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : const Color(0xFF3A506B),
          child: imageWidget ?? _buildFallback(effectiveFound),
        ),
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, String? photoSource, String? resolvedUrl, bool found) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: found ? const Color(0xFF10B981) : const Color(0xFFD92D20), width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildLargeImage(photoSource, resolvedUrl, found),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    person.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${person.age} yrs • ${person.gender} • ${person.status}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeImage(String? photoSource, String? resolvedUrl, bool found) {
    if (photoSource != null && (photoSource.startsWith('data:image/') || _isPureBase64(photoSource))) {
      final bytes = decodeBase64Photo(photoSource);
      if (bytes != null) {
        return Image.memory(bytes, height: 320, width: double.infinity, fit: BoxFit.contain);
      }
    }
    if (resolvedUrl != null) {
      return Image.network(resolvedUrl, height: 320, width: double.infinity, fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(height: 200, color: Colors.black26, child: _buildFallback(found)),
      );
    }
    if (photoSource != null && !kIsWeb) {
      final clean = photoSource.replaceFirst('file://', '');
      final f = File(clean);
      if (f.existsSync()) {
        return Image.file(f, height: 320, width: double.infinity, fit: BoxFit.contain);
      }
    }
    return Container(height: 200, color: Colors.black26, child: _buildFallback(found));
  }

  Widget _buildFallback(bool found) {
    final initial = person.name.trim().isNotEmpty
        ? person.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: found ? const Color(0xFF10B981) : Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
