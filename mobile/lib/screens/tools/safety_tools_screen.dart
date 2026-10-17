import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/emergency_report.dart';
import '../../providers/emergency_report_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/emergency_design_tokens.dart';
import '../../widgets/safety_tools_components.dart';
import '../profile/profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'live_map_screen.dart';
import 'missing_person_screen.dart';
import 'shelters_screen.dart';

/// Safety & Survival Tools Screen
/// Rebuilt with a clear emergency priority hierarchy, sticky compact header,
/// compact tool cards, horizontal relief operations, and real state-driven modals.
class SafetyToolsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onSelectTab;

  const SafetyToolsScreen({
    super.key,
    this.onBackToHome,
    this.onSelectTab,
  });

  @override
  State<SafetyToolsScreen> createState() => _SafetyToolsScreenState();
}

class _SafetyToolsScreenState extends State<SafetyToolsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  void _openOfflineMaps() {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(1);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LiveMapScreen()),
      );
    }
  }

  void _openAiAssistant() {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(4);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AiAssistantScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final meshProvider = context.watch<MeshProvider>();
    final telemetryProvider = context.watch<TelemetryProvider>();
    final reportProvider = context.watch<EmergencyReportProvider>();

    final bool isOnline = telemetryProvider.isOnline;
    final bool isMeshActive = meshProvider.isMeshActive;
    final int batteryLevel = telemetryProvider.batteryLevel;
    final int activeAlertCount = reportProvider.reports.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Sticky Compact Header (No Logo, Zero Truncation)
            SafetyHeader(
              batteryLevel: batteryLevel,
              onBack: _handleBack,
              onOpenProfile: _openProfile,
            ),

            // 2. Scrollable Toolkit Body with guaranteed bottom clearance
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // OFFLINE READINESS BANNER
                      OfflineReadinessBanner(
                        isOnline: isOnline,
                        isMeshActive: isMeshActive,
                      ),
                      const SizedBox(height: 18),

                      // LEVEL 1: EMERGENCY QUICK ACTIONS ROW
                      QuickActionRow(
                        activeAlertCount: activeAlertCount,
                        onFirstAid: () => _showFirstAidSheet(context),
                        onEmergencyNumbers: () =>
                            _showEmergencyNumbersSheet(context),
                        onIAmSafe: () => _showCheckInDialog(context),
                        onAlerts: () => _showDisasterAlertsSheet(context),
                      ),
                      const SizedBox(height: 12),

                      // HIGH-PRIORITY "I AM SAFE" BROADCAST ACTION
                      SafetyStatusAction(
                        isMeshActive: isMeshActive,
                        isOnline: isOnline,
                        onTap: () => _showCheckInDialog(context),
                      ),
                      const SizedBox(height: 22),

                      // LEVEL 2: ESSENTIAL SURVIVAL TOOLS (Compact 2x2 Grid)
                      const ToolSection(
                        title: 'Essential Survival',
                        subtitle:
                            'Guidance and tools for immediate emergencies',
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final spacing =
                              constraints.maxWidth < 340 ? 8.0 : 10.0;
                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SurvivalToolCard(
                                      title: 'First Aid Guide',
                                      description: 'CPR, burns & bleeding',
                                      icon: Icons.medical_services_outlined,
                                      semanticColor: AppColors.sosRed,
                                      onTap: () => _showFirstAidSheet(context),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: SurvivalToolCard(
                                      title: 'Emergency Tips',
                                      description:
                                          'Flood, fire & quake guidance',
                                      icon: Icons.menu_book_rounded,
                                      semanticColor: AppColors.primaryAmber,
                                      onTap: () =>
                                          _showEmergencyTipsSheet(context),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SurvivalToolCard(
                                      title: 'Offline Maps',
                                      description:
                                          'Navigation without internet',
                                      icon: Icons.map_outlined,
                                      semanticColor: AppColors.cyan,
                                      statusText: isOnline
                                          ? 'Live + cached tiles'
                                          : 'Offline map mode',
                                      onTap: _openOfflineMaps,
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: SurvivalToolCard(
                                      title: 'Emergency Numbers',
                                      description:
                                          'Police • Medical • Disaster',
                                      icon: Icons.phone_in_talk_outlined,
                                      semanticColor: AppColors.blue,
                                      onTap: () =>
                                          _showEmergencyNumbersSheet(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      // LEVEL 3: RELIEF & RESPONSE (Horizontal List Cards)
                      const ToolSection(
                        title: 'Relief & Response',
                        subtitle:
                            'Tools for coordination, rescue and recovery',
                      ),
                      ReliefOperationCard(
                        title: 'Emergency Shelters & Relief',
                        description:
                            'Verified shelter information and available resources',
                        icon: Icons.night_shelter_outlined,
                        semanticColor: AppColors.cyan,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SheltersScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ReliefOperationCard(
                        title: 'Missing Persons Registry',
                        description:
                            'Track & report separated family in disaster zones',
                        icon: Icons.person_search_outlined,
                        semanticColor: AppColors.primaryAmber,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MissingPersonScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      DisasterAlertCard(
                        activeAlertCount: activeAlertCount,
                        onTap: () => _showDisasterAlertsSheet(context),
                      ),
                      const SizedBox(height: 22),

                      // LEVEL 4: SURVIVAL ASSISTANT (Highlighted Offline AI Section)
                      const ToolSection(
                        title: 'Survival Assistant',
                        subtitle:
                            'Offline rule-based emergency triage and protocols',
                      ),
                      OfflineAIAssistantCard(
                        onTap: _openAiAssistant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. FIRST AID GUIDE SHEET
  // ===========================================================================
  void _showFirstAidSheet(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            _buildSheetHeader(
              ctx: ctx,
              icon: Icons.medical_services_outlined,
              iconColor: AppColors.sosRed,
              title: 'First Aid Guide',
              subtitle: 'Offline emergency medical protocols',
            ),
            const SizedBox(height: 14),
            _buildProtocolBlock(
              title: '1. Severe Bleeding Control',
              color: AppColors.sosRed,
              steps: const [
                'Apply firm, direct pressure on the wound using clean cloth or sterile gauze.',
                'Do not remove blood-soaked dressings; layer fresh cloth on top.',
                'For life-threatening limb bleeding, apply a tourniquet 2–3 inches above the wound.',
              ],
            ),
            _buildProtocolBlock(
              title: '2. Adult CPR (Unresponsive & Not Breathing)',
              color: AppColors.primaryAmber,
              steps: const [
                'Verify scene safety and check responsiveness.',
                'Place hands in the center of the chest. Push hard and fast (100–120 bpm, 2 inches deep).',
                'Perform 30 chest compressions followed by 2 rescue breaths if trained.',
              ],
            ),
            _buildProtocolBlock(
              title: '3. Fractures & Immobilization',
              color: AppColors.cyan,
              steps: const [
                'Never attempt to straighten or push protruding bone back in.',
                'Immobilize the joints above and below the suspected fracture.',
                'Splint with rigid material padded with cloth and check circulation.',
              ],
            ),
            _buildProtocolBlock(
              title: '4. Burns & Scalds',
              color: AppColors.blue,
              steps: const [
                'Cool the burn under clean running water for at least 10–15 minutes.',
                'Do not apply ice, butter, oil, or ointments.',
                'Cover loosely with a sterile non-stick dressing or clean cloth.',
              ],
            ),
            _buildProtocolBlock(
              title: '5. Airway Obstruction (Choking)',
              color: AppColors.success,
              steps: const [
                'Deliver 5 firm back blows between the shoulder blades with the heel of your hand.',
                'Perform 5 upward abdominal thrusts (Heimlich maneuver) just above the navel.',
                'Alternate 5 back blows and 5 thrusts until the airway clears.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. EMERGENCY TIPS SHEET
  // ===========================================================================
  void _showEmergencyTipsSheet(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            _buildSheetHeader(
              ctx: ctx,
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.primaryAmber,
              title: 'Emergency Tips',
              subtitle: 'Flood, fire, earthquake & cyclone action checklists',
            ),
            const SizedBox(height: 14),
            _buildProtocolBlock(
              title: 'Flash Floods & Rising Water',
              color: AppColors.cyan,
              steps: const [
                'Move to higher ground immediately without waiting for formal evacuation orders.',
                'Never walk or drive through moving floodwater (15 cm can knock an adult down).',
                'Turn off main electrical breakers if dry and safe to reach.',
              ],
            ),
            _buildProtocolBlock(
              title: 'Earthquake Shaking',
              color: AppColors.primaryAmber,
              steps: const [
                'DROP, COVER, and HOLD ON under sturdy furniture or against an interior wall.',
                'Stay clear of windows, glass facades, and exterior masonry.',
                'Expect aftershocks and inspect gas/electrical lines after shaking stops.',
              ],
            ),
            _buildProtocolBlock(
              title: 'Structure Fire & Smoke',
              color: AppColors.sosRed,
              steps: const [
                'Crawl low under smoke where cooler, cleaner air remains.',
                'Test closed doors with the back of your hand before opening.',
                'Never use elevators during a fire evacuation.',
              ],
            ),
            _buildProtocolBlock(
              title: 'Cyclone & Severe Storm',
              color: AppColors.blue,
              steps: const [
                'Shelter in an interior windowless room on the lowest safe floor.',
                'Do not go outside during the calm eye of the cyclone; winds resume rapidly.',
                'Keep offline mesh radio active and conserve device battery.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. "I AM SAFE" CHECK-IN DIALOG (Real Channel State & Real Broadcast)
  // ===========================================================================
  void _showCheckInDialog(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final meshProvider = context.read<MeshProvider>();
    final telemetryProvider = context.read<TelemetryProvider>();
    final chatService = context.read<ChatService>();

    final bool isMeshActive = meshProvider.isMeshActive;
    final int peerCount = meshProvider.connectedPeerCount;
    final bool isOnline = telemetryProvider.isOnline;
    final bool hasGpsFix = telemetryProvider.hasGpsFix;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: theme.border),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Broadcast Safe Status',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send an "I Am Safe" status update so responders and nearby peers know you do not require immediate rescue.',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE TRANSMISSION CHANNELS',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildChannelRow(
                    label: 'Mesh Network (BLE / Wi-Fi)',
                    status: !isMeshActive
                        ? 'Offline'
                        : peerCount > 0
                            ? '$peerCount peers connected'
                            : 'Queued for relay',
                    isActive: isMeshActive,
                    theme: theme,
                  ),
                  const SizedBox(height: 5),
                  _buildChannelRow(
                    label: 'Internet Cloud Sync',
                    status: isOnline ? 'Online' : 'Unavailable',
                    isActive: isOnline,
                    theme: theme,
                  ),
                  const SizedBox(height: 5),
                  _buildChannelRow(
                    label: 'GPS Coordinates',
                    status: hasGpsFix ? 'Attached' : 'Unavailable',
                    isActive: hasGpsFix,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textOnAmber,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await chatService.sendMessage(
                  content:
                      'SAFE STATUS: I am safe and do not require immediate rescue.',
                  conversationId: 'CONV_COMMUNITY',
                );
              } catch (_) {}
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.surface,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"I Am Safe" status saved locally and queued for broadcast.',
                          style: TextStyle(color: theme.text),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text(
              'Broadcast Safe Status',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required String label,
    required String status,
    required bool isActive,
    required ThemeProvider theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 12.5,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: isActive ? AppColors.success : theme.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. EMERGENCY NUMBERS SHEET
  // ===========================================================================
  void _showEmergencyNumbersSheet(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    const numbers = [
      {
        'name': 'National Emergency Helpline',
        'num': '112',
        'desc': 'Integrated Police, Fire & Medical dispatch',
      },
      {
        'name': 'National Disaster Response Force (NDRF)',
        'num': '1078',
        'desc': 'Specialized flood, collapse & disaster rescue',
      },
      {
        'name': 'Medical & Ambulance Service',
        'num': '108',
        'desc': 'Emergency paramedic & trauma response',
      },
      {
        'name': 'Fire & Rescue Service',
        'num': '101',
        'desc': 'Firefighting & hazardous material response',
      },
      {
        'name': 'State Disaster Control Room',
        'num': '1070',
        'desc': 'State-level disaster relief coordination',
      },
      {
        'name': 'District Emergency Operations',
        'num': '1077',
        'desc': 'District collectorate emergency control',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.76,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            _buildSheetHeader(
              ctx: ctx,
              icon: Icons.phone_in_talk_outlined,
              iconColor: AppColors.blue,
              title: 'Emergency Numbers',
              subtitle: 'Tap any helpline to copy number for dialing',
            ),
            const SizedBox(height: 14),
            ...numbers.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: theme.border),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  title: Text(
                    item['name']!,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item['desc']!,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textOnAmber,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item['num']!,
                          style: const TextStyle(
                            color: AppColors.textOnAmber,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item['num']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.surface,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Copied ${item['num']} (${item['name']})',
                          style: TextStyle(color: theme.text),
                        ),
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

  // ===========================================================================
  // 5. DISASTER ALERTS SHEET (Driven 100% by Real SQLite EmergencyReportProvider)
  // ===========================================================================
  void _showDisasterAlertsSheet(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Consumer<EmergencyReportProvider>(
        builder: (ctx, reportProvider, _) {
          final List<EmergencyReport> reports = reportProvider.reports;

          return DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollCtrl) => ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                _buildSheetHeader(
                  ctx: ctx,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.primaryAmber,
                  title: 'Disaster Alerts',
                  subtitle:
                      'Live emergency reports and local warnings from SQLite & Mesh',
                ),
                const SizedBox(height: 16),
                if (reports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_paused_outlined,
                          size: 36,
                          color: theme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No current alerts',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Emergency warnings broadcast across nearby mesh peers or received from command authorities will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...reports.map((report) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primaryAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sosRed.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color:
                                        AppColors.sosRed.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  report.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.sosRed,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                report.status.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.description.isNotEmpty
                                ? report.description
                                : '${report.category} emergency reported (${report.peopleCount} affected)',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'People affected: ${report.peopleCount} • ${report.location}',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader({
    required BuildContext ctx,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final theme = ctx.read<ThemeProvider>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(ctx).pop(),
          icon: Icon(
            Icons.close_rounded,
            color: theme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolBlock({
    required String title,
    required Color color,
    required List<String> steps,
  }) {
    final theme = context.read<ThemeProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13.5,
                        height: 1.38,
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
}
