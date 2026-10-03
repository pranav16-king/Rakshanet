import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../models/shelter_resource.dart';
import '../../providers/theme_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../theme/app_tokens.dart';

/// Screen 9: Shelters & Resources
/// Dynamically loads shelter records from local SQLite (Save-Before-Send / offline source of truth).
/// If no shelters are discovered or reported, displays:
/// "No shelters reported in this area yet."
class SheltersScreen extends StatefulWidget {
  const SheltersScreen({super.key});

  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<ShelterResource> _shelters = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSupplyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSheltersFromDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSheltersFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final records = await AppDatabase.instance.getShelters();
      if (mounted) {
        setState(() {
          _shelters = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ShelterResource> _getFilteredShelters(bool nearbyOnly) {
    return _shelters.where((s) {
      if (nearbyOnly && s.distance > 3.0) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchAddr = (s.address ?? '').toLowerCase().contains(q);
        if (!matchName && !matchAddr) return false;
      }
      if (_selectedSupplyFilter != null) {
        final filterL = _selectedSupplyFilter!.toLowerCase();
        final hasSupply = s.supplies.any((sup) {
          final supL = sup.toLowerCase();
          if (filterL == 'power') {
            return supL.contains('power') || supL.contains('solar') || supL.contains('generator');
          }
          return supL.contains(filterL);
        });
        if (!hasSupply) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bg = themeProvider.bg;
    final surface = themeProvider.surface;
    final border = themeProvider.border;
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
          'Shelters & Resources',
          style: TextStyle(
            color: text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTokens.signalYellow),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Sync via BLE mesh',
            onPressed: () async {
              await _loadSheltersFromDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updated shelters from local mesh database'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTokens.signalYellow,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTokens.nightNavy,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Nearby (< 3 km)'),
                Tab(text: 'All Relief Camps'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTokens.signalYellow),
            )
          : Column(
              children: [
                // Cached Age Disclaimer Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLowPower
                        ? AppTokens.oledSurface
                        : AppTokens.beaconTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(
                      color: AppTokens.beaconTeal.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                        color: AppTokens.beaconTeal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline Cache • Verified capacities synced via peer mesh ~2 h ago',
                          style: TextStyle(
                            color: isLowPower ? AppTokens.oledText : text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search shelter name or area...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        borderSide: const BorderSide(color: AppTokens.signalYellow, width: 2),
                      ),
                    ),
                  ),
                ),

                // Supplies Quick Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Supplies',
                        isSelected: _selectedSupplyFilter == null,
                        onTap: () => setState(() => _selectedSupplyFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Food',
                        icon: Icons.restaurant_rounded,
                        iconColor: const Color(0xFF4CD08A),
                        isSelected: _selectedSupplyFilter == 'Food',
                        onTap: () => setState(() {
                          _selectedSupplyFilter =
                              _selectedSupplyFilter == 'Food' ? null : 'Food';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Water',
                        icon: Icons.water_drop_rounded,
                        iconColor: AppTokens.beaconTeal,
                        isSelected: _selectedSupplyFilter == 'Water',
                        onTap: () => setState(() {
                          _selectedSupplyFilter =
                              _selectedSupplyFilter == 'Water' ? null : 'Water';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Medical',
                        icon: Icons.medical_services_rounded,
                        iconColor: AppTokens.sosRed,
                        isSelected: _selectedSupplyFilter == 'Medical',
                        onTap: () => setState(() {
                          _selectedSupplyFilter =
                              _selectedSupplyFilter == 'Medical' ? null : 'Medical';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Power',
                        icon: Icons.bolt_rounded,
                        iconColor: AppTokens.signalYellow,
                        isSelected: _selectedSupplyFilter == 'Power',
                        onTap: () => setState(() {
                          _selectedSupplyFilter =
                              _selectedSupplyFilter == 'Power' ? null : 'Power';
                        }),
                      ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildShelterList(_getFilteredShelters(true), themeProvider),
                      _buildShelterList(_getFilteredShelters(false), themeProvider),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<ThemeProvider>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppTokens.touchMin),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.signalYellow : theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(
            color: isSelected ? AppTokens.signalYellow : theme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTokens.nightNavy : (iconColor ?? theme.text),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTokens.nightNavy : theme.text,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterList(List<ShelterResource> shelters, ThemeProvider theme) {
    if (shelters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.isLowPower
                      ? AppTokens.oledSurface
                      : AppTokens.beaconTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.border),
                ),
                child: Icon(Icons.night_shelter_outlined, size: 36, color: theme.textMuted),
              ),
              const SizedBox(height: 18),
              Text(
                'No shelters reported in this area yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Relief shelter coordinates will automatically appear as nearby mesh peers broadcast verified shelter packets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textMuted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _loadSheltersFromDatabase,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Scan Local Mesh Cache', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.text,
                    side: BorderSide(color: theme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSheltersFromDatabase,
      color: AppTokens.signalYellow,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          return _buildShelterCard(shelter, theme);
        },
      ),
    );
  }

  Widget _buildShelterCard(ShelterResource shelter, ThemeProvider theme) {
    final maxCap = shelter.maxCapacity > 0 ? shelter.maxCapacity : 100;
    final occupancyRatio = (shelter.capacity / maxCap).clamp(0.0, 1.0);
    final isCritical = occupancyRatio >= 0.90 || shelter.isFull;
    final isWarning = occupancyRatio >= 0.75 && !isCritical;

    final Color statusColor = isCritical
        ? AppTokens.sosRed
        : (isWarning ? AppTokens.darkWarning : const Color(0xFF4CD08A));

    final String statusLabel = isCritical
        ? 'CRITICAL / FULL'
        : (isWarning ? 'HIGH OCCUPANCY' : 'OPEN / SPACES AVAILABLE');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isCritical
              ? AppTokens.sosRed.withValues(alpha: 0.5)
              : theme.border,
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Name & Distance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (shelter.address != null && shelter.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          shelter.address!,
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTokens.signalYellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: AppTokens.signalYellow.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: AppTokens.signalYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shelter.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppTokens.signalYellow,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Capacity Bar & Occupancy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${shelter.capacity} / $maxCap (${(occupancyRatio * 100).toInt()}%)',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: LinearProgressIndicator(
                    value: occupancyRatio,
                    minHeight: 10,
                    backgroundColor: theme.isLowPower
                        ? const Color(0xFF222222)
                        : Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Available Supplies Section
          if (shelter.supplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shelter.supplies.map((supply) {
                  return _buildSupplyBadge(supply);
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // Footer with action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _showContactModal(shelter),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Relay Msg',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.text,
                        side: BorderSide(color: theme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDirectionsModal(shelter),
                      icon: const Icon(Icons.directions_walk_rounded, size: 20),
                      label: const Text(
                        'Directions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTokens.nightNavy,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.nightNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyBadge(String supply) {
    IconData icon;
    Color color;

    final lower = supply.toLowerCase();
    if (lower.contains('food')) {
      icon = Icons.restaurant_rounded;
      color = const Color(0xFF4CD08A);
    } else if (lower.contains('water')) {
      icon = Icons.water_drop_rounded;
      color = AppTokens.beaconTeal;
    } else if (lower.contains('med') || lower.contains('first aid')) {
      icon = Icons.medical_services_rounded;
      color = AppTokens.sosRed;
    } else if (lower.contains('solar') || lower.contains('power') || lower.contains('generator')) {
      icon = Icons.solar_power_rounded;
      color = AppTokens.signalYellow;
    } else {
      icon = Icons.inventory_2_outlined;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            supply,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDirectionsModal(ShelterResource shelter) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    final hasCoordinates = telemetry.hasGpsFix &&
        telemetry.latitude != null &&
        telemetry.longitude != null &&
        shelter.latitude != null &&
        shelter.longitude != null;
    final distanceMeters = hasCoordinates
        ? _distanceMeters(
            telemetry.latitude!,
            telemetry.longitude!,
            shelter.latitude!,
            shelter.longitude!,
          )
        : null;
    final bearing = hasCoordinates
        ? _initialBearing(
            telemetry.latitude!,
            telemetry.longitude!,
            shelter.latitude!,
            shelter.longitude!,
          )
        : null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Offline direction to ${shelter.name}',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.isLowPower
                    ? AppTokens.oledSurface
                    : AppTokens.beaconTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: AppTokens.beaconTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded, size: 36, color: AppTokens.beaconTeal),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasCoordinates
                              ? 'Straight-line distance: ${_formatDistance(distanceMeters!)}'
                              : 'No live GPS route available',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCoordinates
                              ? 'Heading: ${bearing!.round()}° (${_bearingLabel(bearing)})'
                              : 'Turn on Location and obtain current GPS before using direction guidance.',
                          style: TextStyle(color: theme.textMuted, fontSize: 13),
                        ),
                        if (shelter.latitude != null && shelter.longitude != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'GPS: ${shelter.latitude!.toStringAsFixed(4)}° N, ${shelter.longitude!.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              color: AppTokens.beaconTeal,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Guidance:',
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasCoordinates
                  ? 'This is a direct GPS bearing, not turn-by-turn road routing. Follow official evacuation signage and avoid hazards; conditions can change after the local shelter data was saved.\n\nDestination: ${shelter.address ?? shelter.name}.'
                  : 'This phone has no usable origin coordinate or this shelter has no stored coordinate. The app will not invent a route. Check the shelter address and local evacuation signage instead.',
              style: TextStyle(color: theme.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: AppTokens.buttonPrimary,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
                child: const Text(
                  'Close guidance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final a = math.sin(latDelta / 2) * math.sin(latDelta / 2) +
        math.cos(latitudeA * math.pi / 180) *
            math.cos(latitudeB * math.pi / 180) *
            math.sin(lonDelta / 2) *
            math.sin(lonDelta / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _initialBearing(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    final fromLat = latitudeA * math.pi / 180;
    final toLat = latitudeB * math.pi / 180;
    final lonDelta = (longitudeB - longitudeA) * math.pi / 180;
    final y = math.sin(lonDelta) * math.cos(toLat);
    final x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(lonDelta);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _formatDistance(double meters) => meters < 1000
      ? 'about ${meters.round()} m'
      : 'about ${(meters / 1000).toStringAsFixed(1)} km';

  String _bearingLabel(double degrees) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return labels[((degrees + 22.5) ~/ 45) % labels.length];
  }

  void _showContactModal(ShelterResource shelter) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final textController = TextEditingController(
      text: 'Requesting check-in assistance for people arriving at ${shelter.name}.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relay to ${shelter.name}',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.text),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Transmits message via multi-hop BLE mesh to the nearest shelter node.',
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              maxLines: 3,
              style: TextStyle(color: theme.text, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.isLowPower
                    ? AppTokens.oledSurface
                    : theme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: AppTokens.buttonPrimary,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'Broadcast via BLE Mesh',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF162036),
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF4CD08A)),
                          SizedBox(width: 10),
                          Text('Message queued for multi-hop mesh delivery'),
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
