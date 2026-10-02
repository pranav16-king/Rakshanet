import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_profile.dart';
import '../app_database.dart';

/// Repository handling local User Profile storage
class ProfileRepository {
  final AppDatabase _db;
  static const String _tableName = 'user_profile';

  ProfileRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Fetch active user profile from local database
  Future<UserProfile?> getProfile() async {
    final rows = await _db.query(
      _tableName,
      limit: 1,
      orderBy: 'updated_at DESC',
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  /// Check whether civilian profile has completed onboarding registration
  Future<bool> isRegistered() async {
    final profile = await getProfile();
    return profile != null && profile.isRegistered;
  }

  /// Save or replace user profile
  Future<void> saveProfile(UserProfile profile) async {
    await _db.insert(
      _tableName,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update existing profile attributes
  Future<void> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _db.update(
      _tableName,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete current profile (e.g. factory reset)
  Future<void> clearProfile() async {
    await _db.delete(_tableName);
  }

  /// Retrieve existing deviceId or generate a unique ID
  Future<String> getOrCreateDeviceId() async {
    final profile = await getProfile();
    if (profile != null && profile.deviceId.isNotEmpty) {
      return profile.deviceId;
    }
    // Generate format: SR-XXXX-XXXX
    final fullUuid = const Uuid().v4().toUpperCase().replaceAll('-', '');
    return 'SR-${fullUuid.substring(0, 4)}-${fullUuid.substring(4, 8)}';
  }
}
