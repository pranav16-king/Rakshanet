import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../models/emergency_report.dart';
import '../../models/mesh_device.dart';
import '../../models/shelter_resource.dart';
import '../../providers/mesh_provider.dart';
import '../../theme/app_tokens.dart';

/// Screen 6: Live Map & Nearby Devices
/// Features:
/// - Offline topographical custom vector canvas with contour lines and grid
/// - Pulsing SOS markers with expanding wave animation
/// - Peer nodes with mesh connection links
/// - Device cluster bubble ("5 devices in this area")
/// - Interactive zoom & pan via InteractiveViewer
/// - Filter chips: "You", "Nearby", "SOS", "Rescue", "Shelter"
/// - Floating layer toggle and GPS re-center controls
/// - Bottom floating incident sheet: "2 people need help ~1.3 km • Last seen 25 min ago"
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
  final Set<String> _activeFilters = {'You', 'Nearby', 'SOS', 'Rescue', 'Shelter'};

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

  List<_MapNode> _computeNodes(MeshProvider mesh) {
    final List<_MapNode> result = [];

    // 1. User Node ('You')
    result.add(
      _MapNode(
        id: 'node-you',
        label: 'You',
        type: _NodeType.you,
        offset: const Offset(400, 480),
        statusText: 'My Device (Mesh Relay Active)',
        distance: '0 m',
        lastSeen: 'Now',
      ),
    );

    // 2. Real BLE peers dynamically from MeshProvider
    final peers = mesh.nearbyDevices;
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
          statusText: 'Relay node ${dev.deviceId} • Battery ${dev.batteryLevel}% • Hop ${dev.hopCount}',
          distance: dev.proximityBand == ProximityBand.immediate
              ? '~25 m'
              : (dev.proximityBand == ProximityBand.near ? '~120 m' : '~450 m'),
          lastSeen: 'Just now',
        ),
      );
    }

    // 3. Cluster bubble if 4 or more peers
    if (peers.length >= 4) {
      result.add(
        _MapNode(
          id: 'node-cluster-1',
          label: '${peers.length} devices\nin this area',
          type: _NodeType.cluster,
          offset: const Offset(530, 360),
          statusText: 'Dense peer cluster: ${peers.length} active Bluetooth relays',
          distance: '~350 m',
          lastSeen: 'Live',
          clusterCount: peers.length,
        ),
      );
    }

    // 4. Emergency Reports from SQLite (or fallback to active incident)
    if (_emergencyReports.isNotEmpty) {
      for (final rep in _emergencyReports) {
        final angle = (rep.id.hashCode.abs() % 360) * math.pi / 180;
        final pos = Offset(400 + math.cos(angle) * 180, 480 + math.sin(angle) * 180);
        result.add(
          _MapNode(
            id: rep.id,
            label: 'SOS',
            type: _NodeType.sos,
            offset: pos,
            statusText: '${rep.peopleCount} people need help • ${rep.notes.isNotEmpty ? rep.notes : rep.type.label}',
            distance: '~1.3 km',
            lastSeen: 'Reported',
            peopleCount: rep.peopleCount,
          ),
        );
      }
    } else {
      result.add(
        _MapNode(
          id: 'node-sos-1',
          label: 'SOS',
          type: _NodeType.sos,
          offset: const Offset(560, 240),
          statusText: '2 people need help • Trapped by rising water',
          distance: '~1.3 km',
          lastSeen: '25 min ago',
          peopleCount: 2,
        ),
      );
    }

    // 5. Shelter Node from SQLite
    if (_shelterResources.isNotEmpty) {
      final s = _shelterResources.first;
      result.add(
        _MapNode(
          id: s.id,
          label: s.name,
          type: _NodeType.shelter,
          offset: const Offset(260, 270),
          statusText: '${s.name} • ${s.capacity}/${s.maxCapacity} spaces',
          distance: '~${s.distance.toStringAsFixed(1)} km',
          lastSeen: 'Verified',
        ),
      );
    }

    return result;
  }

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
    const Offset userPos = Offset(400, 480);
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

  void _showLayersSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTokens.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
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
                  const Text(
                    'Map Layers & Offline Assets',
                    style: TextStyle(
                      color: AppTokens.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTokens.darkTextMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: const Text('Topographical Elevation Contours',
                    style: TextStyle(color: AppTokens.darkText)),
                subtitle: const Text('Cached terrain relief vectors',
                    style: TextStyle(color: AppTokens.darkTextMuted, fontSize: 13)),
                value: _showContours,
                onChanged: (val) {
                  setSheetState(() => _showContours = val);
                  setState(() => _showContours = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: const Text('Mesh Network Link Lines',
                    style: TextStyle(color: AppTokens.darkText)),
                subtitle: const Text('Direct BLE / Wi-Fi peer connectivity',
                    style: TextStyle(color: AppTokens.darkTextMuted, fontSize: 13)),
                value: _showMeshLinks,
                onChanged: (val) {
                  setSheetState(() => _showMeshLinks = val);
                  setState(() => _showMeshLinks = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTokens.signalYellow,
                title: const Text('Tactical Coordinates Grid',
                    style: TextStyle(color: AppTokens.darkText)),
                subtitle: const Text('Military MGRS / Lat-Long overlay',
                    style: TextStyle(color: AppTokens.darkTextMuted, fontSize: 13)),
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

  void _showIncidentDetailsModal(_MapNode node) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTokens.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
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
                  color: AppTokens.darkBorderStrong,
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
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppTokens.sosRed, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.statusText,
                        style: const TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ${node.distance} • Reported: ${node.lastSeen}',
                        style: const TextStyle(
                          color: AppTokens.darkTextMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.darkSurfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: AppTokens.darkBorder),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mesh Hops:', style: TextStyle(color: AppTokens.darkTextMuted)),
                      Text('2 Relays (BLE Mesh)',
                          style: TextStyle(color: AppTokens.beaconTeal, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coordinates:', style: TextStyle(color: AppTokens.darkTextMuted)),
                      Text('19.0762° N, 72.8781° E',
                          style: TextStyle(
                              color: AppTokens.darkText,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Priority Score:', style: TextStyle(color: AppTokens.darkTextMuted)),
                      Text('CRITICAL (Immediate aid required)',
                          style: TextStyle(color: AppTokens.sosRed, fontWeight: FontWeight.bold)),
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
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text(
                        'Navigate to Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTokens.beaconTeal,
                            content: Text('Offline compass navigation engaged for ${node.distance}'),
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

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final nodes = _computeNodes(mesh);

    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Interactive Vector Map Canvas
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset local = box.globalToLocal(details.globalPosition);
                  final Matrix4 transform = _transformController.value;
                  final Matrix4 inverse = Matrix4.inverted(transform);
                  final Offset mapCoord = MatrixUtils.transformPoint(inverse, local);

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
                      _showIncidentDetailsModal(hit);
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTokens.darkBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: AppTokens.darkBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Live Map',
                            style: TextStyle(
                              color: AppTokens.darkText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  size: 13, color: AppTokens.darkTextMuted),
                              SizedBox(width: 4),
                              Text(
                                'Offline • 18 devices nearby',
                                style: TextStyle(
                                  color: AppTokens.darkTextMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Settings / layers action icon
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: AppTokens.darkText),
                      tooltip: 'Map Settings',
                      onPressed: _showLayersSheet,
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
                    onTap: _showLayersSheet,
                  ),
                  const SizedBox(height: 12),
                  _buildFloatingMapButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Re-center on You',
                    onTap: _centerOnUser,
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
                  ),
                  const SizedBox(height: 8),
                  _buildFloatingMapButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onTap: () {
                      _transformController.value =
                          _transformController.value.clone()
                            ..multiply(Matrix4.diagonal3Values(0.83, 0.83, 1.0));
                    },
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
                        _buildFilterChip('You', Icons.person_pin_circle_rounded,
                            const Color(0xFF2F80ED)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Nearby', Icons.location_on,
                            AppTokens.beaconTeal),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'SOS', Icons.warning_rounded, AppTokens.sosRed),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rescue', Icons.shield_rounded,
                            AppTokens.darkSuccess),
                        const SizedBox(width: 8),
                        _buildFilterChip('Shelter', Icons.home_rounded,
                            AppTokens.signalYellow),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Floating Bottom Sheet: "2 people need help ~1.3 km • Last seen 25 min ago"
                  InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    onTap: () {
                      final sosNode = nodes.firstWhere(
                          (n) => n.id == 'node-sos-1' || n.type == _NodeType.sos,
                          orElse: () => nodes.first);
                      _showIncidentDetailsModal(sosNode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTokens.darkSurface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(
                          color: AppTokens.sosRed.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Red location pin icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTokens.sosRed.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppTokens.sosRed,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Incident Title & Distance / Timestamp
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '2 people need help',
                                  style: TextStyle(
                                    color: AppTokens.darkText,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '~1.3 km • Last seen 25 min ago',
                                  style: TextStyle(
                                    color: AppTokens.darkSos,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTokens.darkTextMuted,
                            size: 26,
                          ),
                        ],
                      ),
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

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: AppTokens.touchMin,
      height: AppTokens.touchMin,
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: AppTokens.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
            child: Icon(icon, color: AppTokens.darkText, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color) {
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
                ? AppTokens.darkSurface
                : AppTokens.darkSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: isSelected ? color : AppTokens.darkBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppTokens.darkTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTokens.darkText : AppTokens.darkTextMuted,
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
  final int clusterCount;

  _MapNode({
    required this.id,
    required this.label,
    required this.type,
    required this.offset,
    required this.statusText,
    required this.distance,
    required this.lastSeen,
    this.peopleCount = 0,
    this.clusterCount = 0,
  });
}

/// Custom Vector Canvas Painter
/// Renders topographical contours, coordinate grid, mesh link connections,
/// glowing pulses, and custom node glyphs.
class _MapCanvasPainter extends CustomPainter {
  final List<_MapNode> nodes;
  final Set<String> activeFilters;
  final double pulseValue;
  final bool showContours;
  final bool showMeshLinks;
  final bool showGrid;
  final _MapNode? selectedNode;

  _MapCanvasPainter({
    required this.nodes,
    required this.activeFilters,
    required this.pulseValue,
    required this.showContours,
    required this.showMeshLinks,
    required this.showGrid,
    this.selectedNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background fill
    final bgPaint = Paint()..color = const Color(0xFF0B1424);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Topographical Contours
    if (showContours) {
      _drawTopographyContours(canvas, size);
    }

    // 3. Coordinate Grid
    if (showGrid) {
      _drawCoordinateGrid(canvas, size);
    }

    // 4. Mesh Link Lines
    if (showMeshLinks) {
      _drawMeshLinks(canvas);
    }

    // 5. Render Nodes
    for (final node in nodes) {
      if (!_isNodeVisible(node)) continue;

      switch (node.type) {
        case _NodeType.you:
          _drawUserNode(canvas, node);
          break;
        case _NodeType.sos:
          _drawSosNode(canvas, node);
          break;
        case _NodeType.cluster:
          _drawClusterBubble(canvas, node);
          break;
        case _NodeType.peerYellow:
          _drawPeerNode(canvas, node, AppTokens.signalYellow);
          break;
        case _NodeType.peerTeal:
          _drawPeerNode(canvas, node, AppTokens.beaconTeal);
          break;
        case _NodeType.rescue:
          _drawRescueNode(canvas, node);
          break;
        case _NodeType.shelter:
          _drawShelterNode(canvas, node);
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
        return activeFilters.contains('Nearby');
      case _NodeType.cluster:
        return activeFilters.contains('Nearby');
      case _NodeType.rescue:
        return activeFilters.contains('Rescue');
      case _NodeType.shelter:
        return activeFilters.contains('Shelter');
    }
  }

  void _drawTopographyContours(Canvas canvas, Size size) {
    final contourPaint = Paint()
      ..color = const Color(0xFF14243B)
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
      ..color = const Color(0xFF0F263E).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(riverPath, riverPaint);
  }

  void _drawCoordinateGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2D47).withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    for (double x = 100; x < size.width; x += 150) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 100; y < size.height; y += 150) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawMeshLinks(Canvas canvas) {
    final linkPaint = Paint()
      ..color = AppTokens.beaconTeal.withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final connections = [
      ['node-you', 'node-peer-1'],
      ['node-you', 'node-peer-2'],
      ['node-you', 'node-peer-3'],
      ['node-you', 'node-peer-4'],
      ['node-peer-1', 'node-sos-2'],
      ['node-peer-1', 'node-shelter-1'],
      ['node-peer-1', 'node-rescue-1'],
      ['node-peer-2', 'node-cluster-1'],
      ['node-peer-2', 'node-peer-6'],
      ['node-peer-6', 'node-sos-1'],
      ['node-cluster-1', 'node-sos-3'],
      ['node-peer-4', 'node-peer-5'],
    ];

    for (final pair in connections) {
      final a = nodes.firstWhere((n) => n.id == pair[0], orElse: () => nodes[0]);
      final b = nodes.firstWhere((n) => n.id == pair[1], orElse: () => nodes[0]);

      if (!_isNodeVisible(a) || !_isNodeVisible(b)) continue;

      // Draw dashed line
      _drawDashedLine(canvas, a.offset, b.offset, linkPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    final double distance = (p2 - p1).distance;
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
      Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)),
    );
  }

  void _drawUserNode(Canvas canvas, _MapNode node) {
    final Offset pos = node.offset;

    // Accuracy / coverage pulse ring
    final pulsePaint = Paint()
      ..color = const Color(0xFF2F80ED).withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, 16.0 + (pulseValue * 18.0), pulsePaint);

    // Outer white rim
    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 10.0, rimPaint);

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

  void _drawClusterBubble(Canvas canvas, _MapNode node) {
    final Offset pos = node.offset;

    // Cluster bubble background
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 88, height: 42),
      const Radius.circular(AppTokens.radiusMd),
    );

    final bgPaint = Paint()
      ..color = AppTokens.darkBg.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bubbleRect, bgPaint);

    final borderPaint = Paint()
      ..color = AppTokens.beaconTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Label: "5 devices\nin this area"
    const textSpan = TextSpan(
      text: '5 devices\nin this area',
      style: TextStyle(
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
      Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)),
    );
  }

  void _drawPeerNode(Canvas canvas, _MapNode node, Color color) {
    final Offset pos = node.offset;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 9.0, glowPaint);

    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 5.0, corePaint);
  }

  void _drawRescueNode(Canvas canvas, _MapNode node) {
    final Offset pos = node.offset;

    final bgPaint = Paint()
      ..color = AppTokens.darkSuccess
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
    canvas.drawLine(Offset(pos.dx - 4, pos.dy), Offset(pos.dx + 4, pos.dy), crossPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 4), Offset(pos.dx, pos.dy + 4), crossPaint);
  }

  void _drawShelterNode(Canvas canvas, _MapNode node) {
    final Offset pos = node.offset;

    final bgPaint = Paint()
      ..color = AppTokens.signalYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 11.0, bgPaint);

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
