import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/device_identity_service.dart';
import '../../theme/emergency_design_tokens.dart';
import '../../widgets/emergency_profile_components.dart';
import '../onboarding/emergency_mesh_intro_screen.dart';
import '../onboarding/splash_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Step 1: Mandatory Identity Fields (ONLY Full Name + Detected Mobile IMEI ID)
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _imeiUniqueIdCtrl;
  bool _isDetectingImei = false;
  bool _imeiPrivacyConfirmed = false;

  // Step 1: Optional Personal & Contact Information
  late final TextEditingController _emailCtrl;
  late final TextEditingController _emergencyContactNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  String _selectedDialCode = '+91';

  // Step 1: Optional Medical Information
  String? _selectedBloodGroup;
  late final TextEditingController _medicalIdCtrl;
  late final TextEditingController _medicalConditionsCtrl;

  // Step 1: Preferences
  String _selectedLanguage = 'English';

  // Flow State (Step 1 = Form, Step 2 = Review & Confirm)
  int _currentStep = 1;
  bool _isSaving = false;

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Gujarati',
  ];

  @override
  void initState() {
    super.initState();
    // IMPORTANT: Do NOT auto-fill the Mobile IMEI Unique ID on screen open.
    // The user MUST tap "Detect & Auto-Fill Mobile IMEI ID" and accept the
    // Privacy & Policy confirmation dialog before it is populated.
    _fullNameCtrl = TextEditingController();
    _imeiUniqueIdCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _emergencyContactNameCtrl = TextEditingController();
    _emergencyPhoneCtrl = TextEditingController();
    _selectedBloodGroup = null;
    _medicalIdCtrl = TextEditingController();
    _medicalConditionsCtrl = TextEditingController();
    _selectedLanguage = 'English';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameCtrl.dispose();
    _imeiUniqueIdCtrl.dispose();
    _emailCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _medicalIdCtrl.dispose();
    _medicalConditionsCtrl.dispose();
    super.dispose();
  }

  /// Shows the mandatory Privacy & Policy Confirmation Dialog BEFORE detecting
  /// and auto-filling the device's Mobile IMEI Unique ID.
  Future<void> _promptPrivacyAndDetectImei() async {
    FocusScope.of(context).unfocus();
    if (_isDetectingImei) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primaryAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primaryAmber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy & Policy Confirmation',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mobile IMEI Unique ID Authorization',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Policy Explanation Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Before auto-filling your device identifier, please review and confirm how your Mobile IMEI ID is used:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPolicyPoint(
                        icon: Icons.fingerprint_rounded,
                        title: 'Used Strictly as Your Unique ID',
                        description:
                            'This mobile IMEI identifier is used ONLY as your unique project ID to identify your emergency profile and prevent duplicate mesh packets.',
                      ),
                      const SizedBox(height: 10),
                      _buildPolicyPoint(
                        icon: Icons.lock_outline_rounded,
                        title: 'Local Session Store & Privacy Protection',
                        description:
                            'Stored securely in your device\'s local SQLite session store. It is never sold, shared for advertising, or used for unauthorized tracking.',
                      ),
                      const SizedBox(height: 10),
                      _buildPolicyPoint(
                        icon: Icons.verified_user_outlined,
                        title: 'Tamper-Proof Auto-Detection',
                        description:
                            'Manual entry is disabled to guarantee authentic device identity during disaster rescue operations.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'By tapping "Agree & Auto-Fill IMEI", you accept this privacy policy and authorize detecting your mobile IMEI ID as your unique project ID.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Agree & Auto-Fill',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAmber,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDetectingImei = true);
    try {
      final detectedImei =
          await DeviceIdentityService.instance.detectAndConfirmHardwareImeiId();
      if (!mounted) return;
      setState(() {
        _imeiUniqueIdCtrl.text = detectedImei;
        _imeiPrivacyConfirmed = true;
        _isDetectingImei = false;
      });
    } catch (e) {
      debugPrint('[ProfileSetupScreen] Error detecting hardware IMEI: $e');
      if (mounted) {
        setState(() => _isDetectingImei = false);
      }
    }
  }

  Widget _buildPolicyPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.cyan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleHeaderBack() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const SplashScreen(),
          transitionsBuilder: (_, a, _, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _handleContinueToReview() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _currentStep = 2);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSaveAndContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      final userProfileProvider = context.read<UserProfileProvider>();

      final rawPhone = _emergencyPhoneCtrl.text.trim();
      final formattedPhone =
          rawPhone.isEmpty ? '' : '$_selectedDialCode $rawPhone'.trim();

      // Combine optional structured metadata cleanly into medicalNotes so all SQLite fields are preserved
      final List<String> notesParts = [];
      if (_emergencyContactNameCtrl.text.trim().isNotEmpty) {
        notesParts.add(
          'Contact: ${_emergencyContactNameCtrl.text.trim()}',
        );
      }
      if (_medicalIdCtrl.text.trim().isNotEmpty) {
        notesParts.add('Med ID: ${_medicalIdCtrl.text.trim()}');
      }
      if (_medicalConditionsCtrl.text.trim().isNotEmpty) {
        notesParts.add(_medicalConditionsCtrl.text.trim());
      }

      final uniqueImeiId = _imeiUniqueIdCtrl.text.trim();
      final combinedNotes = notesParts.join(' | ');

      await profileProvider.registerUser(
        name: _fullNameCtrl.text.trim(),
        uniqueId: uniqueImeiId,
        email: _emailCtrl.text.trim(),
        phone: formattedPhone,
        bloodGroup: _selectedBloodGroup ?? '',
        medicalNotes: combinedNotes,
        preferredLanguage: _selectedLanguage,
      );

      // Keep UserProfileProvider in sync with the SQLite session store
      await userProfileProvider.registerProfile(
        name: _fullNameCtrl.text.trim(),
        bloodGroup: _selectedBloodGroup ?? '',
        emergencyContact: formattedPhone,
        preferredLanguage: _selectedLanguage,
        medicalNotes: combinedNotes,
        anonymousId: uniqueImeiId,
      );
    } catch (e) {
      debugPrint('[ProfileSetupScreen] Error saving profile session: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const EmergencyMeshIntroScreen(),
            transitionsBuilder: (_, a, _, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 320),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1 && Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep == 2) {
          setState(() => _currentStep = 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Compact Header (No Logo)
              EmergencyHeader(
                title: _currentStep == 1
                    ? 'Emergency Profile'
                    : 'Review & Confirm',
                stepText: '$_currentStep of 2',
                onBack: _handleHeaderBack,
              ),

              // 2. Progress Indicator
              StepIndicator(
                currentStep: _currentStep,
                totalSteps: 2,
              ),
              const SizedBox(height: AppSpacing.xs),

              // 3. Scrollable Content Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _currentStep == 1
                      ? _buildStepOneForm(context)
                      : _buildStepTwoReview(context),
                ),
              ),

              // 4. Sticky Bottom CTA + Security / Privacy Note
              _buildStickyBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// STEP 1 OF 2: Structured Emergency Profile Form
  /// Only Full Name and Detected Mobile IMEI Unique ID are mandatory.
  Widget _buildStepOneForm(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final hasImei = _imeiUniqueIdCtrl.text.trim().isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('step_1_form'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl + 40,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title + Description
            const Text(
              'Emergency Profile Setup',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Only your Full Name and verified Mobile IMEI Unique ID are required. All other fields are optional.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Offline Status Card
            const OfflineStatusCard(),
            const SizedBox(height: 12),

            // =========================================================
            // SECTION 1: MANDATORY IDENTITY (NAME + MOBILE IMEI UNIQUE ID)
            // =========================================================
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    badgeText: 'Required',
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // 1. MANDATORY: Full Name
                  AppTextField(
                    label: 'Full Name',
                    placeholder: 'Enter your full name',
                    icon: Icons.badge_outlined,
                    controller: _fullNameCtrl,
                    isRequired: true,
                    optionalLabel: 'Required',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Full Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. MANDATORY: Mobile IMEI ID (Read-Only, No Manual Entry, Auto-Fill via Button after Privacy Confirmation)
                  AppTextField(
                    label: 'Unique Mobile IMEI ID',
                    placeholder:
                        'Tap button below to detect & auto-fill (No manual entry)',
                    icon: Icons.perm_device_information_rounded,
                    controller: _imeiUniqueIdCtrl,
                    isRequired: true,
                    readOnly: true,
                    onTap: _promptPrivacyAndDetectImei,
                    optionalLabel:
                        hasImei ? 'Verified Hardware ID' : 'Read-Only • Required',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please tap "Detect & Auto-Fill Mobile IMEI ID" below';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Dedicated Detect & Auto-Fill Mobile IMEI Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isDetectingImei ? null : _promptPrivacyAndDetectImei,
                      icon: _isDetectingImei
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cyan,
                              ),
                            )
                          : Icon(
                              hasImei
                                  ? Icons.verified_rounded
                                  : Icons.qr_code_scanner_rounded,
                              size: 19,
                              color: hasImei
                                  ? AppColors.success
                                  : AppColors.cyan,
                            ),
                      label: Text(
                        _isDetectingImei
                            ? 'Detecting Hardware IMEI...'
                            : hasImei
                                ? 'IMEI Auto-Filled (${_imeiUniqueIdCtrl.text}) • Tap to View Policy'
                                : 'Detect & Auto-Fill Mobile IMEI ID',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasImei
                              ? AppColors.success
                              : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: hasImei
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.elevatedSurface,
                        side: BorderSide(
                          color: hasImei
                              ? AppColors.success.withValues(alpha: 0.45)
                              : AppColors.cyan.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _imeiPrivacyConfirmed
                            ? Icons.lock_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 13,
                        color: _imeiPrivacyConfirmed
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _imeiPrivacyConfirmed
                              ? 'Privacy policy confirmed. Used solely as your unique project ID.'
                              : 'Manual entry is disabled. Requires privacy confirmation before auto-fill.',
                          style: AppTypography.helper,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 3. OPTIONAL: Email Address
                  AppTextField(
                    label: 'Email Address',
                    placeholder: 'Optional email for cloud backup',
                    icon: Icons.mail_outline_rounded,
                    controller: _emailCtrl,
                    isRequired: false,
                    optionalLabel: 'Optional',
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return null; // Optional
                      }
                      final trimmed = val.trim();
                      if (!trimmed.contains('@') || !trimmed.contains('.')) {
                        return 'Enter a valid email address or leave empty';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // =========================================================
            // SECTION 2: EMERGENCY CONTACT (OPTIONAL)
            // =========================================================
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.contact_phone_outlined,
                    title: 'Emergency Contact',
                    badgeText: 'Optional',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    label: 'Emergency Contact Name',
                    placeholder: 'Optional responder or family contact',
                    icon: Icons.person_pin_outlined,
                    controller: _emergencyContactNameCtrl,
                    isRequired: false,
                    optionalLabel: 'Optional',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PhoneField(
                    label: 'Emergency Contact Phone',
                    selectedDialCode: _selectedDialCode,
                    onDialCodeChanged: (code) {
                      setState(() => _selectedDialCode = code);
                    },
                    controller: _emergencyPhoneCtrl,
                    isRequired: false,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return null; // Optional
                      }
                      final digitsOnly =
                          val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
                        return 'Enter a valid phone number (7–15 digits) or leave blank';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // =========================================================
            // SECTION 3: MEDICAL INFORMATION (OPTIONAL)
            // =========================================================
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.medical_information_outlined,
                    title: 'Medical Information',
                    badgeText: 'Optional',
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Responsive Two-Column Row (Blood Group + Medical ID)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 290;
                      final bloodDropdown = DropdownField<String>(
                        label: 'Blood Group',
                        placeholder: 'Select',
                        icon: Icons.water_drop_outlined,
                        value: _selectedBloodGroup,
                        items: _bloodGroups.map((bg) {
                          return DropdownMenuItem<String>(
                            value: bg,
                            child: Text(bg, style: AppTypography.inputText),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedBloodGroup = val);
                        },
                      );

                      final medicalIdInput = AppTextField(
                        label: 'Medical / Patient ID',
                        placeholder: 'Optional ID',
                        icon: Icons.credit_card_outlined,
                        controller: _medicalIdCtrl,
                        isRequired: false,
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            bloodDropdown,
                            const SizedBox(height: AppSpacing.md),
                            medicalIdInput,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: bloodDropdown),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(flex: 6, child: medicalIdInput),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Medical Conditions Multiline Field
                  MedicalField(
                    label: 'Medical Conditions',
                    placeholder: 'Allergies, conditions, medications...',
                    controller: _medicalConditionsCtrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // =========================================================
            // SECTION 4: PREFERENCES (OPTIONAL)
            // =========================================================
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.tune_rounded,
                    title: 'Preferences',
                    badgeText: 'Optional',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownField<String>(
                    label: 'Preferred Language',
                    placeholder: 'Select language',
                    icon: Icons.language_rounded,
                    value: _selectedLanguage,
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang, style: AppTypography.inputText),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // High Contrast / Low-Power OLED Accessibility Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.contrast_rounded,
                          size: 20,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'High Contrast / Low-Power OLED',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Maximizes contrast and extends battery life in emergencies',
                                style: AppTypography.helper,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: themeProvider.isLowPower,
                          activeTrackColor: AppColors.cyan,
                          activeThumbColor: AppColors.background,
                          onChanged: (enabled) {
                            themeProvider.setLowPower(enabled);
                          },
                        ),
                      ],
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

  /// STEP 2 OF 2: Review & Confirm Screen
  Widget _buildStepTwoReview(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final formattedPhone = _emergencyPhoneCtrl.text.trim().isEmpty
        ? 'Not specified'
        : '$_selectedDialCode ${_emergencyPhoneCtrl.text.trim()}';

    return SingleChildScrollView(
      key: const ValueKey('step_2_review'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl + 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Confirm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Verify your emergency profile details before saving them to your local device session store.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // PERSONAL Summary Card
          ReviewCard(
            icon: Icons.person_outline_rounded,
            categoryTitle: 'Identity & Contact',
            onEdit: () => setState(() => _currentStep = 1),
            rows: [
              ReviewItemRow(
                label: 'Full Name',
                value: _fullNameCtrl.text.trim(),
              ),
              ReviewItemRow(
                label: 'Unique IMEI ID',
                value: _imeiUniqueIdCtrl.text.trim(),
              ),
              ReviewItemRow(
                label: 'Email',
                value: _emailCtrl.text.trim(),
              ),
              ReviewItemRow(
                label: 'Emergency Contact',
                value: _emergencyContactNameCtrl.text.trim().isNotEmpty
                    ? '${_emergencyContactNameCtrl.text.trim()} ($formattedPhone)'
                    : formattedPhone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // MEDICAL Summary Card
          ReviewCard(
            icon: Icons.medical_information_outlined,
            categoryTitle: 'Medical (Optional)',
            onEdit: () => setState(() => _currentStep = 1),
            rows: [
              ReviewItemRow(
                label: 'Blood Group',
                value: _selectedBloodGroup ?? 'Not specified',
              ),
              ReviewItemRow(
                label: 'Medical ID',
                value: _medicalIdCtrl.text.trim(),
              ),
              ReviewItemRow(
                label: 'Medical Conditions',
                value: _medicalConditionsCtrl.text.trim(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // PREFERENCES Summary Card
          ReviewCard(
            icon: Icons.tune_rounded,
            categoryTitle: 'Preferences',
            onEdit: () => setState(() => _currentStep = 1),
            rows: [
              ReviewItemRow(
                label: 'Language',
                value: _selectedLanguage,
              ),
              ReviewItemRow(
                label: 'Display Mode',
                value: themeProvider.isLowPower
                    ? 'High Contrast OLED'
                    : 'Standard Dark Emergency',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // OFFLINE STORAGE Assurance Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'PERSISTENT SESSION STORE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your profile and unique IMEI session will remain active across app restarts.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCheckRow('Bound to Unique Mobile IMEI ID'),
                const SizedBox(height: 6),
                _buildCheckRow('Saved in local SQLite & Session Store'),
                const SizedBox(height: 6),
                _buildCheckRow('Automatic offline login on app restart'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondarySurface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.stickyBar,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs + 2,
            AppSpacing.md,
            AppSpacing.xs + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentStep == 1) ...[
                PrimaryButton(
                  label: 'Continue',
                  onPressed: _handleContinueToReview,
                ),
                const SecurityNote(),
              ] else ...[
                PrimaryButton(
                  label: 'Save & Continue',
                  isLoading: _isSaving,
                  onPressed: _handleSaveAndContinue,
                  trailingIcon: Icons.check_rounded,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _currentStep = 1),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'Back to Edit Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
