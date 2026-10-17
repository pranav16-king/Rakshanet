import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../models/emergency_report.dart';
import '../../models/mesh_device.dart';
import '../../models/offline_map_region.dart';
import '../../models/shelter_resource.dart';
import '../../providers/emergency_report_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/location/location_service.dart';
import '../../services/map/offline_map_service.dart';
import '../../services/mesh_engine.dart';
import '../../services/offline_map_manager.dart';
import '../../services/sos_alert_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/haversine_distance.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 6: Live Map & Offline Tactical Navigation
///
/// Features:
/// 1. Real geographic mapping via FlutterMap & OpenStreetMap / CartoDB tiles
/// 2. 100% Offline disk tile caching with seamless tactical grid fallback
/// 3. One-tap Offline Area Pre-caching (5km - 20km radius downloader)
/// 4. GPS-accurate markers: User Location, Emergency SOS Distress, Shelters & Mesh Peers
/// 5. Distance and Compass Bearing calculation for all incidents and shelters
/// 6. Interactive Pin Drop: tap any point on the map to measure distance & bearing
/// 7. Hi-Vis emergency design system (Light, Dark, OLED Low-Power)
class LiveMapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final double? initialZoom;
  final LatLng? initialNavTarget;
  final String? initialNavTargetName;

  const LiveMapScreen({
    super.key,
    this.initialCenter,
    this.initialZoom,
    this.initialNavTarget,
    this.initialNavTargetName,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  AnimationController? _moveAnimationController;
  StateSetter? _sheetStateSetter;

  // Active navigation target for glowing guide polyline and top HUD
  LatLng? _activeNavTarget;
  String? _activeNavTargetName;

  // Active filter chip keys
  final Set<String> _activeFilters = {
    'All',
    'You',
    'SOS',
    'Shelters',
    'Nearby',
    'Hazards',
  };

  // Map settings
  bool _forceTacticalGrid = false;
  bool _showHazards = true;
  final bool _showAccuracyCircle = true;
  bool _isMeasuring = false;
  LatLng? _measuredPin;

  // Cache stats & Offline Map Manager
  double _cacheSizeMb = 0.0;
  int _cacheTileCount = 0;

  List<OfflineMapRegion> _offlineRegions = [];
  StreamSubscription<MapDownloadProgress>? _progressSub;
  MapDownloadProgress? _activeDownloadProgress;
  double _selectedRadiusKm = 10.0;
  int _estimatedSectorTiles = 0;
  bool _isCurrentCenterCovered = false;
  double _currentZoom = 15.0;
  LatLng _currentCenter = const LatLng(20.5937, 78.9629);
  double _currentRotation = 0.0;

  List<EmergencyReport> _emergencyReports = [];
  List<ShelterResource> _shelterResources = [];
  StreamSubscription? _meshEventSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _loadSqliteData();
    _refreshCacheStats();
    _loadOfflineRegions();

    _progressSub = OfflineMapManager.instance.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _activeDownloadProgress = progress;
          if (progress.isCompleted) {
            _loadOfflineRegions();
            _refreshCacheStats();
          }
        });
        _sheetStateSetter?.call(() {});
      }
    });

    _meshEventSubscription = MeshEngine().incomingEnvelopes.listen((_) {
      _loadSqliteData();
    });

    if (widget.initialNavTarget != null) {
      _activeNavTarget = widget.initialNavTarget;
      _activeNavTargetName = widget.initialNavTargetName ?? 'Distress Beacon';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final telemetry = context.read<TelemetryProvider>();
          final localFix = LocationService.instance.currentFix;
          final userLat = telemetry.latitude ?? localFix?.latitude;
          final userLng = telemetry.longitude ?? localFix?.longitude;
          if (userLat != null && userLng != null) {
            _frameLocations(LatLng(userLat, userLng), widget.initialNavTarget!);
          } else {
            _animatedMapMove(widget.initialNavTarget!, widget.initialZoom ?? 16.5);
          }
        }
      });
    } else if (widget.initialCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animatedMapMove(widget.initialCenter!, widget.initialZoom ?? 16.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _moveAnimationController?.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    _meshEventSubscription?.cancel();
    super.dispose();
  }

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

  Future<void> _refreshCacheStats() async {
    final stats = await OfflineMapService.instance.getCacheStats();
    if (mounted) {
      setState(() {
        _cacheSizeMb = stats['sizeMb'] as double? ?? 0.0;
        _cacheTileCount = stats['count'] as int? ?? 0;
      });
    }
  }

  void _centerOnUser() {
    HapticFeedback.mediumImpact();
    final telemetry = context.read<TelemetryProvider>();
    if (telemetry.latitude != null && telemetry.longitude != null) {
      final userPos = LatLng(telemetry.latitude!, telemetry.longitude!);
      _animatedMapMove(userPos, 16.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gps_fixed, color: AppTokens.signalYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Centered on your GPS location (${telemetry.latitude!.toStringAsFixed(4)}, ${telemetry.longitude!.toStringAsFixed(4)})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      telemetry.refreshTelemetry();
      if (_emergencyReports.isNotEmpty) {
        final r = _emergencyReports.firstWhere(
          (e) => e.latitude != null && e.longitude != null,
          orElse: () => _emergencyReports.first,
        );
        if (r.latitude != null && r.longitude != null) {
          _animatedMapMove(LatLng(r.latitude!, r.longitude!), 14.0);
        }
      } else {
        _animatedMapMove(const LatLng(20.5937, 78.9629), 5.5);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquiring satellite GPS fix... Please check Location services.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _moveAnimationController?.stop();
    _moveAnimationController?.dispose();
    _moveAnimationController = null;

    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _moveAnimationController = controller;

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        if (_moveAnimationController == controller) {
          _moveAnimationController = null;
        }
      }
    });

    controller.forward();
  }

  void _frameLocations(LatLng locA, LatLng locB) {
    final minLat = math.min(locA.latitude, locB.latitude);
    final maxLat = math.max(locA.latitude, locB.latitude);
    final minLng = math.min(locA.longitude, locB.longitude);
    final maxLng = math.max(locA.longitude, locB.longitude);
    final center = LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);

    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = math.max(latDiff, lngDiff);

    double targetZoom = 15.0;
    if (maxDiff > 0.1) {
      targetZoom = 11.5;
    } else if (maxDiff > 0.05) {
      targetZoom = 13.0;
    } else if (maxDiff > 0.02) {
      targetZoom = 14.2;
    } else if (maxDiff > 0.008) {
      targetZoom = 15.2;
    } else if (maxDiff > 0.003) {
      targetZoom = 16.2;
    } else {
      targetZoom = 17.2;
    }

    _animatedMapMove(center, targetZoom);
  }

  void _startNavigation(LatLng target, {String? targetName, EmergencyReport? report}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeNavTarget = target;
      _activeNavTargetName = targetName ?? 'SOS Distress Beacon';
    });

    final telemetry = context.read<TelemetryProvider>();
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;

    if (userLat != null && userLng != null) {
      _frameLocations(LatLng(userLat, userLng), target);
    } else {
      _animatedMapMove(target, 16.5);
    }

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 20.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: target.latitude,
      lng2: target.longitude,
      accuracy2: 15.0,
      timestamp2: DateTime.now().millisecondsSinceEpoch,
    );

    final dist = geoResult.summaryLabel;
    final dir = geoResult.compassDirection;
    final deg = geoResult.bearingDegrees?.round() ?? 0;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.sosRed,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Navigation active: Head $dir ($deg°) • $dist to target',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearNavigation() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeNavTarget = null;
      _activeNavTargetName = null;
    });
  }

  LatLng _getPeerCoordinate(MeshDevice peer, int index, int total, LatLng origin) {
    double distanceMeters;
    switch (peer.proximityBand) {
      case ProximityBand.immediate:
        distanceMeters = 15.0;
        break;
      case ProximityBand.near:
        distanceMeters = 35.0;
        break;
      case ProximityBand.far:
        distanceMeters = 80.0;
        break;
    }
    if (peer.hopCount > 1) {
      distanceMeters += (peer.hopCount - 1) * 70.0;
    }

    final hashVal = (peer.deviceId.hashCode.abs() % 360) * (math.pi / 180.0);
    final spread = total > 0 ? (index * (2 * math.pi / total)) : 0.0;
    final angle = (spread + hashVal * 0.35) % (2 * math.pi);

    final deltaLat = (distanceMeters * math.cos(angle)) / 111320.0;
    final cosLat = math.cos(origin.latitude * math.pi / 180.0);
    final deltaLng = (distanceMeters * math.sin(angle)) /
        (111320.0 * (cosLat.abs() > 0.0001 ? cosLat : 1.0));

    return LatLng(origin.latitude + deltaLat, origin.longitude + deltaLng);
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (filter == 'All') {
        if (_activeFilters.contains('All')) {
          _activeFilters.clear();
          _activeFilters.add('You');
        } else {
          _activeFilters.addAll(['All', 'You', 'SOS', 'Shelters', 'Nearby', 'Hazards']);
        }
      } else {
        if (_activeFilters.contains(filter)) {
          if (_activeFilters.length > 1) {
            _activeFilters.remove(filter);
            _activeFilters.remove('All');
          }
        } else {
          _activeFilters.add(filter);
        }
      }
    });
  }

  Future<void> _loadOfflineRegions() async {
    try {
      final regions = await OfflineMapManager.instance.getDownloadedRegions();
      if (mounted) {
        setState(() {
          _offlineRegions = regions;
          _updateCoverageStatus();
        });
        _sheetStateSetter?.call(() {});
      }
    } catch (_) {}
  }

  void _updateCoverageStatus() {
    final covered = _offlineRegions.any((r) =>
        r.isCompleted &&
        r.containsCoordinate(_currentCenter.latitude, _currentCenter.longitude));
    if (covered != _isCurrentCenterCovered) {
      setState(() {
        _isCurrentCenterCovered = covered;
      });
    }
  }

  Future<void> _updateTileEstimate(LatLng center, double radiusKm) async {
    final bounds = OfflineMapManager.calculateSectorBounds(
      center: center,
      radiusKm: radiusKm,
    );
    final count = await OfflineMapManager.instance.estimateTileCount(
      minLat: bounds['minLat']!,
      maxLat: bounds['maxLat']!,
      minLng: bounds['minLng']!,
      maxLng: bounds['maxLng']!,
      minZoom: 10,
      maxZoom: 15,
    );
    if (mounted) {
      setState(() {
        _estimatedSectorTiles = count;
      });
      _sheetStateSetter?.call(() {});
    }
  }

  Future<void> _startSectorDownload(LatLng center, double radiusKm) async {
    final bounds = OfflineMapManager.calculateSectorBounds(
      center: center,
      radiusKm: radiusKm,
    );
    final regionId = 'sector_${DateTime.now().millisecondsSinceEpoch}';
    final name =
        'Sector ${radiusKm.toInt()} km (${center.latitude.toStringAsFixed(2)}, ${center.longitude.toStringAsFixed(2)})';

    _sheetStateSetter?.call(() {});

    unawaited(OfflineMapManager.instance.downloadRegion(
      regionId: regionId,
      name: name,
      minLat: bounds['minLat']!,
      maxLat: bounds['maxLat']!,
      minLng: bounds['minLng']!,
      maxLng: bounds['maxLng']!,
      minZoom: 10,
      maxZoom: 15,
    ));
  }

  List<Polygon> _buildRegionPolygons(ThemeProvider theme) {
    return _offlineRegions.map((region) {
      final isDone = region.isCompleted;
      return Polygon(
        points: [
          LatLng(region.minLat, region.minLng),
          LatLng(region.maxLat, region.minLng),
          LatLng(region.maxLat, region.maxLng),
          LatLng(region.minLat, region.maxLng),
        ],
        color: isDone
            ? AppTokens.beaconTeal.withValues(alpha: 0.12)
            : AppTokens.signalYellow.withValues(alpha: 0.12),
        borderColor: isDone ? AppTokens.beaconTeal : AppTokens.signalYellow,
        borderStrokeWidth: 2.0,
      );
    }).toList();
  }

  Widget _buildCoverageBanner(ThemeProvider theme) {
    if (_isCurrentCenterCovered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (theme.isLightMode ? AppTokens.lightSurface : AppTokens.darkBg)
              .withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(color: AppTokens.beaconTeal.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin_rounded, color: AppTokens.beaconTeal, size: 14),
            SizedBox(width: 6),
            Text(
              'MAP OFFLINE • CACHED REGION',
              style: TextStyle(
                color: AppTokens.beaconTeal,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () => _showOfflineManagerSheet(theme),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (theme.isLightMode ? AppTokens.lightSurface : AppTokens.darkBg)
                .withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(color: AppTokens.signalYellow.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: AppTokens.signalYellow, size: 14),
              SizedBox(width: 6),
              Text(
                'UNCOVERED REGION — Connect to download',
                style: TextStyle(
                  color: AppTokens.signalYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTokens.signalYellow, size: 10),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildScaleBar(ThemeProvider theme) {
    final latRad = _currentCenter.latitude * math.pi / 180.0;
    final metersPerPixel =
        156543.03392 * math.cos(latRad) / math.pow(2.0, _currentZoom);
    final rawMeters = metersPerPixel * 90.0;

    final double distanceMeters;
    if (rawMeters >= 50000) {
      distanceMeters = (rawMeters / 50000).round() * 50000.0;
    } else if (rawMeters >= 10000) {
      distanceMeters = (rawMeters / 10000).round() * 10000.0;
    } else if (rawMeters >= 5000) {
      distanceMeters = (rawMeters / 5000).round() * 5000.0;
    } else if (rawMeters >= 1000) {
      distanceMeters = (rawMeters / 1000).round() * 1000.0;
    } else if (rawMeters >= 500) {
      distanceMeters = (rawMeters / 500).round() * 500.0;
    } else if (rawMeters >= 200) {
      distanceMeters = (rawMeters / 200).round() * 200.0;
    } else if (rawMeters >= 100) {
      distanceMeters = (rawMeters / 100).round() * 100.0;
    } else if (rawMeters >= 50) {
      distanceMeters = 50.0;
    } else {
      distanceMeters = 20.0;
    }

    final barWidth = (distanceMeters / metersPerPixel).clamp(40.0, 150.0);
    final label = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(distanceMeters % 1000 == 0 ? 0 : 1)} km'
        : '${distanceMeters.toInt()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (theme.isLightMode
                ? AppTokens.lightSurface
                : (theme.isLowPower ? AppTokens.oledSurface : AppTokens.darkBg))
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.text,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: barWidth,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.beaconTeal,
              borderRadius: BorderRadius.circular(2),
              border: Border(
                left: BorderSide(color: theme.text, width: 2),
                right: BorderSide(color: theme.text, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineManagerSheet(ThemeProvider theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          _sheetStateSetter = setSheetState;
          final telemetry = context.read<TelemetryProvider>();
          final userCenter = LatLng(
            telemetry.latitude ?? _currentCenter.latitude,
            telemetry.longitude ?? _currentCenter.longitude,
          );

          final activeProg = _activeDownloadProgress;
          final isDownloading = OfflineMapManager.instance.isDownloading;

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.download_for_offline_rounded,
                              color: AppTokens.signalYellow, size: 26),
                          const SizedBox(width: 10),
                          Text(
                            'Offline Map Manager',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Cache size stats card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storage_rounded,
                              color: AppTokens.beaconTeal, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Cache: ${_cacheSizeMb.toStringAsFixed(1)} MB',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_cacheTileCount map tiles saved locally in app storage',
                                style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await OfflineMapManager.instance.clearAllTiles();
                            await _refreshCacheStats();
                            setSheetState(() {});
                          },
                          child: const Text('Purge',
                              style: TextStyle(color: AppTokens.sosRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Download Current Sector
                  Text(
                    'DOWNLOAD CURRENT SECTOR',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sector Radius Selector (5 km / 10 km / 25 km)
                  Row(
                    children: [5.0, 10.0, 25.0].map((radius) {
                      final isSelected = _selectedRadiusKm == radius;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? AppTokens.signalYellow.withValues(alpha: 0.2)
                                  : theme.surfaceSunken,
                              side: BorderSide(
                                color: isSelected ? AppTokens.signalYellow : theme.border,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _selectedRadiusKm = radius;
                              });
                              _updateTileEstimate(userCenter, radius);
                            },
                            child: Text(
                              '${radius.toInt()} km',
                              style: TextStyle(
                                color: isSelected ? AppTokens.signalYellow : theme.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Estimation display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _estimatedSectorTiles > 0
                          ? 'Estimated: ~$_estimatedSectorTiles tiles (Zoom 10-15 • ~${(_estimatedSectorTiles * 0.015).toStringAsFixed(1)} MB)'
                          : 'Pre-caches complete map sectors across zoom levels 10 to 15 for offline search and rescue navigation.',
                      style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live Progress Bar or Download Button
                  if (isDownloading && activeProg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTokens.beaconTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: AppTokens.beaconTeal.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  activeProg.message,
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(activeProg.percentage * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppTokens.beaconTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: activeProg.percentage,
                              backgroundColor: theme.surfaceSunken,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.signalYellow),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.pause_rounded, size: 18),
                                label: const Text('Pause'),
                                onPressed: () {
                                  OfflineMapManager.instance.pauseDownload(activeProg.regionId);
                                  setSheetState(() {});
                                },
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppTokens.sosRed),
                                icon: const Icon(Icons.cancel_rounded, size: 18),
                                label: const Text('Cancel'),
                                onPressed: () {
                                  OfflineMapManager.instance.cancelDownload(activeProg.regionId);
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: AppTokens.buttonPrimary,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.signalYellow,
                          foregroundColor: AppTokens.nightNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_download_rounded, size: 20),
                        label: Text(
                          'Download Current Sector (${_selectedRadiusKm.toInt()} km)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          _startSectorDownload(userCenter, _selectedRadiusKm);
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section Title: Downloaded Offline Regions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAVED OFFLINE SECTORS (${_offlineRegions.length})',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: () => _loadOfflineRegions(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_offlineRegions.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surfaceSunken,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: theme.border),
                      ),
                      child: Center(
                        child: Text(
                          'No offline sectors saved yet.\nDownload sectors above to enable full offline mapping.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._offlineRegions.map((region) {
                      final isDone = region.isCompleted;
                      final isDownloadingThis =
                          region.id == OfflineMapManager.instance.activeRegionId &&
                              OfflineMapManager.instance.isDownloading;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.surfaceSunken,
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          border: Border.all(
                            color: isDone
                                ? AppTokens.beaconTeal.withValues(alpha: 0.5)
                                : (region.isFailed
                                    ? AppTokens.sosRed.withValues(alpha: 0.5)
                                    : theme.border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    region.name,
                                    style: TextStyle(
                                      color: theme.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDone
                                            ? AppTokens.beaconTeal
                                            : (region.isFailed
                                                ? AppTokens.sosRed
                                                : AppTokens.signalYellow))
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.radiusPill),
                                  ),
                                  child: Text(
                                    region.status,
                                    style: TextStyle(
                                      color: isDone
                                          ? AppTokens.beaconTeal
                                          : (region.isFailed
                                              ? AppTokens.sosRed
                                              : AppTokens.signalYellow),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Zoom: z${region.minZoom}-z${region.maxZoom} • ${region.downloadedTiles}/${region.totalTiles} tiles • ${region.sizeMb.toStringAsFixed(1)} MB',
                              style: TextStyle(color: theme.textMuted, fontSize: 12),
                            ),
                            if (!isDone) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: region.progress,
                                  backgroundColor: theme.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    region.isFailed ? AppTokens.sosRed : AppTokens.signalYellow,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                                  label: const Text('Focus'),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _animatedMapMove(
                                      LatLng(region.centerLat, region.centerLng),
                                      region.minZoom.toDouble() + 2,
                                    );
                                  },
                                ),
                                if (isDownloadingThis) ...[
                                  IconButton(
                                    icon: const Icon(Icons.pause_rounded, size: 20),
                                    tooltip: 'Pause',
                                    onPressed: () async {
                                      await OfflineMapManager.instance.pauseDownload(region.id);
                                      await _loadOfflineRegions();
                                      setSheetState(() {});
                                    },
                                  ),
                                ] else if (region.isPaused || region.isFailed) ...[
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                    tooltip: 'Resume',
                                    onPressed: () async {
                                      await OfflineMapManager.instance.resumeDownload(region.id);
                                      await _loadOfflineRegions();
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppTokens.sosRed, size: 20),
                                  tooltip: 'Delete Region',
                                  onPressed: () async {
                                    await OfflineMapManager.instance.deleteDownloadedRegion(region.id);
                                    await _loadOfflineRegions();
                                    await _refreshCacheStats();
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),

                  // Tactical Grid Mode Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTokens.signalYellow,
                    title: Text(
                      'Offline Tactical Grid Only',
                      style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Ultra-low power vector grid mode (0 KB network activity)',
                      style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                    ),
                    value: _forceTacticalGrid,
                    onChanged: (val) {
                      setState(() => _forceTacticalGrid = val);
                      setSheetState(() {});
                    },
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTokens.signalYellow,
                    title: Text(
                      'Show Hazard & Flooded Zones',
                      style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Overlays flood water perimeter and landslide hazards',
                      style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                    ),
                    value: _showHazards,
                    onChanged: (val) {
                      setState(() => _showHazards = val);
                      setSheetState(() {});
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    ).whenComplete(() {
      _sheetStateSetter = null;
    });
  }

  void _showIncidentSheet(EmergencyReport report, ThemeProvider theme) {
    final telemetry = context.read<TelemetryProvider>();
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;
    final userAcc = localFix?.horizontalAccuracyMeters ?? 20.0;
    final userTs = localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: userAcc,
      timestamp1: userTs,
      lat2: report.latitude,
      lng2: report.longitude,
      accuracy2: 15.0,
      timestamp2: report.timestamp.millisecondsSinceEpoch,
    );

    final distanceStr = geoResult.summaryLabel;
    final bearingStr = geoResult.bearingDegrees != null
        ? ' • ${geoResult.compassDirection} (${geoResult.bearingDegrees!.round()}°)'
        : '';

    final currentAlert = SosAlertService.instance.currentAlert;
    final matchingAlert = (currentAlert != null &&
            (currentAlert.messageId == report.id ||
                (report.latitude != null &&
                    currentAlert.lat != null &&
                    (report.latitude! - currentAlert.lat!).abs() < 0.0001)))
        ? currentAlert
        : null;

    final survivorName = matchingAlert != null
        ? matchingAlert.senderName
        : (report.id.length > 8 ? 'Survivor (${report.id.substring(0, 8)})' : 'Survivor (${report.id})');
    final deviceId = matchingAlert != null ? matchingAlert.senderDeviceId : report.id;
    final batteryLevel = matchingAlert != null
        ? (matchingAlert.rawMetadata?['battery']?.toString() ?? '85%')
        : '80%';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
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
                  child: const Icon(Icons.warning_amber_rounded, color: AppTokens.sosRed, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${report.peopleCount} ${report.peopleCount == 1 ? 'Person' : 'People'} • ${report.category}',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTokens.sosRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: Text(
                              report.severity,
                              style: const TextStyle(
                                color: AppTokens.sosRed,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: $distanceStr$bearingStr',
                        style: const TextStyle(
                          color: AppTokens.sosRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                      Text('Survivor Name:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        survivorName,
                        style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Device ID:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        deviceId,
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Battery Level:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        batteryLevel.endsWith('%') ? batteryLevel : '$batteryLevel%',
                        style: const TextStyle(
                          color: AppTokens.signalYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Casualty Count:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        '${report.peopleCount} ${report.peopleCount == 1 ? 'Individual' : 'Individuals'}',
                        style: const TextStyle(
                          color: AppTokens.sosRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mesh Hops:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      const Text(
                        'Direct Mesh Hop (0 Relays)',
                        style: TextStyle(
                          color: AppTokens.beaconTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Timestamp:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        HaversineDistance.formatTimestampAge(report.timestamp.millisecondsSinceEpoch),
                        style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coordinates:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        report.latitude != null && report.longitude != null
                            ? '${report.latitude!.toStringAsFixed(5)}°, ${report.longitude!.toStringAsFixed(5)}°'
                            : 'Location pending',
                        style: TextStyle(
                          color: theme.text,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (report.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'MEDICAL & SITUATION NOTES',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  report.notes,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                      label: const Text('Focus', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (report.latitude != null && report.longitude != null) {
                          _animatedMapMove(LatLng(report.latitude!, report.longitude!), 16.5);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.sosRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Direction', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (report.latitude != null && report.longitude != null) {
                          _startNavigation(
                            LatLng(report.latitude!, report.longitude!),
                            targetName: 'SOS: ${report.category}',
                            report: report,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPeerInfoSheet(MeshDevice peer, LatLng peerPos, ThemeProvider theme) {
    final telemetry = context.read<TelemetryProvider>();
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 20.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: peerPos.latitude,
      lng2: peerPos.longitude,
      accuracy2: 15.0,
      timestamp2: peer.lastSeen.millisecondsSinceEpoch,
    );

    final distanceStr = geoResult.summaryLabel;
    final bearingStr = geoResult.bearingDegrees != null
        ? ' • ${geoResult.compassDirection} (${geoResult.bearingDegrees!.round()}°)'
        : '';
    final roleStr = peer.isGateway
        ? 'Relief Gateway (Internet Connected)'
        : (peer.hopCount == 1 ? 'Direct Mesh Peer (1 Hop)' : 'Relay Mesh Node (${peer.hopCount} Hops)');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
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
                    color: AppTokens.beaconTeal.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sensors_rounded, color: AppTokens.beaconTeal, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              peer.displayName,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: const Text(
                              'CONNECTED',
                              style: TextStyle(
                                color: AppTokens.beaconTeal,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: $distanceStr$bearingStr',
                        style: const TextStyle(
                          color: AppTokens.beaconTeal,
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
                      Text('Device ID:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        peer.deviceId,
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Signal RSSI:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        '${peer.signalStrength} dBm (${peer.connectionType.name.toUpperCase()})',
                        style: TextStyle(color: theme.text, fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mesh Role:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        roleStr,
                        style: const TextStyle(
                          color: AppTokens.beaconTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Battery Level:', style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
                      Text(
                        '${peer.batteryLevel}%',
                        style: TextStyle(
                          color: peer.batteryLevel <= 20 ? AppTokens.sosRed : theme.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                      label: const Text('Focus', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _animatedMapMove(peerPos, 16.5);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.beaconTeal,
                        foregroundColor: AppTokens.nightNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Direction', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startNavigation(peerPos, targetName: peer.displayName);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShelterSheet(ShelterResource shelter, ThemeProvider theme) {
    final telemetry = context.read<TelemetryProvider>();
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;
    final userAcc = localFix?.horizontalAccuracyMeters ?? 20.0;
    final userTs = localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: userAcc,
      timestamp1: userTs,
      lat2: shelter.latitude,
      lng2: shelter.longitude,
      accuracy2: 25.0,
      timestamp2: DateTime.now().millisecondsSinceEpoch,
    );

    final distanceStr = geoResult.summaryLabel;
    final bearingStr = geoResult.bearingDegrees != null
        ? ' • ${geoResult.compassDirection} (${geoResult.bearingDegrees!.round()}°)'
        : '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
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
                  child: const Icon(Icons.home_work_rounded,
                      color: AppTokens.signalYellow, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: $distanceStr$bearingStr',
                        style: const TextStyle(
                          color: AppTokens.beaconTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
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
                      Text('Capacity:', style: TextStyle(color: theme.textMuted)),
                      Text(
                        '${shelter.capacity}/${shelter.maxCapacity} people',
                        style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (shelter.supplies.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Supplies:', style: TextStyle(color: theme.textMuted)),
                        Text(
                          shelter.supplies.join(', '),
                          style: const TextStyle(
                            color: AppTokens.beaconTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: AppTokens.buttonPrimary,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text(
                  'Focus on Map',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (shelter.latitude != null && shelter.longitude != null) {
                    _animatedMapMove(LatLng(shelter.latitude!, shelter.longitude!), 16.0);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    if (_isMeasuring) {
      setState(() {
        _measuredPin = point;
      });

      final telemetry = context.read<TelemetryProvider>();
      final localFix = LocationService.instance.currentFix;
      final userLat = telemetry.latitude ?? localFix?.latitude;
      final userLng = telemetry.longitude ?? localFix?.longitude;
      final userAcc = localFix?.horizontalAccuracyMeters ?? 20.0;
      final userTs = localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch;

      final geoResult = HaversineDistance.calculateDistanceNullable(
        lat1: userLat,
        lng1: userLng,
        accuracy1: userAcc,
        timestamp1: userTs,
        lat2: point.latitude,
        lng2: point.longitude,
        accuracy2: 5.0,
        timestamp2: DateTime.now().millisecondsSinceEpoch,
      );

      final distStr = geoResult.bearingDegrees != null
          ? 'Distance: ${geoResult.summaryLabel} • Heading: ${geoResult.compassDirection} (${geoResult.bearingDegrees!.round()}°)'
          : 'Distance: ${geoResult.summaryLabel}';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${point.latitude.toStringAsFixed(4)}° N, ${point.longitude.toStringAsFixed(4)}° E\n$distStr',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppTokens.beaconTeal,
          action: SnackBarAction(
            label: 'Clear Pin',
            textColor: Colors.white,
            onPressed: () => setState(() => _measuredPin = null),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mesh = context.watch<MeshProvider>();
    final telemetry = context.watch<TelemetryProvider>();
    final emergencyProvider = context.watch<EmergencyReportProvider>();

    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;

    // Combine provider reports with database reports & active alerts from SosAlertService
    final reportsById = <String, EmergencyReport>{
      for (final report in emergencyProvider.reports) report.id: report,
      for (final report in _emergencyReports) report.id: report,
    };

    final currentAlert = SosAlertService.instance.currentAlert;
    if (currentAlert != null && currentAlert.lat != null && currentAlert.lng != null) {
      reportsById[currentAlert.messageId] = EmergencyReport.create(
        id: currentAlert.messageId,
        category: currentAlert.category,
        description: currentAlert.medicalNotes ?? 'SOS Distress Beacon Active',
        peopleCount: currentAlert.casualties,
        latitude: currentAlert.lat,
        longitude: currentAlert.lng,
        location: '${currentAlert.lat}, ${currentAlert.lng}',
        status: 'ACTIVE_DISTRESS',
        timestamp: currentAlert.timestamp,
        syncPending: true,
        severity: currentAlert.urgency,
      );
    }
    for (final hist in SosAlertService.instance.alertHistory) {
      if (hist.lat != null && hist.lng != null && !reportsById.containsKey(hist.messageId)) {
        reportsById[hist.messageId] = EmergencyReport.create(
          id: hist.messageId,
          category: hist.category,
          description: hist.medicalNotes ?? 'Distress Incident',
          peopleCount: hist.casualties,
          latitude: hist.lat,
          longitude: hist.lng,
          location: '${hist.lat}, ${hist.lng}',
          status: 'LOGGED',
          timestamp: hist.timestamp,
          severity: hist.urgency,
        );
      }
    }
    final activeReports = reportsById.values.toList();

    // Map all connected mesh peers from nearby devices & physical peers
    final Map<String, MeshDevice> peerMap = {};
    for (final p in mesh.nearbyDevices) {
      peerMap[p.deviceId] = p;
    }
    for (final p in mesh.physicalPeers) {
      peerMap[p.deviceId] = p;
    }
    final allConnectedPeers = peerMap.values.toList();

    // Determine initial center
    final LatLng centerPoint = widget.initialCenter ??
        (userLat != null && userLng != null
            ? LatLng(userLat, userLng)
            : (activeReports.isNotEmpty && activeReports.first.latitude != null
                ? LatLng(activeReports.first.latitude!, activeReports.first.longitude!)
                : const LatLng(20.5937, 78.9629)));

    // Build markers
    final markers = <Marker>[];

    // 1. You Marker
    if (_activeFilters.contains('All') || _activeFilters.contains('You')) {
      if (userLat != null && userLng != null) {
        markers.add(
          Marker(
            point: LatLng(userLat, userLng),
            width: 56,
            height: 56,
            child: _buildYouMarker(theme),
          ),
        );
      }
    }

    // 2. SOS Distress Markers
    if (_activeFilters.contains('All') || _activeFilters.contains('SOS')) {
      for (final rep in activeReports) {
        if (rep.latitude != null && rep.longitude != null) {
          markers.add(
            Marker(
              point: LatLng(rep.latitude!, rep.longitude!),
              width: 60,
              height: 60,
              child: _buildSosMarker(rep, theme),
            ),
          );
        }
      }
    }

    // 3. Nearby Connected Mesh Peers Markers (Green/teal beacons with battery % and hop count)
    if (_activeFilters.contains('All') || _activeFilters.contains('Nearby')) {
      for (int i = 0; i < allConnectedPeers.length; i++) {
        final peer = allConnectedPeers[i];
        final peerPos = _getPeerCoordinate(peer, i, allConnectedPeers.length, centerPoint);
        markers.add(
          Marker(
            point: peerPos,
            width: 82,
            height: 62,
            child: _buildPeerMarker(peer, peerPos, theme),
          ),
        );
      }
    }

    // 4. Shelters Markers
    if (_activeFilters.contains('All') || _activeFilters.contains('Shelters')) {
      for (final s in _shelterResources) {
        if (s.latitude != null && s.longitude != null) {
          markers.add(
            Marker(
              point: LatLng(s.latitude!, s.longitude!),
              width: 48,
              height: 48,
              child: _buildShelterMarker(s, theme),
            ),
          );
        }
      }
    }

    // 5. Measured Pin Marker
    if (_measuredPin != null) {
      markers.add(
        Marker(
          point: _measuredPin!,
          width: 44,
          height: 44,
          child: const Icon(Icons.push_pin_rounded, color: AppTokens.signalYellow, size: 38),
        ),
      );
    }

    // Build Circles (Accuracy + Hazard buffers)
    final circles = <CircleMarker>[];
    if (_showAccuracyCircle && userLat != null && userLng != null) {
      circles.add(
        CircleMarker(
          point: LatLng(userLat, userLng),
          radius: 28,
          useRadiusInMeter: false,
          color: AppTokens.beaconTeal.withValues(alpha: 0.15),
          borderColor: AppTokens.beaconTeal,
          borderStrokeWidth: 1.5,
        ),
      );
    }

    if (_showHazards && (_activeFilters.contains('All') || _activeFilters.contains('Hazards'))) {
      for (final rep in activeReports) {
        if (rep.latitude != null && rep.longitude != null) {
          final isFlood = rep.category.toLowerCase().contains('flood') || rep.notes.toLowerCase().contains('flood');
          circles.add(
            CircleMarker(
              point: LatLng(rep.latitude!, rep.longitude!),
              radius: 120, // 120 meters hazard radius
              useRadiusInMeter: true,
              color: isFlood
                  ? const Color(0xFF20D9F5).withValues(alpha: 0.22)
                  : AppTokens.sosRed.withValues(alpha: 0.18),
              borderColor: isFlood ? const Color(0xFF20D9F5) : AppTokens.sosRed,
              borderStrokeWidth: 1.5,
            ),
          );
        }
      }
    }

    // Build Polylines (Glowing guide line between user and active SOS navigation target)
    final polylines = <Polyline>[];
    if (_activeNavTarget != null && userLat != null && userLng != null) {
      polylines.add(
        Polyline(
          points: [LatLng(userLat, userLng), _activeNavTarget!],
          strokeWidth: 8.0,
          color: AppTokens.sosRed.withValues(alpha: 0.35),
        ),
      );
      polylines.add(
        Polyline(
          points: [LatLng(userLat, userLng), _activeNavTarget!],
          strokeWidth: 3.5,
          color: AppTokens.signalYellow,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. FlutterMap Component with Offline Disk Tile Provider
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerPoint,
                  initialZoom: (telemetry.hasGpsFix || localFix != null) ? 15.0 : 6.0,
                  minZoom: 3.0,
                  maxZoom: 18.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    _currentZoom = camera.zoom;
                    _currentCenter = camera.center;
                    _currentRotation = camera.rotation;
                    _updateCoverageStatus();
                  },
                  onTap: _onMapTapped,
                ),
                children: [
                  // Base Tile Layer with Disk Caching, Dark Inversion, & Tactical Grid Fallback
                  TileLayer(
                    urlTemplate: OfflineMapService.freeOsmUrl,
                    tileProvider: OfflineFallbackTileProvider(
                      isDark: theme.isDarkMode,
                      forceOfflineGrid: _forceTacticalGrid,
                    ),
                    tileBuilder: theme.isDarkMode ? darkModeTileBuilder : null,
                    userAgentPackageName: 'org.rakshanet.rakshanet_mobile',
                    maxZoom: 19,
                  ),

                  // Coverage Boundary Polygon Overlay (Spec Sections 2 & 3)
                  PolygonLayer(polygons: _buildRegionPolygons(theme)),

                  // Hazard / Accuracy Buffer Circles
                  CircleLayer(circles: circles),

                  // Polyline Layer (Glowing guide line when navigating)
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),

                  // Pins / Markers
                  MarkerLayer(markers: markers),
                ],
              ),
            ),

            // 2. Top Header Bar
            _buildTopHeader(theme, telemetry, mesh),

            // 3. Top Navigation HUD Bar (Active navigation guidance)
            if (_activeNavTarget != null)
              Positioned(
                top: 72,
                left: 14,
                right: 14,
                child: _buildNavigationHud(theme, telemetry),
              ),

            // 4. Coverage Banner (Cached vs Uncovered status)
            Positioned(
              top: _activeNavTarget != null ? 150 : 72,
              left: 14,
              right: 14,
              child: Center(
                child: _buildCoverageBanner(theme),
              ),
            ),

            // 5. Floating Tactical Map Controls (Right Side)
            _buildFloatingControls(theme),

            // 6. Dynamic Map Scale Bar (Bottom Left)
            Positioned(
              left: 14,
              bottom: activeReports.isNotEmpty ? 220 : 134,
              child: _buildScaleBar(theme),
            ),

            // 7. Bottom Section: Filter Chips & Active Incident Card
            _buildBottomTray(theme, activeReports),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    ThemeProvider theme,
    TelemetryProvider telemetry,
    MeshProvider mesh,
  ) {
    return Positioned(
      top: 10,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (theme.isLightMode
                  ? AppTokens.lightSurface
                  : (theme.isLowPower ? AppTokens.oledSurface : AppTokens.darkBg))
              .withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.border),
          boxShadow: theme.isLowPower
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.isLightMode ? 0.08 : 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Radar Icon
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTokens.signalYellow,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.radar_rounded, color: AppTokens.nightNavy, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Title & GPS/Offline subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Live Offline Map',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _forceTacticalGrid
                              ? AppTokens.darkWarning.withValues(alpha: 0.2)
                              : AppTokens.beaconTeal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          _forceTacticalGrid ? 'TACTICAL' : 'FREE OSM',
                          style: TextStyle(
                            color: _forceTacticalGrid ? AppTokens.darkWarning : AppTokens.beaconTeal,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        telemetry.hasGpsFix ? Icons.location_on : Icons.location_off,
                        size: 12,
                        color: telemetry.hasGpsFix ? const Color(0xFF35D07F) : theme.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          telemetry.hasGpsFix
                              ? 'GPS Fixed • ${mesh.nearbyDevices.length} peers'
                              : 'Searching GPS • Free Maps Ready',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Offline Cache Manager button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.download_for_offline_outlined, color: AppTokens.signalYellow, size: 22),
              tooltip: 'Offline Map Cache',
              onPressed: () => _showOfflineManagerSheet(theme),
            ),
            const ThemeToggleButton(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls(ThemeProvider theme) {
    return Positioned(
      right: 14,
      top: 112,
      child: Column(
        children: [
          // Offline Manager button
          _buildMapBtn(
            icon: Icons.layers_outlined,
            tooltip: 'Offline Layers & Cache',
            onTap: () => _showOfflineManagerSheet(theme),
            theme: theme,
          ),
          const SizedBox(height: 10),
          // Compass Button (Resets bearing to North 0°)
          _buildMapBtn(
            icon: Icons.navigation_rounded,
            tooltip: 'Compass (Reset North)',
            rotationAngle: -(_currentRotation * math.pi / 180.0),
            color: (_currentRotation.abs() > 0.5) ? AppTokens.signalYellow : null,
            onTap: () {
              HapticFeedback.lightImpact();
              _mapController.rotate(0.0);
              setState(() {
                _currentRotation = 0.0;
              });
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          // My Location (Re-center)
          _buildMapBtn(
            icon: Icons.my_location_rounded,
            tooltip: 'Center on Me',
            onTap: _centerOnUser,
            theme: theme,
          ),
          const SizedBox(height: 10),
          // Measure Distance Tool
          _buildMapBtn(
            icon: Icons.straighten_rounded,
            tooltip: _isMeasuring ? 'Measuring Active (Tap Map)' : 'Measure Distance Tool',
            color: _isMeasuring ? AppTokens.signalYellow : null,
            onTap: () {
              setState(() => _isMeasuring = !_isMeasuring);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isMeasuring
                      ? 'Measurement mode active: Tap anywhere on map to drop pin and calculate distance.'
                      : 'Measurement mode off.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          // Zoom In
          _buildMapBtn(
            icon: Icons.add,
            tooltip: 'Zoom In',
            onTap: () {
              final z = _mapController.camera.zoom + 1;
              _mapController.move(_mapController.camera.center, z);
            },
            theme: theme,
          ),
          const SizedBox(height: 8),
          // Zoom Out
          _buildMapBtn(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            onTap: () {
              final z = _mapController.camera.zoom - 1;
              _mapController.move(_mapController.camera.center, z);
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTray(ThemeProvider theme, List<EmergencyReport> activeReports) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Icons.grid_view_rounded, AppTokens.beaconTeal, theme),
                const SizedBox(width: 8),
                _buildFilterChip('You', Icons.person_pin_circle_rounded, const Color(0xFF2F80ED), theme),
                const SizedBox(width: 8),
                _buildFilterChip('SOS', Icons.warning_rounded, AppTokens.sosRed, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Nearby', Icons.sensors_rounded, AppTokens.beaconTeal, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Shelters', Icons.home_rounded, AppTokens.signalYellow, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Hazards', Icons.water_rounded, const Color(0xFF20D9F5), theme),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Incident Card or All-Clear Card
          if (activeReports.isNotEmpty)
            _buildActiveReportCard(activeReports.first, theme)
          else
            _buildCalmCard(theme),
        ],
      ),
    );
  }

  Widget _buildActiveReportCard(EmergencyReport report, ThemeProvider theme) {
    final telemetry = context.read<TelemetryProvider>();
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;
    final userAcc = localFix?.horizontalAccuracyMeters ?? 20.0;
    final userTs = localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: userAcc,
      timestamp1: userTs,
      lat2: report.latitude,
      lng2: report.longitude,
      accuracy2: 15.0,
      timestamp2: report.timestamp.millisecondsSinceEpoch,
    );
    final distStr = geoResult.summaryLabel;
    final bearingStr = geoResult.bearingDegrees != null
        ? ' • ${geoResult.compassDirection} (${geoResult.bearingDegrees!.round()}°)'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.sosRed.withValues(alpha: 0.8), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isLightMode ? 0.08 : 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTokens.sosRed.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTokens.sosRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${report.peopleCount} ${report.peopleCount == 1 ? 'person' : 'people'} in distress • ${report.category}',
                      style: TextStyle(color: theme.text, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$distStr$bearingStr away',
                      style: const TextStyle(color: AppTokens.sosRed, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showIncidentSheet(report, theme),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Direction', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (report.latitude != null && report.longitude != null) {
                      _startNavigation(
                        LatLng(report.latitude!, report.longitude!),
                        targetName: 'SOS: ${report.category}',
                        report: report,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalmCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.beaconTeal.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isLightMode ? 0.06 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTokens.beaconTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: AppTokens.beaconTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Active Distress Alerts Nearby',
                  style: TextStyle(color: theme.text, fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'All clear in local offline mesh range',
                  style: TextStyle(color: AppTokens.beaconTeal, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded,
              color: AppTokens.beaconTeal.withValues(alpha: 0.7), size: 20),
        ],
      ),
    );
  }

  Widget _buildYouMarker(ThemeProvider theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52 * (0.6 + _pulseController.value * 0.4),
              height: 52 * (0.6 + _pulseController.value * 0.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.beaconTeal.withValues(alpha: 1 - _pulseController.value * 0.8),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.beaconTeal,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.person_pin, color: Colors.white, size: 20),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSosMarker(EmergencyReport report, ThemeProvider theme) {
    return GestureDetector(
      onTap: () => _showIncidentSheet(report, theme),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final v = _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ring 1: outer wave
              Container(
                width: 60 * (0.5 + 0.5 * v),
                height: 60 * (0.5 + 0.5 * v),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.sosRed.withValues(alpha: 0.22 * (1 - v)),
                ),
              ),
              // Ring 2: middle wave
              Container(
                width: 46 * (0.6 + 0.4 * v),
                height: 46 * (0.6 + 0.4 * v),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.sosRed.withValues(alpha: 0.45 * (1 - v)),
                ),
              ),
              // Ring 3: inner core halo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.sosRed.withValues(alpha: 0.75),
                  boxShadow: [
                    BoxShadow(
                      color: AppTokens.sosRed.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Center SOS Badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.sosRed,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    report.peopleCount > 1 ? '${report.peopleCount}' : 'SOS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeerMarker(MeshDevice peer, LatLng peerPos, ThemeProvider theme) {
    final isLowBattery = peer.batteryLevel <= 20;
    final batteryColor = peer.batteryLevel > 50
        ? AppTokens.beaconTeal
        : (isLowBattery ? AppTokens.sosRed : AppTokens.signalYellow);

    return GestureDetector(
      onTap: () => _showPeerInfoSheet(peer, peerPos, theme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: (theme.isLightMode ? AppTokens.lightSurface : AppTokens.darkBg)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: AppTokens.beaconTeal, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    peer.displayName.length > 8
                        ? '${peer.displayName.substring(0, 8)}…'
                        : peer.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  isLowBattery ? Icons.battery_alert_rounded : Icons.battery_charging_full_rounded,
                  size: 9,
                  color: batteryColor,
                ),
                Text(
                  '${peer.batteryLevel}%',
                  style: TextStyle(
                    color: batteryColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: AppTokens.beaconTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${peer.hopCount}h',
                    style: const TextStyle(
                      color: AppTokens.beaconTeal,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28 * (0.8 + 0.2 * _pulseController.value),
                    height: 28 * (0.8 + 0.2 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTokens.beaconTeal
                          .withValues(alpha: 0.35 * (1 - _pulseController.value)),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTokens.beaconTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.sensors_rounded, color: Colors.white, size: 11),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHud(ThemeProvider theme, TelemetryProvider telemetry) {
    if (_activeNavTarget == null) return const SizedBox.shrink();

    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry.latitude ?? localFix?.latitude;
    final userLng = telemetry.longitude ?? localFix?.longitude;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 20.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: _activeNavTarget!.latitude,
      lng2: _activeNavTarget!.longitude,
      accuracy2: 15.0,
      timestamp2: DateTime.now().millisecondsSinceEpoch,
    );

    final bearing = geoResult.bearingDegrees ?? 0.0;
    final dir = geoResult.compassDirection;
    final dist = geoResult.summaryLabel;
    final bearingRad = bearing * math.pi / 180.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (theme.isLightMode ? AppTokens.lightSurface : const Color(0xFF140707))
            .withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.sosRed, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppTokens.sosRed.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTokens.sosRed.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppTokens.sosRed, width: 1.2),
            ),
            child: Center(
              child: Transform.rotate(
                angle: bearingRad,
                child: const Icon(Icons.navigation_rounded, color: AppTokens.sosRed, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Head $dir (${bearing.round()}°) • $dist',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: ${_activeNavTargetName ?? 'SOS Distress Target'}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.sosRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.surfaceSunken,
              foregroundColor: theme.text,
              elevation: 0,
              side: BorderSide(color: theme.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _clearNavigation,
          ),
        ],
      ),
    );
  }

  Widget _buildShelterMarker(ShelterResource shelter, ThemeProvider theme) {
    return GestureDetector(
      onTap: () => _showShelterSheet(shelter, theme),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTokens.signalYellow,
          border: Border.all(color: AppTokens.nightNavy, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
          ],
        ),
        child: const Icon(Icons.home_rounded, color: AppTokens.nightNavy, size: 20),
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    double? rotationAngle,
    required ThemeProvider theme,
  }) {
    Widget iconWidget = Icon(icon, color: color ?? theme.text, size: 21);
    if (rotationAngle != null) {
      iconWidget = Transform.rotate(
        angle: rotationAngle,
        child: iconWidget,
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isLightMode ? 0.08 : 0.35),
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
            child: Center(child: iconWidget),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? theme.surface : theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: isSelected ? color : theme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSelected ? color : theme.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.text : theme.textMuted,
                  fontSize: 12.5,
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
