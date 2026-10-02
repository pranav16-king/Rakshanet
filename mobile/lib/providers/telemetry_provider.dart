import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';

class TelemetryProvider extends ChangeNotifier {
  TelemetryModel _telemetry = TelemetryModel(
    meshCount: 12,
    batteryLevel: 85,
    isOnline: false, // Disconnected from internet
    hasGpsFix: true,
  );

  TelemetryModel get telemetry => _telemetry;
  int get meshCount => _telemetry.meshCount;
  int get batteryLevel => _telemetry.batteryLevel;
  bool get isOnline => _telemetry.isOnline;
  bool get hasGpsFix => _telemetry.hasGpsFix;
  bool get showOfflineBanner => !_telemetry.isOnline;
  RadioScanProfile get radioScanProfile => _telemetry.radioScanProfile;

  void setBattery(int level) {
    _telemetry = _telemetry.copyWith(batteryLevel: level);
    notifyListeners();
  }

  void setMeshCount(int count) {
    _telemetry = _telemetry.copyWith(meshCount: count);
    notifyListeners();
  }

  void setOnline(bool online) {
    _telemetry = _telemetry.copyWith(isOnline: online);
    notifyListeners();
  }

  void setGpsFix(bool fix) {
    _telemetry = _telemetry.copyWith(hasGpsFix: fix);
    notifyListeners();
  }
}
