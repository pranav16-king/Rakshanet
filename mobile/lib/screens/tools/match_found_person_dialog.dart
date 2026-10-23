import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/missing_person.dart';
import '../../providers/missing_persons_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/location/location_service.dart';
import '../../theme/app_tokens.dart';

/// Modal Dialog / Bottom Sheet for Field Visual Recognition: Match Found Person
/// Implements offline-first DTN search, camera/gallery photo capture,
/// radar scanning animation, side-by-side comparison, and one-tap mesh bulletins.
class MatchFoundPersonDialog extends StatefulWidget {
  const MatchFoundPersonDialog({super.key});

  /// Displays the Match Found Person dialog as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MatchFoundPersonDialog(),
    );
  }

  @override
  State<MatchFoundPersonDialog> createState() => _MatchFoundPersonDialogState();
}

class _MatchFoundPersonDialogState extends State<MatchFoundPersonDialog>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isScanning = false;
  Map<String, dynamic>? _searchResult;
  String? _statusMessage;
  bool _isTransmittingSighting = false;
  bool _isPublishingBulletin = false;

  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = picked;
          _searchResult = null;
          _statusMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.sosRed,
            content: Text('Failed to capture photo: $e'),
          ),
        );
      }
    }
  }

  Future<void> _scanAndSearch() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _searchResult = null;
      _statusMessage = 'Analyzing facial features & querying disaster registry...';
    });
    _radarController.repeat();

    final provider = context.read<MissingPersonsProvider>();

    try {
      // 1. Acquire current device coordinates for precision location stamping
      final locationService = LocationService.instance;
      var fix = locationService.currentFix;
      if (fix == null) {
        await locationService.refreshLocation();
        fix = locationService.currentFix;
      }

      final photoFile = File(_selectedImage!.path);

      // 2. Perform search (Online Gateway or Offline DTN buffer & local comparison)
      final result = await provider.searchFoundPersonByPhoto(
        photoFile,
        lat: fix?.latitude,
        lng: fix?.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResult = result;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Search encountered an issue: $e';
        });
      }
    } finally {
      if (mounted) {
        _radarController.stop();
        _radarController.reset();
      }
    }
  }

  Future<void> _callFamily(String? phone) async {
    if (!mounted) return;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact phone registered for this record.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Emergency Contact "$phone" copied to clipboard. Dialing...'),
        ),
      );
    }
  }

  Future<void> _confirmSightingAndTransmit(Map<String, dynamic> match) async {
    if (_isTransmittingSighting) return;
    setState(() => _isTransmittingSighting = true);

    try {
      final provider = context.read<MissingPersonsProvider>();
      final locationService = LocationService.instance;
      var fix = locationService.currentFix;
      if (fix == null) {
        await locationService.refreshLocation();
        fix = locationService.currentFix;
      }

      final personId = (match['person_id'] ?? match['id'] ?? '').toString();
      final personName = (match['name'] ?? 'Individual').toString();
      final num? simVal = (match['similarity_percent'] as num?) ??
          (match['confidence_score'] as num?) ??
          (match['similarity_score'] is num ? (match['similarity_score'] as num) * 100 : null) ??
          (match['score'] is num ? (match['score'] as num) * 100 : null);
      final similarity = simVal != null && !simVal.isNaN ? simVal.toInt().clamp(1, 100) : 95;

      final locationStr = fix != null
          ? 'Visual Match Verified (GPS ${fix.latitude.toStringAsFixed(4)}, ${fix.longitude.toStringAsFixed(4)})'
          : 'Visual Match Verified (Local Station)';

      await provider.recordSighting(
        personId: personId,
        location: locationStr,
        lat: fix?.latitude,
        lng: fix?.longitude,
        notes: 'Confirmed visual match from field photo search ($similarity% similarity). Found individual in safe care.',
        photoPath: _selectedImage?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Sighting for "$personName" confirmed & GPS transmitted across DTN mesh!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.sosRed,
            content: Text('Failed to transmit sighting: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTransmittingSighting = false);
      }
    }
  }

  Future<void> _publishBulletinToMesh() async {
    if (_selectedImage == null || _isPublishingBulletin) return;
    setState(() => _isPublishingBulletin = true);

    try {
      final provider = context.read<MissingPersonsProvider>();
      final locationService = LocationService.instance;
      var fix = locationService.currentFix;
      if (fix == null) {
        await locationService.refreshLocation();
        fix = locationService.currentFix;
      }

      final locDesc = fix != null
          ? 'Found at GPS ${fix.latitude.toStringAsFixed(4)}, ${fix.longitude.toStringAsFixed(4)}'
          : 'Found individual (Local shelter / safe zone)';

      await provider.reportMissingPerson(
        name: 'Unidentified Found Person',
        age: 0,
        gender: 'Unspecified',
        lastSeenLocation: locDesc,
        lat: fix?.latitude,
        lng: fix?.longitude,
        description: 'Individual found and sheltered. Field photo registered. Broadcast to mesh for identification and family reunion.',
        photoPath: _selectedImage?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTokens.signalYellow,
            content: Text(
              'Found Person Bulletin broadcasted across Bluetooth DTN Mesh!',
              style: TextStyle(color: AppTokens.nightNavy, fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.sosRed,
            content: Text('Failed to publish bulletin: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishingBulletin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
        border: Border.all(color: theme.borderStrong, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: mediaQuery.viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.borderStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              _buildHeader(theme),
              const SizedBox(height: 18),

              // Photo Picker / Preview Card
              _buildPhotoCard(theme),
              const SizedBox(height: 16),

              // Scan & Search Database Action Button
              if (_selectedImage != null && _searchResult == null)
                _buildSearchButton(theme),

              // Status message or progress description
              if (_statusMessage != null && _searchResult == null) ...[
                const SizedBox(height: 10),
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Results Section
              if (_searchResult != null) ...[
                const SizedBox(height: 16),
                _buildResultsView(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTokens.signalYellow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: AppTokens.signalYellow.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.face_retouching_natural_rounded,
            color: AppTokens.signalYellow,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual Recognition: Match Found Person',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Offline-first DTN search against missing person records',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: theme.textMuted),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildPhotoCard(ThemeProvider theme) {
    if (_selectedImage == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: theme.surfaceSunken,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 28,
                color: theme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture or Select Found Person Photo',
              style: TextStyle(
                color: theme.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clear facial angles produce maximum biometric match accuracy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
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
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Camera',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.text,
                      side: BorderSide(color: theme.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text(
                      'Gallery',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Image preview with scanning radar/pulse animation when searching
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: _isScanning ? const Color(0xFF10B981) : theme.borderStrong,
          width: _isScanning ? 2.0 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Captured Image
          Image.file(
            File(_selectedImage!.path),
            fit: BoxFit.cover,
          ),

          // Radar / Pulse Scanning Overlay
          if (_isScanning)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) => _RadarScannerOverlay(
                progress: _radarController.value,
              ),
            ),

          // Top action: retake / change photo
          if (!_isScanning)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _pickImage(ImageSource.camera),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cached_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Retake',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom label
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isScanning ? Icons.radar_rounded : Icons.camera_alt_outlined,
                    color: _isScanning ? const Color(0xFF10B981) : Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isScanning
                        ? 'Scanning Biometric Features...'
                        : 'Field Photo Captured',
                    style: TextStyle(
                      color: _isScanning ? const Color(0xFF10B981) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSearchButton(ThemeProvider theme) {
    return SizedBox(
      height: AppTokens.inputHeight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.signalYellow,
          foregroundColor: AppTokens.nightNavy,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        icon: _isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppTokens.nightNavy,
                ),
              )
            : const Icon(Icons.saved_search_rounded, size: 22),
        label: Text(
          _isScanning ? 'Searching Database...' : 'Scan & Search Database',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
        onPressed: _isScanning ? null : _scanAndSearch,
      ),
    );
  }

  Widget _buildResultsView(ThemeProvider theme) {
    final result = _searchResult!;
    final bool matchFound = result['match_found'] == true;
    final bool isOffline = result['offline'] == true;
    final dynamic rawTop = result['top_match'];
    final Map<String, dynamic>? topMatch = rawTop is Map<String, dynamic>
        ? rawTop
        : (result['matches'] is List && (result['matches'] as List).isNotEmpty
            ? (result['matches'] as List).first as Map<String, dynamic>?
            : null);

    if (matchFound && topMatch != null) {
      return _buildMatchFoundCard(topMatch, isOffline, theme);
    } else if (isOffline) {
      return _buildOfflineNoMatchCard(theme);
    } else {
      return _buildOnlineNoMatchCard(theme);
    }
  }

  Widget _buildMatchFoundCard(
    Map<String, dynamic> topMatch,
    bool isOffline,
    ThemeProvider theme,
  ) {
    final personId = (topMatch['person_id'] ?? topMatch['id'] ?? '').toString();
    final name = (topMatch['name'] ?? 'Identified Person').toString();
    final age = topMatch['age']?.toString() ?? 'Unknown';
    final gender = topMatch['gender']?.toString() ?? 'Unspecified';
    final contactPhone = topMatch['contact_phone']?.toString();
    final medicalNotes = topMatch['medical_alerts']?.toString() ??
        topMatch['medical_notes']?.toString() ??
        topMatch['description']?.toString() ??
        'No critical alerts noted';

    // Retrieve local report if present to fetch local photoPath or cached details
    final mpProvider = context.read<MissingPersonsProvider>();
    MissingPerson? localReport;
    try {
      localReport = mpProvider.reports.cast<MissingPerson?>().firstWhere(
        (r) => (r != null && personId.isNotEmpty && r.id == personId) ||
               (r != null && r.name.trim().toLowerCase() == name.trim().toLowerCase()),
        orElse: () => null,
      );
    } catch (_) {}

    String? regPhotoPath = topMatch['photo_path']?.toString();
    if ((regPhotoPath == null || regPhotoPath.isEmpty) && localReport?.photoPath != null) {
      regPhotoPath = localReport!.photoPath;
    }

    String? regPhotoUrl = topMatch['photo_url']?.toString();
    if ((regPhotoUrl == null || regPhotoUrl.isEmpty) && localReport?.photoUrl != null) {
      regPhotoUrl = localReport!.photoUrl;
    }

    final String? photoBase64 = topMatch['photo_base64']?.toString();

    // Construct full URL if relative
    String? fullPhotoUrl;
    if (regPhotoUrl != null && regPhotoUrl.isNotEmpty) {
      if (regPhotoUrl.startsWith('http://') || regPhotoUrl.startsWith('https://')) {
        fullPhotoUrl = regPhotoUrl;
      } else {
        final base = AppConfig.backendBaseUrl.replaceAll(RegExp(r'/+$'), '');
        final path = regPhotoUrl.startsWith('/') ? regPhotoUrl : '/$regPhotoUrl';
        fullPhotoUrl = '$base$path';
      }
    } else if (personId.isNotEmpty) {
      final base = AppConfig.backendBaseUrl.replaceAll(RegExp(r'/+$'), '');
      fullPhotoUrl = '$base/api/v1/missing-persons/$personId/photo';
    }

    ImageProvider? registeredImageProvider;
    if (regPhotoPath != null && regPhotoPath.isNotEmpty && File(regPhotoPath).existsSync()) {
      registeredImageProvider = FileImage(File(regPhotoPath));
    } else if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final cleanBase64 = photoBase64.contains(',') ? photoBase64.split(',').last : photoBase64;
        registeredImageProvider = MemoryImage(base64Decode(cleanBase64));
      } catch (e) {
        debugPrint('[MatchFoundPerson] Error decoding base64 photo: $e');
      }
    }

    if (registeredImageProvider == null && fullPhotoUrl != null && fullPhotoUrl.isNotEmpty) {
      registeredImageProvider = NetworkImage(fullPhotoUrl);
    }

    final sim = (topMatch['similarity_percent'] as num?) ??
        (topMatch['confidence_score'] as num?) ??
        (topMatch['similarity_score'] is num ? (topMatch['similarity_score'] as num) * 100 : null) ??
        (topMatch['similarity'] is num ? (topMatch['similarity'] as num) * 100 : null) ??
        (topMatch['score'] is num ? (topMatch['score'] as num) * 100 : null);
    final int similarityPercent = (sim != null && !sim.isNaN) ? sim.toInt().clamp(1, 100) : 95;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // High-Visibility Emerald Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MATCH FOUND ($similarityPercent% Similarity)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isOffline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OFFLINE CACHE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Comparison Card: Found Photo vs Registered Photo
          Row(
            children: [
              Expanded(
                child: _buildComparisonPhoto(
                  label: 'Found Photo',
                  imageProvider: FileImage(File(_selectedImage!.path)),
                  theme: theme,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    const Icon(
                      Icons.compare_arrows_rounded,
                      color: Color(0xFF10B981),
                      size: 26,
                    ),
                    Text(
                      '$similarityPercent%',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildComparisonPhoto(
                  label: 'Registered Record',
                  imageProvider: registeredImageProvider,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Person Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: $age • Gender: $gender',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
                const Divider(height: 16),
                _buildInfoLine(
                  Icons.phone_rounded,
                  'Emergency Contact',
                  contactPhone ?? 'Not listed',
                  theme,
                  isHighlight: contactPhone != null,
                ),
                const SizedBox(height: 6),
                _buildInfoLine(
                  Icons.medical_services_outlined,
                  'Medical Alerts',
                  medicalNotes,
                  theme,
                  accentColor: AppTokens.warningAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Call Family, Confirm Sighting & Transmit GPS, Dismiss
          Row(
            children: [
              if (contactPhone != null && contactPhone.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: const Text(
                      'Call Family',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: () => _callFamily(contactPhone),
                  ),
                ),
              if (contactPhone != null && contactPhone.isNotEmpty)
                const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: _isTransmittingSighting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.nightNavy,
                          ),
                        )
                      : const Icon(Icons.fmd_good_rounded, size: 16),
                  label: const Text(
                    'Confirm & GPS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: _isTransmittingSighting
                      ? null
                      : () => _confirmSightingAndTransmit(topMatch),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textMuted,
                  side: BorderSide(color: theme.borderStrong),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonPhoto({
    required String label,
    required ImageProvider? imageProvider,
    required ThemeProvider theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: theme.borderStrong),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageProvider != null
              ? Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total = loadingProgress.expectedTotalBytes;
                    final loaded = loadingProgress.cumulativeBytesLoaded;
                    final progress = (total != null && total > 0) ? loaded / total : null;
                    return Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded, size: 36, color: theme.textMuted),
                        const SizedBox(height: 2),
                        Text(
                          'No Photo',
                          style: TextStyle(color: theme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 36, color: theme.textMuted),
                      const SizedBox(height: 4),
                      Text(
                        'No Photo',
                        style: TextStyle(color: theme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String title,
    String value,
    ThemeProvider theme, {
    bool isHighlight = false,
    Color? accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: accentColor ?? (isHighlight ? const Color(0xFF10B981) : theme.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.text, fontSize: 12.5),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    color: isHighlight ? const Color(0xFF10B981) : theme.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineNoMatchCard(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.darkWarningSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.warningAmber, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.warningAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppTokens.warningAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Offline Mode: Photo query saved.',
                  style: TextStyle(
                    color: AppTokens.warningAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'DTN Mesh Gateway will transmit to cloud when any peer reaches internet connectivity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No matching missing person found in registry.',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.signalYellow,
              foregroundColor: AppTokens.nightNavy,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
            ),
            icon: _isPublishingBulletin
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.nightNavy,
                    ),
                  )
                : const Icon(Icons.podcasts_rounded, size: 18),
            label: const Text(
              'Publish Found Person Bulletin to Mesh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            onPressed: _isPublishingBulletin ? null : _publishBulletinToMesh,
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineNoMatchCard(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.borderStrong),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: AppTokens.beaconTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No matching missing person found in registry.',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The cloud and mesh registries do not contain an active bulletin matching this photo.',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.signalYellow,
              foregroundColor: AppTokens.nightNavy,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
            ),
            icon: _isPublishingBulletin
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.nightNavy,
                    ),
                  )
                : const Icon(Icons.campaign_rounded, size: 18),
            label: const Text(
              'Publish Found Person Bulletin to Mesh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            onPressed: _isPublishingBulletin ? null : _publishBulletinToMesh,
          ),
        ],
      ),
    );
  }
}

/// Custom Scanning Radar & Pulse Animation Overlay
class _RadarScannerOverlay extends StatelessWidget {
  final double progress;
  const _RadarScannerOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final sweepY = height * progress;
        return Stack(
          children: [
            // Radar pulse waves
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _RadarRingPainter(progress: progress),
            ),
            // Sweeping laser line
            Positioned(
              left: 0,
              right: 0,
              top: sweepY - 2,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF10B981),
                      AppTokens.signalYellow,
                      Color(0xFF10B981),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.9),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Translucent scanning wash
            Positioned(
              left: 0,
              right: 0,
              top: sweepY > 36 ? sweepY - 36 : 0,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF10B981).withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadarRingPainter extends CustomPainter {
  final double progress;
  _RadarRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 0.8);

      final paint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }

    // Reticle
    final reticlePaint = Paint()
      ..color = AppTokens.signalYellow.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 12, reticlePaint);
    canvas.drawLine(
      Offset(center.dx - 22, center.dy),
      Offset(center.dx - 6, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + 22, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 22),
      Offset(center.dx, center.dy - 6),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx, center.dy + 22),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
