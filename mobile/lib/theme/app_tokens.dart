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
  static const Color warningAmber = Color(0xFFF59E0B);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFFFFCEB);
  static const Color lightBgAlt = Color(0xFFFFF5C2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSunken = Color(0xFFF6F0D4);
  static const Color lightBorder = Color(0xFFE6DCA8);
  static const Color lightBorderStrong = Color(0xFFC9BB6E);
  static const Color lightText = Color(0xFF16202D);
  static const Color lightTextMuted = Color(0xFF566070);
  static const Color lightTextDisabled = Color(0xFF9AA1AB);
  static const Color lightPrimary = Color(0xFFFFC400);
  static const Color lightPrimaryPressed = Color(0xFFE0AA00);
  static const Color lightPrimaryInk = Color(0xFF8A5A00); // 4.5:1 contrast on light backgrounds
  static const Color lightPrimarySoft = Color(0xFFFFEFA6);
  static const Color lightOnPrimary = Color(0xFF1A1400);
  static const Color lightSos = Color(0xFFD92D20);
  static const Color lightSosPressed = Color(0xFFB42318);
  static const Color lightSosSoft = Color(0xFFFDE2DF);
  static const Color lightInfo = Color(0xFF0E8A94);
  static const Color lightInfoSoft = Color(0xFFD6F1F3);
  static const Color lightSuccess = Color(0xFF1E8E4E);
  static const Color lightSuccessSoft = Color(0xFFD9F2E3);
  static const Color lightWarning = Color(0xFFE07B00);
  static const Color lightWarningSoft = Color(0xFFFFE6C7);
  static const Color lightScrim = Color(0x7B16202D);

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
  static const Color darkTextDisabled = Color(0xFF5F6E86);
  static const Color darkPrimary = Color(0xFFFFD21F);
  static const Color darkPrimaryPressed = Color(0xFFE6B800);
  static const Color darkPrimaryInk = Color(0xFFFFD21F);
  static const Color darkPrimarySoft = Color(0xFF3A3010);
  static const Color darkOnPrimary = Color(0xFF1A1400);
  static const Color darkSos = Color(0xFFFF5A4E);
  static const Color darkSosMain = Color(0xFFD92D20); // Main SOS button #D92D20 in both themes
  static const Color darkSosPressed = Color(0xFFE0463B);
  static const Color darkSosSoft = Color(0xFF3A1512);
  static const Color darkInfo = Color(0xFF3CC6D0);
  static const Color darkInfoSoft = Color(0xFF0F3037);
  static const Color darkSuccess = Color(0xFF4CD08A);
  static const Color darkSuccessSoft = Color(0xFF0F3322);
  static const Color darkWarning = Color(0xFFFFA033);
  static const Color darkWarningSoft = Color(0xFF3A2508);
  static const Color darkScrim = Color(0xA3000000);

  // Low-Power OLED Colors (True #000000 Black)
  static const Color oledBg = Color(0xFF000000);
  static const Color oledBgAlt = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0E1627);
  static const Color oledSurfaceSunken = Color(0xFF000000);
  static const Color oledBorder = Color(0xFF26344F);
  static const Color oledBorderStrong = Color(0xFF3A4C70);
  static const Color oledText = Color(0xFFEEF2F8);
  static const Color oledTextMuted = Color(0xFF9FADC2);
  static const Color oledTextDisabled = Color(0xFF5F6E86);
  static const Color oledPrimary = Color(0xFFFFD21F);
  static const Color oledPrimaryPressed = Color(0xFFE6B800);
  static const Color oledPrimaryInk = Color(0xFFFFD21F);
  static const Color oledPrimarySoft = Color(0xFF3A3010);
  static const Color oledOnPrimary = Color(0xFF1A1400);
  static const Color oledSos = Color(0xFFFF5A4E);
  static const Color oledSosMain = Color(0xFFD92D20);
  static const Color oledSosPressed = Color(0xFFE0463B);
  static const Color oledSosSoft = Color(0xFF3A1512);
  static const Color oledInfo = Color(0xFF3CC6D0);
  static const Color oledInfoSoft = Color(0xFF0F3037);
  static const Color oledSuccess = Color(0xFF4CD08A);
  static const Color oledSuccessSoft = Color(0xFF0F3322);
  static const Color oledWarning = Color(0xFFFFA033);
  static const Color oledWarningSoft = Color(0xFF3A2508);
  static const Color oledScrim = Color(0xA3000000);

  // Component Sizes (dp)
  static const double touchMin = 48.0;
  static const double buttonPrimary = 56.0;
  static const double buttonSecondary = 48.0;
  static const double inputHeight = 52.0;
  static const double listRowMin = 64.0;
  static const double statusStrip = 40.0;
  static const double tabBarHeight = 64.0;
  static const double appBarHeight = 56.0;
  static const double sosHomeSize = 176.0;
  static const double sosScreenMax = 280.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconHero = 64.0;

  // Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 999.0;
}
