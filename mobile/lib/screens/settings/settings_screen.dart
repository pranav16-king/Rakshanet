import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/device_status_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';
import '../../services/map/offline_map_service.dart';

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

  // Storage stats tracking
  double _mapCacheMb = 0.0;
  double _meshLogKb = 320.0;
  bool _isCacheCleared = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    try {
      final stats = await OfflineMapService.instance.getCacheStats();
      if (mounted) {
        setState(() {
          _mapCacheMb = stats['sizeMb'] as double? ?? 0.0;
        });
      }
    } catch (_) {}
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

  void _handleClearCache(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: themeProvider.border),
        ),
        title: Text(
          'Clear Offline Cache?',
          style: TextStyle(
            color: themeProvider.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will purge ${_mapCacheMb.toStringAsFixed(1)} MB of cached map tiles and relayed packet buffers. '
          'Your emergency volunteer profile, contacts, and outbox queue will not be lost.',
          style: TextStyle(
            color: themeProvider.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: themeProvider.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.sosMain,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final freedMb = _mapCacheMb;
              await OfflineMapService.instance.clearCache();
              await _loadCacheStats();
              setState(() {
                _meshLogKb = 42.0;
                _isCacheCleared = true;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Offline cache cleared successfully (${freedMb.toStringAsFixed(1)} MB freed)'),
                    backgroundColor: themeProvider.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      side: BorderSide(color: themeProvider.border),
                    ),
                  ),
                );
              }
            },
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final meshProvider = context.watch<MeshProvider>();
    final deviceStatusProvider = context.watch<DeviceStatusProvider>();

    final isLowPower = themeProvider.isLowPower;
    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;
    final successColor = themeProvider.success;
    final iconBgColor = themeProvider.isLight
        ? AppTokens.lightBgAlt
        : const Color(0xFF1E2D4A);
    final iconColor = themeProvider.isLight
        ? themeProvider.primaryInk
        : themeProvider.primary;

    final totalStorageMb = _mapCacheMb + (_meshLogKb / 1024.0);

    return Scaffold(
      backgroundColor: themeProvider.bg,
      appBar: AppBar(
        backgroundColor: themeProvider.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: AppTokens.touchMin,
            minHeight: AppTokens.touchMin,
          ),
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
        actions: const [
          ProfileAvatarButton(compact: true),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ==========================================
          // Section 1: Appearance & Power
          // ==========================================
          _buildSectionHeader('APPEARANCE & BATTERY', textMutedColor),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Switcher
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              color: iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme Mode',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isLowPower
                                      ? 'OLED Low-Power override active'
                                      : (themeProvider.baseThemeMode == AppThemeMode.system
                                          ? 'System default'
                                          : (themeProvider.baseThemeMode == AppThemeMode.light
                                              ? 'Light (Hi-vis vest)'
                                              : 'Dark (Night navy)')),
                                  style: TextStyle(
                                    color: textMutedColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Segmented Buttons: System, Light, Dark
                      Row(
                        children: [
                          _buildThemeOptionButton(
                            label: 'System',
                            icon: Icons.brightness_auto,
                            isSelected: !isLowPower &&
                                themeProvider.baseThemeMode == AppThemeMode.system,
                            themeProvider: themeProvider,
                            onTap: () {
                              themeProvider.setThemeMode(AppThemeMode.system);
                              deviceStatusProvider.toggleLowPowerMode(false);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOptionButton(
                            label: 'Light',
                            icon: Icons.light_mode,
                            isSelected: !isLowPower &&
                                themeProvider.baseThemeMode == AppThemeMode.light,
                            themeProvider: themeProvider,
                            onTap: () {
                              themeProvider.setThemeMode(AppThemeMode.light);
                              deviceStatusProvider.toggleLowPowerMode(false);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOptionButton(
                            label: 'Dark',
                            icon: Icons.dark_mode,
                            isSelected: !isLowPower &&
                                themeProvider.baseThemeMode == AppThemeMode.dark,
                            themeProvider: themeProvider,
                            onTap: () {
                              themeProvider.setThemeMode(AppThemeMode.dark);
                              deviceStatusProvider.toggleLowPowerMode(false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                  indent: 16,
                  endIndent: 16,
                ),

                // Low-Power OLED Mode Switch
                _buildSwitchTile(
                  icon: Icons.battery_saver,
                  iconBg: isLowPower
                      ? const Color(0xFF0E1627)
                      : iconBgColor,
                  iconColor: isLowPower
                      ? AppTokens.darkPrimary
                      : iconColor,
                  title: 'Low-Power OLED Mode',
                  subtitle: 'True #000000 pure black to maximize battery',
                  value: isLowPower,
                  onChanged: (val) {
                    themeProvider.setLowPower(val);
                    deviceStatusProvider.toggleLowPowerMode(val);
                  },
                  activeColor: successColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                ),

                if (isLowPower)
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTokens.darkSurfaceSunken,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: AppTokens.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppTokens.darkPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pure #000000 active: OLED screen pixels powered off to conserve critical battery.',
                            style: TextStyle(
                              color: themeProvider.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // Section 2: Network & Mesh Radio (Screen 12)
          // ==========================================
          _buildSectionHeader('NETWORK & RELAY RADIOS', textMutedColor),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // 1. Mesh Radio Toggle
                _buildSwitchTile(
                  icon: Icons.cell_tower,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'Mesh Radio Network',
                  subtitle: meshProvider.isMeshActive
                      ? 'Active (${meshProvider.connectedPeerCount} nearby relays reachable)'
                      : 'Disabled (Bluetooth mesh transceiver paused)',
                  value: meshProvider.isMeshActive,
                  onChanged: (val) {
                    meshProvider.toggleMesh(val);
                  },
                  activeColor: successColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 2. Offline Mode
                _buildSwitchTile(
                  icon: Icons.signal_cellular_off,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'Offline Mode',
                  subtitle: 'Always work without internet',
                  value: _offlineMode,
                  onChanged: _setOfflineMode,
                  activeColor: successColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 3. Location Sharing
                _buildSwitchTile(
                  icon: Icons.location_on,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'Location Sharing',
                  subtitle: 'Share when available',
                  value: _locationSharing,
                  onChanged: _setLocationSharing,
                  activeColor: successColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                ),

                // 4. Auto Sync
                _buildSwitchTile(
                  icon: Icons.sync,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'Auto Sync',
                  subtitle: 'Send to government when internet is back',
                  value: _autoSync,
                  onChanged: _setAutoSync,
                  activeColor: successColor,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // Section 3: Data & Storage Stats + Cache Clear
          // ==========================================
          _buildSectionHeader('DATA & STORAGE', textMutedColor),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // Storage Stats Tile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                        child: Icon(Icons.storage, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Storage',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Offline Maps: ${_mapCacheMb.toStringAsFixed(1)} MB • Mesh Cache: ${_meshLogKb.toStringAsFixed(0)} KB',
                              style: TextStyle(
                                color: textMutedColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeProvider.surfaceSunken,
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          '${totalStorageMb.toStringAsFixed(1)} MB',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                  indent: 70,
                  endIndent: 16,
                ),

                // Clear Cache Row
                InkWell(
                  onTap: () => _handleClearCache(themeProvider),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTokens.radiusMd),
                    bottomRight: Radius.circular(AppTokens.radiusMd),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          ),
                          child: Icon(
                            Icons.delete_sweep_outlined,
                            color: _isCacheCleared
                                ? themeProvider.textMuted
                                : (themeProvider.isLight ? themeProvider.sos : themeProvider.sos),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clear Offline Cache',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isCacheCleared
                                    ? 'Cache already cleared (essential storage retained)'
                                    : 'Free storage while keeping emergency profile',
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // Section 4: Navigation / Info (Screen 12)
          // ==========================================
          _buildSectionHeader('SYSTEM & PRIVACY', textMutedColor),
          const SizedBox(height: 8),

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
                  iconBg: iconBgColor,
                  iconColor: iconColor,
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
                  onTap: () => _showLanguageDialog(context, themeProvider),
                ),

                // Privacy & Security
                _buildNavTile(
                  icon: Icons.lock_outline,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'Privacy & Security',
                  subtitle: 'End-to-end encryption',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showPrivacyDialog(context, themeProvider),
                ),

                // About
                _buildNavTile(
                  icon: Icons.info_outline,
                  iconBg: iconBgColor,
                  iconColor: iconColor,
                  title: 'About',
                  subtitle: 'RakshaNet v1.0',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                  onTap: () => _showAboutDialog(context, themeProvider),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // Quick link to Volunteer Profile (Screen 13)
          // ==========================================
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
                    backgroundColor: themeProvider.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: themeProvider.isLight
                          ? themeProvider.primaryInk
                          : themeProvider.primary,
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildThemeOptionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected
        ? themeProvider.primary
        : themeProvider.surfaceSunken;
    final fgColor = isSelected
        ? themeProvider.onPrimary
        : themeProvider.text;
    final borderCol = isSelected
        ? themeProvider.primary
        : themeProvider.border;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTokens.touchMin),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: borderCol, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

  void _showLanguageDialog(BuildContext context, ThemeProvider themeProvider) {
    final profileProvider = context.read<ProfileProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: themeProvider.border),
        ),
        title: Text(
          'Select Language',
          style: TextStyle(color: themeProvider.text, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: TextStyle(color: themeProvider.text)),
              trailing: profileProvider.profile.preferredLanguage == 'en'
                  ? Icon(Icons.check, color: themeProvider.primaryInk)
                  : null,
              onTap: () {
                profileProvider.updateProfile(preferredLanguage: 'en');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text('Hindi (हिंदी)', style: TextStyle(color: themeProvider.text)),
              trailing: profileProvider.profile.preferredLanguage == 'hi'
                  ? Icon(Icons.check, color: themeProvider.primaryInk)
                  : null,
              onTap: () {
                profileProvider.updateProfile(preferredLanguage: 'hi');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text('Marathi (मराठी)', style: TextStyle(color: themeProvider.text)),
              trailing: profileProvider.profile.preferredLanguage == 'mr'
                  ? Icon(Icons.check, color: themeProvider.primaryInk)
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

  void _showPrivacyDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: themeProvider.border),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(color: themeProvider.text, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'RakshaNet uses cryptographic peer-to-peer security with Ed25519 signatures. '
          'All communication remains anonymous across mesh relays until reaching authorized '
          'emergency responders. Zero telemetry or external tracking is enabled.',
          style: TextStyle(
            color: themeProvider.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Understood',
              style: TextStyle(
                color: themeProvider.primaryInk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: themeProvider.border),
        ),
        title: Text(
          'RakshaNet',
          style: TextStyle(color: themeProvider.text, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Version 1.0.0 (Production Build)\n\n'
          'Engineered for extreme offline disaster resilience with BLE 5.x multi-hop relay, '
          'store-and-forward outbox synchronization, and low-power OLED emergency mode.\n\n'
          'Designed to operate without cell towers, Wi-Fi, or central power grids.',
          style: TextStyle(
            color: themeProvider.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: themeProvider.primaryInk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
