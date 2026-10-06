import 'package:flutter/material.dart';

/// Dedicated design system tokens for the Emergency Profile, Dashboard & Mesh UI.
/// Follows the strict government/emergency-response specification.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFF070D18);
  static const Color secondarySurface = Color(0xFF0D1626);
  static const Color cardSurface = Color(0xFF111D31);
  static const Color elevatedSurface = Color(0xFF16243A);

  // Dashboard Connectivity Card & Navigation Surfaces
  static const Color connectivityCardBg = Color(0xFF101A2B);
  static const Color connectivityCardBorder = Color(0xFF243653);
  static const Color bottomNavBg = Color(0xFF080F1C);

  // Borders
  static const Color border = Color(0xFF263A56);
  static const Color borderSubtle = Color(0xFF1C2C44);

  // Accents & Semantic States
  static const Color primaryAmber = Color(0xFFFFB800);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color blue = Color(0xFF3B82F6);
  static const Color aiPurple = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF35D07F);
  static const Color danger = Color(0xFFFF4D5D);
  static const Color sosRed = Color(0xFFEF4444);
  static const Color sosRedDark = Color(0xFFB91C1C);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA9B7CC);
  static const Color textMuted = Color(0xFF71819A);
  static const Color textOnAmber = Color(0xFF070D18);
}

/// Consistent 8dp base spacing system.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// Standardized corner radii (12–24dp).
class AppRadius {
  AppRadius._();

  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double card = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// Clean, high-contrast emergency-response typography hierarchy.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static const TextStyle pageTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle pageSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle headerTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.15,
  );

  static const TextStyle headerSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle statusValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle statusSecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle sosLabel = TextStyle(
    color: Colors.white,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.0,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle inputText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle placeholder = TextStyle(
    color: AppColors.textMuted,
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle helper = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle errorText = TextStyle(
    color: AppColors.danger,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

/// Restrained, soft elevation shadows (no excessive glow).
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> sosControlled = [
    BoxShadow(
      color: Color(0x40EF4444),
      blurRadius: 22,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 12,
      offset: Offset(0, -2),
    ),
  ];
}

/// Alias for backward compatibility with profile components.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = AppElevation.card;
  static const List<BoxShadow> stickyBar = AppElevation.bottomNav;
}
