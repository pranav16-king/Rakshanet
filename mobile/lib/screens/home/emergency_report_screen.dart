import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../database/repositories/report_repository.dart';
import '../../models/chat_message.dart';
import '../../models/emergency_report.dart';
import '../../providers/emergency_report_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/sos_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
import '../../services/platform_telemetry_service.dart';
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
    final emergencyProvider = Provider.of<EmergencyReportProvider>(
      context,
      listen: false,
    );
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    setState(() {
      _isSending = true;
    });

    HapticFeedback.heavyImpact();

    // SOS must still be saved when location is denied, but when the user has
    // approved it we attach a real GPS fix and its uncertainty. We never put
    // placeholder coordinates on the emergency map.
    final locationPermission = await Permission.location.request();
    final telemetry = locationPermission.isGranted
        ? await PlatformTelemetryService().getTelemetry()
        : TelemetryReading.empty;
    final latitude = telemetry.hasGpsFix ? telemetry.latitude : null;
    final longitude = telemetry.hasGpsFix ? telemetry.longitude : null;
    final accuracy = telemetry.hasGpsFix ? telemetry.accuracy : null;

    final reportId = const Uuid().v4();
    final realReport = EmergencyReport.create(
      id: reportId,
      category: _selectedCategory,
      description: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      peopleCount: _peopleCount,
      latitude: latitude,
      longitude: longitude,
      location: latitude != null && longitude != null
          ? 'GPS fix (accuracy ${accuracy?.round() ?? 'unknown'} m)'
          : 'Location unavailable',
      status: 'QUEUED',
      timestamp: DateTime.now(),
      syncPending: true,
    );

    // 1. Create a real EmergencyReport in SQLite via ReportRepository (Source of truth)
    final reportRepo = ReportRepository();
    await reportRepo.saveReport(realReport);

    // 2. Queue the SOS through the same durable chat outbox as every mesh
    // message. The report and message share an ID for acknowledgement status.
    final location = latitude != null && longitude != null
        ? LocationPreview(
            title: 'GPS location',
            distance: 'Accuracy about ${accuracy?.round() ?? 'unknown'} m',
            latitude: latitude,
            longitude: longitude,
          )
        : null;
    final sosContent =
        'EMERGENCY [${_selectedCategory.toUpperCase()}]: $_peopleCount individual(s) affected.${_notesController.text.trim().isNotEmpty ? ' Notes: ${_notesController.text.trim()}' : ''}';
    await chatService.sendMessage(
      messageId: realReport.id,
      content: sosContent,
      conversationId: 'CONV_COMMUNITY',
      messageType: 'SOS',
      category: _selectedCategory,
      recipientTarget: 'BROADCAST',
      location: location,
      metadata: {
        'category': _selectedCategory,
        'peopleCount': _peopleCount,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracy,
        'location_method': latitude != null ? 'GPS' : 'UNAVAILABLE',
      },
    );

    // 3. Trigger global local SOS alert confirmation & siren feedback
    SosProvider.instance.triggerLocalSos(
      category: _selectedCategory,
      peopleCount: _peopleCount,
      latitude: latitude,
      longitude: longitude,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      messageId: realReport.id,
    );

    // 4. Update in-memory emergency report provider if active
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

    final theme = Provider.of<ThemeProvider>(context, listen: false);

    // Show Confirmation Bottom Sheet
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
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
                child: const Icon(
                  Icons.cell_tower_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SOS Broadcast Live!',
                style: TextStyle(
                  color: theme.text,
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
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: AppTokens.beaconTeal),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTokens.beaconTeal,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Save-Before-Send: Persisted via ReportRepository',
                      style: TextStyle(
                        color: theme.isLightMode
                            ? AppTokens.beaconTeal
                            : AppTokens.darkInfo,
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
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.signalYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTokens.nightNavy,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Emergency Report',
          style: TextStyle(
            color: AppTokens.nightNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTokens.nightNavy),
            tooltip: 'Cancel',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle matching Screen 4 mockup
                    Text(
                      'What type of help do you need?',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the emergency category to notify rescuers.',
                      style: TextStyle(color: theme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Selection Tiles with colored badges (6 categories)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _emergencyTypes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final type = _emergencyTypes[index];
                        final isSelected = _selectedCategory == type['title'];
                        return _buildSelectionTile(
                          theme: theme,
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
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'People Needing Help',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Number of individuals affected',
                                style: TextStyle(
                                  color: theme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed: _peopleCount > 1
                                    ? () => setState(() => _peopleCount--)
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                color: theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  '$_peopleCount',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed: () => setState(() => _peopleCount++),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                color: theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Description / Medical Notes
                    Text(
                      'Medical Notes & Situation Details',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(color: theme.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Additional details (e.g. severe leg wound, 2nd floor, elderly)...',
                        hintStyle: TextStyle(
                          color: theme.textMuted,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: theme.surfaceSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: AppTokens.signalYellow,
                            width: 2,
                          ),
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
                color: theme.surface,
                border: Border(top: BorderSide(color: theme.border)),
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
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                        elevation: 4,
                        shadowColor: AppTokens.sosRed.withValues(alpha: 0.5),
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
                                Icon(
                                  Icons.cell_tower_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
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
                  Text(
                    'Saved to SQLite via ReportRepository • Queued for BLE Mesh relay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textMuted,
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
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final tileBg = isSelected
        ? (theme.isLightMode
              ? AppTokens.lightPrimarySoft
              : (theme.isLowPower
                    ? const Color(0xFF1E1A04)
                    : AppTokens.darkSurfaceAlt))
        : theme.surface;

    final tileBorder = isSelected
        ? (theme.isLightMode
              ? AppTokens.lightPrimaryInk
              : AppTokens.signalYellow)
        : theme.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: tileBorder, width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected && !theme.isLowPower
              ? [
                  BoxShadow(
                    color: AppTokens.signalYellow.withValues(alpha: 0.18),
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
                color: badgeColor == AppTokens.signalYellow
                    ? AppTokens.nightNavy
                    : Colors.white,
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
                      color: theme.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.isLightMode
                    ? AppTokens.lightPrimaryInk
                    : AppTokens.signalYellow,
                size: 24,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.border, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
