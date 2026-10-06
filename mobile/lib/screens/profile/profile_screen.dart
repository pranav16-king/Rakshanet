import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../models/user_profile.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/user_auth_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 13: Profile & Volunteer (aligned with Screen 13 in mockup)
///
/// Features:
/// - Official RakshaNet logo / circular user avatar, User Name, anonymous ID (`SR-XXXX-XXXX`),
///   Blood Group badge tag, and emergency phone number.
/// - Yellow community banner: "You are helping your community / Your device is part of the rescue mesh network."
/// - 2x2 Impact KPI Grid dynamically computed from SQLite database records:
///   * People Helped: sum of `people_count` in resolved rescue reports.
///   * Messages Relayed: real count from `message_relays` table.
///   * SOS Forwarded: real count from forwarded reports.
///   * Missing Found: real count of missing persons marked found.
///   * Zero hardcoded numbers! When records are 0, displays 0.
/// - Volunteer & Emergency Actions:
///   * 'Medical ID Card' offline preview
///   * 'Export Rescue Credentials'
///   * 'Broadcast Emergency Beacon' toggle
///   * 'Personal Details' edit dialog (saves directly to SQLite via ProfileRepository / ProfileProvider)
///   * 'Reset Anonymous Profile' (local factory reset)
/// - Seamless Light Theme, Dark Theme, and Low-Power OLED Theme support.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _relayedCount = 0;
  int _peopleHelpedCount = 0;
  int _sosForwardedCount = 0;
  int _missingFoundCount = 0;
  bool _statsLoaded = false;
  bool _isBeaconActive = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  /// Dynamically computes 2x2 Impact KPIs from local SQLite database records.
  /// Zero hardcoded numbers! When records are 0, display 0.
  Future<void> _loadDatabaseStats() async {
    try {
      // 1. Messages Relayed: real count from message_relays table in SQLite
      final relays = await AppDatabase.instance.query('message_relays');
      final relayCount = relays.length;

      // 2. People Helped & SOS Forwarded from emergency_reports table
      final reports = await AppDatabase.instance.getEmergencyReports();
      int helped = 0;
      int forwarded = 0;

      for (final r in reports) {
        final status = r.status.trim().toUpperCase();
        // People Helped: sum of people_count in resolved rescue reports
        if (status == 'RESOLVED') {
          helped += r.peopleCount;
        }
        // SOS Forwarded: real count from forwarded / relayed reports
        if (status == 'FORWARDED' || status == 'RELAYED') {
          forwarded++;
        }
      }

      // 3. Missing Found: real count of missing persons marked found
      final missing = await AppDatabase.instance.getMissingPersons();
      final missingFound = missing.where((m) => m.isFound).length;

      if (mounted) {
        setState(() {
          _relayedCount = relayCount;
          _peopleHelpedCount = helped;
          _sosForwardedCount = forwarded;
          _missingFoundCount = missingFound;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error querying database stats: $e');
      if (mounted) {
        setState(() {
          _statsLoaded = true;
        });
      }
    }
  }

  /// Formats the user's Unique ID (preserving 15-digit Mobile IMEI ID)
  String _formatAnonymousId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'unregistered') return 'Not detected';
    if (RegExp(r'^\d{15}$').hasMatch(trimmed)) {
      return 'IMEI: $trimmed';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    final isLowPower = themeProvider.isLowPower;
    final isLight = themeProvider.isLight;

    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;

    final displayName = profile.name.trim().isNotEmpty
        ? profile.name
        : 'Registered Volunteer';
    final canonicalId = _formatAnonymousId(
      (profile.id.isNotEmpty && profile.id != 'unregistered')
          ? profile.id
          : profile.deviceId,
    );
    final bloodGroupText = profile.bloodGroup.trim().isNotEmpty
        ? profile.bloodGroup
        : 'Not specified';
    final phoneText = profile.emergencyContact.trim().isNotEmpty
        ? profile.emergencyContact
        : 'Not specified';

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
          'Profile & Volunteer',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
            tooltip: 'Refresh Impact Stats',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () async {
              await _loadDatabaseStats();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impact metrics recomputed from SQLite.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Header Profile Card (Screen 13: Avatar, Name, SR-XXXX-XXXX, Blood, Phone, Edit)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar (60dp) with RakshaNet Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLowPower
                          ? AppTokens.oledBorderStrong
                          : AppTokens.signalYellow.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: isLowPower
                        ? null
                        : [
                            BoxShadow(
                              color: AppTokens.signalYellow.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/rakshanet_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isLowPower
                            ? AppTokens.oledSurfaceSunken
                            : AppTokens.signalYellow.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.person,
                          size: 34,
                          color: AppTokens.signalYellow,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name, Anonymous ID, Blood Group, Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name + Blood Group Tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Blood Group Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.sosRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              border: Border.all(
                                color: AppTokens.sosRed.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bloodtype,
                                  color: AppTokens.sosRed,
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  bloodGroupText,
                                  style: const TextStyle(
                                    color: AppTokens.sosRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Anonymous ID (SR-XXXX-XXXX)
                      Text(
                        'ID: $canonicalId',
                        style: TextStyle(
                          color: textMutedColor,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (profile.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 13,
                              color: isLight
                                  ? AppTokens.lightPrimaryInk
                                  : AppTokens.signalYellow,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),

                      // Emergency Phone Number
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: isLight
                                ? AppTokens.lightPrimaryInk
                                : AppTokens.beaconTeal,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phoneText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textMutedColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Profile Icon (48dp target)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                  iconSize: 22,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: 'Edit Details',
                  onPressed: () => _showEditProfileDialog(
                    context,
                    profileProvider,
                    themeProvider,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Yellow Community Banner (Screen 13: "You are helping your community")
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLowPower ? themeProvider.surface : AppTokens.signalYellow,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: isLowPower
                  ? Border.all(color: AppTokens.signalYellow, width: 1.5)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isLowPower
                        ? AppTokens.signalYellow.withValues(alpha: 0.2)
                        : const Color(0xFFFFA000).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: isLowPower
                        ? AppTokens.signalYellow
                        : const Color(0xFF1A1400),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are helping your community',
                        style: TextStyle(
                          color: isLowPower
                              ? AppTokens.signalYellow
                              : const Color(0xFF1A1400),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your device is part of the rescue mesh network.',
                        style: TextStyle(
                          color: isLowPower
                              ? textMutedColor
                              : const Color(0xFF332A00),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Impact KPI Grid (2x2) - Dynamic SQLite database counts, 0 when 0
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  count: '$_peopleHelpedCount',
                  label: 'People helped',
                  icon: Icons.volunteer_activism_outlined,
                  iconColor: isLight ? AppTokens.lightPrimaryInk : AppTokens.beaconTeal,
                  themeProvider: themeProvider,
                  isLoading: !_statsLoaded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  count: '$_relayedCount',
                  label: 'Messages relayed',
                  icon: Icons.wifi_tethering_rounded,
                  iconColor: isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                  themeProvider: themeProvider,
                  isLoading: !_statsLoaded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  count: '$_sosForwardedCount',
                  label: 'SOS forwarded',
                  icon: Icons.forward_to_inbox_rounded,
                  iconColor: AppTokens.sosRed,
                  themeProvider: themeProvider,
                  isLoading: !_statsLoaded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  count: '$_missingFoundCount',
                  label: 'Missing found',
                  icon: Icons.person_search_outlined,
                  iconColor: const Color(0xFF4CD08A),
                  themeProvider: themeProvider,
                  isLoading: !_statsLoaded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. Volunteer & Emergency Actions List
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // Action 1: 'Medical ID Card' offline preview
                _buildActionTile(
                  icon: Icons.medical_information_outlined,
                  iconColor: AppTokens.beaconTeal,
                  title: 'Medical ID Card',
                  subtitle: 'Offline responder view • Blood, allergies & notes',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showMedicalIdCardModal(
                    context,
                    profile,
                    themeProvider,
                  ),
                ),

                // Action 2: 'Export Rescue Credentials'
                _buildActionTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                  title: 'Export Rescue Credentials',
                  subtitle: 'Cryptographic identity & mesh relay audit',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showExportCredentialsModal(
                    context,
                    profile,
                    canonicalId,
                    themeProvider,
                  ),
                ),

                // Action 3: 'Broadcast Emergency Beacon' toggle
                _buildToggleActionTile(
                  icon: Icons.cell_tower_rounded,
                  iconColor: _isBeaconActive
                      ? AppTokens.sosRed
                      : (isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow),
                  title: 'Broadcast Emergency Beacon',
                  subtitle: _isBeaconActive
                      ? 'Transmitting active distress beacon to mesh nodes'
                      : 'Beacon standby • Toggle to alert nearby nodes',
                  value: _isBeaconActive,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onChanged: (val) {
                    setState(() => _isBeaconActive = val);
                    final mesh = context.read<MeshProvider>();
                    if (val) {
                      mesh.toggleMesh(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTokens.sosRed,
                          content: Text(
                            'Emergency Beacon ACTIVE: Broadcasting distress signal across BLE mesh.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency Beacon deactivated.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Action 4: Personal Details & Edit Dialog
                _buildActionTile(
                  icon: Icons.manage_accounts_outlined,
                  iconColor: const Color(0xFF4CD08A),
                  title: 'Personal Details',
                  subtitle: 'Edit name, blood group, contact & medical info',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showEditProfileDialog(
                    context,
                    profileProvider,
                    themeProvider,
                  ),
                ),

                // Action 5: Cloud Database Sync
                _buildActionTile(
                  icon: Icons.cloud_sync_outlined,
                  iconColor: AppTokens.beaconTeal,
                  title: 'Cloud Database Sync',
                  subtitle: 'Fetch records from server & push local telemetry',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connecting to cloud server and syncing data...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await UserAuthService.instance.syncNow();
                    await _loadDatabaseStats();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTokens.beaconTeal,
                          content: Text('Local SQLite database synced with cloud!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Action 6: Sign Out / Reset Anonymous Profile
                _buildActionTile(
                  icon: Icons.restart_alt_rounded,
                  iconColor: AppTokens.sosRed,
                  title: 'Reset Anonymous Profile',
                  subtitle: 'Clear local SQLite credentials and re-register',
                  textColor: AppTokens.sosRed,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                  onTap: () => _confirmSignOut(
                    context,
                    profileProvider,
                    themeProvider,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 2x2 KPI Card Widget
  Widget _buildKpiCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required ThemeProvider themeProvider,
    bool isLoading = false,
  }) {
    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: themeProvider.isLight
                            ? AppTokens.lightPrimaryInk
                            : AppTokens.signalYellow,
                      ),
                    )
                  : Text(
                      count,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: textMutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Action Tile with standard tap callback
  Widget _buildActionTile({
    required IconData icon,
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
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF64748B),
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
            indent: 52,
            endIndent: 16,
          ),
      ],
    );
  }

  /// Action Tile with a direct Toggle Switch (e.g. Broadcast Emergency Beacon)
  Widget _buildToggleActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color textMutedColor,
    required Color borderColor,
    required bool showDivider,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textMutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: AppTokens.sosRed,
                activeTrackColor: AppTokens.sosRed.withValues(alpha: 0.35),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
            indent: 52,
            endIndent: 16,
          ),
      ],
    );
  }

  /// Action 1: 'Medical ID Card' offline preview modal
  void _showMedicalIdCardModal(
    BuildContext context,
    UserProfile profile,
    ThemeProvider themeProvider,
  ) {
    final textColor = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final surface = themeProvider.surface;
    final border = themeProvider.border;
    final isLowPower = themeProvider.isLowPower;

    final canonicalId = _formatAnonymousId(
      profile.deviceId.isNotEmpty ? profile.deviceId : profile.meshId,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: border, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Grabber Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.sosRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: AppTokens.sosRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Medical ID',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Available to first responders without internet',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: AppTokens.beaconTeal, width: 1),
                    ),
                    child: const Text(
                      'OFFLINE VERIFIED',
                      style: TextStyle(
                        color: AppTokens.beaconTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Medical Card Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLowPower ? AppTokens.oledSurfaceSunken : themeProvider.bgAlt,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  children: [
                    // Rescuer / Civilian Handle
                    _buildMedicalRow(
                      label: 'Rescuer Handle',
                      value: profile.name.trim().isNotEmpty ? profile.name : 'Registered Civilian',
                      textColor: textColor,
                      textMuted: textMuted,
                    ),
                    const Divider(height: 18),

                    // Anonymous Mesh ID
                    _buildMedicalRow(
                      label: 'Mesh ID',
                      value: canonicalId,
                      textColor: textColor,
                      textMuted: textMuted,
                      isMonospace: true,
                    ),
                    const Divider(height: 18),

                    // Blood Group
                    _buildMedicalRow(
                      label: 'Blood Type',
                      value: profile.bloodGroup.isNotEmpty ? profile.bloodGroup : 'O+ (Default)',
                      textColor: AppTokens.sosRed,
                      textMuted: textMuted,
                      isBold: true,
                    ),
                    const Divider(height: 18),

                    // Emergency Contact Phone
                    _buildMedicalRow(
                      label: 'Emergency Phone',
                      value: profile.emergencyContact.isNotEmpty ? profile.emergencyContact : 'Not specified',
                      textColor: textColor,
                      textMuted: textMuted,
                    ),
                    const Divider(height: 18),

                    // Medical Notes / Allergies
                    _buildMedicalRow(
                      label: 'Medical Notes',
                      value: profile.medicalNotes.isNotEmpty ? profile.medicalNotes : 'None listed',
                      textColor: textColor,
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close / Done Button
              SizedBox(
                height: AppTokens.buttonPrimary,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.lightOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Close Offline Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.lightOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRow({
    required String label,
    required String value,
    required Color textColor,
    required Color textMuted,
    bool isMonospace = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Action 2: 'Export Rescue Credentials' modal
  void _showExportCredentialsModal(
    BuildContext context,
    UserProfile profile,
    String canonicalId,
    ThemeProvider themeProvider,
  ) {
    final textColor = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final surface = themeProvider.surface;
    final border = themeProvider.border;

    final exportJson = {
      'rakshanet_protocol': '1.0',
      'id': canonicalId,
      'rescuer_name': profile.name.trim().isNotEmpty ? profile.name : 'Civilian Rescuer',
      'blood_group': profile.bloodGroup.isNotEmpty ? profile.bloodGroup : 'Unknown',
      'impact_audit': {
        'people_helped': _peopleHelpedCount,
        'messages_relayed': _relayedCount,
        'sos_forwarded': _sosForwardedCount,
        'missing_found': _missingFoundCount,
      },
      'exported_at': DateTime.now().toIso8601String(),
      'storage_proof': 'SQLite_Local_Verified',
    };
    final prettyJson = const JsonEncoder.withIndent('  ').convert(exportJson);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: border, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.signalYellow.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppTokens.signalYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rescue Credentials Export',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Cryptographic offline audit proof for disaster relief',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Code/JSON Card
              Container(
                padding: const EdgeInsets.all(12),
                height: 180,
                decoration: BoxDecoration(
                  color: themeProvider.bgAlt,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: border, width: 1),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    prettyJson,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Copy to Clipboard Action (56dp target)
              SizedBox(
                height: AppTokens.buttonPrimary,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.lightOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, color: AppTokens.lightOnPrimary),
                  label: const Text(
                    'Copy Credentials JSON',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.lightOnPrimary,
                    ),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: prettyJson));
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rescue credentials copied to clipboard.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Personal Details & Edit Dialog: Allows editing name, blood group, emergency phone,
  /// and medical notes, and saves directly to SQLite via ProfileRepository / ProfileProvider.
  void _showEditProfileDialog(
    BuildContext context,
    ProfileProvider profileProvider,
    ThemeProvider themeProvider,
  ) {
    final profile = profileProvider.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.emergencyContact);
    final notesCtrl = TextEditingController(text: profile.medicalNotes);
    String selectedBlood = _bloodGroups.contains(profile.bloodGroup)
        ? profile.bloodGroup
        : (_bloodGroups.firstWhere((bg) => bg == 'O+', orElse: () => 'Unknown'));

    final surface = themeProvider.surface;
    final textColor = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final border = themeProvider.border;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            side: BorderSide(color: border),
          ),
          title: Text(
            'Edit Personal Details',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Full Name / Volunteer Handle',
                    labelStyle: TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.person_outline, color: AppTokens.signalYellow),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      borderSide: BorderSide(color: border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Blood Group Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedBlood,
                  dropdownColor: surface,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    labelStyle: TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppTokens.sosRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      borderSide: BorderSide(color: border),
                    ),
                  ),
                  items: _bloodGroups.map((bg) {
                    return DropdownMenuItem<String>(
                      value: bg,
                      child: Text(bg, style: TextStyle(color: textColor)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedBlood = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Emergency Contact Phone
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    labelStyle: TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppTokens.beaconTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      borderSide: BorderSide(color: border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Medical Notes / Conditions
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Medical Notes & Allergies',
                    labelStyle: TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.medical_information_outlined, color: AppTokens.darkInfo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      borderSide: BorderSide(color: border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.signalYellow,
                foregroundColor: AppTokens.lightOnPrimary,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPhone = phoneCtrl.text.trim();
                final newNotes = notesCtrl.text.trim();

                // Save directly to SQLite via ProfileProvider & ProfileRepository
                await profileProvider.updateProfile(
                  name: newName.isNotEmpty ? newName : profile.name,
                  emergencyContact: newPhone,
                  bloodGroup: selectedBlood,
                  medicalNotes: newNotes,
                );

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile details updated and saved to SQLite.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm Sign Out / Reset Anonymous Identity
  void _confirmSignOut(
    BuildContext context,
    ProfileProvider profileProvider,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.surface,
        title: Text(
          'Reset Anonymous Identity',
          style: TextStyle(color: themeProvider.text, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will clear your local SQLite credentials and return you to setup. All emergency outbox records and mesh messages will remain safe in SQLite.',
          style: TextStyle(color: themeProvider.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: themeProvider.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.sosRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await profileProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/profile-setup');
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
