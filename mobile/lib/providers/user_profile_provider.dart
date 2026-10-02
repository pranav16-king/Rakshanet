import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isRegistered => _profile != null && _profile!.isRegistered && _profile!.name.trim().isNotEmpty;

  UserProfileProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // First check SQLite
      UserProfile? loaded = await AppDatabase.instance.getUserProfile();

      // If not in SQLite, check SharedPreferences backup
      if (loaded == null) {
        final registered = prefs.getBool('is_registered') ?? false;
        if (registered) {
          final id = prefs.getString('user_id') ?? _generateAnonymousId();
          final name = prefs.getString('user_name') ?? '';
          final blood = prefs.getString('user_blood_group') ?? 'Unknown';
          final phone = prefs.getString('user_emergency_contact') ?? '';
          final lang = prefs.getString('user_language') ?? 'English';
          final notes = prefs.getString('user_medical_notes');

          loaded = UserProfile(
            id: id,
            name: name,
            bloodGroup: blood,
            emergencyContact: phone,
            preferredLanguage: lang,
            medicalNotes: notes,
            isRegistered: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await AppDatabase.instance.saveUserProfile(loaded);
        }
      }

      _profile = loaded;
    } catch (e) {
      debugPrint('UserProfileProvider error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setOnboardingSeen(bool seen) async {
    _hasSeenOnboarding = seen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', seen);
    notifyListeners();
  }

  /// Generates an anonymous device ID in the required format: SR-XXXX-XXXX
  String _generateAnonymousId() {
    const chars = '0123456789ABCDEF';
    final random = Random();
    String part1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    String part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'SR-$part1-$part2';
  }

  Future<bool> registerProfile({
    required String name,
    required String bloodGroup,
    required String emergencyContact,
    required String preferredLanguage,
    String? medicalNotes,
    String? anonymousId,
  }) async {
    try {
      final id = anonymousId ??
          (_profile?.id.isNotEmpty == true ? _profile!.id : _generateAnonymousId());
      final now = DateTime.now().millisecondsSinceEpoch;

      final newProfile = UserProfile(
        id: id,
        name: name.trim(),
        bloodGroup: bloodGroup.trim(),
        emergencyContact: emergencyContact.trim(),
        preferredLanguage: preferredLanguage.trim(),
        medicalNotes: medicalNotes?.trim().isNotEmpty == true ? medicalNotes!.trim() : null,
        isRegistered: true,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
      );

      // Save to SQLite (Source of truth)
      await AppDatabase.instance.saveUserProfile(newProfile);

      // Mirror to SharedPreferences for quick key-value retrieval
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_registered', true);
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setString('user_id', id);
      await prefs.setString('user_name', newProfile.name);
      await prefs.setString('user_blood_group', newProfile.bloodGroup);
      await prefs.setString('user_emergency_contact', newProfile.emergencyContact);
      await prefs.setString('user_language', newProfile.preferredLanguage);
      if (newProfile.medicalNotes.isNotEmpty) {
        await prefs.setString('user_medical_notes', newProfile.medicalNotes);
      }

      _profile = newProfile;
      _hasSeenOnboarding = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error registering profile: $e');
      return false;
    }
  }
}
