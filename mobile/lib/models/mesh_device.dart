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

  factory MeshDevice.fromMap(Map<String, dynamic> map) {
    return MeshDevice(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      displayName: map['display_name'] as String,
      connectionType: ConnectionType.values.firstWhere(
        (c) => c.name == (map['connection_type'] as String? ?? 'ble'),
        orElse: () => ConnectionType.ble,
      ),
      signalStrength: map['signal_strength'] as int? ?? -65,
      proximityBand: ProximityBand.values.firstWhere(
        (p) => p.name == (map['proximity_band'] as String? ?? 'near'),
        orElse: () => ProximityBand.near,
      ),
      hopCount: map['hop_count'] as int? ?? 1,
      batteryLevel: map['battery_level'] as int? ?? 80,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int),
      isConnected: (map['is_connected'] as int? ?? 1) == 1,
    );
  }
}
