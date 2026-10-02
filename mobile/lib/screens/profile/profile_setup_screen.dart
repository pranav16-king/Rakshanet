import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Amit Sharma');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _bloodCtrl = TextEditingController(text: 'O+');
  final _notesCtrl = TextEditingController(text: 'First-aid certified');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bloodCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final profileProvider = context.read<ProfileProvider>();

    await profileProvider.registerUser(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bloodGroup: _bloodCtrl.text.trim(),
      medicalNotes: _notesCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = themeProvider.text;
    final textMuted = themeProvider.textMuted;
    final surfaceColor = themeProvider.surface;
    final borderColor = themeProvider.border;

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
                  // App Icon / Beacon Symbol
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTokens.signalYellow.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTokens.signalYellow,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.radar_rounded,
                          color: AppTokens.signalYellow,
                          size: 38,
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
                  const SizedBox(height: 28),

                  // Profile Input Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name / Volunteer Handle',
                            hintText: 'e.g. Amit Sharma',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Phone',
                            hintText: 'e.g. +91 98765 43210',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _bloodCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Blood Group',
                                  hintText: 'O+',
                                  prefixIcon: const Icon(Icons.bloodtype_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.radiusSm),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _notesCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Medical Notes',
                                  hintText: 'No allergies',
                                  prefixIcon: const Icon(Icons.medical_information_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.radiusSm),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Primary Button (56dp)
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
                          ? const CircularProgressIndicator(color: AppTokens.lightOnPrimary)
                          : const Text(
                              'Join Mesh & Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
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
