import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_tokens.dart';
import 'profile_setup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _navigateToProfileSetup(BuildContext context) {
    Provider.of<UserProfileProvider>(context, listen: false).setOnboardingSeen(true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const ProfileSetupScreen(),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // Top Illustration: Mesh Network between two devices
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTokens.darkBgAlt,
                            AppTokens.darkSurface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: AppTokens.darkBorder),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glow
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTokens.signalYellow.withValues(alpha: 0.08),
                            ),
                          ),

                          // Left Device
                          Positioned(
                            left: 45,
                            child: Transform.rotate(
                              angle: -0.15,
                              child: Container(
                                width: 72,
                                height: 125,
                                decoration: BoxDecoration(
                                  color: AppTokens.darkSurfaceSunken,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTokens.beaconTeal, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.wifi_tethering_rounded, color: AppTokens.darkInfo, size: 28),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTokens.darkBorderStrong,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Middle Official Logo
                          Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTokens.signalYellow.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppTokens.beaconTeal.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/rakshanet_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.podcasts_rounded,
                                    color: AppTokens.signalYellow,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Right Device
                          Positioned(
                            right: 45,
                            child: Transform.rotate(
                              angle: 0.15,
                              child: Container(
                                width: 72,
                                height: 125,
                                decoration: BoxDecoration(
                                  color: AppTokens.darkSurfaceSunken,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTokens.signalYellow, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cell_tower_rounded, color: AppTokens.signalYellow, size: 28),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTokens.darkBorderStrong,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main Title matching Screen 2 mockup
                    const Text(
                      'Help each other\nwhen networks fail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle matching Screen 2 mockup
                    const Text(
                      'Chat offline, send SOS, get help,\nand stay safe with AI - anywhere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTokens.darkTextMuted,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 4 Value Cards matching Screen 2 mockup
                    _buildValueCard(
                      icon: Icons.wifi_off_rounded,
                      title: 'Works without internet',
                      subtitle: 'Full peer-to-peer communication without mobile towers',
                    ),
                    const SizedBox(height: 12),

                    _buildValueCard(
                      icon: Icons.hub_rounded,
                      title: 'Connects nearby devices',
                      subtitle: 'Auto-forms self-healing Bluetooth & Wi-Fi Direct mesh',
                    ),
                    const SizedBox(height: 12),

                    _buildValueCard(
                      icon: Icons.psychology_rounded,
                      title: 'AI guidance on your device',
                      subtitle: 'Offline emergency first-aid, survival tips, and triage',
                    ),
                    const SizedBox(height: 12),

                    _buildValueCard(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Auto sends to government when internet is back',
                      subtitle: 'Instant dispatch to NDRF, SDRF, and local rescue teams',
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTokens.nightNavy,
                border: Border(top: BorderSide(color: AppTokens.darkBorder.withValues(alpha: 0.5))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.buttonPrimary,
                    child: ElevatedButton(
                      onPressed: () => _navigateToProfileSetup(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.signalYellow,
                        foregroundColor: AppTokens.nightNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Skip Button
                  SizedBox(
                    height: AppTokens.touchMin,
                    child: TextButton(
                      onPressed: () => _navigateToProfileSetup(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.darkTextMuted,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      child: Row(
        children: [
          // Yellow Icon Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTokens.signalYellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTokens.nightNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTokens.darkText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTokens.darkTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
