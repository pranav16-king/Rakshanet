import 'package:flutter/foundation.dart';

class DeviceStatusProvider extends ChangeNotifier {
  int _meshDevicesCount = 12;
  bool _isInternetAvailable = false;
  bool _isGpsAvailable = false;
  int _batteryLevel = 68;
  bool _isLowPowerMode = false;

  int get meshDevicesCount => _meshDevicesCount;
  bool get isInternetAvailable => _isInternetAvailable;
  bool get isGpsAvailable => _isGpsAvailable;
  int get batteryLevel => _batteryLevel;
  bool get isLowPowerMode => _isLowPowerMode;

  void updateMeshCount(int count) {
    _meshDevicesCount = count;
    notifyListeners();
  }

  void setInternetAvailable(bool available) {
    _isInternetAvailable = available;
    notifyListeners();
  }

  void setGpsAvailable(bool available) {
    _isGpsAvailable = available;
    notifyListeners();
  }

  void updateBattery(int level) {
    _batteryLevel = level;
    notifyListeners();
  }

  void toggleLowPowerMode(bool enable) {
    _isLowPowerMode = enable;
    notifyListeners();
  }
}
