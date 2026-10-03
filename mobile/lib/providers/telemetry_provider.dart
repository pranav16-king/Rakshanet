import 'dart:async';
import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';
import '../services/platform_telemetry_service.dart';

class TelemetryProvider extends ChangeNotifier {
  final PlatformTelemetryService _telemetryService;
  Timer? _refreshTimer;

  // Real initial states: 0 peers, 0 battery until sensor reading, no internet, no GPS fix
  TelemetryModel _telemetry = TelemetryModel(
    meshCount: 0,
    batteryLevel: 0,
    isOnline: false,
    hasGpsFix: false,
  );
  double? _latitude;
  double? _longitude;

  TelemetryModel get telemetry => _telemetry;
  int get meshCount => _telemetry.meshCount;
  int get batteryLevel => _telemetry.batteryLevel;
  bool get isOnline => _telemetry.isOnline;
  bool get hasGpsFix => _telemetry.hasGpsFix;
  bool get showOfflineBanner => !_telemetry.isOnline;
  RadioScanProfile get radioScanProfile => _telemetry.radioScanProfile;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  TelemetryProvider({PlatformTelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? PlatformTelemetryService() {
    _initAndRefresh();
  }

  void _initAndRefresh() {
    refreshTelemetry();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      refreshTelemetry();
    });
  }

  /// Query actual device sensors / platform channels
  Future<void> refreshTelemetry() async {
    try {
      final reading = await _telemetryService.getTelemetry();
      _latitude = reading.latitude;
      _longitude = reading.longitude;
      _telemetry = _telemetry.copyWith(
        batteryLevel: reading.batteryLevel,
        isOnline: reading.isOnline,
        hasGpsFix: reading.hasGpsFix,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[TelemetryProvider] Error fetching telemetry: $e');
    }
  }

  void setBattery(int level) {
    if (_telemetry.batteryLevel == level) return;
    _telemetry = _telemetry.copyWith(batteryLevel: level);
    notifyListeners();
  }

  void setMeshCount(int count) {
    if (_telemetry.meshCount == count) return;
    _telemetry = _telemetry.copyWith(meshCount: count);
    notifyListeners();
  }

  void setOnline(bool online) {
    if (_telemetry.isOnline == online) return;
    _telemetry = _telemetry.copyWith(isOnline: online);
    notifyListeners();
  }

  void setGpsFix(bool fix) {
    if (_telemetry.hasGpsFix == fix) return;
    _telemetry = _telemetry.copyWith(hasGpsFix: fix);
    if (!fix) {
      _latitude = null;
      _longitude = null;
    }
    notifyListeners();
  }

  void setGpsCoordinates({required double? latitude, required double? longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    final fix = latitude != null && longitude != null;
    _telemetry = _telemetry.copyWith(hasGpsFix: fix);
    notifyListeners();
  }

  void stopPolling() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
