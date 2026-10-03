import 'package:flutter/material.dart';
import 'app_tokens.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  lowPower,
}

/// RakshaNet Hi-vis beacon design system theme definitions.
/// Strict adherence to `p:\RakshaNet\design.md`:
/// - Light theme: Background #FFFCEB, Surface #FFFFFF, Text #16202D, Text Muted #566070, PrimaryInk #8A5A00 (4.5:1 contrast)
/// - Dark theme: Night Navy #0B1220, Surface #162036, Text #EEF2F8, Text Muted #9FADC2, Primary #FFD21F, SOS #FF5A4E (Main #D92D20)
/// - Low-power OLED theme: True #000000 Black, Surface #0E1627, Border #26344F, OLED pure black saving battery
/// - Touch targets >= 48dp, primary buttons 56dp
class AppTheme {
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTokens.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppTokens.darkPrimary,
        onPrimary: AppTokens.darkOnPrimary,
        surface: AppTokens.darkSurface,
        onSurface: AppTokens.darkText,
        error: AppTokens.darkSos,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.darkBg,
        elevation: 0,
        foregroundColor: AppTokens.darkText,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
          side: BorderSide(color: AppTokens.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.darkPrimary,
          foregroundColor: AppTokens.darkOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.darkPrimary,
          foregroundColor: AppTokens.darkOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          foregroundColor: AppTokens.darkText,
          side: const BorderSide(color: AppTokens.darkBorder, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppTokens.touchMin, AppTokens.touchMin), // >= 48dp
          foregroundColor: AppTokens.darkPrimary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.darkSurfaceSunken,
        constraints: const BoxConstraints(minHeight: AppTokens.inputHeight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.darkPrimary, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.darkSuccess;
          }
          return AppTokens.darkBorderStrong;
        }),
      ),
      dividerColor: AppTokens.darkBorder,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTokens.darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTokens.darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppTokens.darkText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppTokens.darkTextMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTokens.darkTextMuted,
        ),
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTokens.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppTokens.lightPrimary,
        onPrimary: AppTokens.lightOnPrimary,
        surface: AppTokens.lightSurface,
        onSurface: AppTokens.lightText,
        error: AppTokens.lightSos,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.lightBg,
        elevation: 0,
        foregroundColor: AppTokens.lightText,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
          side: BorderSide(color: AppTokens.lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.lightPrimary,
          foregroundColor: AppTokens.lightOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.lightPrimary,
          foregroundColor: AppTokens.lightOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          foregroundColor: AppTokens.lightText,
          side: const BorderSide(color: AppTokens.lightBorder, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppTokens.touchMin, AppTokens.touchMin), // >= 48dp
          foregroundColor: AppTokens.lightPrimaryInk, // passes 4.5:1 contrast on light backgrounds
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.lightSurfaceSunken,
        constraints: const BoxConstraints(minHeight: AppTokens.inputHeight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.lightPrimaryInk, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.lightSuccess;
          }
          return AppTokens.lightBorderStrong;
        }),
      ),
      dividerColor: AppTokens.lightBorder,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightText,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppTokens.lightText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppTokens.lightTextMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightTextMuted,
        ),
      ),
    );
  }

  static ThemeData getLowPowerOledTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTokens.oledBg, // True OLED #000000 Black
      colorScheme: const ColorScheme.dark(
        primary: AppTokens.oledPrimary,
        onPrimary: AppTokens.oledOnPrimary,
        surface: AppTokens.oledSurface,
        onSurface: AppTokens.oledText,
        error: AppTokens.oledSos,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.oledBg,
        elevation: 0,
        foregroundColor: AppTokens.oledText,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.oledSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
          side: BorderSide(color: AppTokens.oledBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.oledPrimary,
          foregroundColor: AppTokens.oledOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          backgroundColor: AppTokens.oledPrimary,
          foregroundColor: AppTokens.oledOnPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonPrimary), // 56dp
          foregroundColor: AppTokens.oledText,
          side: const BorderSide(color: AppTokens.oledBorder, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppTokens.touchMin, AppTokens.touchMin), // >= 48dp
          foregroundColor: AppTokens.oledPrimary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.oledSurfaceSunken,
        constraints: const BoxConstraints(minHeight: AppTokens.inputHeight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.oledBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.oledBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.oledPrimary, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.oledSuccess;
          }
          return AppTokens.oledBorder;
        }),
      ),
      dividerColor: AppTokens.oledBorder,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTokens.oledText,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.oledText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTokens.oledText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppTokens.oledText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppTokens.oledTextMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTokens.oledTextMuted,
        ),
      ),
    );
  }
}
