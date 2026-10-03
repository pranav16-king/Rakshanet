import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/repositories/missing_person_repository.dart';
import '../../models/missing_person.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

/// Screen 8: Report Missing Person
/// Features:
/// - Screen 8 Form: Name, Age, Clothing/Description, Last Seen Location & Time, Photo attachments, 56dp Submit button
/// - Writes new reports to SQLite via MissingPersonRepository (Save-Before-Send guarantee)
/// - Dynamically loads and displays existing submitted reports from SQLite
class MissingPersonScreen extends StatefulWidget {
  const MissingPersonScreen({super.key});

  @override
  State<MissingPersonScreen> createState() => _MissingPersonScreenState();
}

class _MissingPersonScreenState extends State<MissingPersonScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final MissingPersonRepository _repository = MissingPersonRepository();
  late final TabController _tabController;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<_PhotoThumb> _photos = [
    _PhotoThumb(id: '1', title: 'Portrait', color: const Color(0xFF3A506B), icon: Icons.face_rounded),
    _PhotoThumb(id: '2', title: 'Backpack', color: const Color(0xFF1C2541), icon: Icons.backpack_rounded),
    _PhotoThumb(id: '3', title: 'Full View', color: const Color(0xFF5BC0BE), icon: Icons.person_rounded),
  ];

  bool _isSubmitting = false;
  List<MissingPerson> _submittedReports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubmittedReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmittedReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final records = await _repository.getMissingPersons();
      if (mounted) {
        setState(() {
          _submittedReports = records;
          _isLoadingReports = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
  }

  void _pickTime() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 30),
      builder: (context, child) {
        return Theme(
          data: theme.themeData,
          child: child!,
        );
      },
    );

    if (picked != null) {
      final periodStr = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _timeController.text =
            'Today, ${picked.hourOfPeriod}:${picked.minute.toString().padLeft(2, '0')} $periodStr';
      });
    }
  }

  void _addLocation() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Last Seen Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: AppTokens.beaconTeal),
              ),
              title: Text('Use Current GPS Fix',
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
              subtitle: Text('19.0760° N, 72.8777° E (Accuracy: ±4 m)',
                  style: TextStyle(color: theme.textMuted)),
              onTap: () {
                setState(() {
                  _locationController.text = 'Near River Bridge (GPS: 19.0760, 72.8777)';
                });
                Navigator.pop(ctx);
              },
            ),
            Divider(color: theme.border),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.signalYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_city, color: AppTokens.signalYellow),
              ),
              title: Text('Nearby Landmark: River Bridge Checkpoint',
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
              subtitle: Text('0.3 km from your current location',
                  style: TextStyle(color: theme.textMuted)),
              onTap: () {
                setState(() {
                  _locationController.text = 'Near River Bridge (North Bank)';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addPhotoDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
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
          children: [
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTokens.beaconTeal),
              title: Text('Take Photo With Camera', style: TextStyle(color: theme.text)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _photos.add(
                    _PhotoThumb(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: 'Camera Photo',
                      color: const Color(0xFF4A6572),
                      icon: Icons.camera_alt_outlined,
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTokens.signalYellow),
              title: Text('Choose From Offline Gallery', style: TextStyle(color: theme.text)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _photos.add(
                    _PhotoThumb(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: 'Gallery Photo',
                      color: const Color(0xFF34495E),
                      icon: Icons.image_rounded,
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final ageInt =
        int.tryParse(_ageController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final reportId = 'mp_${DateTime.now().millisecondsSinceEpoch}';
    final newReport = MissingPerson(
      id: reportId,
      name: _nameController.text.trim(),
      age: ageInt,
      description: _descriptionController.text.trim(),
      lastSeenLocation: _locationController.text.trim(),
      lastSeenTime: DateTime.now(),
      photoPath: _photos.isNotEmpty ? _photos.first.title : null,
      status: 'SEARCHING',
    );

    // Save-Before-Send guarantee: persist to SQLite via MissingPersonRepository
    await _repository.saveReport(newReport);
    await _loadSubmittedReports();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4CD08A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CD08A), size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Missing Person Report Saved to SQLite',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Report for "${newReport.name}" committed to offline database.\nBroadcasting to nearby peer devices over BLE mesh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Report ID', reportId, theme),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Search Status', 'SEARCHING', theme),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Database State', 'Committed to SQLite (Save-Before-Send)', theme),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Attached Photos', '${_photos.length} thumbnail(s)', theme),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: AppTokens.buttonPrimary,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(1); // Switch to Active Reports tab
                },
                child: const Text(
                  'View Saved Reports',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeProvider theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: theme.textMuted, fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bg = theme.bg;
    final surface = theme.surface;
    final text = theme.text;
    final border = theme.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Hi-Vis Yellow Header Bar
            _buildYellowHeaderBar(),

            // Sub Tab Bar: New Report Form vs Saved Reports
            Container(
              color: surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTokens.signalYellow,
                indicatorWeight: 3,
                labelColor: text,
                unselectedLabelColor: theme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  const Tab(text: 'New Report Form'),
                  Tab(text: 'Saved Reports (${_submittedReports.length})'),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: New Report Form
                  _buildFormTab(theme),

                  // Tab 1: Saved Reports from SQLite
                  _buildSavedReportsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonDetailsCard(theme),
            const SizedBox(height: 16),
            _buildLocationCard(theme),
            const SizedBox(height: 16),
            _buildTimeCard(theme),
            const SizedBox(height: 20),
            _buildPhotoPickerSection(theme),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: AppTokens.buttonPrimary,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.lightOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTokens.lightOnPrimary),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedReportsTab(ThemeProvider theme) {
    if (_isLoadingReports) {
      return const Center(
        child: CircularProgressIndicator(color: AppTokens.signalYellow),
      );
    }

    if (_submittedReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_rounded, size: 56, color: theme.textMuted),
              const SizedBox(height: 16),
              Text(
                'No missing person reports filed yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reports submitted through this terminal or received via mesh hops will appear here dynamically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubmittedReports,
      color: AppTokens.signalYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _submittedReports.length,
        itemBuilder: (context, index) {
          final rep = _submittedReports[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rep.name,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rep.isFound
                            ? const Color(0xFF4CD08A).withValues(alpha: 0.18)
                            : AppTokens.signalYellow.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: Text(
                        rep.status,
                        style: TextStyle(
                          color: rep.isFound
                              ? const Color(0xFF4CD08A)
                              : AppTokens.signalYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Age: ${rep.age} yrs • Last Seen: ${rep.lastSeenLocation}',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Description: ${rep.description}',
                  style: TextStyle(color: theme.text, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report ID: ${rep.id}',
                  style: const TextStyle(
                    color: AppTokens.beaconTeal,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYellowHeaderBar() {
    return Container(
      width: double.infinity,
      height: 56,
      color: AppTokens.signalYellow,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTokens.lightOnPrimary, size: 24),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Text(
            'Report Missing Person',
            style: TextStyle(
              color: AppTokens.lightOnPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonDetailsCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Person Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Name', theme),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                      decoration: _buildInputDecoration('Full Name', theme),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Age', theme),
                    TextFormField(
                      controller: _ageController,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                      decoration: _buildInputDecoration('Age in years', theme),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Clothing / Description', theme),
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.text,
                      ),
                      decoration:
                          _buildInputDecoration('e.g. Blue jacket, black bag', theme),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Portrait Placeholder
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A506B),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 48, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Photo 1',
                      style: TextStyle(fontSize: 11, color: theme.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Seen Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              InkWell(
                onTap: _addLocation,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.add_location_alt_outlined,
                          size: 16, color: AppTokens.signalYellow),
                      SizedBox(width: 4),
                      Text(
                        'Add location',
                        style: TextStyle(
                          color: AppTokens.signalYellow,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'e.g. Near River Bridge, Station Road...',
              hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              prefixIcon: const Icon(Icons.location_on,
                  color: AppTokens.signalYellow, size: 20),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTokens.signalYellow, width: 2),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Seen Time',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickTime,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppTokens.beaconTeal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _timeController.text.isEmpty
                        ? 'Select time (tap to set)'
                        : _timeController.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _timeController.text.isEmpty
                          ? theme.textMuted
                          : theme.text,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: theme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPickerSection(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add photo (optional)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            Text(
              '${_photos.length}/4',
              style: TextStyle(fontSize: 13, color: theme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              InkWell(
                onTap: _addPhotoDialog,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: theme.border),
                  ),
                  child: Center(
                    child: Icon(Icons.camera_alt_outlined,
                        color: theme.textMuted, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ..._photos.map((photo) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: photo.color,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(photo.icon, color: Colors.white, size: 30),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => _photos.remove(photo)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, ThemeProvider theme) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        color: theme.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, ThemeProvider theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppTokens.signalYellow, width: 2),
      ),
    );
  }
}

class _PhotoThumb {
  final String id;
  final String title;
  final Color color;
  final IconData icon;

  _PhotoThumb({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
  });
}
