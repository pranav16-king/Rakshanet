import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../models/user_profile.dart';
import 'device_identity_service.dart';

/// UserAuthService – Mobile IMEI Unique ID session store with offline-first login.
///
/// Flow:
///  1. checkOfflineLoginAvailable() → returns true if this device has an active
///     registered session in SQLite or SharedPreferences (keyed by Unique IMEI ID).
///  2. loginWithUniqueId() / loginWithEmail() → looks up local SQLite first
///     (works 100% offline), then attempts a non-blocking cloud sync.
///  3. On successful registration/login the session state is persisted to both
///     SQLite and SharedPreferences so app restarts ('R' or cold start) restore
///     the session automatically.
class UserAuthService extends ChangeNotifier {
  static final UserAuthService instance = UserAuthService._();
  UserAuthService._();

  static const String _baseUrl = AppConfig.backendUrl;
  static const String _prefUniqueIdKey = 'rakshanet_unique_imei_id';
  static const String _prefUserIdKey = 'rakshanet_user_id';
  static const String _prefEmailKey = 'rakshanet_user_email';
  static const String _prefLoggedInKey = 'rakshanet_logged_in';
  static const String _prefRegisteredKey = 'rakshanet_user_registered';
  static const Duration _networkTimeout = Duration(seconds: 5);

  String? _currentUniqueId;
  String? _currentEmail;
  bool _isLoggedIn = false;
  bool _isSyncing = false;

  String? get currentUniqueId => _currentUniqueId;
  String? get currentEmail => _currentEmail;
  bool get isLoggedIn => _isLoggedIn;
  bool get isSyncing => _isSyncing;

  // ──────────────────────────────────────────────
  // Offline Session Store Gate
  // ──────────────────────────────────────────────

  /// Returns true when a valid registered user session exists in SQLite or
  /// SharedPreferences (using Unique Mobile IMEI ID + Full Name).
  Future<bool> checkOfflineLoginAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn =
          (prefs.getBool(_prefLoggedInKey) ?? false) ||
          (prefs.getBool(_prefRegisteredKey) ?? false) ||
          (prefs.getBool('is_registered') ?? false);

      final savedUniqueId =
          prefs.getString(_prefUniqueIdKey)?.trim() ??
          prefs.getString(_prefUserIdKey)?.trim() ??
          prefs.getString('user_id')?.trim();

      bool isValidImeiSession(String? id, String? name) =>
          id != null &&
          name != null &&
          name.trim().isNotEmpty &&
          id.trim().isNotEmpty &&
          id.trim() != 'unregistered';

      // 1. Check SQLite durable session store first
      final dbProfile = await AppDatabase.instance.getUserProfile();
      if (dbProfile != null &&
          dbProfile.isRegistered &&
          isValidImeiSession(dbProfile.id, dbProfile.name)) {
        _currentUniqueId = dbProfile.id;
        _currentEmail = dbProfile.email;
        _isLoggedIn = true;
        await _persistSessionToPrefs(dbProfile);
        await DeviceIdentityService.instance.restoreSessionImeiId(
          dbProfile.id,
          name: dbProfile.name,
        );
        notifyListeners();
        return true;
      }

      // 2. Fallback: Check SharedPreferences session store backup and re-hydrate SQLite
      final savedName =
          prefs.getString('rakshanet_user_name')?.trim() ??
          prefs.getString('user_name')?.trim() ??
          '';

      if (loggedIn && isValidImeiSession(savedUniqueId, savedName)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final restoredProfile = UserProfile(
          id: savedUniqueId!,
          email: prefs.getString(_prefEmailKey) ?? '',
          name: savedName,
          deviceId: savedUniqueId,
          bloodGroup: prefs.getString('rakshanet_user_blood') ??
              prefs.getString('user_blood_group') ??
              '',
          emergencyContact: prefs.getString('rakshanet_user_phone') ??
              prefs.getString('user_emergency_contact') ??
              '',
          medicalNotes: prefs.getString('rakshanet_user_notes') ??
              prefs.getString('user_medical_notes') ??
              '',
          language: prefs.getString('rakshanet_user_lang') ??
              prefs.getString('user_language') ??
              'English',
          isRegistered: true,
          createdAt: now,
          updatedAt: now,
        );
        await AppDatabase.instance.saveUserProfile(restoredProfile);
        await DeviceIdentityService.instance.restoreSessionImeiId(
          savedUniqueId,
          name: savedName,
        );
        _currentUniqueId = savedUniqueId;
        _currentEmail = restoredProfile.email;
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
  // Login / Session Registration
  // ──────────────────────────────────────────────

  /// Primary login/registration entry-point using Mobile IMEI ID as Unique ID.
  Future<UserProfile?> loginWithUniqueId({
    required String uniqueId,
    required String name,
    String? email,
    String? phone,
    String? bloodGroup,
    String? medicalNotes,
    String? language,
  }) async {
    final cleanId = uniqueId.trim();
    final cleanName = name.trim();
    if (cleanId.isEmpty || cleanName.isEmpty) return null;

    final cleanEmail = email?.trim().toLowerCase() ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;

    final profile = UserProfile(
      id: cleanId,
      email: cleanEmail,
      name: cleanName,
      deviceId: cleanId,
      emergencyContact: phone?.trim() ?? '',
      bloodGroup: bloodGroup?.trim() ?? '',
      medicalNotes: medicalNotes?.trim() ?? '',
      language: language?.trim() ?? 'English',
      isRegistered: true,
      createdAt: now,
      updatedAt: now,
    );

    await AppDatabase.instance.saveUserProfile(profile);
    await _persistSessionToPrefs(profile);
    await DeviceIdentityService.instance.restoreSessionImeiId(
      cleanId,
      name: cleanName,
    );

    _currentUniqueId = cleanId;
    _currentEmail = cleanEmail;
    _isLoggedIn = true;
    notifyListeners();

    // Best-effort cloud push (non-blocking)
    _pushToCloud(profile).ignore();

    return profile;
  }

  /// Legacy compatibility method for email/ID login.
  Future<UserProfile?> loginWithEmail(
    String emailOrId, {
    String? name,
    String? phone,
    String? bloodGroup,
    String? language,
  }) async {
    final cleanKey = emailOrId.trim();
    if (cleanKey.isEmpty) return null;

    // 1 ─ Local SQLite lookup
    final localProfile = await _getLocalProfileByKey(cleanKey);
    if (localProfile != null) {
      _currentUniqueId = localProfile.id;
      _currentEmail = localProfile.email;
      _isLoggedIn = true;
      await _persistSessionToPrefs(localProfile);
      notifyListeners();
      _syncFromCloud(cleanKey).ignore();
      return localProfile;
    }

    // 2 ─ Create new profile if name provided
    if (name != null && name.trim().isNotEmpty) {
      return loginWithUniqueId(
        uniqueId: cleanKey,
        name: name.trim(),
        email: cleanKey.contains('@') ? cleanKey : '',
        phone: phone,
        bloodGroup: bloodGroup,
        language: language,
      );
    }

    return null;
  }

  // ──────────────────────────────────────────────
  // Cloud sync (opportunistic, always non-blocking)
  // ──────────────────────────────────────────────

  Future<void> syncNow() async {
    final lookupKey =
        (_currentEmail != null && _currentEmail!.isNotEmpty)
            ? _currentEmail!
            : _currentUniqueId;
    if (lookupKey == null || lookupKey.isEmpty || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await _syncFromCloud(lookupKey);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromCloud(String key) async {
    final cloudProfile = await _fetchFromCloud(key);
    if (cloudProfile != null &&
        cloudProfile.name.trim().isNotEmpty &&
        cloudProfile.id.trim().isNotEmpty) {
      await AppDatabase.instance.saveUserProfile(cloudProfile);
      await _persistSessionToPrefs(cloudProfile);
    }
  }

  Future<UserProfile?> _fetchFromCloud(String key) async {
    try {
      final uri = Uri.parse(
        !key.contains('@')
            ? '$_baseUrl/api/v1/users/imei/$key'
            : '$_baseUrl/api/v1/users/by-email?email=${Uri.encodeComponent(key)}',
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
      debugPrint('[UserAuthService] _fetchFromCloud (offline mode active): $e');
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
      debugPrint('[UserAuthService] _pushToCloud (offline mode active): $e');
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  Future<UserProfile?> _getLocalProfileByKey(String key) async {
    try {
      final byId = await AppDatabase.instance.query(
        'user_profile',
        where: 'id = ? OR device_id = ? OR email = ?',
        whereArgs: [key, key, key],
        limit: 1,
      );
      if (byId.isNotEmpty) return UserProfile.fromMap(byId.first);
    } catch (e) {
      debugPrint('[UserAuthService] _getLocalProfileByKey: $e');
    }
    return null;
  }

  Future<void> _persistSessionToPrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUniqueIdKey, profile.id);
    await prefs.setString(_prefUserIdKey, profile.id);
    await prefs.setString('user_id', profile.id);
    await prefs.setString('rakshanet_user_name', profile.name);
    await prefs.setString('user_name', profile.name);
    await prefs.setString(_prefEmailKey, profile.email);
    await prefs.setString('rakshanet_user_phone', profile.emergencyContact);
    await prefs.setString('user_emergency_contact', profile.emergencyContact);
    await prefs.setString('rakshanet_user_blood', profile.bloodGroup);
    await prefs.setString('user_blood_group', profile.bloodGroup);
    await prefs.setString('rakshanet_user_notes', profile.medicalNotes);
    await prefs.setString('user_medical_notes', profile.medicalNotes);
    await prefs.setString('rakshanet_user_lang', profile.language);
    await prefs.setString('user_language', profile.language);
    await prefs.setBool(_prefLoggedInKey, true);
    await prefs.setBool(_prefRegisteredKey, true);
    await prefs.setBool('is_registered', true);
    await prefs.setBool('has_seen_onboarding', true);
  }

  Future<void> markOfflineLoginAvailable(
    String uniqueId, {
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanId = uniqueId.trim();
    if (cleanId.isNotEmpty) {
      _currentUniqueId = cleanId;
      await prefs.setString(_prefUniqueIdKey, cleanId);
      await prefs.setString(_prefUserIdKey, cleanId);
      await prefs.setString('user_id', cleanId);
    }
    if (email != null) {
      _currentEmail = email.trim();
      await prefs.setString(_prefEmailKey, _currentEmail!);
    }
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString('rakshanet_user_name', name.trim());
      await prefs.setString('user_name', name.trim());
    }
    await prefs.setBool(_prefLoggedInKey, true);
    await prefs.setBool(_prefRegisteredKey, true);
    await prefs.setBool('is_registered', true);
    _isLoggedIn = true;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Sign-out / Clear Session
  // ──────────────────────────────────────────────

  Future<void> logout() async {
    _currentUniqueId = null;
    _currentEmail = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefLoggedInKey, false);
    await prefs.setBool(_prefRegisteredKey, false);
    await prefs.setBool('is_registered', false);
    await DeviceIdentityService.instance.clearConsentOnSignOut();
    notifyListeners();
  }
}
