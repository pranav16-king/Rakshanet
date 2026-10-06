import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../database/app_database.dart';
import '../database/repositories/profile_repository.dart';
import '../services/device_identity_service.dart';
import '../services/user_auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  static const String _prefRegisteredKey = 'rakshanet_user_registered';
  static const String _prefUserIdKey = 'rakshanet_user_id';
  static const String _prefUniqueImeiKey = 'rakshanet_unique_imei_id';
  static const String _prefUserNameKey = 'rakshanet_user_name';
  static const String _prefUserEmailKey = 'rakshanet_user_email';
  static const String _prefUserPhoneKey = 'rakshanet_user_phone';
  static const String _prefUserBloodKey = 'rakshanet_user_blood';
  static const String _prefUserNotesKey = 'rakshanet_user_notes';
  static const String _prefUserLangKey = 'rakshanet_user_lang';

  final ProfileRepository _profileRepo = ProfileRepository();
  UserProfile _profile = UserProfile.unregistered();
  bool _isLoading = true;
  bool _isRegistered = false;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isRegistered => _isRegistered;
  ProfileRepository get repository => _profileRepo;

  ProfileProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      await DeviceIdentityService.instance.initialize();
      final prefs = await SharedPreferences.getInstance();
      final hasRegisteredFlag =
          (prefs.getBool(_prefRegisteredKey) ?? false) ||
          (prefs.getBool('is_registered') ?? false);

      // 1. Check SQLite durable source of truth first
      final dbProfile =
          await AppDatabase.instance.getUserProfile() ??
          await _profileRepo.getProfile();

      bool isValidImeiSession(String id, String name) =>
          name.trim().isNotEmpty &&
          id.trim().isNotEmpty &&
          id.trim() != 'unregistered';

      if (dbProfile != null &&
          dbProfile.isRegistered &&
          isValidImeiSession(dbProfile.id, dbProfile.name)) {
        _profile = dbProfile;
        _isRegistered = true;
        await _mirrorProfileToPrefs(prefs, dbProfile);
        await DeviceIdentityService.instance.restoreSessionImeiId(
          dbProfile.id,
          name: dbProfile.name,
        );
      } else if (hasRegisteredFlag) {
        // 2. Reconstruct from SharedPreferences session backup if SQLite was reset or in-memory
        final savedId =
            prefs.getString(_prefUniqueImeiKey)?.trim() ??
            prefs.getString(_prefUserIdKey)?.trim() ??
            prefs.getString('user_id')?.trim() ??
            '';
        final savedName =
            prefs.getString(_prefUserNameKey)?.trim() ??
            prefs.getString('user_name')?.trim() ??
            '';

        if (isValidImeiSession(savedId, savedName)) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final restored = UserProfile(
            id: savedId,
            email: prefs.getString(_prefUserEmailKey) ?? '',
            name: savedName,
            deviceId: savedId,
            language:
                prefs.getString(_prefUserLangKey) ??
                prefs.getString('user_language') ??
                'English',
            bloodGroup:
                prefs.getString(_prefUserBloodKey) ??
                prefs.getString('user_blood_group') ??
                '',
            emergencyContact:
                prefs.getString(_prefUserPhoneKey) ??
                prefs.getString('user_emergency_contact') ??
                '',
            medicalNotes:
                prefs.getString(_prefUserNotesKey) ??
                prefs.getString('user_medical_notes') ??
                '',
            isRegistered: true,
            createdAt: now,
            updatedAt: now,
          );
          _profile = restored;
          _isRegistered = true;
          await AppDatabase.instance.saveUserProfile(restored);
          await DeviceIdentityService.instance.restoreSessionImeiId(
            savedId,
            name: savedName,
          );
        } else {
          _profile = UserProfile.unregistered();
          _isRegistered = false;
        }
      } else if (!_isRegistered) {
        _profile = UserProfile.unregistered();
        _isRegistered = false;
      }
    } catch (e) {
      debugPrint('[ProfileProvider] Error loading profile session: $e');
      if (!_isRegistered) {
        _profile = UserProfile.unregistered();
        _isRegistered = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerUser({
    required String name,
    String? uniqueId,
    String phone = '',
    String? email,
    String? bloodGroup,
    String? medicalNotes,
    String? preferredLanguage,
    int? age,
  }) async {
    _isLoading = true;
    notifyListeners();

    await DeviceIdentityService.instance.initialize();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanEmail = email?.trim().toLowerCase() ?? '';
    final resolvedUniqueId =
        (uniqueId != null && uniqueId.trim().isNotEmpty)
            ? uniqueId.trim()
            : (DeviceIdentityService.instance.consentedImeiId ??
                DeviceIdentityService.instance.deviceId);

    final newProfile = UserProfile(
      id: resolvedUniqueId,
      email: cleanEmail,
      name: name.trim(),
      deviceId: resolvedUniqueId,
      language: preferredLanguage ?? 'English',
      age: age,
      bloodGroup: bloodGroup ?? '',
      emergencyContact: phone.trim(),
      medicalNotes: medicalNotes ?? '',
      isRegistered: true,
      peopleHelped: _profile.peopleHelped,
      messagesRelayed: _profile.messagesRelayed,
      sosForwarded: _profile.sosForwarded,
      missingFound: _profile.missingFound,
      createdAt: _profile.isRegistered ? _profile.createdAt : now,
      updatedAt: now,
    );

    _profile = newProfile;
    _isRegistered = true;

    // 1. Save-Before-Send: Persist to SQLite via ProfileRepository & AppDatabase
    try {
      await _profileRepo.saveProfile(newProfile);
      await AppDatabase.instance.saveUserProfile(newProfile);
    } catch (e) {
      debugPrint('[ProfileProvider] Error saving user profile to SQLite: $e');
    }

    // 2. Mirror full session state to SharedPreferences & UserAuthService
    try {
      final prefs = await SharedPreferences.getInstance();
      await _mirrorProfileToPrefs(prefs, newProfile);
      await DeviceIdentityService.instance.restoreSessionImeiId(
        resolvedUniqueId,
        name: newProfile.name,
      );
      await UserAuthService.instance.markOfflineLoginAvailable(
        resolvedUniqueId,
        email: cleanEmail,
        name: newProfile.name,
      );
      UserAuthService.instance.syncNow();
    } catch (e) {
      debugPrint('[ProfileProvider] Error saving session to SharedPreferences: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? preferredLanguage,
    int? age,
    String? bloodGroup,
    String? emergencyContact,
    String? medicalNotes,
  }) async {
    final updated = _profile.copyWith(
      name: name,
      language: preferredLanguage,
      age: age,
      bloodGroup: bloodGroup,
      emergencyContact: emergencyContact,
      medicalNotes: medicalNotes,
      isRegistered: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _profile = updated;
    _isRegistered = true;
    notifyListeners();

    try {
      await _profileRepo.saveProfile(updated);
      await AppDatabase.instance.saveUserProfile(updated);
      final prefs = await SharedPreferences.getInstance();
      await _mirrorProfileToPrefs(prefs, updated);
    } catch (e) {
      debugPrint('[ProfileProvider] Error updating profile in SQLite: $e');
    }
  }

  Future<void> _mirrorProfileToPrefs(
    SharedPreferences prefs,
    UserProfile p,
  ) async {
    await prefs.setBool(_prefRegisteredKey, true);
    await prefs.setBool('is_registered', true);
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setBool('rakshanet_logged_in', true);
    await prefs.setString(_prefUserIdKey, p.id);
    await prefs.setString(_prefUniqueImeiKey, p.id);
    await prefs.setString('user_id', p.id);
    await prefs.setString(_prefUserNameKey, p.name);
    await prefs.setString('user_name', p.name);
    await prefs.setString(_prefUserEmailKey, p.email);
    await prefs.setString(_prefUserPhoneKey, p.emergencyContact);
    await prefs.setString('user_emergency_contact', p.emergencyContact);
    await prefs.setString(_prefUserBloodKey, p.bloodGroup);
    await prefs.setString('user_blood_group', p.bloodGroup);
    await prefs.setString(_prefUserNotesKey, p.medicalNotes);
    await prefs.setString('user_medical_notes', p.medicalNotes);
    await prefs.setString(_prefUserLangKey, p.language);
    await prefs.setString('user_language', p.language);
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _profileRepo.clearProfile();
      await AppDatabase.instance.clearUserProfile();
    } catch (e) {
      debugPrint('[ProfileProvider] Error clearing profile in SQLite: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRegisteredKey, false);
    await prefs.setBool('is_registered', false);
    await prefs.setBool('rakshanet_logged_in', false);
    await prefs.remove(_prefUniqueImeiKey);
    await prefs.remove(_prefUserIdKey);
    await prefs.remove(_prefUserNameKey);
    await UserAuthService.instance.logout();

    _profile = UserProfile.unregistered();
    _isRegistered = false;
    _isLoading = false;
    notifyListeners();
  }

  // Impact telemetry helpers
  Future<void> incrementPeopleHelped() async {
    _profile = _profile.copyWith(peopleHelped: _profile.peopleHelped + 1);
    notifyListeners();
    await AppDatabase.instance.saveUserProfile(_profile);
  }

  Future<void> incrementMessagesRelayed() async {
    _profile = _profile.copyWith(messagesRelayed: _profile.messagesRelayed + 1);
    notifyListeners();
    await AppDatabase.instance.saveUserProfile(_profile);
  }

  Future<void> incrementSosForwarded() async {
    _profile = _profile.copyWith(sosForwarded: _profile.sosForwarded + 1);
    notifyListeners();
    await AppDatabase.instance.saveUserProfile(_profile);
  }

  Future<void> incrementMissingFound() async {
    _profile = _profile.copyWith(missingFound: _profile.missingFound + 1);
    notifyListeners();
    await AppDatabase.instance.saveUserProfile(_profile);
  }
}
