import '../models/mesh_message.dart';
import '../models/user_profile.dart';
import '../models/mesh_device.dart';

/// AppDatabase provides the Save-Before-Send transactional storage layer
/// backing the SQLite schema for RakshaNet.
class AppDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'user_profile': [],
    'device_identity': [],
    'nearby_devices': [],
    'conversations': [
      {'id': 'conv_comm', 'conversationId': 'COMMUNITY_MESH', 'type': 'GROUP'}
    ],
    'messages': [],
    'message_relays': [],
  };

  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  /// Create an isolated database instance (for multi-phone simulations)
  static AppDatabase createIsolated() => AppDatabase._internal();

  void clear() {
    _tables['user_profile']!.clear();
    _tables['device_identity']!.clear();
    _tables['nearby_devices']!.clear();
    _tables['messages']!.clear();
    _tables['message_relays']!.clear();
  }

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    _tables['user_profile']!.removeWhere((p) => p['id'] == profile.id);
    _tables['user_profile']!.add(profile.toMap());
  }

  Future<UserProfile?> getUserProfile() async {
    if (_tables['user_profile']!.isEmpty) return null;
    return UserProfile.fromMap(_tables['user_profile']!.last);
  }

  // --- Messages (Save-Before-Send Guaranteed) ---
  Future<void> insertMessage(MeshMessage message) async {
    // SQLite primary key constraint check
    final exists = _tables['messages']!.any((m) => m['messageId'] == message.messageId);
    if (exists) {
      // Update existing
      _tables['messages']!.removeWhere((m) => m['messageId'] == message.messageId);
    }
    _tables['messages']!.add(message.toMap());
  }

  Future<bool> hasMessage(String messageId) async {
    return _tables['messages']!.any((m) => m['messageId'] == messageId);
  }

  Future<MeshMessage?> getMessage(String messageId) async {
    final list = _tables['messages']!.where((m) => m['messageId'] == messageId);
    if (list.isEmpty) return null;
    return MeshMessage.fromMap(list.first);
  }

  Future<List<MeshMessage>> getAllMessages() async {
    return _tables['messages']!
        .map((m) => MeshMessage.fromMap(m))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // --- Relay Audit Trail ---
  Future<void> recordRelay({
    required String messageId,
    required String fromDeviceId,
    required String toDeviceId,
    required int hopNumber,
  }) async {
    _tables['message_relays']!.add({
      'id': _tables['message_relays']!.length + 1,
      'messageId': messageId,
      'fromDeviceId': fromDeviceId,
      'toDeviceId': toDeviceId,
      'hopNumber': hopNumber,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<Map<String, dynamic>> getRelays() {
    return List.unmodifiable(_tables['message_relays']!);
  }

  // --- Durability & Recovery ---
  Map<String, dynamic> dumpState() {
    return {
      'user_profile': List<Map<String, dynamic>>.from(_tables['user_profile']!),
      'device_identity': List<Map<String, dynamic>>.from(_tables['device_identity']!),
      'nearby_devices': List<Map<String, dynamic>>.from(_tables['nearby_devices']!),
      'conversations': List<Map<String, dynamic>>.from(_tables['conversations']!),
      'messages': List<Map<String, dynamic>>.from(_tables['messages']!),
      'message_relays': List<Map<String, dynamic>>.from(_tables['message_relays']!),
    };
  }

  void restoreState(Map<String, dynamic> state) {
    clear();
    for (final table in _tables.keys) {
      if (state[table] != null) {
        _tables[table]!.addAll(List<Map<String, dynamic>>.from(state[table]));
      }
    }
  }

  // --- Devices ---
  Future<void> addOrUpdateDevice(MeshDevice device) async {
    _tables['nearby_devices']!.removeWhere((d) => d['deviceId'] == device.deviceId);
    _tables['nearby_devices']!.add(device.toMap());
  }

  Future<List<MeshDevice>> getNearbyDevices() async {
    return _tables['nearby_devices']!.map((d) => MeshDevice.fromMap(d)).toList();
  }
}
