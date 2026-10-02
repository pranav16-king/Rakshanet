import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

/// Screen 13: Profile & Community Impact
/// Features:
/// - Displays actual registered user profile loaded from ProfileProvider / SQLite
/// - Dynamic 2x2 Impact KPI grid calculated from SQLite database records
///   (relayed packets count, sent reports count, people helped, missing found)
/// - Personal details, edit dialog, volunteer mesh actions
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _relayedCount = 0;
  int _sentReportsCount = 0;
  int _peopleHelpedCount = 0;
  int _missingFoundCount = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final relays = await AppDatabase.instance.query('message_relays');
      final reports = await AppDatabase.instance.getEmergencyReports();
      final missing = await AppDatabase.instance.getMissingPersons();

      int helped = 0;
      for (final r in reports) {
        helped += r.peopleCount;
      }
      final found = missing.where((m) => m.isFound).length;

      if (mounted) {
        setState(() {
          _relayedCount = relays.length;
          _sentReportsCount = reports.length;
          _peopleHelpedCount = helped;
          _missingFoundCount = found;
          _statsLoaded = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;

    final displayName = profile.name.trim().isNotEmpty
        ? profile.name
        : 'Registered Volunteer';
    final displayId = profile.meshId.isNotEmpty ? profile.meshId : profile.deviceId;

    // Dynamically calculate from SQLite records with profile fallback
    final displayHelped = _statsLoaded && _peopleHelpedCount > 0
        ? _peopleHelpedCount
        : profile.peopleHelped;
    final displayRelayed = _statsLoaded && _relayedCount > 0
        ? _relayedCount
        : profile.messagesRelayed;
    final displayForwarded = _statsLoaded && _sentReportsCount > 0
        ? _sentReportsCount
        : profile.sosForwarded;
    final displayMissing = _statsLoaded && _missingFoundCount > 0
        ? _missingFoundCount
        : profile.missingFound;

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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Header Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                // Avatar (56dp)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTokens.signalYellow.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 34,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $displayId',
                        style: TextStyle(
                          color: textMutedColor,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTokens.signalYellow,
                  iconSize: 22,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: 'Edit Profile',
                  onPressed: () => _showEditProfileDialog(context, profileProvider),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Yellow Community Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.signalYellow,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF1A1400),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are helping your community',
                        style: TextStyle(
                          color: Color(0xFF1A1400),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your device is part of the rescue mesh network.',
                        style: TextStyle(
                          color: Color(0xFF332A00),
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

          // 3. Impact KPI Grid (2x2)
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  count: '$displayHelped',
                  label: 'People helped',
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  count: '$displayRelayed',
                  label: 'Messages relayed',
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  count: '$displayForwarded',
                  label: 'SOS forwarded',
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  count: '$displayMissing',
                  label: 'Missing person found',
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. List Actions
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // Medical Notes & Blood Group
                _buildActionTile(
                  icon: Icons.medical_services_outlined,
                  iconColor: AppTokens.beaconTeal,
                  title: 'Medical Info: ${profile.bloodGroup.isNotEmpty ? profile.bloodGroup : "Not specified"}',
                  subtitle: profile.medicalNotes.isNotEmpty
                      ? profile.medicalNotes
                      : 'No medical conditions reported',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showEditProfileDialog(context, profileProvider),
                ),

                // Emergency Contact
                _buildActionTile(
                  icon: Icons.contact_phone_outlined,
                  iconColor: const Color(0xFF4CD08A),
                  title: 'Emergency Contact',
                  subtitle: profile.emergencyContact.isNotEmpty
                      ? profile.emergencyContact
                      : 'None provided',
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () => _showEditProfileDialog(context, profileProvider),
                ),

                // Sign Out / Reset Profile
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTokens.sosRed,
                  title: 'Reset Anonymous Profile',
                  subtitle: 'Clear local SQLite key and re-register',
                  textColor: AppTokens.sosRed,
                  textMutedColor: textMutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                  onTap: () {
                    _confirmSignOut(context, profileProvider);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String count,
    required String label,
    required ThemeProvider themeProvider,
  }) {
    final cardColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final textColor = themeProvider.text;
    final textMutedColor = themeProvider.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
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
                Icon(
                  Icons.chevron_right,
                  color: iconColor == AppTokens.sosRed
                      ? AppTokens.sosRed.withValues(alpha: 0.7)
                      : const Color(0xFF64748B),
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

  void _showEditProfileDialog(
      BuildContext context, ProfileProvider profileProvider) {
    final nameCtrl =
        TextEditingController(text: profileProvider.profile.name);
    final phoneCtrl = TextEditingController(
        text: profileProvider.profile.emergencyContact);
    final bloodCtrl = TextEditingController(
        text: profileProvider.profile.bloodGroup);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Volunteer Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Emergency Contact Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodCtrl,
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.signalYellow,
              foregroundColor: AppTokens.nightNavy,
            ),
            onPressed: () {
              profileProvider.updateProfile(
                name: nameCtrl.text.trim(),
                emergencyContact: phoneCtrl.text.trim(),
                bloodGroup: bloodCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Identity'),
        content: const Text(
          'This will clear the active profile and return to registration. All local emergency outbox packets will remain safe in SQLite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
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
