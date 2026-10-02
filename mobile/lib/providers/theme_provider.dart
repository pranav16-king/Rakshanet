import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefThemeKey = 'rakshanet_theme_mode';

  AppThemeMode _currentMode = AppThemeMode.dark;
  AppThemeMode _previousNonOledMode = AppThemeMode.dark;

  AppThemeMode get currentMode => _currentMode;
  bool get isLowPower => _currentMode == AppThemeMode.lowPower;
  bool get isDarkMode => _currentMode == AppThemeMode.dark;
  bool get isLightMode => _currentMode == AppThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefThemeKey);
      if (savedMode != null) {
        if (savedMode == AppThemeMode.lowPower.name) {
          _currentMode = AppThemeMode.lowPower;
        } else if (savedMode == AppThemeMode.light.name) {
          _currentMode = AppThemeMode.light;
          _previousNonOledMode = AppThemeMode.light;
        } else {
          _currentMode = AppThemeMode.dark;
          _previousNonOledMode = AppThemeMode.dark;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentMode == mode) return;

    if (mode != AppThemeMode.lowPower) {
      _previousNonOledMode = mode;
    }
    _currentMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setLowPower(bool enabled) async {
    if (enabled) {
      if (_currentMode != AppThemeMode.lowPower) {
        _previousNonOledMode = _currentMode;
      }
      await setThemeMode(AppThemeMode.lowPower);
    } else {
      await setThemeMode(_previousNonOledMode);
    }
  }

  ThemeData get themeData => switch (_currentMode) {
        AppThemeMode.light => AppTheme.getLightTheme(),
        AppThemeMode.lowPower => AppTheme.getLowPowerOledTheme(),
        AppThemeMode.dark => AppTheme.getDarkTheme(),
      };

  // Active token helpers for widgets
  Color get bg => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightBg,
        AppThemeMode.lowPower => AppTokens.oledBg,
        AppThemeMode.dark => AppTokens.darkBg,
      };

  Color get surface => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightSurface,
        AppThemeMode.lowPower => AppTokens.oledSurface,
        AppThemeMode.dark => AppTokens.darkSurface,
      };

  Color get surfaceSunken => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightSurfaceSunken,
        AppThemeMode.lowPower => AppTokens.oledSurfaceSunken,
        AppThemeMode.dark => AppTokens.darkSurfaceSunken,
      };

  Color get border => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightBorder,
        AppThemeMode.lowPower => AppTokens.oledBorder,
        AppThemeMode.dark => AppTokens.darkBorder,
      };

  Color get text => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightText,
        AppThemeMode.lowPower => Colors.white,
        AppThemeMode.dark => AppTokens.darkText,
      };

  Color get textMuted => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightTextMuted,
        AppThemeMode.lowPower => const Color(0xFF888888),
        AppThemeMode.dark => AppTokens.darkTextMuted,
      };

  Color get primary => switch (_currentMode) {
        AppThemeMode.light => AppTokens.lightPrimary,
        AppThemeMode.lowPower || AppThemeMode.dark => AppTokens.darkPrimary,
      };
}
