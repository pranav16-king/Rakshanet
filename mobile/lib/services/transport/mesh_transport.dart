import 'dart:typed_data';

/// The communication medium or network channel used for peer-to-peer data transfer.
enum TransportType {
  ble,
  wifiDirect,
  wifiAware,
  internetGateway,
}

/// Information about a discovered or connected peer node in the mesh network.
class PeerInfo {
  final String peerId;
  final String deviceId;
  final String displayName;
  final Set<TransportType> supportedTransports;
  final int batteryLevel;
  final bool isRelay;
  final bool isInternetGateway;
  final int rssi;
  final DateTime lastSeen;

  const PeerInfo({
    required this.peerId,
    required this.deviceId,
    required this.displayName,
    this.supportedTransports = const {TransportType.ble},
    this.batteryLevel = 100,
    this.isRelay = true,
    this.isInternetGateway = false,
    this.rssi = -60,
    required this.lastSeen,
  });

  /// Check whether this peer supports a specific transport type.
  bool supports(TransportType transport) =>
      supportedTransports.contains(transport);

  /// Check if the peer was seen recently (within last 120 seconds).
  bool get isOnline =>
      DateTime.now().difference(lastSeen).inSeconds < 120;

  PeerInfo copyWith({
    String? peerId,
    String? deviceId,
    String? displayName,
    Set<TransportType>? supportedTransports,
    int? batteryLevel,
    bool? isRelay,
    bool? isInternetGateway,
    int? rssi,
    DateTime? lastSeen,
  }) {
    return PeerInfo(
      peerId: peerId ?? this.peerId,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      supportedTransports: supportedTransports ?? this.supportedTransports,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isRelay: isRelay ?? this.isRelay,
      isInternetGateway: isInternetGateway ?? this.isInternetGateway,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'peer_id': peerId,
      'device_id': deviceId,
      'display_name': displayName,
      'supported_transports':
          supportedTransports.map((t) => t.name).toList(),
      'battery_level': batteryLevel,
      'is_relay': isRelay,
      'is_internet_gateway': isInternetGateway,
      'rssi': rssi,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
  }

  factory PeerInfo.fromMap(Map<String, dynamic> map) {
    final rawTransports = map['supported_transports'];
    final Set<TransportType> transports = {};
    if (rawTransports is Iterable) {
      for (final item in rawTransports) {
        for (final t in TransportType.values) {
          if (t.name == item.toString()) {
            transports.add(t);
            break;
          }
        }
      }
    }
    if (transports.isEmpty) {
      transports.add(TransportType.ble);
    }

    final rawLastSeen = map['last_seen'];
    final DateTime parsedLastSeen = (rawLastSeen is int)
        ? DateTime.fromMillisecondsSinceEpoch(rawLastSeen)
        : (rawLastSeen is String)
            ? DateTime.tryParse(rawLastSeen) ?? DateTime.now()
            : DateTime.now();

    return PeerInfo(
      peerId: map['peer_id']?.toString() ?? '',
      deviceId: map['device_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      supportedTransports: transports,
      batteryLevel: (map['battery_level'] as num?)?.toInt() ?? 100,
      isRelay: map['is_relay'] == true || map['is_relay'] == 1,
      isInternetGateway: map['is_internet_gateway'] == true ||
          map['is_internet_gateway'] == 1,
      rssi: (map['rssi'] as num?)?.toInt() ?? -60,
      lastSeen: parsedLastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerInfo &&
          runtimeType == other.runtimeType &&
          peerId == other.peerId &&
          deviceId == other.deviceId;

  @override
  int get hashCode => peerId.hashCode ^ deviceId.hashCode;

  @override
  String toString() {
    return 'PeerInfo(peerId: $peerId, deviceId: $deviceId, name: $displayName, transports: $supportedTransports, gateway: $isInternetGateway, rssi: $rssi dBm)';
  }
}

/// A data packet received over a specific physical mesh transport.
class TransportPacket {
  final Uint8List rawBytes;
  final String sourcePeerId;
  final TransportType transportType;
  final DateTime timestamp;

  const TransportPacket({
    required this.rawBytes,
    required this.sourcePeerId,
    required this.transportType,
    required this.timestamp,
  });

  int get byteLength => rawBytes.length;

  TransportPacket copyWith({
    Uint8List? rawBytes,
    String? sourcePeerId,
    TransportType? transportType,
    DateTime? timestamp,
  }) {
    return TransportPacket(
      rawBytes: rawBytes ?? this.rawBytes,
      sourcePeerId: sourcePeerId ?? this.sourcePeerId,
      transportType: transportType ?? this.transportType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source_peer_id': sourcePeerId,
      'transport_type': transportType.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'byte_length': rawBytes.length,
    };
  }

  @override
  String toString() {
    return 'TransportPacket(from: $sourcePeerId, type: ${transportType.name}, bytes: ${rawBytes.length}, time: $timestamp)';
  }
}

/// Abstract contract for peer-to-peer physical/logical mesh transport layers.
abstract class MeshTransport {
  /// The transport protocol type implemented by this transport.
  TransportType get type;

  /// Whether the transport hardware/service is currently available and active.
  bool get isAvailable;

  /// Starts scanning/discovering neighboring peers.
  Future<void> startDiscovery();

  /// Stops peer discovery.
  Future<void> stopDiscovery();

  /// Sends a data packet to a specific peer endpoint.
  Future<bool> send(String peerId, Uint8List data);

  /// Broadcasts a data packet to all connected peers.
  Future<int> broadcast(Uint8List data);

  /// Stream emitting newly discovered or updated peers.
  Stream<PeerInfo> get discoveredPeers;

  /// Stream emitting incoming raw transport packets.
  Stream<TransportPacket> get receivedPackets;

  /// Disposes resources, subscriptions, and active radio operations.
  Future<void> dispose();
}
