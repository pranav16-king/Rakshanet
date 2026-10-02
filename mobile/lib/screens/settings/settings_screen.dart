import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _prefOfflineModeKey = 'rakshanet_offline_mode';
  static const String _prefLocationSharingKey = 'rakshanet_location_sharing';
  static const String _prefAutoSyncKey = 'rakshanet_auto_sync';

  bool _offlineMode = true;
  bool _locationSharing = true;
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _offlineMode = prefs.getBool(_prefOfflineModeKey) ?? true;
          _locationSharing = prefs.getBool(_prefLocationSharingKey) ?? true;
          _autoSync = prefs.getBool(_prefAutoSyncKey) ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _setOfflineMode(bool val) async {
    setState(() => _offlineMode = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefOfflineModeKey, val);
    } catch (_) {}
  }

  Future<void> _setLocationSharing(bool val) async {
    setState(() => _locationSharing = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLocationSharingKey, val);
    } catch (_) {}
  }

  Future<void> _setAutoSync(bool val) async {
    setState(() => _autoSync = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAutoSyncKey, val);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final isLowPower = themeProvider.isLowPower;
    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;
    const greenActiveColor = Color(0xFF4CD08A);

    return Scaffold(
      backgroundColor: themeProvider.bg,
      appBar: AppBar(
        backgroundColor: themeProvider.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Toggle switches card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // 1. Offline Mode
                _buildSwitchTile(
                  icon: Icons.signal_cellular_off,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Offline Mode',
                  subtitle: 'Always work without internet',
                  value: _offlineMode,
                  onChanged: _setOfflineMode,
                  activeColor: greenActiveColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 2. Location Sharing
                _buildSwitchTile(
                  icon: Icons.location_on,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Location Sharing',
                  subtitle: 'Share when available',
                  value: _locationSharing,
                  onChanged: _setLocationSharing,
                  activeColor: greenActiveColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 3. Auto Sync
                _buildSwitchTile(
                  icon: Icons.sync,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Auto Sync',
                  subtitle: 'Send to government when internet is back',
                  value: _autoSync,
                  onChanged: _setAutoSync,
                  activeColor: greenActiveColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 4. Low Power Theme
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Low Power Theme',
                  subtitle: 'Save battery (dark mode / OLED)',
                  value: isLowPower,
                  onChanged: (val) {
                    themeProvider.setLowPower(val);
                  },
                  activeColor: greenActiveColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Navigation rows card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // Language
                _buildNavTile(
                  icon: Icons.language,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Language',
                  subtitle: profileProvider.profile.preferredLanguage == 'hi'
                      ? 'Hindi (हिंदी)'
                      : profileProvider.profile.preferredLanguage == 'mr'
                          ? 'Marathi (मराठी)'
                          : 'English',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showLanguageDialog(context),
                ),

                // Privacy & Security
                _buildNavTile(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'Privacy & Security',
                  subtitle: 'End-to-end encryption',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showPrivacyDialog(context),
                ),

                // About
                _buildNavTile(
                  icon: Icons.info_outline,
                  iconBg: const Color(0xFF1E2D4A),
                  iconColor: Colors.white,
                  title: 'About',
                  subtitle: 'SignalRescue AI v1.0',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick link to Volunteer Profile (Screen 13)
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTokens.signalYellow.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      color: AppTokens.signalYellow,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileProvider.profile.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${profileProvider.profile.meshId} • View Volunteer Profile',
                          style: TextStyle(
                            color: textMutedColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: textMutedColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required Color textColor,
    required Color textMutedColor,
    required Color borderColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: AppTokens.touchMin,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: activeColor,
                  thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
            indent: 70,
            endIndent: 16,
          ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color textMutedColor,
    required Color borderColor,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textMutedColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textMutedColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
            indent: 70,
            endIndent: 16,
          ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: profileProvider.profile.preferredLanguage == 'en'
                  ? const Icon(Icons.check, color: AppTokens.signalYellow)
                  : null,
              onTap: () {
                profileProvider.updateProfile(preferredLanguage: 'en');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Hindi (हिंदी)'),
              trailing: profileProvider.profile.preferredLanguage == 'hi'
                  ? const Icon(Icons.check, color: AppTokens.signalYellow)
                  : null,
              onTap: () {
                profileProvider.updateProfile(preferredLanguage: 'hi');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Marathi (मराठी)'),
              trailing: profileProvider.profile.preferredLanguage == 'mr'
                  ? const Icon(Icons.check, color: AppTokens.signalYellow)
                  : null,
              onTap: () {
                profileProvider.updateProfile(preferredLanguage: 'mr');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'SignalRescue AI uses cryptographic peer-to-peer security with Ed25519 signatures. '
          'All communication remains anonymous across mesh relays until reaching authorized '
          'emergency responders. No cloud telemetry or third-party trackers are used.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SignalRescue AI (RakshaNet)'),
        content: const Text(
          'Version 1.0.0 (Production Build)\n\n'
          'Engineered for extreme offline disaster resilience with BLE 5.x multi-hop relay, '
          'store-and-forward outbox synchronization, and low-power OLED emergency mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
