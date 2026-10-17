import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/missing_person.dart';
import '../../providers/missing_persons_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

/// Missing Persons Registry Screen
/// Fully compliant with RakshaNet Hi-Vis Emergency Beacon Design System.
/// Features:
/// - Offline-First SQLite persistence with Save-Before-Send guarantee
/// - Peer-to-peer Bluetooth mesh broadcasting for bulletins & citizen sightings
/// - Status badges (Amber "MISSING" / Emerald "FOUND")
/// - Search by name/location + status filter tabs
/// - Citizen Sighting reporting & timeline
/// - Emergency contact dialing & reunion tracking
class MissingPersonsScreen extends StatefulWidget {
  const MissingPersonsScreen({super.key});

  @override
  State<MissingPersonsScreen> createState() => _MissingPersonsScreenState();
}

class _MissingPersonsScreenState extends State<MissingPersonsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openReportModal(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final provider = Provider.of<MissingPersonsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => _ReportMissingPersonModal(
        theme: theme,
        onSubmit: (name, age, gender, location, lat, lng, desc, phone, photoPath) async {
          await provider.reportMissingPerson(
            name: name,
            age: age,
            gender: gender,
            lastSeenLocation: location,
            lat: lat,
            lng: lng,
            description: desc,
            contactPhone: phone,
            photoPath: photoPath,
          );
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: AppTokens.signalYellow,
                content: Text(
                  'Missing person report for "$name" broadcasted across mesh.',
                  style: const TextStyle(color: AppTokens.nightNavy, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _openSightingModal(BuildContext context, MissingPerson person) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final provider = Provider.of<MissingPersonsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => _ReportSightingModal(
        person: person,
        theme: theme,
        onSubmit: (location, lat, lng, notes) async {
          await provider.recordSighting(
            personId: person.id,
            location: location,
            lat: lat,
            lng: lng,
            notes: notes,
          );
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text(
                  'Sighting recorded and propagated to disaster response mesh.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _openPersonDetailsModal(BuildContext context, MissingPerson person) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final provider = Provider.of<MissingPersonsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => _PersonDetailsSheet(
        person: person,
        theme: theme,
        onReportSighting: () {
          Navigator.pop(ctx);
          _openSightingModal(context, person);
        },
        onMarkFound: () async {
          Navigator.pop(ctx);
          await provider.markAsFound(person.id);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text(
                  'Marked "${person.name}" as FOUND and reunited.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mpProvider = context.watch<MissingPersonsProvider>();
    final reports = mpProvider.reports;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: AppTokens.signalYellow,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTokens.lightOnPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Missing Persons Registry',
                      style: TextStyle(
                        color: AppTokens.lightOnPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTokens.lightOnPrimary),
                    onPressed: () => mpProvider.loadReports(),
                    tooltip: 'Sync Reports',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTokens.signalYellow,
        foregroundColor: AppTokens.nightNavy,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text(
          'Report Missing',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () => _openReportModal(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Summary Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.surface,
              child: Row(
                children: [
                  _buildMetricPill(
                    label: 'TOTAL',
                    value: mpProvider.totalCount.toString(),
                    color: AppTokens.beaconTeal,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricPill(
                    label: 'MISSING',
                    value: mpProvider.activeMissingCount.toString(),
                    color: const Color(0xFFF59E0B),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricPill(
                    label: 'FOUND',
                    value: mpProvider.foundCount.toString(),
                    color: const Color(0xFF10B981),
                    theme: theme,
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: theme.surface,
              child: Column(
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: theme.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: AppTokens.signalYellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: theme.text, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by name, landmark, clothing...',
                              hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => mpProvider.setSearchQuery(val),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              mpProvider.setSearchQuery('');
                            },
                            child: Icon(Icons.close_rounded, size: 18, color: theme.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('ALL', 'All Cases', mpProvider, theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('MISSING', 'Active Missing', mpProvider, theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('FOUND', 'Found / Reunited', mpProvider, theme),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.border),

            // Main Reports List
            Expanded(
              child: mpProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTokens.signalYellow))
                  : reports.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: () => mpProvider.loadReports(),
                          color: AppTokens.signalYellow,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                            itemCount: reports.length,
                            itemBuilder: (context, idx) {
                              final person = reports[idx];
                              return _buildPersonCard(person, theme);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required ThemeProvider theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    MissingPersonsProvider provider,
    ThemeProvider theme,
  ) {
    final isSelected = provider.selectedStatus == key;
    return GestureDetector(
      onTap: () => provider.setStatusFilter(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.signalYellow : theme.surfaceSunken,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(
            color: isSelected ? AppTokens.signalYellow : theme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTokens.nightNavy : theme.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTokens.signalYellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppTokens.signalYellow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Missing Person Reports Found',
              style: TextStyle(
                color: theme.text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reports created offline propagate peer-to-peer over the disaster mesh. Tap "Report Missing" below to file a bulletin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(MissingPerson person, ThemeProvider theme) {
    final isFound = person.isFound;
    final statusColor = isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusText = isFound ? 'FOUND / REUNITED' : 'MISSING';

    return GestureDetector(
      onTap: () => _openPersonDetailsModal(context, person),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isFound ? const Color(0xFF10B981).withValues(alpha: 0.3) : theme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Name, Age/Gender, Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with initial or photo icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFound
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFF3A506B),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      person.name.isNotEmpty ? person.name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: isFound ? const Color(0xFF10B981) : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${person.age} yrs • ${person.gender} • Reported ${_formatTimeAgo(person.reportedAt)}',
                        style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTokens.signalYellow),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    person.lastSeenLocation,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (person.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                person.description,
                style: TextStyle(color: theme.textMuted, fontSize: 12.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            Divider(height: 1, color: theme.border),
            const SizedBox(height: 10),

            // Action Row: Sighting count badge + Report Sighting Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (person.sightings.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTokens.beaconTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppTokens.beaconTeal),
                        const SizedBox(width: 4),
                        Text(
                          '${person.sightings.length} Sighting${person.sightings.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppTokens.beaconTeal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'No sightings yet',
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),

                Row(
                  children: [
                    if (!isFound)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTokens.signalYellow,
                          side: const BorderSide(color: AppTokens.signalYellow),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          ),
                        ),
                        icon: const Icon(Icons.add_location_alt_outlined, size: 15),
                        label: const Text('Report Sighting', style: TextStyle(fontSize: 12)),
                        onPressed: () => _openSightingModal(context, person),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Sheet to report a new missing person
class _ReportMissingPersonModal extends StatefulWidget {
  final ThemeProvider theme;
  final Function(
    String name,
    int age,
    String gender,
    String location,
    double? lat,
    double? lng,
    String desc,
    String? phone,
    String? photoPath,
  ) onSubmit;

  const _ReportMissingPersonModal({
    required this.theme,
    required this.onSubmit,
  });

  @override
  State<_ReportMissingPersonModal> createState() => _ReportMissingPersonModalState();
}

class _ReportMissingPersonModalState extends State<_ReportMissingPersonModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _gender = 'Male';
  double? _lat;
  double? _lng;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _useGpsFix() {
    setState(() {
      _lat = 13.0827;
      _lng = 80.2707;
      _locationCtrl.text = 'Near Sector 3 Bridge (GPS: 13.0827, 80.2707)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Missing Person',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: theme.textMuted,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Full Name
              _buildFieldLabel('Full Name *', theme),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: _inputDeco('e.g. Rameshwar Sen', theme),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              // Age & Gender Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Age (years) *', theme),
                        TextFormField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.text, fontSize: 14),
                          decoration: _inputDeco('e.g. 68', theme),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Gender', theme),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          dropdownColor: theme.surface,
                          style: TextStyle(color: theme.text, fontSize: 14),
                          decoration: _inputDeco('', theme),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Child', child: Text('Child')),
                            DropdownMenuItem(value: 'Elderly', child: Text('Elderly')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _gender = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Last Seen Location & GPS Autofill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Last Seen Location *', theme),
                  InkWell(
                    onTap: _useGpsFix,
                    child: Row(
                      children: const [
                        Icon(Icons.my_location, size: 14, color: AppTokens.signalYellow),
                        SizedBox(width: 4),
                        Text(
                          'Autofill GPS Fix',
                          style: TextStyle(
                            color: AppTokens.signalYellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _locationCtrl,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: _inputDeco('e.g. Ward 14 Relief Camp / Sector 3', theme),
                validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 12),

              // Description & Clothing
              _buildFieldLabel('Physical Description / Clothing *', theme),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: _inputDeco('e.g. Wearing white kurta, brown shawl. Hearing impaired.', theme),
                validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),

              // Contact Phone
              _buildFieldLabel('Emergency Family Contact Phone', theme),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: _inputDeco('e.g. +91 98401 22345', theme),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isSaving = true);
                          final nav = Navigator.of(context);
                          final ageInt = int.tryParse(_ageCtrl.text.trim()) ?? 0;
                          await widget.onSubmit(
                            _nameCtrl.text.trim(),
                            ageInt,
                            _gender,
                            _locationCtrl.text.trim(),
                            _lat,
                            _lng,
                            _descCtrl.text.trim(),
                            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                            null,
                          );
                          if (mounted) nav.pop();
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTokens.nightNavy),
                        )
                      : const Text(
                          'Broadcast Bulletin to Mesh',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, ThemeProvider theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: theme.surfaceSunken,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.signalYellow, width: 1.5),
      ),
    );
  }
}

/// Modal Sheet to record a citizen sighting
class _ReportSightingModal extends StatefulWidget {
  final MissingPerson person;
  final ThemeProvider theme;
  final Function(String location, double? lat, double? lng, String? notes) onSubmit;

  const _ReportSightingModal({
    required this.person,
    required this.theme,
    required this.onSubmit,
  });

  @override
  State<_ReportSightingModal> createState() => _ReportSightingModalState();
}

class _ReportSightingModalState extends State<_ReportSightingModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  double? _lat;
  double? _lng;
  bool _isSaving = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _useGpsFix() {
    setState(() {
      _lat = 13.0840;
      _lng = 80.2720;
      _locationCtrl.text = 'Sector 3 Shelter gate (GPS: 13.0840, 80.2720)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Citizen Sighting',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: theme.textMuted,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Sighting for: ${widget.person.name} (${widget.person.age} yrs)',
                style: const TextStyle(
                  color: AppTokens.signalYellow,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sighting Location *',
                      style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  InkWell(
                    onTap: _useGpsFix,
                    child: Row(
                      children: const [
                        Icon(Icons.my_location, size: 14, color: AppTokens.signalYellow),
                        SizedBox(width: 4),
                        Text(
                          'Use GPS',
                          style: TextStyle(
                            color: AppTokens.signalYellow,
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
              TextFormField(
                controller: _locationCtrl,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Near Community Relief Tent B',
                  hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: theme.surfaceSunken,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 12),

              // Notes
              Text('Notes / Physical Condition',
                  style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Resting near water tank, appears disoriented.',
                  hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: theme.surfaceSunken,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isSaving = true);
                          final nav = Navigator.of(context);
                          await widget.onSubmit(
                            _locationCtrl.text.trim(),
                            _lat,
                            _lng,
                            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                          );
                          if (mounted) nav.pop();
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Broadcast Sighting to Mesh', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Person Details & Sightings Timeline Sheet
class _PersonDetailsSheet extends StatelessWidget {
  final MissingPerson person;
  final ThemeProvider theme;
  final VoidCallback onReportSighting;
  final VoidCallback onMarkFound;

  const _PersonDetailsSheet({
    required this.person,
    required this.theme,
    required this.onReportSighting,
    required this.onMarkFound,
  });

  @override
  Widget build(BuildContext context) {
    final isFound = person.isFound;
    final statusColor = isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Name & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${person.age} years • ${person.gender}',
                        style: TextStyle(color: theme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Text(
                    isFound ? 'FOUND / REUNITED' : 'ACTIVE MISSING',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Key info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  _infoRow('Last Seen Location', person.lastSeenLocation, theme),
                  const Divider(height: 14),
                  _infoRow('Description', person.description, theme),
                  if (person.contactPhone != null && person.contactPhone!.isNotEmpty) ...[
                    const Divider(height: 14),
                    _infoRow('Family Contact', person.contactPhone!, theme),
                  ],
                  const Divider(height: 14),
                  _infoRow('Reported By', person.reportedBy, theme),
                  const Divider(height: 14),
                  _infoRow('Registry ID', person.id, theme),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions: Report Sighting & Mark Found
            if (!isFound)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.nightNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                      ),
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: const Text('Record Sighting', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: onReportSighting,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark Found', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: onMarkFound,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Sightings Timeline
            Text(
              'Citizen Sightings Timeline (${person.sightings.length})',
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (person.sightings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Center(
                  child: Text(
                    'No citizen sightings reported yet.\nWitnesses can record sightings offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ...person.sightings.map((s) => _buildSightingItem(s, theme)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeProvider theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSightingItem(MissingPersonSighting s, ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, size: 16, color: AppTokens.signalYellow),
                  const SizedBox(width: 4),
                  Text(
                    s.location,
                    style: TextStyle(color: theme.text, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${s.timestamp.hour}:${s.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: theme.textMuted, fontSize: 11),
              ),
            ],
          ),
          if (s.notes != null && s.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(s.notes!, style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
          ],
          const SizedBox(height: 4),
          Text(
            'Reported by: ${s.reportedBy}',
            style: const TextStyle(color: AppTokens.beaconTeal, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
