import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_tokens.dart';
import '../profile/profile_setup_screen.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _beaconPulseAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _beaconPulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    _navTimer = Timer(const Duration(milliseconds: 2800), _checkRegistrationAndNavigate);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  void _checkRegistrationAndNavigate() {
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.isRegistered) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainShell(),
          transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const ProfileSetupScreen(),
          transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      body: Stack(
        children: [
          // Background Atmospheric Search Beam Gradients
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            height: 480,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.4),
                  radius: 0.9,
                  colors: [
                    AppTokens.beaconTeal.withValues(alpha: 0.25),
                    AppTokens.signalYellow.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Animated Beacon Logo and Title
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Beacon Icon with Glowing Pulse Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _beaconPulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 96 * _beaconPulseAnimation.value,
                                height: 96 * _beaconPulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTokens.signalYellow.withValues(alpha: 0.15),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTokens.signalYellow, Color(0xFFFFA000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTokens.signalYellow.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              size: 46,
                              color: AppTokens.nightNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Brand Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'SignalRescue ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTokens.signalYellow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: AppTokens.nightNavy,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tagline matching Mockup Screen 1
                      const Text(
                        'Stay Connected.\nSave Lives.\nAnytime. Anywhere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTokens.darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Rescuer / Beacon Illustration Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTokens.darkSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(
                      color: AppTokens.beaconTeal.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTokens.beaconTeal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                        child: const Icon(
                          Icons.emergency_share_rounded,
                          color: AppTokens.darkInfo,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi-Vis Disaster Mesh',
                              style: TextStyle(
                                color: AppTokens.signalYellow,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Zero internet required. Device-to-device offline rescue beacon.',
                              style: TextStyle(
                                color: AppTokens.darkTextMuted,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Bottom Branding Subtext
                Column(
                  children: [
                    const Text(
                      'Offline Communication',
                      style: TextStyle(
                        color: AppTokens.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'AI-Powered Disaster Response',
                      style: TextStyle(
                        color: AppTokens.darkTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5-dot indicator from Mockup Screen 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isFirst = index == 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isFirst ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isFirst ? AppTokens.signalYellow : AppTokens.darkBorderStrong,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
