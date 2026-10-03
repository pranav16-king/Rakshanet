import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Provider managing active theme mode, OLED low-power state, persistence,
/// and reactive design system token accessors.
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _prefThemeKey = 'rakshanet_theme_mode';
  static const String _prefLowPowerKey = 'rakshanet_low_power_oled';

  AppThemeMode _baseThemeMode = AppThemeMode.dark;
  bool _isLowPower = false;

  AppThemeMode get baseThemeMode => _baseThemeMode;
  bool get isLowPower => _isLowPower;

  /// Effective theme mode (resolves to lowPower if OLED pure black mode is active)
  AppThemeMode get currentMode {
    if (_isLowPower) return AppThemeMode.lowPower;
    return _baseThemeMode;
  }

  /// Whether the effective presentation is dark (Dark or Low-Power OLED)
  bool get isDark {
    if (_isLowPower) return true;
    if (_baseThemeMode == AppThemeMode.dark) return true;
    if (_baseThemeMode == AppThemeMode.light) return false;
    // AppThemeMode.system follows device platform brightness
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// Whether the effective presentation is light
  bool get isLight => !isDark;

  // Backward compatibility getters
  bool get isDarkMode => isDark;
  bool get isLightMode => isLight;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadThemeFromPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_baseThemeMode == AppThemeMode.system && !_isLowPower) {
      notifyListeners();
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefThemeKey);
      final savedLowPower = prefs.getBool(_prefLowPowerKey);

      if (savedLowPower != null) {
        _isLowPower = savedLowPower;
      }

      if (savedMode != null) {
        if (savedMode == AppThemeMode.lowPower.name) {
          _isLowPower = true;
          _baseThemeMode = AppThemeMode.dark;
        } else if (savedMode == AppThemeMode.light.name) {
          _baseThemeMode = AppThemeMode.light;
          if (savedLowPower == null) _isLowPower = false;
        } else if (savedMode == AppThemeMode.system.name) {
          _baseThemeMode = AppThemeMode.system;
          if (savedLowPower == null) _isLowPower = false;
        } else {
          _baseThemeMode = AppThemeMode.dark;
          if (savedLowPower == null) _isLowPower = false;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Sets the base theme mode (system, light, or dark).
  /// If selecting light or dark, turns off OLED low-power mode unless lowPower was passed.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (mode == AppThemeMode.lowPower) {
      await setLowPower(true);
      return;
    }

    if (_baseThemeMode == mode && !_isLowPower) return;

    _isLowPower = false;
    _baseThemeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, mode.name);
      await prefs.setBool(_prefLowPowerKey, false);
    } catch (_) {}
  }

  /// Toggles true #000000 Low-Power OLED mode for extreme battery savings.
  Future<void> setLowPower(bool enabled) async {
    if (_isLowPower == enabled) return;

    _isLowPower = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLowPowerKey, enabled);
      if (enabled) {
        await prefs.setString(_prefThemeKey, AppThemeMode.lowPower.name);
      } else {
        await prefs.setString(_prefThemeKey, _baseThemeMode.name);
      }
    } catch (_) {}
  }

  Future<void> toggleLowPower() async {
    await setLowPower(!_isLowPower);
  }

  /// Complete ThemeData configuration for MaterialApp
  ThemeData get themeData {
    if (_isLowPower) {
      return AppTheme.getLowPowerOledTheme();
    }
    if (isLight) {
      return AppTheme.getLightTheme();
    }
    return AppTheme.getDarkTheme();
  }

  // ==========================================
  // Complete Active Token Accessors for UI
  // ==========================================

  Color get bg {
    if (_isLowPower) return AppTokens.oledBg;
    return isLight ? AppTokens.lightBg : AppTokens.darkBg;
  }

  Color get bgAlt {
    if (_isLowPower) return AppTokens.oledBgAlt;
    return isLight ? AppTokens.lightBgAlt : AppTokens.darkBgAlt;
  }

  Color get surface {
    if (_isLowPower) return AppTokens.oledSurface;
    return isLight ? AppTokens.lightSurface : AppTokens.darkSurface;
  }

  Color get surfaceAlt {
    if (_isLowPower) return AppTokens.oledSurface;
    return isLight ? AppTokens.lightBgAlt : AppTokens.darkSurfaceAlt;
  }

  Color get surfaceSunken {
    if (_isLowPower) return AppTokens.oledSurfaceSunken;
    return isLight ? AppTokens.lightSurfaceSunken : AppTokens.darkSurfaceSunken;
  }

  Color get border {
    if (_isLowPower) return AppTokens.oledBorder;
    return isLight ? AppTokens.lightBorder : AppTokens.darkBorder;
  }

  Color get borderStrong {
    if (_isLowPower) return AppTokens.oledBorderStrong;
    return isLight ? AppTokens.lightBorderStrong : AppTokens.darkBorderStrong;
  }

  Color get text {
    if (_isLowPower) return AppTokens.oledText;
    return isLight ? AppTokens.lightText : AppTokens.darkText;
  }

  Color get textMuted {
    if (_isLowPower) return AppTokens.oledTextMuted;
    return isLight ? AppTokens.lightTextMuted : AppTokens.darkTextMuted;
  }

  Color get textDisabled {
    if (_isLowPower) return AppTokens.oledTextDisabled;
    return isLight ? AppTokens.lightTextDisabled : AppTokens.darkTextDisabled;
  }

  Color get onPrimary {
    if (_isLowPower) return AppTokens.oledOnPrimary;
    return isLight ? AppTokens.lightOnPrimary : AppTokens.darkOnPrimary;
  }

  Color get primary {
    if (_isLowPower) return AppTokens.oledPrimary;
    return isLight ? AppTokens.lightPrimary : AppTokens.darkPrimary;
  }

  Color get primaryPressed {
    if (_isLowPower) return AppTokens.oledPrimaryPressed;
    return isLight ? AppTokens.lightPrimaryPressed : AppTokens.darkPrimaryPressed;
  }

  Color get primarySoft {
    if (_isLowPower) return AppTokens.oledPrimarySoft;
    return isLight ? AppTokens.lightPrimarySoft : AppTokens.darkPrimarySoft;
  }

  /// Yellow text / icons on light backgrounds MUST use primaryInk (#8A5A00) to pass 4.5:1 contrast
  Color get primaryInk {
    if (_isLowPower) return AppTokens.oledPrimaryInk;
    return isLight ? AppTokens.lightPrimaryInk : AppTokens.darkPrimaryInk;
  }

  Color get sos {
    if (_isLowPower) return AppTokens.oledSos;
    return isLight ? AppTokens.lightSos : AppTokens.darkSos;
  }

  Color get sosMain {
    if (_isLowPower) return AppTokens.oledSosMain;
    return isLight ? AppTokens.lightSos : AppTokens.darkSosMain;
  }

  Color get sosPressed {
    if (_isLowPower) return AppTokens.oledSosPressed;
    return isLight ? AppTokens.lightSosPressed : AppTokens.darkSosPressed;
  }

  Color get sosSoft {
    if (_isLowPower) return AppTokens.oledSosSoft;
    return isLight ? AppTokens.lightSosSoft : AppTokens.darkSosSoft;
  }

  Color get info {
    if (_isLowPower) return AppTokens.oledInfo;
    return isLight ? AppTokens.lightInfo : AppTokens.darkInfo;
  }

  Color get infoSoft {
    if (_isLowPower) return AppTokens.oledInfoSoft;
    return isLight ? AppTokens.lightInfoSoft : AppTokens.darkInfoSoft;
  }

  Color get success {
    if (_isLowPower) return AppTokens.oledSuccess;
    return isLight ? AppTokens.lightSuccess : AppTokens.darkSuccess;
  }

  Color get successSoft {
    if (_isLowPower) return AppTokens.oledSuccessSoft;
    return isLight ? AppTokens.lightSuccessSoft : AppTokens.darkSuccessSoft;
  }

  Color get warning {
    if (_isLowPower) return AppTokens.oledWarning;
    return isLight ? AppTokens.lightWarning : AppTokens.darkWarning;
  }

  Color get warningSoft {
    if (_isLowPower) return AppTokens.oledWarningSoft;
    return isLight ? AppTokens.lightWarningSoft : AppTokens.darkWarningSoft;
  }

  Color get scrim {
    if (_isLowPower) return AppTokens.oledScrim;
    return isLight ? AppTokens.lightScrim : AppTokens.darkScrim;
  }
}
