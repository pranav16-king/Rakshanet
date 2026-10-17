import 'dart:math' as math;

/// Offline map sector / region model for SignalRescue AI / RakshaNet
class OfflineMapRegion {
  final String id;
  final String name;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final int minZoom;
  final int maxZoom;
  final int totalTiles;
  final int downloadedTiles;
  final int sizeBytes;
  final String status; // PENDING, DOWNLOADING, COMPLETED, PAUSED, FAILED
  final int? downloadedAt;
  final String? filePath;

  const OfflineMapRegion({
    required this.id,
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.minZoom,
    required this.maxZoom,
    required this.totalTiles,
    required this.downloadedTiles,
    this.sizeBytes = 0,
    required this.status,
    this.downloadedAt,
    this.filePath,
  });

  double get progress =>
      totalTiles > 0 ? (downloadedTiles / totalTiles).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == 'COMPLETED';
  bool get isDownloading => status == 'DOWNLOADING';
  bool get isPaused => status == 'PAUSED';
  bool get isFailed => status == 'FAILED';
  bool get isPending => status == 'PENDING';

  double get sizeMb => sizeBytes / (1024.0 * 1024.0);

  double get centerLat => (minLat + maxLat) / 2.0;
  double get centerLng => (minLng + maxLng) / 2.0;

  bool containsCoordinate(double lat, double lng) {
    final latMin = math.min(minLat, maxLat);
    final latMax = math.max(minLat, maxLat);
    final lngMin = math.min(minLng, maxLng);
    final lngMax = math.max(minLng, maxLng);

    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
  }

  OfflineMapRegion copyWith({
    String? id,
    String? name,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
    int? minZoom,
    int? maxZoom,
    int? totalTiles,
    int? downloadedTiles,
    int? sizeBytes,
    String? status,
    int? downloadedAt,
    String? filePath,
  }) {
    return OfflineMapRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      minLat: minLat ?? this.minLat,
      maxLat: maxLat ?? this.maxLat,
      minLng: minLng ?? this.minLng,
      maxLng: maxLng ?? this.maxLng,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      totalTiles: totalTiles ?? this.totalTiles,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lng': minLng,
      'max_lng': maxLng,
      'min_zoom': minZoom,
      'max_zoom': maxZoom,
      'total_tiles': totalTiles,
      'downloaded_tiles': downloadedTiles,
      'size_bytes': sizeBytes,
      'status': status,
      'downloaded_at': downloadedAt,
      'file_path': filePath,
    };
  }

  factory OfflineMapRegion.fromMap(Map<String, dynamic> map) {
    return OfflineMapRegion(
      id: map['id'] as String,
      name: map['name'] as String,
      minLat: (map['min_lat'] as num).toDouble(),
      maxLat: (map['max_lat'] as num).toDouble(),
      minLng: (map['min_lng'] as num).toDouble(),
      maxLng: (map['max_lng'] as num).toDouble(),
      minZoom: (map['min_zoom'] as num).toInt(),
      maxZoom: (map['max_zoom'] as num).toInt(),
      totalTiles: (map['total_tiles'] as num).toInt(),
      downloadedTiles: (map['downloaded_tiles'] as num).toInt(),
      sizeBytes: (map['size_bytes'] as num?)?.toInt() ?? 0,
      status: map['status'] as String,
      downloadedAt: (map['downloaded_at'] as num?)?.toInt(),
      filePath: map['file_path'] as String?,
    );
  }
}
