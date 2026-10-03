import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/user_profile.dart';
import 'device_identity_service.dart';

/// UserAuthService – email-as-key identity with offline-first login.
///
/// Flow:
///  1. checkOfflineLoginAvailable() → returns true if this device has a
///     stored email and a local profile row matching it.
///  2. loginWithEmail() → looks up local SQLite first (works offline),
///     then attempts a background cloud fetch.
///  3. On successful login the state is persisted so the next cold-start
///     can bypass the setup screen without any network.
class UserAuthService extends ChangeNotifier {
  static final UserAuthService instance = UserAuthService._();
  UserAuthService._();

  static const String _baseUrl = 'http://localhost:8000';
  static const String _prefEmailKey = 'rakshanet_user_email';
  static const String _prefLoggedInKey = 'rakshanet_logged_in';
  static const Duration _networkTimeout = Duration(seconds: 5);

  String? _currentEmail;
  bool _isLoggedIn = false;
  bool _isSyncing = false;

  String? get currentEmail => _currentEmail;
  bool get isLoggedIn => _isLoggedIn;
  bool get isSyncing => _isSyncing;

  // ──────────────────────────────────────────────
  // Offline gate
  // ──────────────────────────────────────────────

  /// Call from SplashScreen: returns true when a prior login exists in
  /// SharedPreferences AND a matching profile row lives in SQLite.
  Future<bool> checkOfflineLoginAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_prefEmailKey);
      final loggedIn = prefs.getBool(_prefLoggedInKey) ?? false;
      if (!loggedIn || email == null || email.isEmpty) return false;

      final profile = await _getLocalProfileByEmail(email);
      if (profile != null) {
        _currentEmail = email;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[UserAuthService] checkOfflineLoginAvailable error: $e');
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────

  /// Primary login entry-point. Works fully offline using SQLite.
  /// [name] and [phone] are only needed when creating a brand-new profile.
  Future<UserProfile?> loginWithEmail(
    String email, {
    String? name,
    String? phone,
    String? bloodGroup,
    String? language,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    // 1 ─ Local SQLite (works offline)
    final localProfile = await _getLocalProfileByEmail(cleanEmail);
    if (localProfile != null) {
      _currentEmail = cleanEmail;
      _isLoggedIn = true;
      await _persistLoginState(cleanEmail);
      notifyListeners();
      // Background cloud pull (non-blocking — does not fail offline login)
      _syncFromCloud(cleanEmail).ignore();
      return localProfile;
    }

    // 2 ─ Cloud lookup (requires network)
    try {
      final cloudProfile = await _fetchFromCloud(cleanEmail);
      if (cloudProfile != null) {
        await AppDatabase.instance.saveUserProfile(cloudProfile);
        _currentEmail = cleanEmail;
        _isLoggedIn = true;
        await _persistLoginState(cleanEmail);
        notifyListeners();
        return cloudProfile;
      }
    } catch (e) {
      debugPrint('[UserAuthService] Cloud lookup failed (will work offline): $e');
    }

    // 3 ─ Create new profile (first-time registration)
    if (name != null && name.trim().isNotEmpty) {
      return _createNewProfile(
        email: cleanEmail,
        name: name.trim(),
        phone: phone ?? '',
        bloodGroup: bloodGroup,
        language: language,
      );
    }

    return null;
  }

  Future<UserProfile> _createNewProfile({
    required String email,
    required String name,
    required String phone,
    String? bloodGroup,
    String? language,
  }) async {
    await DeviceIdentityService.instance.initialize();
    final deviceId = DeviceIdentityService.instance.deviceId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final profile = UserProfile(
      id: email, // email IS the primary key
      email: email,
      name: name,
      deviceId: deviceId,
      emergencyContact: phone,
      bloodGroup: bloodGroup ?? '',
      language: language ?? 'en',
      isRegistered: true,
      createdAt: now,
      updatedAt: now,
    );

    await AppDatabase.instance.saveUserProfile(profile);
    _currentEmail = email;
    _isLoggedIn = true;
    await _persistLoginState(email);
    notifyListeners();

    // Best-effort cloud push (non-blocking)
    _pushToCloud(profile).ignore();

    return profile;
  }

  // ──────────────────────────────────────────────
  // Cloud sync (opportunistic, always non-blocking)
  // ──────────────────────────────────────────────

  /// Manually trigger a sync from the cloud (e.g. when connectivity returns).
  Future<void> syncNow() async {
    if (_currentEmail == null || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await _syncFromCloud(_currentEmail!);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromCloud(String email) async {
    final cloudProfile = await _fetchFromCloud(email);
    if (cloudProfile != null) {
      await AppDatabase.instance.saveUserProfile(cloudProfile);
      debugPrint('[UserAuthService] Profile synced from cloud for $email');
    }
  }

  Future<UserProfile?> _fetchFromCloud(String email) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/v1/users/by-email?email=${Uri.encodeComponent(email)}',
      );
      final response = await HttpClient()
          .getUrl(uri)
          .then((req) => req.close())
          .timeout(_networkTimeout);
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('[UserAuthService] _fetchFromCloud: $e');
    }
    return null;
  }

  Future<void> _pushToCloud(UserProfile profile) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/users');
      final client = HttpClient();
      final req = await client.postUrl(uri).timeout(_networkTimeout);
      req.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      req.write(jsonEncode(profile.toJson()));
      await req.close();
    } catch (e) {
      debugPrint('[UserAuthService] _pushToCloud: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  Future<UserProfile?> _getLocalProfileByEmail(String email) async {
    try {
      // Try email column first (schema ≥ v5)
      final rows = await AppDatabase.instance.query(
        'user_profile',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (rows.isNotEmpty) return UserProfile.fromMap(rows.first);

      // Fallback: id column equals email (email-as-id pattern)
      final byId = await AppDatabase.instance.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (byId.isNotEmpty) return UserProfile.fromMap(byId.first);
    } catch (e) {
      debugPrint('[UserAuthService] _getLocalProfileByEmail: $e');
    }
    return null;
  }

  Future<void> _persistLoginState(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefEmailKey, email);
    await prefs.setBool(_prefLoggedInKey, true);
  }

  Future<void> markOfflineLoginAvailable([String? email]) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null && email.isNotEmpty) {
      _currentEmail = email;
      await prefs.setString(_prefEmailKey, email);
    }
    await prefs.setBool(_prefLoggedInKey, true);
    _isLoggedIn = true;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Sign-out
  // ──────────────────────────────────────────────

  Future<void> logout() async {
    _currentEmail = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefLoggedInKey, false);
    notifyListeners();
  }
}
