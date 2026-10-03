import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Owns the stable, pseudonymous identity used by the local mesh node.
///
/// This is deliberately not a hardware identifier. It survives restarts but can
/// be reset by clearing the app's data, which avoids exposing a phone identity
/// to nearby people.
class DeviceIdentityService {
  DeviceIdentityService._();

  static final DeviceIdentityService instance = DeviceIdentityService._();
  static const _deviceIdKey = 'rakshanet_mesh_device_id';
  static const _displayNameKey = 'rakshanet_mesh_display_name';

  String _deviceId = _newDeviceId();
  String _displayName = 'RakshaNet user';
  bool _initialized = false;

  String get deviceId => _deviceId;
  String get displayName => _displayName;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_deviceIdKey);
    if (_isValidDeviceId(storedId)) {
      _deviceId = storedId!;
    } else {
      _deviceId = _newDeviceId();
      await prefs.setString(_deviceIdKey, _deviceId);
    }

    final storedName = prefs.getString(_displayNameKey)?.trim();
    if (storedName != null && storedName.isNotEmpty) {
      _displayName = storedName;
    }
    _initialized = true;
  }

  Future<void> updateDisplayName(String? name) async {
    await initialize();
    final cleaned = name?.trim() ?? '';
    _displayName = cleaned.isEmpty ? 'RakshaNet user' : cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, _displayName);
  }

  static bool _isValidDeviceId(String? value) =>
      value != null && RegExp(r'^SR-[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(value);

  static String _newDeviceId() {
    const alphabet = '0123456789ABCDEF';
    final random = Random.secure();
    String part() => List.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return 'SR-${part()}-${part()}';
  }
}
