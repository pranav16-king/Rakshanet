import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_tokens.dart';
import '../shell/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String _selectedLanguage = 'English';
  late String _generatedAnonymousId;
  bool _isSaving = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'
  ];

  final List<String> _languages = [
    'English',
    'Hindi (हिन्दी)',
    'Marathi (मराठी)',
    'Bengali (বাংলা)',
    'Tamil (தமிழ்)',
    'Telugu (తెలుగు)',
    'Gujarati (ગુજરાતી)',
  ];

  @override
  void initState() {
    super.initState();
    _generatedAnonymousId = _generateAnonymousId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateAnonymousId() {
    const chars = '0123456789ABCDEF';
    final random = Random();
    String p1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    String p2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'SR-$p1-$p2';
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    final success = await provider.registerProfile(
      name: _nameController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      emergencyContact: _phoneController.text.trim(),
      preferredLanguage: _selectedLanguage,
      medicalNotes: _notesController.text.trim(),
      anonymousId: _generatedAnonymousId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTokens.signalYellow),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Profile registered as $_generatedAnonymousId',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTokens.darkSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainShell(),
          transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: AppTokens.sosRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      appBar: AppBar(
        backgroundColor: AppTokens.nightNavy,
        elevation: 0,
        title: const Text(
          'Emergency Setup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTokens.sosRed.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(color: AppTokens.sosRed.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: AppTokens.sosRed, size: 14),
                SizedBox(width: 4),
                Text(
                  'Mandatory Gate',
                  style: TextStyle(
                    color: AppTokens.sosRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with Anonymous ID
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTokens.darkSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          border: Border.all(color: AppTokens.beaconTeal.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTokens.beaconTeal.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: AppTokens.darkInfo,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Anonymous Rescue ID',
                                    style: TextStyle(
                                      color: AppTokens.darkTextMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _generatedAnonymousId,
                                    style: const TextStyle(
                                      color: AppTokens.signalYellow,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Privacy Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTokens.darkSurfaceSunken,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          border: Border.all(color: AppTokens.darkBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: AppTokens.darkInfo, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Data stored locally in SQLite. Transmitted only during active SOS broadcasts.',
                                style: TextStyle(
                                  color: AppTokens.darkTextMuted,
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Field 1: Full Name / Nickname (Required)
                      const Text(
                        'Full Name or Nickname *',
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'e.g. Amit Sharma or Arjun',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTokens.signalYellow),
                          filled: true,
                          fillColor: AppTokens.darkSurfaceSunken,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            borderSide: const BorderSide(color: AppTokens.darkBorder),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name or nickname';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Field 2: Blood Group
                      const Text(
                        'Blood Group',
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: AppTokens.inputHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTokens.darkSurfaceSunken,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          border: Border.all(color: AppTokens.darkBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBloodGroup,
                            dropdownColor: AppTokens.darkSurface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTokens.signalYellow),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: _bloodGroups.map((group) {
                              return DropdownMenuItem(
                                value: group,
                                child: Row(
                                  children: [
                                    const Icon(Icons.water_drop_rounded, color: AppTokens.sosRed, size: 18),
                                    const SizedBox(width: 10),
                                    Text(group, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBloodGroup = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Field 3: Emergency Contact Phone
                      const Text(
                        'Emergency Contact Phone',
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTokens.darkInfo),
                          filled: true,
                          fillColor: AppTokens.darkSurfaceSunken,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            borderSide: const BorderSide(color: AppTokens.darkBorder),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Field 4: Preferred Language
                      const Text(
                        'Preferred Language',
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: AppTokens.inputHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTokens.darkSurfaceSunken,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          border: Border.all(color: AppTokens.darkBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: AppTokens.darkSurface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTokens.signalYellow),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            items: _languages.map((lang) {
                              return DropdownMenuItem(
                                value: lang,
                                child: Row(
                                  children: [
                                    const Icon(Icons.translate_rounded, color: AppTokens.signalYellow, size: 18),
                                    const SizedBox(width: 10),
                                    Text(lang, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLanguage = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Optional Medical Notes
                      const Text(
                        'Medical Notes / Allergies (Optional)',
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: 'e.g. Diabetic, allergic to penicillin, asthma',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Icon(Icons.medical_information_outlined, color: AppTokens.darkTextMuted),
                          ),
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
            ),

            // Save and Continue Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTokens.nightNavy,
                border: Border(top: BorderSide(color: AppTokens.darkBorder.withValues(alpha: 0.5))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppTokens.buttonPrimary,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTokens.nightNavy,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save & Join Rescue Mesh',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
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
