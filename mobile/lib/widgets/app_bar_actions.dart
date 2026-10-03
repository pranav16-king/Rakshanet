import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../screens/profile/profile_screen.dart';

/// Reusable Theme Toggle Action Button for Top AppBars
/// Displays the active theme icon with quick 1-tap theme switcher modal sheet
/// and instant toggle cycling.
class ThemeToggleButton extends StatelessWidget {
  final bool compact;

  const ThemeToggleButton({
    super.key,
    this.compact = false,
  });

  void _showThemePicker(BuildContext context, ThemeProvider theme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.isLight
                          ? AppTokens.lightBorderStrong
                          : AppTokens.darkBorderStrong,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Theme Mode',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Light Mode Option
                _buildThemeOption(
                  context: ctx,
                  theme: theme,
                  title: 'Light Theme',
                  subtitle: 'Optimized for high-glare direct sunlight visibility (#FFFCEB)',
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFD97706),
                  isSelected: theme.isLight && !theme.isLowPower,
                  onTap: () {
                    theme.setThemeMode(AppThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),

                // 2. Dark Mode Option
                _buildThemeOption(
                  context: ctx,
                  theme: theme,
                  title: 'Dark Theme',
                  subtitle: 'Night navy tactical command mode with Signal Yellow (#0B1220)',
                  icon: Icons.dark_mode_rounded,
                  iconColor: AppTokens.signalYellow,
                  isSelected: theme.isDark && !theme.isLowPower,
                  onTap: () {
                    theme.setThemeMode(AppThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),

                // 3. Low-Power OLED Option
                _buildThemeOption(
                  context: ctx,
                  theme: theme,
                  title: 'Low-Power OLED (Pure Black)',
                  subtitle: 'Turns off display pixels for maximum battery life (#000000)',
                  icon: Icons.battery_saver_rounded,
                  iconColor: const Color(0xFF10B981),
                  isSelected: theme.isLowPower,
                  onTap: () {
                    theme.setLowPower(true);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.isLight
                  ? AppTokens.signalYellow.withValues(alpha: 0.18)
                  : AppTokens.signalYellow.withValues(alpha: 0.12))
              : theme.bgAlt,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isSelected ? AppTokens.signalYellow : theme.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTokens.signalYellow,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider? theme;
    try {
      theme = Provider.of<ThemeProvider>(context);
    } catch (_) {}

    final isLowPower = theme?.isLowPower ?? false;
    final isLight = theme?.isLight ?? false;
    final border = theme?.border ?? AppTokens.darkBorder;

    IconData icon;
    Color iconColor;
    String tooltip;

    if (isLowPower) {
      icon = Icons.battery_saver_rounded;
      iconColor = const Color(0xFF10B981);
      tooltip = 'Theme: OLED Low-Power (Tap to switch)';
    } else if (isLight) {
      icon = Icons.dark_mode_rounded;
      iconColor = AppTokens.lightPrimaryInk;
      tooltip = 'Theme: Light Mode (Tap to switch)';
    } else {
      icon = Icons.light_mode_rounded;
      iconColor = AppTokens.signalYellow;
      tooltip = 'Theme: Dark Mode (Tap to switch)';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isLowPower
            ? AppTokens.oledSurface
            : (isLight ? AppTokens.lightBgAlt : AppTokens.darkBgAlt),
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: compact ? 20 : 22),
        tooltip: tooltip,
        constraints: BoxConstraints(
          minWidth: compact ? 36 : AppTokens.touchMin,
          minHeight: compact ? 36 : AppTokens.touchMin,
        ),
        onPressed: () {
          if (theme != null) {
            _showThemePicker(context, theme);
          }
        },
      ),
    );
  }
}

/// Reusable Profile Avatar Action Button for Top AppBars
/// Displays user initials/avatar and navigates to ProfileScreen
class ProfileAvatarButton extends StatelessWidget {
  final bool compact;

  const ProfileAvatarButton({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider? theme;
    try {
      theme = Provider.of<ThemeProvider>(context);
    } catch (_) {}

    ProfileProvider? profileProvider;
    try {
      profileProvider = Provider.of<ProfileProvider>(context);
    } catch (_) {}

    final isLight = theme?.isLight ?? false;
    final isLowPower = theme?.isLowPower ?? false;
    final border = theme?.border ?? AppTokens.darkBorder;
    final surface = theme?.surface ?? AppTokens.darkSurface;

    final profile = profileProvider?.profile;
    final name = profile?.name.trim() ?? '';
    final hasName = name.isNotEmpty;
    final initial = hasName ? name[0].toUpperCase() : 'U';
    final bloodGroup = profile?.bloodGroup.trim() ?? '';
    final isRegistered = profileProvider?.isRegistered ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: 'Profile & Volunteer (${hasName ? name : 'Anonymous'})',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: isLight
                      ? AppTokens.signalYellow.withValues(alpha: 0.22)
                      : (isLowPower
                          ? AppTokens.oledSurface
                          : const Color(0xFF1E2D4A)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRegistered
                        ? AppTokens.signalYellow
                        : border,
                    width: isRegistered ? 1.6 : 1.0,
                  ),
                ),
                child: Center(
                  child: hasName
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: isLight
                                ? AppTokens.lightPrimaryInk
                                : AppTokens.signalYellow,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: isLight
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow,
                          size: compact ? 20 : 22,
                        ),
                ),
              ),

              // Mini blood group or registered badge
              if (bloodGroup.isNotEmpty && bloodGroup != 'Unknown')
                Positioned(
                  bottom: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTokens.sosRed,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: surface, width: 1.2),
                    ),
                    child: Text(
                      bloodGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                )
              else if (isRegistered)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
