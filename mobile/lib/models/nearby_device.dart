/// Mesh Discovered Nearby Device
class NearbyDevice {
  final String deviceId;
  final String displayName;
  final String connectionType; // 'BLE', 'WIFI_DIRECT'
  final int rssi; // dBm e.g. -65
  final String proximityBand; // 'IMMEDIATE', 'NEAR', 'FAR'
  final DateTime lastSeen;
  final bool isConnected;
  final int hopCount;
  final int? batteryLevel; // 0 - 100 percentage

  const NearbyDevice({
    required this.deviceId,
    required this.displayName,
    required this.connectionType,
    required this.rssi,
    required this.proximityBand,
    required this.lastSeen,
    this.isConnected = false,
    this.hopCount = 1,
    this.batteryLevel,
  });

  NearbyDevice copyWith({
    String? deviceId,
    String? displayName,
    String? connectionType,
    int? rssi,
    String? proximityBand,
    DateTime? lastSeen,
    bool? isConnected,
    int? hopCount,
    int? batteryLevel,
  }) {
    return NearbyDevice(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      connectionType: connectionType ?? this.connectionType,
      rssi: rssi ?? this.rssi,
      proximityBand: proximityBand ?? this.proximityBand,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      hopCount: hopCount ?? this.hopCount,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'display_name': displayName,
      'connection_type': connectionType,
      'rssi': rssi,
      'proximity_band': proximityBand,
      'last_seen': lastSeen.millisecondsSinceEpoch,
      'is_connected': isConnected ? 1 : 0,
      'hop_count': hopCount,
      'battery_level': batteryLevel,
    };
  }

  factory NearbyDevice.fromMap(Map<String, dynamic> map) {
    return NearbyDevice(
      deviceId: map['device_id']?.toString() ?? map['deviceId']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? map['displayName']?.toString() ?? 'Unknown Device',
      connectionType: map['connection_type']?.toString() ?? map['connectionType']?.toString() ?? 'BLE',
      rssi: map['rssi'] is int
          ? map['rssi'] as int
          : (map['signal_strength'] is int
              ? map['signal_strength'] as int
              : int.tryParse(map['rssi']?.toString() ?? '-90') ?? -90),
      proximityBand: map['proximity_band']?.toString() ?? map['proximityBand']?.toString() ?? 'NEAR',
      lastSeen: map['last_seen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int)
          : (map['lastSeen'] != null
              ? (map['lastSeen'] is DateTime ? map['lastSeen'] as DateTime : DateTime.tryParse(map['lastSeen'].toString()) ?? DateTime.now())
              : DateTime.now()),
      isConnected: (map['is_connected'] == 1 || map['is_connected'] == true || map['isConnected'] == true),
      hopCount: map['hop_count'] is int
          ? map['hop_count'] as int
          : int.tryParse(map['hopCount']?.toString() ?? '1') ?? 1,
      batteryLevel: map['battery_level'] is int
          ? map['battery_level'] as int
          : (map['batteryLevel'] is int ? map['batteryLevel'] as int : int.tryParse(map['batteryLevel']?.toString() ?? '')),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory NearbyDevice.fromJson(Map<String, dynamic> json) => NearbyDevice.fromMap(json);

  /// Helper to calculate proximity band from RSSI if needed
  static String calculateBand(int rssi) {
    if (rssi >= -60) return 'IMMEDIATE';
    if (rssi >= -80) return 'NEAR';
    return 'FAR';
  }
}
