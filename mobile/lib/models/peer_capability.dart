/// Represents peer node hardware & transport capabilities used for intelligent multi-hop routing scoring.
class PeerCapability {
  final String peerId;
  final String deviceId;
  final String transports;
  final int batteryLevel;
  final bool isRelay;
  final bool isInternetGateway;
  final int lastSeen;

  const PeerCapability({
    required this.peerId,
    required this.deviceId,
    this.transports = 'BLE',
    this.batteryLevel = 100,
    this.isRelay = true,
    this.isInternetGateway = false,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'peer_id': peerId,
      'device_id': deviceId,
      'transports': transports,
      'battery_level': batteryLevel,
      'is_relay': isRelay ? 1 : 0,
      'is_internet_gateway': isInternetGateway ? 1 : 0,
      'last_seen': lastSeen,
    };
  }

  factory PeerCapability.fromMap(Map<String, dynamic> map) {
    return PeerCapability(
      peerId: (map['peer_id'] ?? map['peerId'] ?? '') as String,
      deviceId: (map['device_id'] ?? map['deviceId'] ?? '') as String,
      transports: (map['transports'] ?? 'BLE') as String,
      batteryLevel:
          (map['battery_level'] ?? map['batteryLevel'] as num?)?.toInt() ?? 100,
      isRelay:
          (map['is_relay'] ?? map['isRelay']) == 1 ||
          (map['is_relay'] ?? map['isRelay']) == true,
      isInternetGateway:
          (map['is_internet_gateway'] ?? map['isInternetGateway']) == 1 ||
          (map['is_internet_gateway'] ?? map['isInternetGateway']) == true,
      lastSeen:
          (map['last_seen'] ?? map['lastSeen'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Routing score: prefer peers with higher battery, known route, and internet gateway
  double get routingScore {
    double score = 0.0;
    // 1. Internet gateway bonus (highest priority for multi-hop reaching command center)
    if (isInternetGateway) score += 50.0;
    // 2. Active relay capability
    if (isRelay) score += 20.0;
    // 3. Battery level contribution (up to 30.0 points)
    score += batteryLevel.clamp(0, 100) * 0.3;
    // 4. Freshness bonus if seen in last 60 seconds
    final ageMs = DateTime.now().millisecondsSinceEpoch - lastSeen;
    if (ageMs >= 0 && ageMs < 60000) score += 10.0;
    return score;
  }
}
