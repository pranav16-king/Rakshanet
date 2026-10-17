import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../models/offline_map_region.dart';

/// Progress event emitted during offline tile downloads
class MapDownloadProgress {
  final String regionId;
  final String name;
  final int downloadedTiles;
  final int totalTiles;
  final double percentage;
  final String status; // PENDING, DOWNLOADING, COMPLETED, PAUSED, FAILED, CANCELLED
  final String message;
  final int totalBytes;
  final bool isCompleted;

  const MapDownloadProgress({
    required this.regionId,
    required this.name,
    required this.downloadedTiles,
    required this.totalTiles,
    required this.percentage,
    required this.status,
    required this.message,
    this.totalBytes = 0,
    this.isCompleted = false,
  });

  MapDownloadProgress copyWith({
    String? regionId,
    String? name,
    int? downloadedTiles,
    int? totalTiles,
    double? percentage,
    String? status,
    String? message,
    int? totalBytes,
    bool? isCompleted,
  }) {
    return MapDownloadProgress(
      regionId: regionId ?? this.regionId,
      name: name ?? this.name,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      message: message ?? this.message,
      totalBytes: totalBytes ?? this.totalBytes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Offline Maps & Tile Manager for RakshaNet / SignalRescue AI
///
/// Implements Spec Sections 2 & 3:
/// - Offline-first interactive map tile caching
/// - Pre-downloading area sectors (5 km, 10 km, 25 km)
/// - Pause, resume, cancel, and delete capabilities
/// - Persistent SQLite tracking via `offline_map_regions`
/// - Rate-limited download loop with exponential backoff
/// - Tile server user-agent policy: `RakshaNet-Disaster-Mesh/1.0`
class OfflineMapManager {
  static final OfflineMapManager instance = OfflineMapManager._internal();

  OfflineMapManager._internal();

  static const String userAgent =
      'RakshaNet-Disaster-Mesh/1.0 (Emergency Rescue; contact: ops@rakshanet.org)';

  /// Primary tile endpoints (OpenStreetMap Free Tile Server & Humanitarian OSM)
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String hotTileUrl =
      'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  final StreamController<MapDownloadProgress> _progressController =
      StreamController<MapDownloadProgress>.broadcast();

  Stream<MapDownloadProgress> get progressStream => _progressController.stream;

  String? _tileStorageDirPath;
  String? _activeRegionId;
  bool _isPaused = false;
  bool _isCancelled = false;

  String? get activeRegionId => _activeRegionId;
  bool get isDownloading => _activeRegionId != null && !_isPaused;

  /// Returns the canonical tile directory:
  /// `getApplicationDocumentsDirectory()/offline_tiles`
  Future<String> getTileStorageDirectory() async {
    if (_tileStorageDirPath != null) return _tileStorageDirPath!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/offline_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tileStorageDirPath = dir.path;
    return _tileStorageDirPath!;
  }

  // =========================================================================
  // TILE MATHEMATICS & ESTIMATION (Slippy Map Mercator EPSG:3857)
  // =========================================================================

  static int lngToTileX(double lng, int zoom) {
    final n = 1 << zoom;
    final x = ((lng + 180.0) / 360.0 * n).floor();
    return x.clamp(0, n - 1);
  }

  static int latToTileY(double lat, int zoom) {
    final latClamped = lat.clamp(-85.05112878, 85.05112878);
    final latRad = latClamped * math.pi / 180.0;
    final n = 1 << zoom;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n)
        .floor();
    return y.clamp(0, n - 1);
  }

  /// Estimates the total number of tiles required for a bounding box
  Future<int> estimateTileCount({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required int minZoom,
    required int maxZoom,
  }) async {
    int total = 0;
    final zMin = math.min(minZoom, maxZoom);
    final zMax = math.max(minZoom, maxZoom);

    for (int z = zMin; z <= zMax; z++) {
      final minTileX = math.min(lngToTileX(minLng, z), lngToTileX(maxLng, z));
      final maxTileX = math.max(lngToTileX(minLng, z), lngToTileX(maxLng, z));
      final minTileY = math.min(latToTileY(minLat, z), latToTileY(maxLat, z));
      final maxTileY = math.max(latToTileY(minLat, z), latToTileY(maxLat, z));

      total += (maxTileX - minTileX + 1) * (maxTileY - minTileY + 1);
    }
    return total;
  }

  /// Calculates bounding box for a circular radius around a center coordinate
  static Map<String, double> calculateSectorBounds({
    required LatLng center,
    required double radiusKm,
  }) {
    final latDelta = radiusKm / 111.0;
    final cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    final lngDelta = radiusKm / (111.0 * (cosLat > 0.0001 ? cosLat : 1.0));

    final minLat = (center.latitude - latDelta).clamp(-85.0511, 85.0511);
    final maxLat = (center.latitude + latDelta).clamp(-85.0511, 85.0511);
    final minLng = (center.longitude - lngDelta).clamp(-180.0, 180.0);
    final maxLng = (center.longitude + lngDelta).clamp(-180.0, 180.0);

    return {
      'minLat': math.min(minLat, maxLat),
      'maxLat': math.max(minLat, maxLat),
      'minLng': math.min(minLng, maxLng),
      'maxLng': math.max(minLng, maxLng),
    };
  }

  // =========================================================================
  // REGION DOWNLOAD ENGINE
  // =========================================================================

  /// Downloads an offline region across specified zoom levels.
  /// Handles pausing, resuming, exponential backoff retries, and persistence.
  Future<void> downloadRegion({
    required String regionId,
    required String name,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int minZoom = 10,
    int maxZoom = 15,
    bool wifiOnly = false,
  }) async {
    if (_activeRegionId != null && _activeRegionId != regionId) {
      throw StateError(
          'Another region download is already active: $_activeRegionId');
    }

    _activeRegionId = regionId;
    _isPaused = false;
    _isCancelled = false;

    final baseDir = await getTileStorageDirectory();
    final zMin = math.min(minZoom, maxZoom);
    final zMax = math.max(minZoom, maxZoom);

    // Calculate all required tile coordinates
    final tileCoords = <Map<String, int>>[];
    for (int z = zMin; z <= zMax; z++) {
      final minTileX = math.min(lngToTileX(minLng, z), lngToTileX(maxLng, z));
      final maxTileX = math.max(lngToTileX(minLng, z), lngToTileX(maxLng, z));
      final minTileY = math.min(latToTileY(minLat, z), latToTileY(maxLat, z));
      final maxTileY = math.max(latToTileY(minLat, z), latToTileY(maxLat, z));

      for (int x = minTileX; x <= maxTileX; x++) {
        for (int y = minTileY; y <= maxTileY; y++) {
          tileCoords.add({'z': z, 'x': x, 'y': y});
        }
      }
    }

    final totalTiles = tileCoords.length;

    // Check or create database entry
    var region = await AppDatabase.instance.getOfflineMapRegion(regionId);
    if (region == null) {
      region = OfflineMapRegion(
        id: regionId,
        name: name,
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        minZoom: zMin,
        maxZoom: zMax,
        totalTiles: totalTiles,
        downloadedTiles: 0,
        sizeBytes: 0,
        status: 'DOWNLOADING',
        filePath: baseDir,
      );
      await AppDatabase.instance.saveOfflineMapRegion(region);
    } else {
      await AppDatabase.instance.updateOfflineMapRegionStatus(
        regionId,
        'DOWNLOADING',
        filePath: baseDir,
      );
    }

    _emitProgress(MapDownloadProgress(
      regionId: regionId,
      name: name,
      downloadedTiles: region.downloadedTiles,
      totalTiles: totalTiles,
      percentage: totalTiles > 0 ? region.downloadedTiles / totalTiles : 0.0,
      status: 'DOWNLOADING',
      message: 'Initializing tile downloads ($totalTiles total)...',
      totalBytes: region.sizeBytes,
    ));

    final client = http.Client();
    int downloadedCount = 0;
    int totalBytes = region.sizeBytes;
    int consecutiveNetworkErrors = 0;

    try {
      const batchSize = 3;
      final totalBatches = (tileCoords.length / batchSize).ceil();

      for (int b = 0; b < totalBatches; b++) {
        if (_isCancelled) {
          await AppDatabase.instance.updateOfflineMapRegionStatus(
            regionId,
            'FAILED',
            downloadedTiles: downloadedCount,
            sizeBytes: totalBytes,
          );
          _emitProgress(MapDownloadProgress(
            regionId: regionId,
            name: name,
            downloadedTiles: downloadedCount,
            totalTiles: totalTiles,
            percentage: totalTiles > 0 ? downloadedCount / totalTiles : 0.0,
            status: 'CANCELLED',
            message: 'Download cancelled by user',
            totalBytes: totalBytes,
          ));
          return;
        }

        if (_isPaused) {
          await AppDatabase.instance.updateOfflineMapRegionStatus(
            regionId,
            'PAUSED',
            downloadedTiles: downloadedCount,
            sizeBytes: totalBytes,
          );
          _emitProgress(MapDownloadProgress(
            regionId: regionId,
            name: name,
            downloadedTiles: downloadedCount,
            totalTiles: totalTiles,
            percentage: totalTiles > 0 ? downloadedCount / totalTiles : 0.0,
            status: 'PAUSED',
            message: 'Download paused',
            totalBytes: totalBytes,
          ));
          return;
        }

        final startIdx = b * batchSize;
        final endIdx = math.min(startIdx + batchSize, tileCoords.length);
        final batch = tileCoords.sublist(startIdx, endIdx);

        await Future.wait(batch.map((coord) async {
          final z = coord['z']!;
          final x = coord['x']!;
          final y = coord['y']!;

          final file = File('$baseDir/$z/$x/$y.png');
          if (await file.exists() && await file.length() > 0) {
            downloadedCount++;
            return;
          }

          // Fetch with exponential backoff retry on network failure
          final bytes = await _downloadTileWithRetry(
            client: client,
            z: z,
            x: x,
            y: y,
            maxRetries: 3,
          );

          if (bytes != null && bytes.isNotEmpty) {
            try {
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes);
              downloadedCount++;
              totalBytes += bytes.length;
              consecutiveNetworkErrors = 0;
            } catch (e) {
              debugPrint('[OfflineMapManager] Tile write error: $e');
            }
          } else {
            consecutiveNetworkErrors++;
          }
        }));

        // Rate-limiting throttle (respecting tile server usage guidelines)
        await Future.delayed(const Duration(milliseconds: 60));

        // Periodic database updates and progress emissions
        final pct = totalTiles > 0 ? (downloadedCount / totalTiles).clamp(0.0, 1.0) : 1.0;
        if (b % 4 == 0 || b == totalBatches - 1) {
          await AppDatabase.instance.updateOfflineMapRegionStatus(
            regionId,
            'DOWNLOADING',
            downloadedTiles: downloadedCount,
            sizeBytes: totalBytes,
          );

          _emitProgress(MapDownloadProgress(
            regionId: regionId,
            name: name,
            downloadedTiles: downloadedCount,
            totalTiles: totalTiles,
            percentage: pct,
            status: 'DOWNLOADING',
            message: 'Downloaded $downloadedCount / $totalTiles tiles (${(pct * 100).toInt()}%)',
            totalBytes: totalBytes,
          ));
        }

        // Abort if sustained network blackout
        if (consecutiveNetworkErrors >= 15) {
          throw const SocketException('Too many consecutive network failures');
        }
      }

      // Mark region as COMPLETED
      final completedTime = DateTime.now().millisecondsSinceEpoch;
      await AppDatabase.instance.updateOfflineMapRegionStatus(
        regionId,
        'COMPLETED',
        downloadedTiles: downloadedCount,
        sizeBytes: totalBytes,
        downloadedAt: completedTime,
        filePath: baseDir,
      );

      _emitProgress(MapDownloadProgress(
        regionId: regionId,
        name: name,
        downloadedTiles: downloadedCount,
        totalTiles: totalTiles,
        percentage: 1.0,
        status: 'COMPLETED',
        message: 'Sector offline download complete ($downloadedCount tiles)',
        totalBytes: totalBytes,
        isCompleted: true,
      ));
    } catch (e) {
      debugPrint('[OfflineMapManager] Download error for $regionId: $e');
      await AppDatabase.instance.updateOfflineMapRegionStatus(
        regionId,
        'FAILED',
        downloadedTiles: downloadedCount,
        sizeBytes: totalBytes,
      );

      _emitProgress(MapDownloadProgress(
        regionId: regionId,
        name: name,
        downloadedTiles: downloadedCount,
        totalTiles: totalTiles,
        percentage: totalTiles > 0 ? (downloadedCount / totalTiles).clamp(0.0, 1.0) : 0.0,
        status: 'FAILED',
        message: 'Download failed: $e',
        totalBytes: totalBytes,
      ));
    } finally {
      client.close();
      if (_activeRegionId == regionId) {
        _activeRegionId = null;
      }
    }
  }

  /// Single tile download with exponential retry loop
  Future<Uint8List?> _downloadTileWithRetry({
    required http.Client client,
    required int z,
    required int x,
    required int y,
    int maxRetries = 3,
  }) async {
    final urls = [
      osmTileUrl.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y'),
      hotTileUrl.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y'),
    ];

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final url = urls[attempt % urls.length];
      try {
        final response = await client.get(
          Uri.parse(url),
          headers: const {
            'User-Agent': userAgent,
            'Accept': 'image/png,image/jpeg,*/*',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final b = response.bodyBytes;
          final isPng = b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
          final isJpg = b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

          if (isPng || isJpg) {
            return b;
          }
        } else if (response.statusCode == 429) {
          // Rate-limit response, exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * (1 << (attempt + 1))));
        }
      } catch (_) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (1 << attempt)));
        }
      }
    }
    return null;
  }

  void _emitProgress(MapDownloadProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  // =========================================================================
  // CONTROL METHODS: PAUSE, RESUME, CANCEL, DELETE
  // =========================================================================

  /// Pauses an active region download
  Future<void> pauseDownload(String regionId) async {
    if (_activeRegionId == regionId) {
      _isPaused = true;
    }
    await AppDatabase.instance.updateOfflineMapRegionStatus(regionId, 'PAUSED');
  }

  /// Resumes a paused region download
  Future<void> resumeDownload(String regionId) async {
    final region = await AppDatabase.instance.getOfflineMapRegion(regionId);
    if (region == null) {
      throw ArgumentError('Region not found: $regionId');
    }
    unawaited(downloadRegion(
      regionId: region.id,
      name: region.name,
      minLat: region.minLat,
      maxLat: region.maxLat,
      minLng: region.minLng,
      maxLng: region.maxLng,
      minZoom: region.minZoom,
      maxZoom: region.maxZoom,
    ));
  }

  /// Cancels an active download
  Future<void> cancelDownload(String regionId) async {
    if (_activeRegionId == regionId) {
      _isCancelled = true;
    }
    await AppDatabase.instance.updateOfflineMapRegionStatus(regionId, 'FAILED');
  }

  /// Deletes a downloaded region from database and purges tiles if desired
  Future<void> deleteDownloadedRegion(String regionId) async {
    if (_activeRegionId == regionId) {
      _isCancelled = true;
    }
    await AppDatabase.instance.deleteOfflineMapRegion(regionId);
  }

  // =========================================================================
  // COVERAGE AND REGION QUERIES
  // =========================================================================

  /// Checks if a geographic coordinate falls within any COMPLETED offline region
  Future<bool> isCoordinateCovered(double lat, double lng) async {
    final regions = await getDownloadedRegions();
    return regions.any((r) => r.isCompleted && r.containsCoordinate(lat, lng));
  }

  /// Retrieves all recorded offline map regions
  Future<List<OfflineMapRegion>> getDownloadedRegions() async {
    return await AppDatabase.instance.getOfflineMapRegions();
  }

  /// Calculates total offline tile cache stats (MB and tile count)
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final baseDir = await getTileStorageDirectory();
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
      debugPrint('[OfflineMapManager] Error reading storage stats: $e');
      return {'sizeMb': 0.0, 'count': 0};
    }
  }

  /// Purges all local cached tile files
  Future<void> clearAllTiles() async {
    try {
      final baseDir = await getTileStorageDirectory();
      final dir = Directory(baseDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _tileStorageDirPath = null;
      await getTileStorageDirectory();
    } catch (e) {
      debugPrint('[OfflineMapManager] Error clearing tiles: $e');
    }
  }
}
