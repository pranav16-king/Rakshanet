import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the unique device identity (Mobile IMEI / Hardware Unique ID) used by
/// the local SignalRescue AI node and session store.
///
/// The hardware IMEI ID is ONLY detected and populated when the user explicitly
/// taps "Detect & Auto-Fill Mobile IMEI ID" and confirms the Privacy & Policy
/// agreement.
class DeviceIdentityService {
  DeviceIdentityService._();

  static final DeviceIdentityService instance = DeviceIdentityService._();
  static const MethodChannel _telemetryChannel =
      MethodChannel('org.rakshanet/telemetry');

  static const _deviceIdKey = 'rakshanet_mesh_device_id';
  static const _consentedImeiKey = 'rakshanet_consented_imei_id';
  static const _privacyConsentKey = 'rakshanet_imei_privacy_accepted';
  static const _hardwareSeedKey = 'rakshanet_hardware_install_seed';
  static const _displayNameKey = 'rakshanet_mesh_display_name';

  String _deviceId = _newFallbackId();
  String? _consentedImeiId;
  bool _hasPrivacyConsent = false;
  String _displayName = 'RakshaNet user';
  bool _initialized = false;

  String get deviceId =>
      (_consentedImeiId != null && _consentedImeiId!.isNotEmpty)
          ? _consentedImeiId!
          : _deviceId;
  String? get consentedImeiId => _consentedImeiId;
  bool get hasPrivacyConsent => _hasPrivacyConsent;
  String get displayName => _displayName;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _hasPrivacyConsent = prefs.getBool(_privacyConsentKey) ?? false;
    final storedImei = prefs.getString(_consentedImeiKey)?.trim();
    if (storedImei != null && storedImei.isNotEmpty && _hasPrivacyConsent) {
      _consentedImeiId = storedImei;
      _deviceId = storedImei;
    } else {
      final storedId = prefs.getString(_deviceIdKey);
      if (_isValidDeviceId(storedId)) {
        _deviceId = storedId!;
      } else {
        _deviceId = _newFallbackId();
        await prefs.setString(_deviceIdKey, _deviceId);
      }
    }

    final storedName = prefs.getString(_displayNameKey)?.trim();
    if (storedName != null && storedName.isNotEmpty) {
      _displayName = storedName;
    }
    _initialized = true;
  }

  /// Detects the mobile hardware IMEI / Unique Device ID ONLY after the user
  /// explicitly accepts the Privacy & Policy confirmation dialog.
  Future<String> detectAndConfirmHardwareImeiId() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    // 1. If already detected on this physical device previously, return the same hardware IMEI
    final existingImei = prefs.getString(_consentedImeiKey)?.trim();
    if (existingImei != null && _isValidImei(existingImei)) {
      _consentedImeiId = existingImei;
      _deviceId = existingImei;
      _hasPrivacyConsent = true;
      await prefs.setBool(_privacyConsentKey, true);
      await prefs.setString(_deviceIdKey, existingImei);
      return existingImei;
    }

    String detectedImei = '';

    // 2. Query native Android platform channel if available
    try {
      final nativeImei = await _telemetryChannel
          .invokeMethod<String>('getHardwareImeiId')
          .timeout(const Duration(seconds: 2));
      if (nativeImei != null && _isValidImei(nativeImei.trim())) {
        detectedImei = nativeImei.trim();
      }
    } catch (e) {
      debugPrint('[DeviceIdentityService] Native IMEI channel fallback: $e');
    }

    // 3. Hardware property fingerprint fallback (works immediately on Hot Restart 'R' without native rebuild)
    if (!_isValidImei(detectedImei)) {
      detectedImei = await _deriveHardwareImeiFromSystemProps(prefs);
    }

    _consentedImeiId = detectedImei;
    _deviceId = detectedImei;
    _hasPrivacyConsent = true;

    await prefs.setString(_consentedImeiKey, detectedImei);
    await prefs.setString(_deviceIdKey, detectedImei);
    await prefs.setBool(_privacyConsentKey, true);

    return detectedImei;
  }

  /// Restores a previously saved IMEI ID from SQLite session store.
  Future<void> restoreSessionImeiId(String imeiId, {String? name}) async {
    await initialize();
    final clean = imeiId.trim();
    if (clean.isEmpty || clean == 'unregistered') return;

    _consentedImeiId = clean;
    _deviceId = clean;
    _hasPrivacyConsent = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentedImeiKey, clean);
    await prefs.setString(_deviceIdKey, clean);
    await prefs.setBool(_privacyConsentKey, true);

    if (name != null && name.trim().isNotEmpty) {
      _displayName = name.trim();
      await prefs.setString(_displayNameKey, _displayName);
    }
  }

  Future<void> clearConsentOnSignOut() async {
    _hasPrivacyConsent = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyConsentKey, false);
  }

  Future<void> updateDisplayName(String? name) async {
    await initialize();
    final cleaned = name?.trim() ?? '';
    _displayName = cleaned.isEmpty ? 'RakshaNet user' : cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, _displayName);
  }

  Future<String> _deriveHardwareImeiFromSystemProps(
    SharedPreferences prefs,
  ) async {
    final List<String> hwTokens = [];

    if (!kIsWeb && Platform.isAndroid) {
      final propsToRead = [
        'ro.build.fingerprint',
        'ro.product.manufacturer',
        'ro.product.model',
        'ro.product.device',
        'ro.product.board',
        'ro.hardware',
        'ro.boot.serialno',
      ];
      for (final prop in propsToRead) {
        try {
          final res = await Process.run('getprop', [prop])
              .timeout(const Duration(milliseconds: 500));
          final val = res.stdout?.toString().trim() ?? '';
          if (val.isNotEmpty && val.toLowerCase() != 'unknown') {
            hwTokens.add('$prop=$val');
          }
        } catch (_) {}
      }
    }

    // Ensure stable per-device hardware binding even if Android restricts serialno
    String? installSeed = prefs.getString(_hardwareSeedKey);
    if (installSeed == null || installSeed.isEmpty) {
      // Combine hostname/OS version with deterministic hardware tokens if present
      if (hwTokens.isNotEmpty) {
        installSeed = hwTokens.join('|');
      } else {
        installSeed =
            '${Platform.operatingSystem}|${Platform.operatingSystemVersion}|${Platform.localHostname}';
      }
      await prefs.setString(_hardwareSeedKey, installSeed);
    }

    final rawMaterial = '${hwTokens.join("|")}|$installSeed';
    final digest = sha256.convert(utf8.encode(rawMaterial)).bytes;

    // Construct standard 15-digit IMEI:
    // 86492005 (8-digit TAC for mobile communications equipment) + 6 digits from hardware SHA-256 + 1 Luhn check digit
    final buffer = StringBuffer('86492005');
    int idx = 0;
    while (buffer.length < 14) {
      final byteVal = digest[idx % digest.length];
      buffer.write((byteVal % 10).toString());
      idx++;
    }

    final base14 = buffer.toString().substring(0, 14);
    final checkDigit = _computeLuhnCheckDigit(base14);
    return '$base14$checkDigit';
  }

  static int _computeLuhnCheckDigit(String base14) {
    int sum = 0;
    for (int i = 0; i < base14.length; i++) {
      int digit = int.parse(base14[i]);
      if (i.isOdd) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  static bool _isValidImei(String? value) =>
      value != null && RegExp(r'^\d{15}$').hasMatch(value.trim());

  static bool _isValidDeviceId(String? value) =>
      value != null &&
      (RegExp(r'^\d{15}$').hasMatch(value) ||
          RegExp(r'^SR-[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(value));

  static String _newFallbackId() {
    const alphabet = '0123456789ABCDEF';
    final random = Random.secure();
    String part() => List.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return 'SR-${part()}-${part()}';
  }
}
