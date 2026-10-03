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

  // Real initial states: 0 peers initially, mesh active, scanning for neighbors
  int _connectedPeerCount = 0;
  RadioMode _radioMode = RadioMode.normal;
  bool _isScanning = true;
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
    _initRadioListener();
    _loadStoredPeers();
    if (_isMeshActive) {
      startScan();
    }
  }

  void _initRadioListener() {
    _peerSubscription = _radioService.peerUpdateStream.listen((realPeers) {
      _onPhysicalPeersUpdated(realPeers);
    });
  }

  /// Load previously discovered real peers from SQLite `nearby_devices` on startup
  Future<void> _loadStoredPeers() async {
    try {
      final storedDevices = await AppDatabase.instance.getNearbyDevices();
      if (storedDevices.isNotEmpty) {
        _nearbyDevices.clear();
        for (final d in storedDevices) {
          _nearbyDevices.add(MeshDevice.fromNearbyDevice(d));
        }
        // Physical peers take priority if already connected
        _connectedPeerCount = _physicalPeers.isNotEmpty
            ? _physicalPeers.length
            : _nearbyDevices.where((d) => d.isConnected).length;
      } else {
        // Empty state: no peers yet
        _connectedPeerCount = 0;
        _isScanning = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[MeshProvider] Error loading stored peers from SQLite: $e');
    }
  }

  /// When BluetoothRadioService discovers or disconnects real devices via BLE / Nearby
  void _onPhysicalPeersUpdated(List<MeshDevice> realPeers) {
    _physicalPeers.clear();
    _physicalPeers.addAll(realPeers);

    if (realPeers.isNotEmpty) {
      // Real physical peers take priority at the top of the nearby radar
      for (final peer in realPeers) {
        final existingIdx = _nearbyDevices.indexWhere(
          (d) => d.deviceId == peer.deviceId || d.id == peer.id,
        );
        if (existingIdx >= 0) {
          _nearbyDevices[existingIdx] = peer;
        } else {
          _nearbyDevices.insert(0, peer);
        }
        // Persist real discovered peer to SQLite
        AppDatabase.instance.saveNearbyDevice(peer);
      }
      _connectedPeerCount = realPeers.length;
    } else {
      // Mark physical peers as disconnected in stored nearby list
      for (int i = 0; i < _nearbyDevices.length; i++) {
        if (_nearbyDevices[i].isConnected) {
          _nearbyDevices[i] = _nearbyDevices[i].copyWith(isConnected: false);
          AppDatabase.instance.saveNearbyDevice(_nearbyDevices[i]);
        }
      }
      _connectedPeerCount = 0;
      if (_nearbyDevices.isEmpty) {
        // Empty state: mesh active, 0 peers, scanning
        _isScanning = true;
      }
    }

    notifyListeners();
  }

  void setRadioMode(RadioMode mode) {
    if (_radioMode == mode) return;
    _radioMode = mode;
    notifyListeners();
  }

  void toggleMesh(bool active) {
    _isMeshActive = active;
    if (!active) {
      if (_isScanning) stopScan();
    } else {
      startScan();
    }
    notifyListeners();
  }

  void setConnectedPeerCount(int count) {
    _connectedPeerCount = count;
    notifyListeners();
  }

  void startScan() async {
    _isScanning = true;
    notifyListeners();

    // Trigger physical Bluetooth radio - both advertise AND discover
    try {
      await _radioService.initialize(
        deviceId: DatabaseService.myDeviceId,
        displayName: DatabaseService.myDisplayName,
      );
    } catch (e) {
      debugPrint('[MeshProvider] Physical scan+advertise error: $e');
    }

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 15), () {
      // Maintain isScanning = true if no peers are found to represent active empty state
      if (_nearbyDevices.isEmpty && _physicalPeers.isEmpty) {
        _isScanning = true;
      } else {
        _isScanning = false;
      }
      notifyListeners();
    });
  }

  void stopScan() {
    _scanTimer?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  void addOrUpdateDevice(MeshDevice device) {
    final index = _nearbyDevices.indexWhere(
      (d) => d.id == device.id || d.deviceId == device.deviceId,
    );
    if (index >= 0) {
      _nearbyDevices[index] = device;
    } else {
      _nearbyDevices.add(device);
    }
    _connectedPeerCount = _physicalPeers.isNotEmpty
        ? _physicalPeers.length
        : _nearbyDevices.where((d) => d.isConnected).length;
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
