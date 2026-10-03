import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/platform_telemetry_service.dart';

class DeviceStatusProvider extends ChangeNotifier {
  final PlatformTelemetryService _telemetryService;
  Timer? _refreshTimer;

  // Real initial states: 0 peers, 0 battery until sensor reading, no internet, no GPS fix
  int _meshDevicesCount = 0;
  bool _isInternetAvailable = false;
  bool _isGpsAvailable = false;
  int _batteryLevel = 0;
  bool _isLowPowerMode = false;
  double? _latitude;
  double? _longitude;

  int get meshDevicesCount => _meshDevicesCount;
  bool get isInternetAvailable => _isInternetAvailable;
  bool get isGpsAvailable => _isGpsAvailable;
  bool get hasGpsFix => _isGpsAvailable;
  int get batteryLevel => _batteryLevel;
  bool get isLowPowerMode => _isLowPowerMode;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  DeviceStatusProvider({PlatformTelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? PlatformTelemetryService() {
    _initAndRefresh();
  }

  void _initAndRefresh() {
    refreshStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      refreshStatus();
    });
  }

  /// Poll real device sensors / platform channels for status
  Future<void> refreshStatus() async {
    try {
      final reading = await _telemetryService.getTelemetry();
      _batteryLevel = reading.batteryLevel;
      _isInternetAvailable = reading.isOnline;
      _isGpsAvailable = reading.hasGpsFix;
      _latitude = reading.latitude;
      _longitude = reading.longitude;
      _isLowPowerMode = _batteryLevel > 0 && _batteryLevel < 20;
      notifyListeners();
    } catch (e) {
      debugPrint('[DeviceStatusProvider] Error reading telemetry: $e');
    }
  }

  void updateMeshCount(int count) {
    if (_meshDevicesCount == count) return;
    _meshDevicesCount = count;
    notifyListeners();
  }

  void setInternetAvailable(bool available) {
    if (_isInternetAvailable == available) return;
    _isInternetAvailable = available;
    notifyListeners();
  }

  void setGpsAvailable(bool available) {
    if (_isGpsAvailable == available) return;
    _isGpsAvailable = available;
    if (!available) {
      _latitude = null;
      _longitude = null;
    }
    notifyListeners();
  }

  void setCoordinates({required double? latitude, required double? longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    _isGpsAvailable = latitude != null && longitude != null;
    notifyListeners();
  }

  void updateBattery(int level) {
    if (_batteryLevel == level) return;
    _batteryLevel = level;
    _isLowPowerMode = level > 0 && level < 20;
    notifyListeners();
  }

  void toggleLowPowerMode(bool enable) {
    if (_isLowPowerMode == enable) return;
    _isLowPowerMode = enable;
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
