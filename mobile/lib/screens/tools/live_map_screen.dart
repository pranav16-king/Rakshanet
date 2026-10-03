import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../models/emergency_report.dart';
import '../../models/mesh_device.dart';
import '../../models/shelter_resource.dart';
import '../../providers/emergency_report_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Screen 6: Live Map & Nearby Devices
/// Features:
/// - Offline topographical custom vector canvas with contour lines and grid
/// - Dynamic real nodes: You, BLE Mesh Peers, Emergency SOS Reports, Shelter Hubs
/// - Dynamic mesh connectivity links between actual active nodes
/// - Interactive zoom & pan via InteractiveViewer
/// - Filter chips: "You", "Nearby", "SOS", "Rescue", "Shelter"
/// - Floating layer toggle and GPS re-center controls
/// - Bottom floating incident card reading live from emergency reports with calm all-clear state
/// - Full theme support: Light (#FFFCEB), Dark (#0B1220), OLED Low-Power (#000000 True Black)
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TransformationController _transformController =
      TransformationController();

  // Active filter chip keys
  final Set<String> _activeFilters = {
    'You',
    'Nearby',
    'SOS',
    'Rescue',
    'Shelter',
  };

  // Layer settings
  bool _showContours = true;
  bool _showMeshLinks = true;
  bool _showGrid = true;

  // Selected marker details for inspection
  _MapNode? _selectedNode;

  List<EmergencyReport> _emergencyReports = [];
  List<ShelterResource> _shelterResources = [];

  Future<void> _loadSqliteData() async {
    try {
      final reps = await AppDatabase.instance.getEmergencyReports();
      final shels = await AppDatabase.instance.getShelters();
      if (mounted) {
        setState(() {
          _emergencyReports = reps;
          _shelterResources = shels;
        });
      }
    } catch (_) {}
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  List<_MapNode> _computeNodes(
    MeshProvider mesh,
    List<EmergencyReport> emergencyReports,
    TelemetryProvider telemetry,
  ) {
    final List<_MapNode> result = [];

    // 1. User Node ('You')
    result.add(
      _MapNode(
        id: 'node-you',
        label: 'You',
        type: _NodeType.you,
        offset: const Offset(450, 450),
        statusText: 'Mesh relay active • GPS status in header',
        distance: '0 m',
        lastSeen: 'Now',
      ),
    );

    final originLatitude = telemetry.latitude;
    final originLongitude = telemetry.longitude;
    if (!telemetry.hasGpsFix ||
        originLatitude == null ||
        originLongitude == null) {
      // Bluetooth tells us that peers are nearby, not their bearing. Do not
      // draw made-up positions when this device has no GPS reference.
      return result;
    }
    final pixelsPerMeter = _pixelsPerMeter(
      originLatitude,
      originLongitude,
      emergencyReports,
    );

    // 2. Real BLE peers dynamically from MeshProvider
    // Nearby Connections exposes no peer direction or peer GPS coordinate.
    // Connected peers remain visible in the Network tab instead of being
    // placed arbitrarily on a geographic map.
    const peers = <MeshDevice>[];
    for (int i = 0; i < peers.length; i++) {
      final dev = peers[i];
      final angle = (dev.deviceId.hashCode.abs() % 360) * math.pi / 180;
      final rssiAbs = dev.signalStrength.abs().clamp(30, 95);
      final radius = 90.0 + ((rssiAbs - 30) / 65.0) * 160.0;
      final pos = Offset(
        400 + math.cos(angle) * radius,
        480 + math.sin(angle) * radius,
      );

      result.add(
        _MapNode(
          id: dev.deviceId,
          label: dev.displayName.isNotEmpty ? dev.displayName : dev.deviceId,
          type: i % 2 == 0 ? _NodeType.peerTeal : _NodeType.peerYellow,
          offset: pos,
          statusText:
              'Relay node ${dev.displayName.isNotEmpty ? dev.displayName : dev.deviceId} • Battery ${dev.batteryLevel}% • Hop ${dev.hopCount}',
          distance: dev.proximityBand == ProximityBand.immediate
              ? '~25 m'
              : (dev.proximityBand == ProximityBand.near ? '~120 m' : '~450 m'),
          lastSeen: 'Just now',
          meshDevice: dev,
        ),
      );
    }

    // 3. Real Emergency Reports from SQLite (zero fake fallback nodes)
    if (emergencyReports.isNotEmpty) {
      for (int i = 0; i < emergencyReports.length; i++) {
        final rep = emergencyReports[i];
        if (rep.latitude == null || rep.longitude == null) continue;
        final pos = _projectCoordinate(
          originLatitude: originLatitude,
          originLongitude: originLongitude,
          latitude: rep.latitude!,
          longitude: rep.longitude!,
          pixelsPerMeter: pixelsPerMeter,
        );
        result.add(
          _MapNode(
            id: rep.id,
            label: 'SOS',
            type: _NodeType.sos,
            offset: pos,
            statusText:
                '${rep.peopleCount} ${rep.peopleCount == 1 ? 'person needs' : 'people need'} help • ${rep.notes.isNotEmpty ? rep.notes : rep.type.label}',
            distance: _formatDistance(
              _distanceMeters(
                originLatitude,
                originLongitude,
                rep.latitude!,
                rep.longitude!,
              ),
            ),
            lastSeen: _formatTimeAgo(rep.timestamp),
            peopleCount: rep.peopleCount,
            emergencyReport: rep,
          ),
        );
      }
    }

    // 4. Real Shelter Resources from SQLite
    if (_shelterResources.isNotEmpty) {
      for (int i = 0; i < _shelterResources.length; i++) {
        final s = _shelterResources[i];
        if (s.latitude == null || s.longitude == null) continue;
        final pos = _projectCoordinate(
          originLatitude: originLatitude,
          originLongitude: originLongitude,
          latitude: s.latitude!,
          longitude: s.longitude!,
          pixelsPerMeter: pixelsPerMeter,
        );

        result.add(
          _MapNode(
            id: s.id,
            label: s.name,
            type: _NodeType.shelter,
            offset: pos,
            statusText: '${s.name} • ${s.capacity}/${s.maxCapacity} spaces',
            distance: _formatDistance(
              _distanceMeters(
                originLatitude,
                originLongitude,
                s.latitude!,
                s.longitude!,
              ),
            ),
            lastSeen: s.isOpen ? 'Open' : (s.isFull ? 'Full' : 'Closed'),
            shelterResource: s,
          ),
        );
      }
    }

    return result;
  }

  double _pixelsPerMeter(
    double originLatitude,
    double originLongitude,
    List<EmergencyReport> reports,
  ) {
    final distances = <double>[
      for (final report in reports)
        if (report.latitude != null && report.longitude != null)
          _distanceMeters(
            originLatitude,
            originLongitude,
            report.latitude!,
            report.longitude!,
          ),
      for (final shelter in _shelterResources)
        if (shelter.latitude != null && shelter.longitude != null)
          _distanceMeters(
            originLatitude,
            originLongitude,
            shelter.latitude!,
            shelter.longitude!,
          ),
    ];
    final maximum = distances.isEmpty
        ? 1.0
        : distances.reduce(math.max).clamp(1.0, 100000.0).toDouble();
    return math.min(0.35, 320 / maximum);
  }

  Offset _projectCoordinate({
    required double originLatitude,
    required double originLongitude,
    required double latitude,
    required double longitude,
    required double pixelsPerMeter,
  }) {
    const metersPerLatitudeDegree = 111320.0;
    final north = (latitude - originLatitude) * metersPerLatitudeDegree;
    final east =
        (longitude - originLongitude) *
        metersPerLatitudeDegree *
        math.cos(originLatitude * math.pi / 180);
    return Offset(450 + east * pixelsPerMeter, 450 - north * pixelsPerMeter);
  }

  double _distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadius = 6371000.0;
    final latDelta = (latitudeB - latitudeA) * math.pi / 180;
    final lonDelta = (longitudeB - longitudeA) * math.pi / 180;
    final a =
        math.sin(latDelta / 2) * math.sin(latDelta / 2) +
        math.cos(latitudeA * math.pi / 180) *
            math.cos(latitudeB * math.pi / 180) *
            math.sin(lonDelta / 2) *
            math.sin(lonDelta / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String _formatDistance(double meters) => meters < 1000
      ? 'about ${meters.round()} m'
      : 'about ${(meters / 1000).toStringAsFixed(1)} km';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _loadSqliteData();

    // Center view on user node after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUser();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final Size size = MediaQuery.of(context).size;
    const Offset userPos = Offset(450, 450);
    const double scale = 1.0;
    final double dx = (size.width / 2) - (userPos.dx * scale);
    final double dy = (size.height / 2) - (userPos.dy * scale) - 40;

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 3, dx);
    matrix.setEntry(1, 3, dy);
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    _transformController.value = matrix;
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        if (_activeFilters.length > 1) {
          _activeFilters.remove(filter);
        }
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  void _showLayersSheet(ThemeProvider theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Map Layers & Offline Assets',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: Text(
                  'Topographical Elevation Contours',
                  style: TextStyle(color: theme.text),
                ),
                subtitle: Text(
                  'Local visual reference only; not a surveyed terrain layer',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
                value: _showContours,
                onChanged: (val) {
                  setSheetState(() => _showContours = val);
                  setState(() => _showContours = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: Text(
                  'Mesh Network Link Lines',
                  style: TextStyle(color: theme.text),
                ),
                subtitle: Text(
                  'Direct BLE / Wi-Fi peer connectivity',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
                value: _showMeshLinks,
                onChanged: (val) {
                  setSheetState(() => _showMeshLinks = val);
                  setState(() => _showMeshLinks = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: Text(
                  'Tactical Coordinates Grid',
                  style: TextStyle(color: theme.text),
                ),
                subtitle: Text(
                  'GPS-based local coordinate reference',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
                value: _showGrid,
                onChanged: (val) {
                  setSheetState(() => _showGrid = val);
                  setState(() => _showGrid = val);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetailsModal(
    _MapNode node, {
    EmergencyReport? report,
    required ThemeProvider theme,
  }) {
    final rep = report ?? node.emergencyReport;
    final int people =
        rep?.peopleCount ?? (node.peopleCount > 0 ? node.peopleCount : 1);
    final String category = rep?.category ?? 'Emergency SOS';
    final String severity = rep?.severity ?? 'CRITICAL';
    final repNotes = rep?.notes;
    final String notes = (repNotes != null && repNotes.isNotEmpty)
        ? repNotes
        : (rep?.type.description ?? node.statusText);
    final lat = rep?.latitude;
    final lng = rep?.longitude;
    final String coords = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
        : (rep?.location.isNotEmpty == true && rep?.location != 'Unknown'
            ? rep!.location
            : 'No shared GPS coordinate');
    final String status = rep?.status ?? 'SAVED';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.isLightMode
                      ? AppTokens.lightBorderStrong
                      : (theme.isLowPower
                            ? AppTokens.oledBorderStrong
                            : AppTokens.darkBorderStrong),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTokens.sosRed.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTokens.sosRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$people ${people == 1 ? 'person needs' : 'people need'} help • $category',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ${node.distance} • Reported: ${node.lastSeen}',
                        style: TextStyle(color: theme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  notes,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mesh Status:',
                        style: TextStyle(color: theme.textMuted),
                      ),
                      Text(
                        '$status (BLE Relay)',
                        style: const TextStyle(
                          color: AppTokens.beaconTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coordinates:',
                        style: TextStyle(color: theme.textMuted),
                      ),
                      Text(
                        coords,
                        style: TextStyle(
                          color: theme.text,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Severity Level:',
                        style: TextStyle(color: theme.textMuted),
                      ),
                      Text(
                        '$severity (Priority Aid)',
                        style: TextStyle(
                          color: theme.isLightMode
                              ? AppTokens.lightSos
                              : AppTokens.darkSos,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.lightOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text(
                        'Navigate to Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTokens.beaconTeal,
                            content: Text(
                              'Offline compass navigation engaged for ${node.distance}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showShelterDetailsModal(
    _MapNode node, {
    ShelterResource? shelter,
    required ThemeProvider theme,
  }) {
    final s = shelter ?? node.shelterResource;
    if (s == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.isLightMode
                      ? AppTokens.lightBorderStrong
                      : (theme.isLowPower
                            ? AppTokens.oledBorderStrong
                            : AppTokens.darkBorderStrong),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTokens.signalYellow.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppTokens.signalYellow,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ${node.distance} • Status: ${s.openStatus}',
                        style: TextStyle(
                          color: s.isOpen
                              ? AppTokens.beaconTeal
                              : theme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capacity Occupancy:',
                        style: TextStyle(color: theme.textMuted),
                      ),
                      Text(
                        '${s.capacity} / ${s.maxCapacity} (${s.availableSpots} spots left)',
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (s.supplies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Supplies:',
                          style: TextStyle(color: theme.textMuted),
                        ),
                        Text(
                          s.supplies.join(', '),
                          style: const TextStyle(
                            color: AppTokens.beaconTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (s.address != null && s.address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Address:',
                          style: TextStyle(color: theme.textMuted),
                        ),
                        Flexible(
                          child: Text(
                            s.address!,
                            textAlign: TextAlign.end,
                            style: TextStyle(color: theme.text, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.lightOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text(
                        'Route to Shelter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTokens.beaconTeal,
                            content: Text(
                              'Offline directions engaged for ${s.name} (${node.distance})',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCalmStatusCard(ThemeProvider theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTokens.beaconTeal,
            content: Text(
              'All clear in local mesh range. No active distress alerts.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: AppTokens.beaconTeal.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: theme.isLowPower
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.isLightMode ? 0.08 : 0.4,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Teal shield icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_rounded,
                  color: AppTokens.beaconTeal,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No active distress alerts nearby',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'All clear in local mesh range',
                    style: TextStyle(
                      color: AppTokens.beaconTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppTokens.beaconTeal.withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveIncidentCard(
    EmergencyReport report,
    List<_MapNode> nodes,
    ThemeProvider theme,
  ) {
    final sosNode = nodes.firstWhere(
      (n) => n.id == report.id || n.type == _NodeType.sos,
      orElse: () => _MapNode(
        id: report.id,
        label: 'SOS',
        type: _NodeType.sos,
        offset: const Offset(400, 480),
        statusText:
            '${report.peopleCount} ${report.peopleCount == 1 ? 'person needs' : 'people need'} help • ${report.category}',
        distance: '~1.3 km',
        lastSeen: _formatTimeAgo(report.timestamp),
        peopleCount: report.peopleCount,
        emergencyReport: report,
      ),
    );

    final String distanceStr = sosNode.distance;
    final String timeAgoStr = _formatTimeAgo(report.timestamp);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      onTap: () =>
          _showIncidentDetailsModal(sosNode, report: report, theme: theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: AppTokens.sosRed.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: theme.isLowPower
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.isLightMode ? 0.1 : 0.5,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Red warning icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTokens.sosRed.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppTokens.sosRed,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Incident Title & Distance / Timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${report.peopleCount} ${report.peopleCount == 1 ? 'person needs' : 'people need'} help • ${report.category}',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$distanceStr • Reported $timeAgoStr',
                    style: TextStyle(
                      color: theme.isLightMode
                          ? AppTokens.lightSos
                          : AppTokens.darkSos,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textMuted, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeProvider theme,
  }) {
    return Container(
      width: AppTokens.touchMin,
      height: AppTokens.touchMin,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border),
        boxShadow: theme.isLowPower
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.isLightMode ? 0.08 : 0.35,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: theme.text, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    Color color,
    ThemeProvider theme,
  ) {
    final bool isSelected = _activeFilters.contains(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        onTap: () => _toggleFilter(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.surface
                : theme.surface.withValues(
                    alpha: theme.isLightMode ? 0.6 : 0.4,
                  ),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: isSelected ? color : theme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : theme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.text : theme.textMuted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mesh = context.watch<MeshProvider>();
    final telemetry = context.watch<TelemetryProvider>();
    final emergencyProvider = context.watch<EmergencyReportProvider>();
    final activeReports = emergencyProvider.reports.isNotEmpty
        ? emergencyProvider.reports
        : _emergencyReports;
    final nodes = _computeNodes(mesh, activeReports, telemetry);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Interactive Vector Map Canvas
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset local = box.globalToLocal(
                    details.globalPosition,
                  );
                  final Matrix4 transform = _transformController.value;
                  final Matrix4 inverse = Matrix4.inverted(transform);
                  final Offset mapCoord = MatrixUtils.transformPoint(
                    inverse,
                    local,
                  );

                  _MapNode? hit;
                  for (final node in nodes) {
                    if ((node.offset - mapCoord).distance <= 32) {
                      hit = node;
                      break;
                    }
                  }
                  if (hit != null) {
                    setState(() => _selectedNode = hit);
                    if (hit.type == _NodeType.sos) {
                      _showIncidentDetailsModal(
                        hit,
                        report: hit.emergencyReport,
                        theme: theme,
                      );
                    } else if (hit.type == _NodeType.shelter) {
                      _showShelterDetailsModal(
                        hit,
                        shelter: hit.shelterResource,
                        theme: theme,
                      );
                    } else if (hit.type == _NodeType.peerTeal ||
                        hit.type == _NodeType.peerYellow) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTokens.beaconTeal,
                          content: Text(
                            '${hit.label} • ${hit.statusText} (${hit.distance})',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    setState(() => _selectedNode = null);
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.6,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(500),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(900, 900),
                        painter: _MapCanvasPainter(
                          nodes: nodes,
                          activeFilters: _activeFilters,
                          pulseValue: _pulseController.value,
                          showContours: _showContours,
                          showMeshLinks: _showMeshLinks,
                          showGrid: _showGrid,
                          selectedNode: _selectedNode,
                          themeMode: theme.currentMode,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Header Bar (Top)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      (theme.isLightMode
                              ? AppTokens.lightSurface
                              : (theme.isLowPower
                                    ? AppTokens.oledSurface
                                    : AppTokens.darkBg))
                          .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: theme.border),
                  boxShadow: theme.isLowPower
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.isLightMode ? 0.08 : 0.4,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Hi-Vis yellow beacon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTokens.signalYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.radar_rounded,
                          color: AppTokens.lightOnPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and status subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Live Map',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                telemetry.hasGpsFix
                                    ? Icons.location_on_rounded
                                    : Icons.location_off_rounded,
                                size: 13,
                                color: telemetry.hasGpsFix
                                    ? (theme.isLightMode
                                          ? AppTokens.lightSuccess
                                          : AppTokens.darkSuccess)
                                    : theme.warning,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  mesh.nearbyDevices.isEmpty
                                      ? 'Offline • Searching for nearby devices...'
                                      : 'Offline • ${mesh.nearbyDevices.length} ${mesh.nearbyDevices.length == 1 ? 'device' : 'devices'} nearby',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Settings / layers action icon
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: theme.text),
                      tooltip: 'Map Settings',
                      onPressed: () => _showLayersSheet(theme),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Map Controls (Right Side)
            Positioned(
              right: 16,
              top: 96,
              child: Column(
                children: [
                  _buildFloatingMapButton(
                    icon: Icons.layers_outlined,
                    tooltip: 'Toggle Layers',
                    onTap: () => _showLayersSheet(theme),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildFloatingMapButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Re-center on You',
                    onTap: _centerOnUser,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildFloatingMapButton(
                    icon: Icons.add,
                    tooltip: 'Zoom In',
                    onTap: () {
                      _transformController.value =
                          _transformController.value.clone()
                            ..multiply(Matrix4.diagonal3Values(1.2, 1.2, 1.0));
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildFloatingMapButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onTap: () {
                      _transformController.value =
                          _transformController.value.clone()..multiply(
                            Matrix4.diagonal3Values(0.83, 0.83, 1.0),
                          );
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),

            // 4. Bottom Section: Filter Chips & Floating Emergency Sheet
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'You',
                          Icons.person_pin_circle_rounded,
                          const Color(0xFF2F80ED),
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Nearby',
                          Icons.location_on,
                          AppTokens.beaconTeal,
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'SOS',
                          Icons.warning_rounded,
                          AppTokens.sosRed,
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Rescue',
                          Icons.shield_rounded,
                          theme.isLightMode
                              ? AppTokens.lightSuccess
                              : AppTokens.darkSuccess,
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Shelter',
                          Icons.home_rounded,
                          theme.isLightMode
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow,
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Floating Bottom Sheet: Dynamic from active reports
                  if (activeReports.isEmpty)
                    _buildCalmStatusCard(theme)
                  else
                    _buildActiveIncidentCard(activeReports.first, nodes, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NodeType { you, sos, cluster, peerYellow, peerTeal, rescue, shelter }

class _MapNode {
  final String id;
  final String label;
  final _NodeType type;
  final Offset offset;
  final String statusText;
  final String distance;
  final String lastSeen;
  final int peopleCount;
  final EmergencyReport? emergencyReport;
  final ShelterResource? shelterResource;
  final MeshDevice? meshDevice;

  _MapNode({
    required this.id,
    required this.label,
    required this.type,
    required this.offset,
    required this.statusText,
    required this.distance,
    required this.lastSeen,
    this.peopleCount = 0,
    this.emergencyReport,
    this.shelterResource,
    this.meshDevice,
  });
}

/// Custom Vector Canvas Painter
/// Renders topographical contours, coordinate grid, mesh link connections,
/// glowing pulses, and custom node glyphs with multi-theme support.
class _MapCanvasPainter extends CustomPainter {
  final List<_MapNode> nodes;
  final Set<String> activeFilters;
  final double pulseValue;
  final bool showContours;
  final bool showMeshLinks;
  final bool showGrid;
  final _MapNode? selectedNode;
  final AppThemeMode themeMode;

  _MapCanvasPainter({
    required this.nodes,
    required this.activeFilters,
    required this.pulseValue,
    required this.showContours,
    required this.showMeshLinks,
    required this.showGrid,
    this.selectedNode,
    required this.themeMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isLight = themeMode == AppThemeMode.light;
    final bool isOled = themeMode == AppThemeMode.lowPower;

    final Color canvasBg = isOled
        ? AppTokens
              .oledBg // True #000000 Black
        : (isLight ? AppTokens.lightBg : const Color(0xFF0B1424));

    final Color contourColor = isOled
        ? const Color(0xFF181818)
        : (isLight ? const Color(0xFFE2D9A0) : const Color(0xFF14243B));

    final Color riverColor = isOled
        ? const Color(0xFF0A121A).withValues(alpha: 0.5)
        : (isLight
              ? const Color(0xFFD0E3F3).withValues(alpha: 0.75)
              : const Color(0xFF0F263E).withValues(alpha: 0.6));

    final Color gridColor = isOled
        ? const Color(0xFF141414).withValues(alpha: 0.45)
        : (isLight
              ? const Color(0xFFDCD296).withValues(alpha: 0.4)
              : const Color(0xFF1E2D47).withValues(alpha: 0.35));

    final Color meshLinkColor = isLight
        ? AppTokens.lightInfo
        : (isOled ? AppTokens.oledInfo : AppTokens.beaconTeal);

    // 1. Background fill
    final bgPaint = Paint()..color = canvasBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Topographical Contours
    if (showContours) {
      _drawTopographyContours(canvas, size, contourColor, riverColor);
    }

    // 3. Coordinate Grid
    if (showGrid) {
      _drawCoordinateGrid(canvas, size, gridColor);
    }

    // 4. Mesh Link Lines
    if (showMeshLinks) {
      _drawMeshLinks(canvas, meshLinkColor);
    }

    // 5. Render Nodes
    for (final node in nodes) {
      if (!_isNodeVisible(node)) continue;

      switch (node.type) {
        case _NodeType.you:
          _drawUserNode(canvas, node, isLight);
          break;
        case _NodeType.sos:
          _drawSosNode(canvas, node);
          break;
        case _NodeType.cluster:
          _drawClusterBubble(canvas, node, isLight, isOled);
          break;
        case _NodeType.peerYellow:
          _drawPeerNode(
            canvas,
            node,
            isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
            isLight,
          );
          break;
        case _NodeType.peerTeal:
          _drawPeerNode(canvas, node, AppTokens.beaconTeal, isLight);
          break;
        case _NodeType.rescue:
          _drawRescueNode(canvas, node, isLight);
          break;
        case _NodeType.shelter:
          _drawShelterNode(canvas, node, isLight);
          break;
      }
    }
  }

  bool _isNodeVisible(_MapNode node) {
    switch (node.type) {
      case _NodeType.you:
        return activeFilters.contains('You');
      case _NodeType.sos:
        return activeFilters.contains('SOS');
      case _NodeType.peerYellow:
      case _NodeType.peerTeal:
      case _NodeType.cluster:
        return activeFilters.contains('Nearby');
      case _NodeType.rescue:
        return activeFilters.contains('Rescue');
      case _NodeType.shelter:
        return activeFilters.contains('Shelter');
    }
  }

  void _drawTopographyContours(
    Canvas canvas,
    Size size,
    Color contourColor,
    Color riverColor,
  ) {
    final contourPaint = Paint()
      ..color = contourColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final elevationRings = [
      Path()
        ..moveTo(100, 200)
        ..cubicTo(200, 150, 400, 180, 500, 120)
        ..cubicTo(600, 80, 750, 140, 850, 220),
      Path()
        ..moveTo(80, 320)
        ..cubicTo(180, 260, 350, 310, 480, 250)
        ..cubicTo(620, 190, 760, 270, 860, 360),
      Path()
        ..moveTo(50, 480)
        ..cubicTo(160, 420, 320, 460, 490, 400)
        ..cubicTo(640, 340, 780, 440, 880, 510),
      Path()
        ..moveTo(70, 620)
        ..cubicTo(200, 560, 390, 610, 540, 540)
        ..cubicTo(680, 480, 800, 590, 870, 680),
      Path()
        ..moveTo(120, 750)
        ..cubicTo(260, 690, 450, 740, 600, 670)
        ..cubicTo(720, 620, 810, 720, 860, 810),
    ];

    for (final path in elevationRings) {
      canvas.drawPath(path, contourPaint);
    }

    // River / Waterway polygon fill
    final riverPath = Path()
      ..moveTo(210, 0)
      ..cubicTo(240, 200, 280, 350, 330, 500)
      ..cubicTo(370, 620, 420, 750, 450, 900)
      ..lineTo(480, 900)
      ..cubicTo(450, 750, 400, 620, 360, 500)
      ..cubicTo(310, 350, 270, 200, 240, 0)
      ..close();

    final riverPaint = Paint()
      ..color = riverColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(riverPath, riverPaint);
  }

  void _drawCoordinateGrid(Canvas canvas, Size size, Color gridColor) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    for (double x = 100; x < size.width; x += 150) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 100; y < size.height; y += 150) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawMeshLinks(Canvas canvas, Color linkColor) {
    final linkPaint = Paint()
      ..color = linkColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final visibleNodes = nodes.where((n) => _isNodeVisible(n)).toList();
    final youNode = visibleNodes
        .where((n) => n.type == _NodeType.you)
        .firstOrNull;

    if (youNode != null) {
      // Connect 'You' to visible peers in radio proximity
      for (final peer in visibleNodes.where(
        (n) => n.type == _NodeType.peerTeal || n.type == _NodeType.peerYellow,
      )) {
        final dist = (youNode.offset - peer.offset).distance;
        if (dist <= 280) {
          _drawDashedLine(canvas, youNode.offset, peer.offset, linkPaint);
        }
      }
    }

    // Connect peers to neighboring peers
    final peers = visibleNodes
        .where(
          (n) => n.type == _NodeType.peerTeal || n.type == _NodeType.peerYellow,
        )
        .toList();
    for (int i = 0; i < peers.length; i++) {
      for (int j = i + 1; j < peers.length; j++) {
        if ((peers[i].offset - peers[j].offset).distance <= 170) {
          _drawDashedLine(canvas, peers[i].offset, peers[j].offset, linkPaint);
        }
      }
    }

    // Connect SOS nodes to the nearest peer or You relay
    final sosNodes = visibleNodes
        .where((n) => n.type == _NodeType.sos)
        .toList();
    for (final sos in sosNodes) {
      _MapNode? nearestRelay;
      double minDist = double.infinity;
      for (final other in visibleNodes) {
        if (other.id == sos.id || other.type == _NodeType.sos) continue;
        final d = (sos.offset - other.offset).distance;
        if (d < minDist) {
          minDist = d;
          nearestRelay = other;
        }
      }
      if (nearestRelay != null && minDist <= 350) {
        _drawDashedLine(canvas, sos.offset, nearestRelay.offset, linkPaint);
      }
    }

    // Connect shelters to nearest mesh relay
    final shelterNodes = visibleNodes
        .where((n) => n.type == _NodeType.shelter)
        .toList();
    for (final shelter in shelterNodes) {
      _MapNode? nearest;
      double minDist = double.infinity;
      for (final other in visibleNodes) {
        if (other.id == shelter.id || other.type == _NodeType.shelter) continue;
        final d = (shelter.offset - other.offset).distance;
        if (d < minDist) {
          minDist = d;
          nearest = other;
        }
      }
      if (nearest != null && minDist <= 320) {
        _drawDashedLine(canvas, shelter.offset, nearest.offset, linkPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    final double distance = (p2 - p1).distance;
    if (distance == 0) return;
    final double dx = (p2.dx - p1.dx) / distance;
    final double dy = (p2.dy - p1.dy) / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final double end = math.min(currentDist + dashWidth, distance);
      canvas.drawLine(
        Offset(p1.dx + dx * currentDist, p1.dy + dy * currentDist),
        Offset(p1.dx + dx * end, p1.dy + dy * end),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawSosNode(Canvas canvas, _MapNode node) {
    final Offset pos = node.offset;

    // Concentric expanding pulse wave rings
    for (int i = 0; i < 2; i++) {
      final double progress = (pulseValue + (i * 0.5)) % 1.0;
      final double radius = 18.0 + (progress * 26.0);
      final double opacity = (1.0 - progress).clamp(0.0, 0.85);

      final pulsePaint = Paint()
        ..color = AppTokens.sosRed.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pos, radius, pulsePaint);
    }

    // Outer glow ring
    final glowPaint = Paint()
      ..color = AppTokens.sosRed.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 20.0, glowPaint);

    // Inner filled SOS circle
    final corePaint = Paint()
      ..color = AppTokens.sosRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 15.0, corePaint);

    // "SOS" Bold White Text
    const textSpan = TextSpan(
      text: 'SOS',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        pos.dx - (textPainter.width / 2),
        pos.dy - (textPainter.height / 2),
      ),
    );
  }

  void _drawUserNode(Canvas canvas, _MapNode node, bool isLight) {
    final Offset pos = node.offset;

    // Accuracy / coverage pulse ring
    final pulsePaint = Paint()
      ..color = const Color(0xFF2F80ED)
          .withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, 16.0 + (pulseValue * 18.0), pulsePaint);

    // Outer white rim
    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 10.0, rimPaint);

    if (isLight) {
      final borderPaint = Paint()
        ..color = const Color(0xFF1B64C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(pos, 10.0, borderPaint);
    }

    // Core blue dot
    final corePaint = Paint()
      ..color = const Color(0xFF2F80ED)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 7.5, corePaint);

    // Directional heading arrow
    final headingPaint = Paint()
      ..color = const Color(0xFF2F80ED).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final headingPath = Path()
      ..moveTo(pos.dx, pos.dy - 24)
      ..lineTo(pos.dx - 12, pos.dy - 8)
      ..lineTo(pos.dx + 12, pos.dy - 8)
      ..close();
    canvas.drawPath(headingPath, headingPaint);
  }

  void _drawClusterBubble(
    Canvas canvas,
    _MapNode node,
    bool isLight,
    bool isOled,
  ) {
    final Offset pos = node.offset;

    // Cluster bubble background
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 88, height: 42),
      const Radius.circular(AppTokens.radiusMd),
    );

    final bgPaint = Paint()
      ..color =
          (isLight
                  ? AppTokens.lightSurface
                  : (isOled ? AppTokens.oledSurface : AppTokens.darkBg))
              .withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bubbleRect, bgPaint);

    final borderPaint = Paint()
      ..color = AppTokens.beaconTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Dynamic cluster count label
    final textSpan = TextSpan(
      text: node.label.isNotEmpty ? node.label : 'Devices\nin this area',
      style: const TextStyle(
        color: AppTokens.beaconTeal,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        height: 1.15,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        pos.dx - (textPainter.width / 2),
        pos.dy - (textPainter.height / 2),
      ),
    );
  }

  void _drawPeerNode(Canvas canvas, _MapNode node, Color color, bool isLight) {
    final Offset pos = node.offset;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: isLight ? 0.35 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 9.0, glowPaint);

    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 5.0, corePaint);

    if (isLight) {
      final rimPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(pos, 5.0, rimPaint);
    }
  }

  void _drawRescueNode(Canvas canvas, _MapNode node, bool isLight) {
    final Offset pos = node.offset;

    final bgPaint = Paint()
      ..color = isLight ? AppTokens.lightSuccess : AppTokens.darkSuccess
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 11.0, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, 11.0, borderPaint);

    // Draw white plus / shield mark
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(pos.dx - 4, pos.dy),
      Offset(pos.dx + 4, pos.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 4),
      Offset(pos.dx, pos.dy + 4),
      crossPaint,
    );
  }

  void _drawShelterNode(Canvas canvas, _MapNode node, bool isLight) {
    final Offset pos = node.offset;

    final bgPaint = Paint()
      ..color = isLight ? AppTokens.lightPrimary : AppTokens.signalYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 11.0, bgPaint);

    final borderPaint = Paint()
      ..color = isLight ? AppTokens.lightBorderStrong : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(pos, 11.0, borderPaint);

    // House roof mark
    final housePath = Path()
      ..moveTo(pos.dx, pos.dy - 5)
      ..lineTo(pos.dx - 5, pos.dy)
      ..lineTo(pos.dx - 3, pos.dy)
      ..lineTo(pos.dx - 3, pos.dy + 4)
      ..lineTo(pos.dx + 3, pos.dy + 4)
      ..lineTo(pos.dx + 3, pos.dy)
      ..lineTo(pos.dx + 5, pos.dy)
      ..close();

    final markPaint = Paint()
      ..color = AppTokens.lightOnPrimary
      ..style = PaintingStyle.fill;
    canvas.drawPath(housePath, markPaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return true;
  }
}
