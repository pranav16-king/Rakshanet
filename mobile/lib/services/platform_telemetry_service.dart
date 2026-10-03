import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware sensor telemetry reading acquired from actual device sensors / platform channels
class TelemetryReading {
  final int batteryLevel; // 0..100 percentage, or 0 if uninitialized / unknown
  final bool isOnline;
  final bool hasGpsFix;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  const TelemetryReading({
    required this.batteryLevel,
    required this.isOnline,
    required this.hasGpsFix,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  static const TelemetryReading empty = TelemetryReading(
    batteryLevel: 0,
    isOnline: false,
    hasGpsFix: false,
    latitude: null,
    longitude: null,
    accuracy: null,
  );
}

/// Service bridging hardware sensors and platform channels for telemetry data
class PlatformTelemetryService {
  static const MethodChannel _channel = MethodChannel('org.rakshanet/telemetry');
  static final PlatformTelemetryService _instance = PlatformTelemetryService._internal();

  factory PlatformTelemetryService() => _instance;
  PlatformTelemetryService._internal();

  /// Queries native Android BatteryManager, ConnectivityManager, and LocationManager
  Future<TelemetryReading> getTelemetry() async {
    try {
      final res = await _channel.invokeMethod<Map>('getTelemetry');
      if (res == null) return TelemetryReading.empty;

      final rawBattery = res['batteryLevel'];
      final battery = rawBattery is int
          ? (rawBattery < 0 ? 0 : rawBattery.clamp(0, 100))
          : (int.tryParse(rawBattery?.toString() ?? '0') ?? 0).clamp(0, 100);

      final online = res['isOnline'] == true;
      final rawGpsFix = res['hasGpsFix'] == true;
      final lat = res['latitude'] is num ? (res['latitude'] as num).toDouble() : null;
      final lng = res['longitude'] is num ? (res['longitude'] as num).toDouble() : null;
      final acc = res['accuracy'] is num ? (res['accuracy'] as num).toDouble() : null;

      // Never return fake coordinates. If GPS is not fixed or coordinates null, accurately report hasGpsFix = false
      final actualGpsFix = rawGpsFix && lat != null && lng != null;

      return TelemetryReading(
        batteryLevel: battery,
        isOnline: online,
        hasGpsFix: actualGpsFix,
        latitude: actualGpsFix ? lat : null,
        longitude: actualGpsFix ? lng : null,
        accuracy: actualGpsFix ? acc : null,
      );
    } catch (e) {
      // In tests, desktop runner, or before platform channels respond:
      // Return accurate empty / no-fix telemetry (never hardcoded fake numbers)
      debugPrint('[PlatformTelemetryService] Platform channel query: $e');
      return TelemetryReading.empty;
    }
  }

  /// Queries device hardware battery percentage directly
  Future<int> getBatteryLevel() async {
    try {
      final res = await _channel.invokeMethod<int>('getBatteryLevel');
      if (res == null || res < 0) return 0;
      return res.clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  /// Queries active cellular/Wi-Fi route validity
  Future<bool> isOnline() async {
    try {
      final res = await _channel.invokeMethod<bool>('isOnline');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Queries GPS hardware fix
  Future<Map<String, dynamic>> getGpsStatus() async {
    try {
      final res = await _channel.invokeMethod<Map>('getGpsStatus');
      if (res == null) {
        return {'hasGpsFix': false, 'latitude': null, 'longitude': null};
      }
      final hasFix = res['hasGpsFix'] == true;
      final lat = res['latitude'] is num ? (res['latitude'] as num).toDouble() : null;
      final lng = res['longitude'] is num ? (res['longitude'] as num).toDouble() : null;
      return {
        'hasGpsFix': hasFix && lat != null && lng != null,
        'latitude': (hasFix && lat != null && lng != null) ? lat : null,
        'longitude': (hasFix && lat != null && lng != null) ? lng : null,
        'accuracy': res['accuracy'],
      };
    } catch (_) {
      return {'hasGpsFix': false, 'latitude': null, 'longitude': null};
    }
  }
}
