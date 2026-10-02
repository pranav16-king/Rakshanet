import 'package:flutter/material.dart';

/// RakshaNet (SignalRescue AI) — Design System Tokens
/// Source of Truth: design.md
/// Hi-vis beacon design system for extreme emergency / offline resilience.
class AppTokens {
  // Brand Core
  static const Color signalYellow = Color(0xFFFFC400);
  static const Color sosRed = Color(0xFFD92D20);
  static const Color beaconTeal = Color(0xFF0E8A94);
  static const Color nightNavy = Color(0xFF0B1220);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFFFFCEB);
  static const Color lightBgAlt = Color(0xFFFFF5C2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSunken = Color(0xFFF6F0D4);
  static const Color lightBorder = Color(0xFFE6DCA8);
  static const Color lightBorderStrong = Color(0xFFC9BB6E);
  static const Color lightText = Color(0xFF16202D);
  static const Color lightTextMuted = Color(0xFF566070);
  static const Color lightPrimary = Color(0xFFFFC400);
  static const Color lightPrimaryInk = Color(0xFF8A5A00);
  static const Color lightPrimarySoft = Color(0xFFFFEFA6);
  static const Color lightOnPrimary = Color(0xFF1A1400);
  static const Color lightSos = Color(0xFFD92D20);
  static const Color lightInfo = Color(0xFF0E8A94);
  static const Color lightSuccess = Color(0xFF1E8E4E);
  static const Color lightWarning = Color(0xFFE07B00);

  // Dark Theme Colors (Default)
  static const Color darkBg = Color(0xFF0B1220);
  static const Color darkBgAlt = Color(0xFF111A2C);
  static const Color darkSurface = Color(0xFF162036);
  static const Color darkSurfaceAlt = Color(0xFF1E2D4A);
  static const Color darkSurfaceSunken = Color(0xFF0E1627);
  static const Color darkBorder = Color(0xFF26344F);
  static const Color darkBorderStrong = Color(0xFF3A4C70);
  static const Color darkText = Color(0xFFEEF2F8);
  static const Color darkTextMuted = Color(0xFF9FADC2);
  static const Color darkPrimary = Color(0xFFFFD21F);
  static const Color darkPrimaryInk = Color(0xFFFFD21F);
  static const Color darkPrimarySoft = Color(0xFF3A3010);
  static const Color darkOnPrimary = Color(0xFF1A1400);
  static const Color darkSos = Color(0xFFFF5A4E);
  static const Color darkInfo = Color(0xFF3CC6D0);
  static const Color darkSuccess = Color(0xFF4CD08A);
  static const Color darkWarning = Color(0xFFFFA033);

  // Low-Power OLED Colors (True #000000 Black)
  static const Color oledBg = Color(0xFF000000);
  static const Color oledBgAlt = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF101010);
  static const Color oledSurfaceSunken = Color(0xFF000000);
  static const Color oledBorder = Color(0xFF222222);
  static const Color oledBorderStrong = Color(0xFF333333);
  static const Color oledText = Color(0xFFEEF2F8);
  static const Color oledTextMuted = Color(0xFF888888);
  static const Color oledPrimary = Color(0xFFFFD21F);
  static const Color oledPrimarySoft = Color(0xFF222005);
  static const Color oledSos = Color(0xFFFF5A4E);
  static const Color oledInfo = Color(0xFF3CC6D0);
  static const Color oledSuccess = Color(0xFF4CD08A);
  static const Color oledWarning = Color(0xFFFFA033);

  // Component Sizes (dp)
  static const double touchMin = 48.0;
  static const double buttonPrimary = 56.0;
  static const double inputHeight = 52.0;
  static const double statusStrip = 40.0;
  static const double tabBarHeight = 64.0;
  static const double sosHomeSize = 176.0;

  // Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 999.0;
}
