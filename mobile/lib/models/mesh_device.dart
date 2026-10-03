import 'nearby_device.dart';

enum ProximityBand {
  immediate,
  near,
  far,
}

enum ConnectionType {
  ble,
  wifiDirect,
}

class MeshDevice {
  final String id;
  final String deviceId;
  final String displayName;
  final ConnectionType connectionType;
  final int signalStrength; // RSSI dBm
  final ProximityBand proximityBand;
  final int hopCount;
  final int batteryLevel;
  final DateTime lastSeen;
  final bool isConnected;

  const MeshDevice({
    required this.id,
    required this.deviceId,
    required this.displayName,
    this.connectionType = ConnectionType.ble,
    required this.signalStrength,
    this.proximityBand = ProximityBand.near,
    this.hopCount = 1,
    this.batteryLevel = 80,
    required this.lastSeen,
    this.isConnected = true,
  });

  String get proximityDisplay {
    switch (proximityBand) {
      case ProximityBand.immediate:
        return 'about 5 m';
      case ProximityBand.near:
        return 'about 15 m';
      case ProximityBand.far:
        return 'about 40 m';
    }
  }

  MeshDevice copyWith({
    String? id,
    String? deviceId,
    String? displayName,
    ConnectionType? connectionType,
    int? signalStrength,
    ProximityBand? proximityBand,
    int? hopCount,
    int? batteryLevel,
    DateTime? lastSeen,
    bool? isConnected,
  }) {
    return MeshDevice(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      connectionType: connectionType ?? this.connectionType,
      signalStrength: signalStrength ?? this.signalStrength,
      proximityBand: proximityBand ?? this.proximityBand,
      hopCount: hopCount ?? this.hopCount,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'display_name': displayName,
      'connection_type': connectionType.name,
      'signal_strength': signalStrength,
      'proximity_band': proximityBand.name,
      'hop_count': hopCount,
      'battery_level': batteryLevel,
      'last_seen': lastSeen.millisecondsSinceEpoch,
      'is_connected': isConnected ? 1 : 0,
    };
  }

  NearbyDevice toNearbyDevice() {
    return NearbyDevice(
      deviceId: deviceId,
      displayName: displayName,
      connectionType: connectionType == ConnectionType.wifiDirect ? 'WIFI_DIRECT' : 'BLE',
      rssi: signalStrength,
      proximityBand: proximityBand.name.toUpperCase(),
      lastSeen: lastSeen,
      isConnected: isConnected,
      hopCount: hopCount,
      batteryLevel: batteryLevel,
    );
  }

  factory MeshDevice.fromNearbyDevice(NearbyDevice nd) {
    ProximityBand band = ProximityBand.near;
    final pb = nd.proximityBand.toUpperCase();
    if (pb == 'IMMEDIATE') {
      band = ProximityBand.immediate;
    } else if (pb == 'FAR') {
      band = ProximityBand.far;
    }

    return MeshDevice(
      id: nd.deviceId,
      deviceId: nd.deviceId,
      displayName: nd.displayName,
      connectionType: nd.connectionType.toUpperCase().contains('WIFI')
          ? ConnectionType.wifiDirect
          : ConnectionType.ble,
      signalStrength: nd.rssi,
      proximityBand: band,
      hopCount: nd.hopCount,
      batteryLevel: nd.batteryLevel ?? 80,
      lastSeen: nd.lastSeen,
      isConnected: nd.isConnected,
    );
  }

  factory MeshDevice.fromMap(Map<String, dynamic> map) {
    final devId = (map['device_id'] ?? map['deviceId'] ?? map['id'] ?? '').toString();
    final dispName = (map['display_name'] ?? map['displayName'] ?? 'Peer').toString();
    final connTypeStr = (map['connection_type'] ?? map['connectionType'] ?? 'ble').toString().toLowerCase();
    final connType = connTypeStr.contains('wifi') ? ConnectionType.wifiDirect : ConnectionType.ble;
    final rssi = map['signal_strength'] is int
        ? map['signal_strength'] as int
        : (map['rssi'] is int
            ? map['rssi'] as int
            : int.tryParse(map['rssi']?.toString() ?? '-65') ?? -65);
    final proxStr = (map['proximity_band'] ?? map['proximityBand'] ?? 'near').toString().toLowerCase();
    final prox = proxStr.contains('immediate')
        ? ProximityBand.immediate
        : (proxStr.contains('far') ? ProximityBand.far : ProximityBand.near);
    final hops = map['hop_count'] is int
        ? map['hop_count'] as int
        : (int.tryParse(map['hopCount']?.toString() ?? '1') ?? 1);
    final bat = map['battery_level'] is int
        ? map['battery_level'] as int
        : (int.tryParse(map['batteryLevel']?.toString() ?? '80') ?? 80);
    DateTime seen = DateTime.now();
    if (map['last_seen'] is int) {
      seen = DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int);
    } else if (map['last_seen'] != null) {
      seen = DateTime.tryParse(map['last_seen'].toString()) ?? DateTime.now();
    }
    final conn = map['is_connected'] == 1 || map['is_connected'] == true;

    return MeshDevice(
      id: (map['id'] ?? devId).toString(),
      deviceId: devId,
      displayName: dispName,
      connectionType: connType,
      signalStrength: rssi,
      proximityBand: prox,
      hopCount: hops,
      batteryLevel: bat,
      lastSeen: seen,
      isConnected: conn,
    );
  }
}
