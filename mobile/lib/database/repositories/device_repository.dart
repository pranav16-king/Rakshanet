import 'package:sqflite/sqflite.dart';

import '../../models/nearby_device.dart';
import '../app_database.dart';

/// Repository handling BLE & Wi-Fi Direct discovered peer devices
class DeviceRepository {
  final AppDatabase _db;
  static const String _tableName = 'nearby_devices';

  DeviceRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Retrieve all discovered mesh devices ordered by last seen timestamp
  Future<List<NearbyDevice>> getNearbyDevices() async {
    final rows = await _db.query(
      _tableName,
      orderBy: 'last_seen DESC',
    );
    return rows.map((r) => NearbyDevice.fromMap(r)).toList();
  }

  /// Retrieve a specific device by its hardware / mesh device ID
  Future<NearbyDevice?> getDeviceById(String deviceId) async {
    final rows = await _db.query(
      _tableName,
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NearbyDevice.fromMap(rows.first);
  }

  /// Upsert a device discovered via BLE advertisement or Wi-Fi Direct probe
  Future<void> upsertDevice(NearbyDevice device) async {
    await _db.insert(
      _tableName,
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update connection status or signal telemetry
  Future<void> updateDeviceStatus(
    String deviceId, {
    bool? isConnected,
    int? rssi,
    DateTime? lastSeen,
    int? batteryLevel,
  }) async {
    final values = <String, dynamic>{};
    if (isConnected != null) values['is_connected'] = isConnected ? 1 : 0;
    if (rssi != null) {
      values['rssi'] = rssi;
      values['proximity_band'] = NearbyDevice.calculateBand(rssi);
    }
    if (lastSeen != null) values['last_seen'] = lastSeen.millisecondsSinceEpoch;
    if (batteryLevel != null) values['battery_level'] = batteryLevel;

    if (values.isEmpty) return;

    await _db.update(
      _tableName,
      values,
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Prune or mark offline devices that haven't responded within the threshold
  Future<void> removeStaleDevices(Duration staleThreshold) async {
    final cutoff = DateTime.now().subtract(staleThreshold).millisecondsSinceEpoch;
    // Set is_connected to 0 for devices not seen recently
    await _db.update(
      _tableName,
      {'is_connected': 0},
      where: 'last_seen < ?',
      whereArgs: [cutoff],
    );
  }

  /// Get count of actively connected peer devices
  Future<int> getConnectedCount() async {
    final rows = await _db.query(
      _tableName,
      where: 'is_connected = ?',
      whereArgs: [1],
    );
    return rows.length;
  }

  /// Clear all stored nearby devices
  Future<void> clearAll() async {
    await _db.delete(_tableName);
  }
}
