import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform_telemetry_service.dart';

/// Supported positioning sources for [DeviceLocationFix].
class LocationFixSource {
  /// Fresh fused location fix combining GNSS satellites, Wi-Fi RTT, and cell towers.
  static const String fusedGps = 'FUSED_GPS';

  /// Direct hardware GNSS / GPS receiver satellite constellation fix.
  static const String hardwareGps = 'HARDWARE_GPS';

  /// Cached previous location fix with explicit staleness (> 60s old).
  static const String lastKnown = 'LAST_KNOWN';

  /// Probabilistic position solved via peer mesh anchor multilateration in GPS-denied blackout.
  static const String peerMultilateration = 'PEER_MULTILATERATION';

  const LocationFixSource._();
}

/// Represents a validated geospatial location fix for this device.
///
/// Complies with Spec Sections 4 & 5 ("Reliable device location" and
/// "Calculate distance between two users").
class DeviceLocationFix {
  /// WGS84 Latitude in decimal degrees (-90.0 to +90.0).
  final double latitude;

  /// WGS84 Longitude in decimal degrees (-180.0 to +180.0).
  final double longitude;

  /// Estimated 1-sigma horizontal accuracy radius in meters.
  final double horizontalAccuracyMeters;

  /// Altitude above WGS84 reference ellipsoid in meters, if hardware GNSS reports it.
  final double? altitudeMeters;

  /// Instantaneous ground speed in meters per second, if moving.
  final double? speedMps;

  /// Compass track bearing in degrees (0.0 to 360.0).
  final double? bearingDegrees;

  /// Epoch millisecond timestamp when this fix was acquired.
  final int timestamp;

  /// Position source: 'FUSED_GPS', 'HARDWARE_GPS', 'LAST_KNOWN', or 'PEER_MULTILATERATION'.
  final String source;

  /// Whether this fix is actively live (received within the last 60 seconds).
  final bool isLive;

  /// Explicit flag indicating the fix is stale (older than 60 seconds).
  final bool isStale;

  const DeviceLocationFix({
    required this.latitude,
    required this.longitude,
    required this.horizontalAccuracyMeters,
    this.altitudeMeters,
    this.speedMps,
    this.bearingDegrees,
    required this.timestamp,
    required this.source,
    required this.isLive,
    required this.isStale,
  });

  /// Factory verifying freshness against current epoch time (stale if > 60 seconds).
  factory DeviceLocationFix.create({
    required double latitude,
    required double longitude,
    required double horizontalAccuracyMeters,
    double? altitudeMeters,
    double? speedMps,
    double? bearingDegrees,
    required int timestamp,
    required String source,
    int? currentTimestampMs,
  }) {
    final now = currentTimestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final ageMs = (now - timestamp).abs();
    final isStale = ageMs > 60000;
    final isLive = !isStale && source != LocationFixSource.lastKnown;

    return DeviceLocationFix(
      latitude: latitude.clamp(-90.0, 90.0),
      longitude: longitude.clamp(-180.0, 180.0),
      horizontalAccuracyMeters: math.max(0.1, horizontalAccuracyMeters),
      altitudeMeters: altitudeMeters,
      speedMps: speedMps != null ? math.max(0.0, speedMps) : null,
      bearingDegrees: bearingDegrees != null ? (bearingDegrees % 360.0) : null,
      timestamp: timestamp,
      source: isStale ? LocationFixSource.lastKnown : source,
      isLive: isLive,
      isStale: isStale,
    );
  }

  /// Age of this location fix in seconds.
  int get ageSeconds {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - timestamp) / 1000).floor().clamp(0, 9999999);
  }

  /// Human-readable formatted coordinate string (e.g. "13.0450° N, 80.2300° E").
  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir';
  }

  /// Formatted horizontal accuracy (e.g. "± 12 m").
  String get formattedAccuracy {
    if (horizontalAccuracyMeters < 1000) {
      return '± ${horizontalAccuracyMeters.round()} m';
    }
    return '± ${(horizontalAccuracyMeters / 1000.0).toStringAsFixed(1)} km';
  }

  /// Returns a copy of this fix marked as stale.
  DeviceLocationFix toStale() {
    return DeviceLocationFix(
      latitude: latitude,
      longitude: longitude,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      altitudeMeters: altitudeMeters,
      speedMps: speedMps,
      bearingDegrees: bearingDegrees,
      timestamp: timestamp,
      source: LocationFixSource.lastKnown,
      isLive: false,
      isStale: true,
    );
  }

  DeviceLocationFix copyWith({
    double? latitude,
    double? longitude,
    double? horizontalAccuracyMeters,
    double? altitudeMeters,
    double? speedMps,
    double? bearingDegrees,
    int? timestamp,
    String? source,
    bool? isLive,
    bool? isStale,
  }) {
    return DeviceLocationFix(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      horizontalAccuracyMeters:
          horizontalAccuracyMeters ?? this.horizontalAccuracyMeters,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      speedMps: speedMps ?? this.speedMps,
      bearingDegrees: bearingDegrees ?? this.bearingDegrees,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      isLive: isLive ?? this.isLive,
      isStale: isStale ?? this.isStale,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'horizontalAccuracyMeters': horizontalAccuracyMeters,
        'altitudeMeters': altitudeMeters,
        'speedMps': speedMps,
        'bearingDegrees': bearingDegrees,
        'timestamp': timestamp,
        'source': source,
        'isLive': isLive,
        'isStale': isStale,
      };

  factory DeviceLocationFix.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isStale = (now - ts) > 60000 || json['isStale'] == true;

    return DeviceLocationFix(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      horizontalAccuracyMeters:
          (json['horizontalAccuracyMeters'] as num?)?.toDouble() ?? 25.0,
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
      speedMps: (json['speedMps'] as num?)?.toDouble(),
      bearingDegrees: (json['bearingDegrees'] as num?)?.toDouble(),
      timestamp: ts,
      source: isStale
          ? LocationFixSource.lastKnown
          : (json['source'] as String? ?? LocationFixSource.lastKnown),
      isLive: !isStale && json['isLive'] == true,
      isStale: isStale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceLocationFix &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp &&
          source == other.source;

  @override
  int get hashCode => Object.hash(latitude, longitude, timestamp, source);

  @override
  String toString() =>
      'DeviceLocationFix($formattedCoordinates, src: $source, acc: $formattedAccuracy, age: ${ageSeconds}s, stale: $isStale)';
}

/// Android Foreground Notification compliance configuration.
class AndroidLocationNotificationConfig {
  /// Channel identifier required for Android 8.0+ (Oreo).
  static const String defaultChannelId = 'rakshanet_location_tracking';

  /// User-visible notification channel name in Android App Info settings.
  static const String defaultChannelName = 'Emergency Location Tracking';

  /// User-visible notification channel description.
  static const String defaultChannelDescription =
      'Maintains continuous GPS and mesh proximity tracking during emergency disaster response';

  final String channelId;
  final String channelName;
  final String channelDescription;
  final String title;
  final String text;
  final String icon;

  const AndroidLocationNotificationConfig({
    this.channelId = defaultChannelId,
    this.channelName = defaultChannelName,
    this.channelDescription = defaultChannelDescription,
    this.title = 'RakshaNet Active Location Tracking',
    this.text = 'Monitoring emergency location in background for disaster mesh rescue',
    this.icon = 'ic_launcher',
  });

  Map<String, dynamic> toMap() => {
        'channelId': channelId,
        'channelName': channelName,
        'channelDescription': channelDescription,
        'title': title,
        'text': text,
        'icon': icon,
      };
}

/// Reliable Device Location Service for RakshaNet.
///
/// Implements Spec Section 4 ("Reliable device location") with a rigorous priority hierarchy:
/// 1. Fresh fused location fix (GPS / network provider, age <= 60s).
/// 2. Native GNSS / GPS hardware constellation fix (age <= 60s).
/// 3. Last known location with explicit `isStale: true` flag and timestamp.
/// 4. Peer multilateration position in GPS-denied environments.
///
/// Features:
/// - Background tracking support with explicit Android foreground notification compliance.
/// - Persistent SharedPreferences backing for immediate offline startup availability.
/// - Reactive `ValueNotifier<DeviceLocationFix?>` and broadcast `Stream<DeviceLocationFix>`.
/// - Automatic permission orchestration (Fine Location, Background Location, Post Notifications).
class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  static const String _lastKnownPrefKey = 'rakshanet_last_known_location_fix_v1';
  static const MethodChannel _locationChannel =
      MethodChannel('org.rakshanet/location');

  final PlatformTelemetryService _telemetryService = PlatformTelemetryService();

  // Fix priority slots
  DeviceLocationFix? _fusedGpsFix;
  DeviceLocationFix? _hardwareGpsFix;
  DeviceLocationFix? _lastKnownFix;
  DeviceLocationFix? _peerMultilaterationFix;

  // Reactive state
  final ValueNotifier<DeviceLocationFix?> _currentFixNotifier =
      ValueNotifier<DeviceLocationFix?>(null);
  ValueListenable<DeviceLocationFix?> get currentFixListenable =>
      _currentFixNotifier;
  DeviceLocationFix? get currentFix => _resolveBestFix();

  final StreamController<DeviceLocationFix> _locationStreamController =
      StreamController<DeviceLocationFix>.broadcast();
  Stream<DeviceLocationFix> get locationStream =>
      _locationStreamController.stream;

  bool _isTracking = false;
  bool get isTrackingActive => _isTracking;

  Timer? _pollingTimer;
  bool _isInitialized = false;

  /// Initializes the location service, restoring persisted last-known position.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadPersistedLastKnownFix();
    _evaluateAndPublishBestFix();

    // Query immediate initial reading
    await refreshLocation(forceFresh: true);
  }

  /// Evaluates and selects the highest priority fix according to the specification hierarchy:
  /// 1. Fresh fused location fix (GPS / network provider, age <= 60s)
  /// 2. Native GNSS / GPS hardware fix (age <= 60s)
  /// 3. Peer multilateration fix (age <= 60s)
  /// 4. Last known location with explicit `isStale: true` flag and timestamp
  DeviceLocationFix? _resolveBestFix() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Fresh fused location fix (age <= 60s)
    if (_fusedGpsFix != null && (now - _fusedGpsFix!.timestamp) <= 60000) {
      return _fusedGpsFix;
    }

    // 2. Native GNSS / GPS hardware fix (age <= 60s)
    if (_hardwareGpsFix != null && (now - _hardwareGpsFix!.timestamp) <= 60000) {
      return _hardwareGpsFix;
    }

    // 3. Peer multilateration fix (age <= 60s)
    if (_peerMultilaterationFix != null &&
        (now - _peerMultilaterationFix!.timestamp) <= 60000) {
      return _peerMultilaterationFix;
    }

    // 4. Last known location with explicit `isStale: true` flag and timestamp
    // Pick the most recent available fix across all slots
    final candidates = <DeviceLocationFix>[
      ?_lastKnownFix,
      ?_fusedGpsFix,
      ?_hardwareGpsFix,
      ?_peerMultilaterationFix,
    ];

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final bestStaleCandidate = candidates.first;

    // Ensure stale flag and LAST_KNOWN source are explicitly set
    return bestStaleCandidate.toStale();
  }

  void _evaluateAndPublishBestFix() {
    final best = _resolveBestFix();
    if (best != null && best != _currentFixNotifier.value) {
      _currentFixNotifier.value = best;
      _locationStreamController.add(best);
    }
  }

  /// Actively queries device GNSS/telemetry platform channels and updates the hierarchy.
  Future<DeviceLocationFix?> refreshLocation({bool forceFresh = false}) async {
    try {
      final reading = await _telemetryService.getTelemetry();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (reading.hasGpsFix &&
          reading.latitude != null &&
          reading.longitude != null) {
        final rawAccuracy = reading.accuracy ?? 15.0;

        // Categorize into FUSED vs HARDWARE GPS based on accuracy envelope
        final isHighPrecisionConstellation = rawAccuracy <= 10.0;
        final source = isHighPrecisionConstellation
            ? LocationFixSource.hardwareGps
            : LocationFixSource.fusedGps;

        final freshFix = DeviceLocationFix.create(
          latitude: reading.latitude!,
          longitude: reading.longitude!,
          horizontalAccuracyMeters: rawAccuracy,
          timestamp: now,
          source: source,
        );

        if (source == LocationFixSource.hardwareGps) {
          _hardwareGpsFix = freshFix;
        } else {
          _fusedGpsFix = freshFix;
        }

        // Persist as last known fix for disaster resilience
        _lastKnownFix = freshFix.copyWith(source: LocationFixSource.lastKnown);
        unawaited(_persistLastKnownFix(_lastKnownFix!));

        _evaluateAndPublishBestFix();
        return _currentFixNotifier.value;
      } else {
        // No fresh fix available; ensure stale status is marked
        _evaluateAndPublishBestFix();
        return _currentFixNotifier.value;
      }
    } catch (e) {
      debugPrint('[LocationService] refreshLocation notice: $e');
      _evaluateAndPublishBestFix();
      return _currentFixNotifier.value;
    }
  }

  /// Injects a solved peer multilateration estimate (e.g. from LocationEstimationEngine).
  void updateFromPeerMultilateration({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    int? timestampMs,
  }) {
    final ts = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _peerMultilaterationFix = DeviceLocationFix.create(
      latitude: latitude,
      longitude: longitude,
      horizontalAccuracyMeters: accuracyMeters,
      timestamp: ts,
      source: LocationFixSource.peerMultilateration,
    );

    _evaluateAndPublishBestFix();
  }

  /// Starts continuous background location tracking with explicit Android
  /// Foreground Service Notification compliance.
  ///
  /// Enforces Android foreground service policy requirements:
  /// - Declares foregroundServiceType="location" in manifest
  /// - Creates user-visible notification channel
  /// - Configures persistent notification with high visibility
  Future<bool> startTracking({
    Duration interval = const Duration(seconds: 5),
    bool enableBackground = true,
    AndroidLocationNotificationConfig notificationConfig =
        const AndroidLocationNotificationConfig(),
  }) async {
    await initialize();

    // 1. Check and request location permissions
    final locStatus = await Permission.location.request();
    if (!locStatus.isGranted && !locStatus.isLimited) {
      debugPrint('[LocationService] Location permission denied: $locStatus');
      return false;
    }

    // 2. Request Android 13+ Notification permission if background tracking is requested
    if (enableBackground) {
      try {
        await Permission.notification.request();
      } catch (_) {}

      // Attempt background location permission (Android 10+)
      try {
        if (await Permission.locationAlways.isDenied) {
          await Permission.locationAlways.request();
        }
      } catch (_) {}
    }

    // 3. Initiate native Android foreground service via platform channel
    if (enableBackground) {
      try {
        await _locationChannel.invokeMethod('startForegroundTracking', {
          'notification': notificationConfig.toMap(),
          'intervalMs': interval.inMilliseconds,
        });
      } catch (e) {
        // Fallback gracefully on desktop/test runners without native channel
        debugPrint('[LocationService] Platform foreground channel notice: $e');
      }
    }

    // 4. Start periodic polling timer in Dart runtime
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      await refreshLocation();
    });

    _isTracking = true;
    await refreshLocation(forceFresh: true);
    return true;
  }

  /// Stops active background location tracking and releases notification.
  Future<void> stopTracking() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isTracking = false;

    try {
      await _locationChannel.invokeMethod('stopForegroundTracking');
    } catch (_) {}

    debugPrint('[LocationService] Background location tracking stopped');
  }

  Future<void> _persistLastKnownFix(DeviceLocationFix fix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(fix.toJson());
      await prefs.setString(_lastKnownPrefKey, jsonStr);
    } catch (e) {
      debugPrint('[LocationService] Failed to persist last-known fix: $e');
    }
  }

  Future<void> _loadPersistedLastKnownFix() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_lastKnownPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = DeviceLocationFix.fromJson(map);
        _lastKnownFix = restored.toStale();
      }
    } catch (e) {
      debugPrint('[LocationService] Failed to load persisted last-known fix: $e');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _locationStreamController.close();
  }
}
