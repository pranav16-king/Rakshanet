import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Progress event when downloading offline map regions
class TileDownloadProgress {
  final int downloaded;
  final int total;
  final double percentage;
  final String status;
  final bool isCompleted;

  const TileDownloadProgress({
    required this.downloaded,
    required this.total,
    required this.percentage,
    required this.status,
    this.isCompleted = false,
  });
}

/// Offline Map Service for SignalRescue AI / RakshaNet
///
/// Features:
/// 1. Local disk tile caching in app storage (`offline_map_tiles/{z}/{x}/{y}.png`)
/// 2. Seamless offline fallback with tactical grid tiles (never shows blank/broken tiles)
/// 3. Offline region downloader (pre-caches area tiles for disaster blackout readiness)
/// 4. Tile cache size tracking and purge
/// 5. Geodetic distance, compass bearing, and coordinate projection utilities
class OfflineMapService {
  static final OfflineMapService instance = OfflineMapService._();
  OfflineMapService._();

  String? _tileCacheDirPath;
  final Map<bool, Uint8List> _generatedGridTiles = {};

  /// 100% Free OpenStreetMap & Humanitarian OSM endpoints (Zero API key required)
  static const String freeOsmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String humanitarianOsmUrl =
      'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  // Compatibility aliases pointing to 100% free OpenStreetMap
  static const String darkTileUrl = freeOsmUrl;
  static const String lightTileUrl = freeOsmUrl;

  /// Returns the base directory for offline map tiles
  Future<String> getTileCacheDirectory() async {
    if (_tileCacheDirPath != null) return _tileCacheDirPath!;
    final appDir = await getApplicationDocumentsDirectory();

    // Clean up any legacy cache directories that may contain watermarked CartoDB tiles
    try {
      final legacyDir = Directory('${appDir.path}/offline_map_tiles');
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
      }
      final legacyV2 = Directory('${appDir.path}/offline_map_tiles_v2');
      if (await legacyV2.exists()) {
        await legacyV2.delete(recursive: true);
      }
    } catch (_) {}

    final dir = Directory('${appDir.path}/offline_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tileCacheDirPath = dir.path;
    return _tileCacheDirPath!;
  }

  /// Calculates total offline tile cache size in Megabytes and file count
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final baseDir = await getTileCacheDirectory();
      final dir = Directory(baseDir);
      if (!await dir.exists()) {
        return {'sizeMb': 0.0, 'count': 0};
      }

      int totalBytes = 0;
      int count = 0;

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.png')) {
          totalBytes += await entity.length();
          count++;
        }
      }

      final mb = totalBytes / (1024.0 * 1024.0);
      return {'sizeMb': double.parse(mb.toStringAsFixed(2)), 'count': count};
    } catch (e) {
      debugPrint('[OfflineMapService] Error getting cache stats: $e');
      return {'sizeMb': 0.0, 'count': 0};
    }
  }

  /// Clears all offline cached map tiles
  Future<void> clearCache() async {
    try {
      final baseDir = await getTileCacheDirectory();
      final dir = Directory(baseDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _tileCacheDirPath = null;
      await getTileCacheDirectory();
    } catch (e) {
      debugPrint('[OfflineMapService] Error clearing cache: $e');
    }
  }

  /// Pre-downloads map tiles for a specified geographic radius (e.g. 10 km)
  /// across critical emergency zoom levels (zoom 12 to 15).
  Stream<TileDownloadProgress> downloadRegion({
    required LatLng center,
    double radiusKm = 10.0,
    int minZoom = 12,
    int maxZoom = 15,
    bool isDark = true,
  }) async* {
    yield const TileDownloadProgress(
      downloaded: 0,
      total: 1,
      percentage: 0.0,
      status: 'Preparing tile coordinates for offline area...',
    );

    final baseDir = await getTileCacheDirectory();
    final tileCoords = <Map<String, int>>[];

    // Calculate bounding box in lat/lng
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * math.cos(center.latitude * math.pi / 180.0));

    final minLat = (center.latitude - latDelta).clamp(-85.0511, 85.0511);
    final maxLat = (center.latitude + latDelta).clamp(-85.0511, 85.0511);
    final minLng = (center.longitude - lngDelta).clamp(-180.0, 180.0);
    final maxLng = (center.longitude + lngDelta).clamp(-180.0, 180.0);

    for (int z = minZoom; z <= maxZoom; z++) {
      final minTileX = _lngToTileX(minLng, z);
      final maxTileX = _lngToTileX(maxLng, z);
      final minTileY = _latToTileY(maxLat, z); // Note: tile Y is inverted
      final maxTileY = _latToTileY(minLat, z);

      for (int x = math.min(minTileX, maxTileX); x <= math.max(minTileX, maxTileX); x++) {
        for (int y = math.min(minTileY, maxTileY); y <= math.max(minTileY, maxTileY); y++) {
          tileCoords.add({'z': z, 'x': x, 'y': y});
        }
      }
    }

    final total = tileCoords.length;
    if (total == 0) {
      yield const TileDownloadProgress(
        downloaded: 0,
        total: 0,
        percentage: 1.0,
        status: 'Area already prepared.',
        isCompleted: true,
      );
      return;
    }

    int downloaded = 0;
    final urlTemplate = freeOsmUrl;
    final client = http.Client();

    try {
      const batchSize = 4;
      for (int i = 0; i < tileCoords.length; i += batchSize) {
        final batch = tileCoords.sublist(i, math.min(i + batchSize, tileCoords.length));
        await Future.wait(batch.map((coord) async {
          final z = coord['z']!;
          final x = coord['x']!;
          final y = coord['y']!;

          final filePath = '$baseDir/$z/$x/$y.png';
          final file = File(filePath);

          if (!await file.exists()) {
            final url = urlTemplate
                .replaceAll('{z}', z.toString())
                .replaceAll('{x}', x.toString())
                .replaceAll('{y}', y.toString());

            try {
              final resp = await client.get(
                Uri.parse(url),
                headers: const {
                  'User-Agent':
                      'org.rakshanet.rakshanet_mobile/1.0.0 (Emergency Rescue; support@rakshanet.org)'
                },
              ).timeout(const Duration(seconds: 4));

              if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
                final b = resp.bodyBytes;
                final isPng = b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
                final isJpg = b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
                if (isPng || isJpg) {
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(resp.bodyBytes);
                }
              }
            } catch (_) {}
          }
          downloaded++;
        }));

        final pct = (downloaded / total).clamp(0.0, 1.0);
        yield TileDownloadProgress(
          downloaded: downloaded,
          total: total,
          percentage: pct,
          status: 'Cached $downloaded of $total tiles (${(pct * 100).toInt()}%)...',
        );
      }
    } finally {
      client.close();
    }

    yield TileDownloadProgress(
      downloaded: downloaded,
      total: total,
      percentage: 1.0,
      status: 'Offline map cache complete for ${radiusKm.toInt()} km region!',
      isCompleted: true,
    );
  }

  // ---------------------------------------------------------------------------
  // GEODETIC & TILE MATH HELPERS
  // ---------------------------------------------------------------------------
  static int _lngToTileX(double lng, int zoom) {
    return ((lng + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  /// Haversine distance in meters between two coordinates
  static double distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final latDelta = (b.latitude - a.latitude) * math.pi / 180.0;
    final lonDelta = (b.longitude - a.longitude) * math.pi / 180.0;
    final sinLat = math.sin(latDelta / 2.0);
    final sinLon = math.sin(lonDelta / 2.0);
    final h = sinLat * sinLat +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            sinLon *
            sinLon;
    return earthRadius * 2.0 * math.atan2(math.sqrt(h), math.sqrt(1.0 - h));
  }

  /// Initial compass bearing (azimuth 0 to 360 degrees) from a to b
  static double bearingDegrees(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  /// Formatted cardinal direction (N, NE, E, SE, S, SW, W, NW)
  static String cardinalDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  /// Formats human-readable distance (e.g. "350 m" or "4.2 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000.0).toStringAsFixed(1)} km';
    }
  }

  /// Generates an in-memory 256x256 fallback tactical grid PNG tile
  /// Used when completely offline and tile has not been pre-cached
  Future<Uint8List> getTacticalGridTileBytes({required bool isDark}) async {
    if (_generatedGridTiles.containsKey(isDark)) {
      return _generatedGridTiles[isDark]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 256.0;

    // Background color
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF070D18) : const Color(0xFFF3F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF16243A) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double i = 0; i <= size; i += 32.0) {
      canvas.drawLine(Offset(i, 0), Offset(i, size), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size, i), gridPaint);
    }

    // Corner crosshairs / tick marks
    final crosshairPaint = Paint()
      ..color = isDark ? const Color(0xFF263A56) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(128, 120), const Offset(128, 136), crosshairPaint);
    canvas.drawLine(const Offset(120, 128), const Offset(136, 128), crosshairPaint);

    // Border around each tile
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1A2A42) : const Color(0xFFD8E2EC)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    _generatedGridTiles[isDark] = bytes;
    return bytes;
  }
}

/// Custom Tile Provider for FlutterMap with On-Device Disk Caching & Offline Tactical Fallback
class OfflineFallbackTileProvider extends TileProvider {
  final bool isDark;
  final bool forceOfflineGrid;

  OfflineFallbackTileProvider({
    this.isDark = true,
    this.forceOfflineGrid = false,
  }) : super(headers: <String, String>{
          'User-Agent':
              'RakshaNet-Disaster-Mesh/1.0 (Emergency Rescue; contact: ops@rakshanet.org)',
        });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = options.urlTemplate != null
        ? options.urlTemplate!
            .replaceAll('{z}', coordinates.z.toString())
            .replaceAll('{x}', coordinates.x.toString())
            .replaceAll('{y}', coordinates.y.toString())
        : (isDark ? OfflineMapService.darkTileUrl : OfflineMapService.lightTileUrl)
            .replaceAll('{z}', coordinates.z.toString())
            .replaceAll('{x}', coordinates.x.toString())
            .replaceAll('{y}', coordinates.y.toString());

    return OfflineCachedTileImageProvider(
      url: url,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
      headers: headers,
      isDark: isDark,
      forceOfflineGrid: forceOfflineGrid,
    );
  }
}

/// Custom ImageProvider that checks local disk cache first, downloads if online,
/// and falls back to a clean tactical grid when offline.
class OfflineCachedTileImageProvider
    extends ImageProvider<OfflineCachedTileImageProvider> {
  final String url;
  final int z;
  final int x;
  final int y;
  final Map<String, String> headers;
  final bool isDark;
  final bool forceOfflineGrid;

  const OfflineCachedTileImageProvider({
    required this.url,
    required this.z,
    required this.x,
    required this.y,
    required this.headers,
    required this.isDark,
    required this.forceOfflineGrid,
  });

  @override
  Future<OfflineCachedTileImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<OfflineCachedTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    OfflineCachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: 'OfflineCachedTile_${key.z}_${key.x}_${key.y}',
    );
  }

  Future<ui.Codec> _loadAsync(
    OfflineCachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    // If tactical grid mode forced, return generated grid bytes
    if (key.forceOfflineGrid) {
      final gridBytes =
          await OfflineMapService.instance.getTacticalGridTileBytes(isDark: key.isDark);
      final buffer = await ui.ImmutableBuffer.fromUint8List(gridBytes);
      return decode(buffer);
    }

    try {
      final baseDir = await OfflineMapService.instance.getTileCacheDirectory();
      final localFile = File('$baseDir/${key.z}/${key.x}/${key.y}.png');

      // 1. Check local offline disk cache
      if (await localFile.exists()) {
        final bytes = await localFile.readAsBytes();
        if (bytes.isNotEmpty) {
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          return await decode(buffer);
        }
      }

      // 2. Fetch online if available
      try {
        final response = await http
            .get(Uri.parse(key.url), headers: key.headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final bytes = response.bodyBytes;
          final isPng = bytes.length > 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47;
          final isJpg = bytes.length > 3 &&
              bytes[0] == 0xFF &&
              bytes[1] == 0xD8 &&
              bytes[2] == 0xFF;

          if (isPng || isJpg) {
            // Asynchronously write to local disk cache for future offline access
            unawaited(() async {
              try {
                await localFile.parent.create(recursive: true);
                await localFile.writeAsBytes(bytes);
              } catch (_) {}
            }());

            final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
            return await decode(buffer);
          }
        }
      } catch (_) {
        // Network unavailable or timeout -> fallback to tactical grid
      }
    } catch (_) {}

    // 3. Complete Offline Fallback: Tactical Grid
    final fallbackBytes =
        await OfflineMapService.instance.getTacticalGridTileBytes(isDark: key.isDark);
    final fallbackBuffer = await ui.ImmutableBuffer.fromUint8List(fallbackBytes);
    return await decode(fallbackBuffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineCachedTileImageProvider &&
        other.url == url &&
        other.z == z &&
        other.x == x &&
        other.y == y &&
        other.isDark == isDark &&
        other.forceOfflineGrid == forceOfflineGrid;
  }

  @override
  int get hashCode => Object.hash(url, z, x, y, isDark, forceOfflineGrid);
}
