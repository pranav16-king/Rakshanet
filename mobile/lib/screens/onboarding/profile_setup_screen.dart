import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import '../shell/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedBloodGroup = 'O+';
  String _selectedLanguage = 'English';
  bool _isSubmitting = false;

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
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.registerUser(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bloodGroup: _selectedBloodGroup,
        medicalNotes: _notesCtrl.text.trim(),
        preferredLanguage: _selectedLanguage,
      );
    } catch (e) {
      debugPrint('[ProfileSetupScreen] Error during submit: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const MainShell(),
            transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final surfaceColor = themeProvider.surface;
    final borderColor = themeProvider.border;
    final isLowPower = themeProvider.isLowPower;
    final isLight = themeProvider.isLight;
    final yellowAccent = isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow;

    return Scaffold(
      backgroundColor: themeProvider.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // RakshaNet Official Logo with Glowing Beacon Aura
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isLowPower
                            ? null
                            : [
                                BoxShadow(
                                  color: AppTokens.signalYellow.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppTokens.beaconTeal.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/rakshanet_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTokens.signalYellow.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.radar_rounded,
                              color: yellowAccent,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      'Emergency Profile Setup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Be reachable when networks fail. Stored locally in SQLite with zero cloud dependencies.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Input Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Full Name / Volunteer Handle',
                            labelStyle: TextStyle(color: textMuted),
                            hintText: 'e.g. Amit Sharma',
                            hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.6)),
                            prefixIcon: const Icon(Icons.person_outline, color: AppTokens.signalYellow),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: const BorderSide(color: AppTokens.signalYellow, width: 2),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Phone',
                            labelStyle: TextStyle(color: textMuted),
                            hintText: 'e.g. +91 98765 43210',
                            hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.6)),
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppTokens.beaconTeal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: const BorderSide(color: AppTokens.signalYellow, width: 2),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedBloodGroup,
                                dropdownColor: surfaceColor,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Blood',
                                  labelStyle: TextStyle(color: textMuted),
                                  prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppTokens.sosRed),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                items: _bloodGroups.map((bg) {
                                  return DropdownMenuItem<String>(
                                    value: bg,
                                    child: Text(bg, style: TextStyle(color: textColor)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBloodGroup = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _notesCtrl,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Medical Notes',
                                  labelStyle: TextStyle(color: textMuted),
                                  hintText: 'First-aid cert',
                                  hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.6)),
                                  prefixIcon: const Icon(Icons.medical_information_outlined, color: AppTokens.darkInfo),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    borderSide: const BorderSide(color: AppTokens.signalYellow, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          dropdownColor: surfaceColor,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Preferred Language',
                            labelStyle: TextStyle(color: textMuted),
                            prefixIcon: const Icon(Icons.language_rounded, color: AppTokens.darkWarning),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                          items: _languages.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang,
                              child: Text(lang, style: TextStyle(color: textColor)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLanguage = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.lightOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTokens.lightOnPrimary,
                              ),
                            )
                          : const Text(
                              'Join Mesh & Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.lightOnPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
