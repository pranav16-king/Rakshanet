import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../database/app_database.dart';
import '../database/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  static const String _prefRegisteredKey = 'rakshanet_user_registered';
  static const String _prefUserIdKey = 'rakshanet_user_id';

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
      final prefs = await SharedPreferences.getInstance();
      final hasRegisteredFlag = prefs.getBool(_prefRegisteredKey);

      // Check SQLite durable source of truth first via ProfileRepository
      final dbProfile = await _profileRepo.getProfile() ?? await AppDatabase.instance.getUserProfile();

      if (dbProfile != null && dbProfile.isRegistered) {
        _profile = dbProfile;
        _isRegistered = true;
      } else if (hasRegisteredFlag == true) {
        if (dbProfile != null) _profile = dbProfile;
        _isRegistered = true;
      } else if (_isRegistered) {
        // Keep current registered state
      } else {
        _profile = dbProfile ?? UserProfile.unregistered();
        _isRegistered = false;
      }
    } catch (e) {
      debugPrint('[ProfileProvider] Error loading profile from SQLite: $e');
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
    required String phone,
    String? bloodGroup,
    String? medicalNotes,
    String? preferredLanguage,
    int? age,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Generate canonical anonymous ID format: SR-XXXX-XXXX
    final fullUuid = const Uuid().v4().toUpperCase().replaceAll('-', '');
    final meshId = 'SR-${fullUuid.substring(0, 4)}-${fullUuid.substring(4, 8)}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final newProfile = UserProfile(
      id: 'usr-$now',
      name: name.trim(),
      deviceId: meshId,
      language: preferredLanguage ?? 'en',
      age: age,
      bloodGroup: bloodGroup ?? '',
      emergencyContact: phone,
      medicalNotes: medicalNotes ?? '',
      isRegistered: true,
      peopleHelped: 0,
      messagesRelayed: 0,
      sosForwarded: 0,
      missingFound: 0,
      createdAt: now,
      updatedAt: now,
    );

    _profile = newProfile;
    _isRegistered = true;

    // Save-Before-Send: Persist to SQLite via ProfileRepository & AppDatabase
    try {
      await _profileRepo.saveProfile(newProfile);
      await AppDatabase.instance.saveUserProfile(newProfile);
    } catch (e) {
      debugPrint('[ProfileProvider] Error saving user profile to SQLite: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRegisteredKey, true);
      await prefs.setString(_prefUserIdKey, newProfile.id);
    } catch (e) {
      debugPrint('[ProfileProvider] Error saving to SharedPreferences: $e');
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
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _profile = updated;
    notifyListeners();

    try {
      await _profileRepo.updateProfile(updated);
      await AppDatabase.instance.saveUserProfile(updated);
    } catch (e) {
      debugPrint('[ProfileProvider] Error updating profile in SQLite: $e');
    }
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
