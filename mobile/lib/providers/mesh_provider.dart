import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/mesh_device.dart';
import '../database/app_database.dart';
import '../services/bluetooth_radio_service.dart';
import '../services/database_service.dart';

enum RadioMode {
  normal,
  lowPower,
  emergency,
}

class MeshProvider extends ChangeNotifier {
  final BluetoothRadioService _radioService = BluetoothRadioService();
  StreamSubscription<List<MeshDevice>>? _peerSubscription;

  int _connectedPeerCount = 12; // Matches mockup Screen 3 & Screen 13
  RadioMode _radioMode = RadioMode.normal;
  bool _isScanning = false;
  bool _isMeshActive = true;
  Timer? _scanTimer;

  final List<MeshDevice> _nearbyDevices = [];
  final List<MeshDevice> _physicalPeers = [];

  int get connectedPeerCount => _connectedPeerCount;
  RadioMode get radioMode => _radioMode;
  bool get isScanning => _isScanning;
  bool get isMeshActive => _isMeshActive;
  List<MeshDevice> get nearbyDevices => List.unmodifiable(_nearbyDevices);
  List<MeshDevice> get physicalPeers => List.unmodifiable(_physicalPeers);

  String get radioModeLabel {
    switch (_radioMode) {
      case RadioMode.normal:
        return 'Normal (Balanced)';
      case RadioMode.lowPower:
        return 'Low Power (Battery Saver)';
      case RadioMode.emergency:
        return 'Emergency (High Frequency)';
    }
  }

  MeshProvider() {
    _seedInitialDevices();
    _initRadioListener();
  }

  void _initRadioListener() {
    _peerSubscription = _radioService.peerUpdateStream.listen((realPeers) {
      _onPhysicalPeersUpdated(realPeers);
    });
  }

  void _onPhysicalPeersUpdated(List<MeshDevice> realPeers) {
    _physicalPeers.clear();
    _physicalPeers.addAll(realPeers);

    if (realPeers.isNotEmpty) {
      // Real physical peers take priority at the top of the nearby radar
      for (final peer in realPeers) {
        final existingIdx = _nearbyDevices.indexWhere((d) => d.id == peer.id);
        if (existingIdx >= 0) {
          _nearbyDevices[existingIdx] = peer;
        } else {
          _nearbyDevices.insert(0, peer);
        }
        AppDatabase.instance.saveNearbyDevice(peer);
      }
      _connectedPeerCount = realPeers.length;
    } else {
      _connectedPeerCount = _nearbyDevices.length;
    }

    notifyListeners();
  }

  void _seedInitialDevices() {
    final now = DateTime.now();
    _nearbyDevices.addAll([
      MeshDevice(
        id: 'dev-1',
        deviceId: 'SR-7B1A',
        displayName: 'Priya (Near School)',
        signalStrength: -62,
        proximityBand: ProximityBand.immediate,
        hopCount: 1,
        batteryLevel: 85,
        lastSeen: now.subtract(const Duration(seconds: 40)),
      ),
      MeshDevice(
        id: 'dev-2',
        deviceId: 'SR-3E9C',
        displayName: 'Rahul (Bridge Road)',
        signalStrength: -74,
        proximityBand: ProximityBand.near,
        hopCount: 1,
        batteryLevel: 68,
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
      MeshDevice(
        id: 'dev-3',
        deviceId: 'SR-9A2F',
        displayName: 'Relief Camp Gateway',
        signalStrength: -80,
        proximityBand: ProximityBand.near,
        hopCount: 2,
        batteryLevel: 95,
        lastSeen: now.subtract(const Duration(minutes: 1)),
      ),
      MeshDevice(
        id: 'dev-4',
        deviceId: 'SR-4D21',
        displayName: 'Medical Team Van #2',
        signalStrength: -89,
        proximityBand: ProximityBand.far,
        hopCount: 2,
        batteryLevel: 72,
        lastSeen: now.subtract(const Duration(minutes: 3)),
      ),
      MeshDevice(
        id: 'dev-5',
        deviceId: 'SR-108B',
        displayName: 'Community Center Node',
        signalStrength: -68,
        proximityBand: ProximityBand.near,
        hopCount: 1,
        batteryLevel: 90,
        lastSeen: now.subtract(const Duration(seconds: 15)),
      ),
    ]);
  }

  void setRadioMode(RadioMode mode) {
    if (_radioMode == mode) return;
    _radioMode = mode;
    notifyListeners();
  }

  void toggleMesh(bool active) {
    _isMeshActive = active;
    if (!active && _isScanning) {
      stopScan();
    }
    notifyListeners();
  }

  void setConnectedPeerCount(int count) {
    _connectedPeerCount = count;
    notifyListeners();
  }

  void startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    // Trigger physical Bluetooth radio scanning
    try {
      await _radioService.startDiscovery(
        deviceId: DatabaseService.myDeviceId,
        displayName: DatabaseService.myDisplayName,
      );
    } catch (e) {
      debugPrint('[MeshProvider] Physical scan error: $e');
    }

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 5), () {
      _isScanning = false;
      notifyListeners();
    });
  }

  void stopScan() {
    _scanTimer?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  void addOrUpdateDevice(MeshDevice device) {
    final index = _nearbyDevices.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      _nearbyDevices[index] = device;
    } else {
      _nearbyDevices.add(device);
    }
    _connectedPeerCount = _nearbyDevices.length;
    notifyListeners();
    AppDatabase.instance.saveNearbyDevice(device);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _peerSubscription?.cancel();
    super.dispose();
  }
}
