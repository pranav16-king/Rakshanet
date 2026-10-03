import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import 'live_map_screen.dart';
import 'shelters_screen.dart';
import 'missing_person_screen.dart';
import 'ai_assistant_screen.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 11: Safety Tools (2x3 Survival Grid)
/// Features:
/// 1. First Aid Guide (triage steps for bleeding, CPR, fractures, burns, choking)
/// 2. Emergency Tips (flood, earthquake, cyclone, fire survival checklists)
/// 3. Offline Maps (direct shortcut to LiveMapScreen vector canvas)
/// 4. "I Am Safe" Check-in (1-tap broadcast distress/status ping with Save-Before-Send guarantee)
/// 5. Emergency Numbers (NDRF 1078, 112, 108, 101, 1070, 1077 with one-tap copy)
/// 6. Disaster Alerts (broadcast warning bulletin feed)
/// + Bottom Quick Access Bar to Shelters & Missing Person flows
class SafetyToolsScreen extends StatelessWidget {
  const SafetyToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bg = themeProvider.bg;
    final text = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final isLowPower = themeProvider.isLowPower;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Safety & Survival Tools',
          style: TextStyle(
            color: text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          ThemeToggleButton(compact: true),
          ProfileAvatarButton(compact: true),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Subheader card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLowPower
                  ? AppTokens.oledSurface
                  : AppTokens.beaconTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: AppTokens.beaconTeal.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTokens.beaconTeal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.offline_bolt_rounded,
                    color: AppTokens.beaconTeal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline Survival Suite',
                        style: TextStyle(
                          color: text,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Essential emergency protocols operate without cellular connectivity or internet.',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Quick Action Tools',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 2x3 Grid of Survival Tools
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              // Tool 1: First Aid Guide
              _buildToolCard(
                context: context,
                title: 'First Aid Guide',
                subtitle: 'CPR, burns & bleeding',
                icon: Icons.medical_services_rounded,
                accentColor: AppTokens.sosRed,
                onTap: () => _showFirstAidSheet(context),
              ),

              // Tool 2: Emergency Tips
              _buildToolCard(
                context: context,
                title: 'Emergency Tips',
                subtitle: 'Flood & quake checklists',
                icon: Icons.lightbulb_rounded,
                accentColor: AppTokens.signalYellow,
                onTap: () => _showEmergencyTipsSheet(context),
              ),

              // Tool 3: Offline Maps
              _buildToolCard(
                context: context,
                title: 'Offline Maps',
                subtitle: 'Topographical vector grid',
                icon: Icons.map_rounded,
                accentColor: AppTokens.beaconTeal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiveMapScreen(),
                    ),
                  );
                },
              ),

              // Tool 4: "I Am Safe" Check-in
              _buildToolCard(
                context: context,
                title: 'I Am Safe',
                subtitle: '1-tap status broadcast',
                icon: Icons.verified_user_rounded,
                accentColor: const Color(0xFF4CD08A),
                onTap: () => _showCheckInDialog(context),
              ),

              // Tool 5: Emergency Numbers
              _buildToolCard(
                context: context,
                title: 'Emergency Numbers',
                subtitle: 'NDRF, Police & Med',
                icon: Icons.phone_in_talk_rounded,
                accentColor: const Color(0xFF3B82F6),
                onTap: () => _showEmergencyNumbersSheet(context),
              ),

              // Tool 6: Disaster Alerts
              _buildToolCard(
                context: context,
                title: 'Disaster Alerts',
                subtitle: 'Mesh warning feed',
                icon: Icons.notifications_active_rounded,
                accentColor: AppTokens.darkWarning,
                onTap: () => _showDisasterAlertsSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Specialized Relief Operations',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Secondary navigation list to other tools
          _buildSpecializedActionRow(
            context: context,
            title: 'Emergency Shelters & Relief Camps',
            subtitle: 'Verified occupancy, food, water & solar supplies',
            icon: Icons.night_shelter_rounded,
            iconColor: AppTokens.beaconTeal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SheltersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSpecializedActionRow(
            context: context,
            title: 'Report Missing Person',
            subtitle: 'Broadcast photo bulletins across all BLE mesh hops',
            icon: Icons.person_search_rounded,
            iconColor: AppTokens.signalYellow,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MissingPersonScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSpecializedActionRow(
            context: context,
            title: 'Offline AI Survival Assistant',
            subtitle: 'Rule-based disaster triage with step-by-step guidance',
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF4CD08A),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AiAssistantScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<ThemeProvider>();
    final surface = theme.surface;
    final border = theme.border;
    final text = theme.text;
    final textMuted = theme.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializedActionRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<ThemeProvider>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  // 1. First Aid Bottom Sheet
  void _showFirstAidSheet(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_rounded, color: AppTokens.sosRed, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Offline First Aid Manual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFirstAidItem(
              theme: theme,
              title: '1. Severe Bleeding Control',
              steps: [
                'Apply direct, firm pressure on the wound using clean cloth or gauze.',
                'Do not remove blood-soaked dressings; layer new ones on top.',
                'If bleeding is life-threatening on limbs, apply a tourniquet 2-3 inches above wound.',
              ],
              color: AppTokens.sosRed,
            ),
            _buildFirstAidItem(
              theme: theme,
              title: '2. CPR (Adult)',
              steps: [
                'Ensure the scene is safe and check for responsiveness.',
                'Place hands center of chest. Push hard and fast (100-120 bpm, 2 inches deep).',
                'Deliver 30 compressions followed by 2 rescue breaths if trained.',
              ],
              color: AppTokens.signalYellow,
            ),
            _buildFirstAidItem(
              theme: theme,
              title: '3. Fractures & Splinting',
              steps: [
                'Do not attempt to push protruding bones back in.',
                'Immobilize the joint above and below the suspected fracture.',
                'Use rigid materials (rolled cardboard, branch) padded with cloth.',
              ],
              color: AppTokens.beaconTeal,
            ),
            _buildFirstAidItem(
              theme: theme,
              title: '4. Burns & Scalds',
              steps: [
                'Cool burn under clean, cool running water for at least 10 minutes.',
                'Never apply ice, butter, grease, or oil to burns.',
                'Cover loosely with sterile, non-stick dressing or clean plastic wrap.',
              ],
              color: AppTokens.darkWarning,
            ),
            _buildFirstAidItem(
              theme: theme,
              title: '5. Choking (Heimlich Maneuver)',
              steps: [
                'Stand behind person, lean them slightly forward.',
                'Give 5 sharp back blows between shoulder blades with heel of hand.',
                'Make a fist above navel, give 5 quick upward abdominal thrusts.',
              ],
              color: const Color(0xFF4CD08A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstAidItem({
    required ThemeProvider theme,
    required String title,
    required List<String> steps,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: theme.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Emergency Tips Bottom Sheet
  void _showEmergencyTipsSheet(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppTokens.signalYellow, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Disaster Survival Checklists',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSurvivalTip(
              theme: theme,
              hazard: 'Flash Floods & Rising Water',
              icon: Icons.waves_rounded,
              color: AppTokens.beaconTeal,
              tips: [
                'Move to higher ground immediately; do not wait for instructions.',
                'Never walk, swim, or drive through flood waters. 15 cm of water knocks a person down.',
                'Disconnect electrical appliances if safe to prevent electrocution.',
              ],
            ),
            _buildSurvivalTip(
              theme: theme,
              hazard: 'Earthquake Shaking',
              icon: Icons.terrain_rounded,
              color: AppTokens.darkWarning,
              tips: [
                'DROP, COVER, and HOLD ON under sturdy furniture or against interior walls.',
                'Stay away from windows, heavy glass, and overhead hanging fixtures.',
                'If outdoors, move into an open area away from electrical wires and masonry.',
              ],
            ),
            _buildSurvivalTip(
              theme: theme,
              hazard: 'Building Fire & Smoke Inhalation',
              icon: Icons.local_fire_department_rounded,
              color: AppTokens.sosRed,
              tips: [
                'Crawl low on hands and knees; cooler, breathable air is near floor level.',
                'Feel closed door handles with back of hand. If warm, DO NOT open.',
                'Never use elevators during fire evacuation.',
              ],
            ),
            _buildSurvivalTip(
              theme: theme,
              hazard: 'Severe Cyclone / Storm Surge',
              icon: Icons.air_rounded,
              color: const Color(0xFF3B82F6),
              tips: [
                'Stay in the strongest, windowless central room on ground level.',
                'Do not venture outside during the eye of the storm; wind suddenly reverses.',
                'Keep emergency radio and battery-operated lamps accessible.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurvivalTip({
    required ThemeProvider theme,
    required String hazard,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                hazard,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: theme.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. "I Am Safe" Quick Check-in Dialog
  void _showCheckInDialog(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: theme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF4CD08A), size: 26),
            const SizedBox(width: 10),
            Text(
              'Quick Safety Check-in',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.text),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Broadcast an autonomous "I Am Safe" packet across all nearby BLE and Wi-Fi Direct devices.',
              style: TextStyle(fontSize: 14, height: 1.4, color: theme.text),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CD08A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(color: const Color(0xFF4CD08A).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payload Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Status: ALL SAFE / NO ASSISTANCE NEEDED',
                    style: TextStyle(fontSize: 12, color: theme.text),
                  ),
                  Text(
                    '• Timestamp: Just Now',
                    style: TextStyle(fontSize: 12, color: theme.textMuted),
                  ),
                  Text(
                    '• GPS: Last Known Location Included',
                    style: TextStyle(fontSize: 12, color: theme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD08A),
              foregroundColor: AppTokens.nightNavy,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.isLightMode ? AppTokens.nightNavy : AppTokens.darkSurface,
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF4CD08A)),
                      SizedBox(width: 10),
                      Text('"I Am Safe" status broadcasted to nearby mesh peers'),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Broadcast Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 5. Emergency Numbers Sheet
  void _showEmergencyNumbersSheet(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final numbers = [
      {'name': 'National Disaster Response (NDRF)', 'num': '1078', 'desc': 'Specialized search & flood rescue'},
      {'name': 'National Emergency Integrated Helpline', 'num': '112', 'desc': 'All-in-one emergency dispatch'},
      {'name': 'Ambulance & Medical Emergency', 'num': '108', 'desc': 'Urgent paramedic ambulance service'},
      {'name': 'Fire & Hazard Rescue', 'num': '101', 'desc': 'Firefighting and structure collapse'},
      {'name': 'State Disaster Control Room', 'num': '1070', 'desc': 'State disaster management commissioner'},
      {'name': 'District Disaster Control Room', 'num': '1077', 'desc': 'Local district collector dispatch'},
      {'name': 'Women Emergency Helpline', 'num': '1091', 'desc': 'Disaster shelter safety assistance'},
      {'name': 'Child Protection Helpline', 'num': '1098', 'desc': 'Unaccompanied minor rescue triage'},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF3B82F6), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Verified Emergency Numbers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tapping a number copies it to your clipboard. Standard telecom dials operate during cellular coverage; otherwise numbers are queued for uplink nodes.',
              style: TextStyle(fontSize: 12.5, color: theme.textMuted),
            ),
            const SizedBox(height: 14),
            ...numbers.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.isLowPower
                      ? AppTokens.oledSurface
                      : theme.bg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: theme.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  title: Text(
                    item['name']!,
                    style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    item['desc']!,
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTokens.signalYellow,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Text(
                      item['num']!,
                      style: const TextStyle(
                        color: AppTokens.nightNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item['num']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.isLightMode ? AppTokens.nightNavy : AppTokens.darkSurface,
                        content: Text('Copied ${item['num']} to clipboard'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 6. Disaster Alerts Sheet
  void _showDisasterAlertsSheet(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final alerts = [
      {
        'title': 'Flash Flood Surge Warning',
        'severity': 'CRITICAL',
        'color': AppTokens.sosRed,
        'time': '18 min ago',
        'desc': 'River basin water levels rose +2.1m. Low-lying sectors 3, 4, 8 advised to evacuate immediately to high ground.',
      },
      {
        'title': 'Upstream Dam Inflow Discharge',
        'severity': 'WARNING',
        'color': AppTokens.darkWarning,
        'time': '1 h ago',
        'desc': 'Dam sluice gates opened. Discharge rate 18,500 cusecs flowing downstream towards city bridge.',
      },
      {
        'title': 'Severe Windstorm Advisory',
        'severity': 'ADVISORY',
        'color': AppTokens.beaconTeal,
        'time': '3 h ago',
        'desc': 'Wind gusts up to 75 km/h recorded. Risk of tree falls and unreinforced tin roof detachments.',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppTokens.darkWarning, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Broadcast Warning Bulletins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map((alert) {
              final color = alert['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(AppTokens.radiusXs),
                          ),
                          child: Text(
                            alert['severity'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          alert['time'] as String,
                          style: TextStyle(color: theme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert['title'] as String,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['desc'] as String,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
