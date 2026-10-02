import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../database/repositories/report_repository.dart';
import '../../models/emergency_report.dart';
import '../../models/message_envelope.dart';
import '../../providers/emergency_report_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/mesh_engine.dart';
import '../../theme/app_tokens.dart';

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  String _selectedCategory = 'Medical';
  int _peopleCount = 1;
  final TextEditingController _notesController = TextEditingController();
  bool _isSending = false;

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'title': 'Medical',
      'subtitle': 'Injury or health issue',
      'icon': Icons.medical_services_rounded,
      'badgeColor': const Color(0xFFD92D20), // SOS Red
    },
    {
      'title': 'Trapped',
      'subtitle': 'Stuck or unable to move',
      'icon': Icons.person_pin_circle_rounded,
      'badgeColor': const Color(0xFFE07B00), // Warning Orange/Red
    },
    {
      'title': 'Fire',
      'subtitle': 'Fire or smoke',
      'icon': Icons.local_fire_department_rounded,
      'badgeColor': const Color(0xFFD92D20), // Red
    },
    {
      'title': 'Flood',
      'subtitle': 'Water related emergency',
      'icon': Icons.flood_rounded,
      'badgeColor': const Color(0xFF0E8A94), // Teal/Blue
    },
    {
      'title': 'Missing Person',
      'subtitle': 'Someone is missing',
      'icon': Icons.people_rounded,
      'badgeColor': const Color(0xFFFFA033), // Amber Orange
    },
    {
      'title': 'Other',
      'subtitle': 'Describe the situation',
      'icon': Icons.more_horiz_rounded,
      'badgeColor': const Color(0xFFFFC400), // Safety Yellow
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSendSos() async {
    // Read providers synchronously before any async gap
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final emergencyProvider = Provider.of<EmergencyReportProvider>(context, listen: false);
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);

    setState(() {
      _isSending = true;
    });

    HapticFeedback.heavyImpact();

    final reportId = const Uuid().v4();
    final realReport = EmergencyReport.create(
      id: reportId,
      category: _selectedCategory,
      description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      peopleCount: _peopleCount,
      latitude: null, // GPS unavailable in offline mode without permissions
      longitude: null,
      status: 'QUEUED',
      timestamp: DateTime.now(),
      syncPending: true,
    );

    // 1. Create a real EmergencyReport in SQLite via ReportRepository (Source of truth)
    final reportRepo = ReportRepository();
    await reportRepo.saveReport(realReport);

    // 2. Queue in MeshEngine for peer-to-peer mesh broadcast
    final senderId = profileProvider.profile?.id.isNotEmpty == true
        ? profileProvider.profile!.id
        : 'SR-ANONYMOUS';
    final senderName = profileProvider.profile?.name.isNotEmpty == true
        ? profileProvider.profile!.name
        : 'Emergency Operator';

    final envelope = MessageEnvelope(
      uuid: realReport.id,
      senderId: senderId,
      senderName: senderName,
      conversationId: 'CONV_COMMUNITY',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: 5,
      hops: 0,
      type: 'SOS',
      payload: 'EMERGENCY [${_selectedCategory.toUpperCase()}]: $_peopleCount individual(s) affected.${_notesController.text.trim().isNotEmpty ? ' Notes: ${_notesController.text.trim()}' : ''}',
      recipientTarget: 'BROADCAST',
      metadata: {
        'category': _selectedCategory,
        'peopleCount': _peopleCount,
        'latitude': realReport.latitude,
        'longitude': realReport.longitude,
      },
    );
    MeshEngine().queueOutboxMessage(envelope);

    // 3. Update in-memory emergency report provider if active
    try {
      await emergencyProvider.loadReports();
    } catch (_) {}

    final peerCount = meshProvider.nearbyDevices.isNotEmpty
        ? meshProvider.nearbyDevices.length
        : meshProvider.connectedPeerCount;

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    // Show Confirmation Bottom Sheet
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTokens.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.sosRed,
                ),
                child: const Icon(Icons.cell_tower_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'SOS Broadcast Live!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                peerCount > 0
                    ? 'Saved to SQLite (ID: ${realReport.id.substring(0, 8)}). Broadcasting $_selectedCategory emergency to $peerCount nearby mesh devices.'
                    : 'Saved to SQLite (ID: ${realReport.id.substring(0, 8)}). Broadcasting $_selectedCategory emergency beacon. Will relay once peers connect.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTokens.darkTextMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTokens.darkSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: AppTokens.beaconTeal),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTokens.darkInfo, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Save-Before-Send: Persisted via ReportRepository',
                      style: TextStyle(
                        color: AppTokens.darkInfo,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: AppTokens.buttonPrimary,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                  ),
                  child: const Text(
                    'Return to Safety Hub',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      appBar: AppBar(
        backgroundColor: AppTokens.nightNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Emergency Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle matching Screen 4 mockup
                    const Text(
                      'What type of help do you need?',
                      style: TextStyle(
                        color: AppTokens.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the emergency category to notify rescuers.',
                      style: TextStyle(
                        color: AppTokens.darkTextMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Selection Tiles with colored badges (6 categories)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _emergencyTypes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final type = _emergencyTypes[index];
                        final isSelected = _selectedCategory == type['title'];
                        return _buildSelectionTile(
                          title: type['title'] as String,
                          subtitle: type['subtitle'] as String,
                          icon: type['icon'] as IconData,
                          badgeColor: type['badgeColor'] as Color,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = type['title'] as String;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // People Affected Stepper
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTokens.darkSurface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: AppTokens.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'People Needing Help',
                                style: TextStyle(
                                  color: AppTokens.darkText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Number of individuals affected',
                                style: TextStyle(
                                  color: AppTokens.darkTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _peopleCount > 1
                                    ? () => setState(() => _peopleCount--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                color: AppTokens.signalYellow,
                              ),
                              Text(
                                '$_peopleCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _peopleCount++),
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: AppTokens.signalYellow,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Description
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Additional details (e.g. 2nd floor, water rising)...',
                        filled: true,
                        fillColor: AppTokens.darkSurfaceSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          borderSide: const BorderSide(color: AppTokens.darkBorder),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Big Action Button: ((•)) Send SOS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTokens.nightNavy,
                border: Border(top: BorderSide(color: AppTokens.darkBorder.withValues(alpha: 0.5))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _handleSendSos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.sosRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                        elevation: 4,
                        shadowColor: AppTokens.sosRed.withValues(alpha: 0.6),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cell_tower_rounded, size: 24, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Send SOS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Will be saved to SQLite and queued in MeshEngine for relay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.darkSurfaceAlt : AppTokens.darkSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isSelected ? AppTokens.signalYellow : AppTokens.darkBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTokens.signalYellow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Colored Badge Container matching Mockup Screen 4
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: badgeColor == const Color(0xFFFFC400) ? AppTokens.nightNavy : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTokens.darkText,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTokens.signalYellow,
                size: 24,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTokens.darkBorderStrong, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
