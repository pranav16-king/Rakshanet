import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/user_auth_service.dart';
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
  Timer? _phaseTimer;
  bool _showLandingPage = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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

    _beaconPulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    // Phase 1: Show dedicated Splash Screen for 1.8s while checking session store
    _initializeSessionAndTransition();
  }

  Future<void> _initializeSessionAndTransition() async {
    final minSplashDelay = Future.delayed(const Duration(milliseconds: 1800));
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    bool hasValidSession = false;

    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfile();
      final offlineAvailable =
          await UserAuthService.instance.checkOfflineLoginAvailable();

      if (offlineAvailable ||
          (profileProvider.isRegistered &&
              profileProvider.profile.name.trim().isNotEmpty &&
              profileProvider.profile.id != 'unregistered')) {
        hasValidSession = true;
      }
    } catch (e) {
      debugPrint('[SplashScreen] Session restore check error: $e');
    }

    await minSplashDelay;
    if (!mounted) return;

    if (hasValidSession) {
      // Active session exists in session store — restore directly into MainShell
      setState(() => _isNavigating = true);
      UserAuthService.instance.syncNow();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainShell(),
          transitionsBuilder: (_, a, _, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      setState(() {
        _showLandingPage = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  /// Triggered when the user taps "Get Started" on the Landing Screen:
  /// Checks session store first; if registered -> MainShell, else -> ProfileSetupScreen.
  Future<void> _onGetStartedPressed() async {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfile();
    final offlineLoginAvailable =
        await UserAuthService.instance.checkOfflineLoginAvailable();
    if (!mounted) return;

    if (offlineLoginAvailable ||
        (profileProvider.isRegistered &&
            profileProvider.profile.name.trim().isNotEmpty &&
            profileProvider.profile.id != 'unregistered')) {
      UserAuthService.instance.syncNow();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainShell(),
          transitionsBuilder: (_, a, _, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const ProfileSetupScreen(),
          transitionsBuilder: (_, a, _, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  Future<void> _onSetupProfilePressed() async {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const ProfileSetupScreen(),
        transitionsBuilder: (_, a, _, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showLandingPage
            ? _buildLandingView(context)
            : _buildSplashIntroView(context),
      ),
    );
  }

  /// PHASE 1: Dedicated Animated Splash Screen
  Widget _buildSplashIntroView(BuildContext context) {
    return Stack(
      key: const ValueKey('splash_intro'),
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
                center: const Alignment(0.0, -0.3),
                radius: 0.9,
                colors: [
                  AppTokens.beaconTeal.withValues(alpha: 0.28),
                  AppTokens.signalYellow.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Pulsing Radar / Crest Logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value.clamp(0.4, 1.0),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _beaconPulseAnimation,
                          builder: (context, _) {
                            return Container(
                              width: 112 * _beaconPulseAnimation.value,
                              height: 112 * _beaconPulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTokens.signalYellow
                                    .withValues(alpha: 0.14),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTokens.beaconTeal.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: AppTokens.signalYellow
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/rakshanet_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppTokens.nightNavy,
                                child: const Icon(
                                  Icons.radar_rounded,
                                  size: 54,
                                  color: AppTokens.signalYellow,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Brand Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RakshaNet ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.signalYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: AppTokens.nightNavy,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'OFFLINE-FIRST DISASTER MESH NETWORK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTokens.beaconTeal,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Boot Progress Indicator
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor:
                            AppTokens.darkBorderStrong.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTokens.signalYellow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Initializing BLE & Wi-Fi Direct Mesh...',
                    style: TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// PHASE 2: Full-Screen Hero Landing Page with Mountain Rescue Artwork & Get Started CTA
  Widget _buildLandingView(BuildContext context) {
    return Stack(
      key: const ValueKey('landing_hero'),
      fit: StackFit.expand,
      children: [
        // 1. Full-bleed Mountain Rescue Artwork Background
        Image.asset(
          'assets/images/splash_hero.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: AppTokens.nightNavy);
          },
        ),

        // 2. Cinematic Gradient Overlay for crisp text readability at top & bottom
        // while keeping the central rescuer and glowing beacon vivid and clear
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.28, 0.55, 0.76, 1.0],
              colors: [
                AppTokens.nightNavy.withValues(alpha: 0.78),
                AppTokens.nightNavy.withValues(alpha: 0.35),
                Colors.transparent,
                AppTokens.nightNavy.withValues(alpha: 0.72),
                AppTokens.nightNavy.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),

        // 3. Foreground Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Top Brand Title: RakshaNet AI
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'RakshaNet ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTokens.signalYellow,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTokens.signalYellow.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: AppTokens.nightNavy,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Primary Hero Headline matching Screen 1
                const Text(
                  'Stay Connected.\nSave Lives.\nAnytime. Anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),

                // Unobstructed middle area showcasing the Mountain Rescuer & Beacon
                const Spacer(),

                // Bottom Feature Subtitle
                const Text(
                  'Offline Communication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-Powered Disaster Response',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 20),

                // Primary CTA: "Get Started" Button (56dp Hi-Vis Signal Yellow)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isNavigating ? null : _onGetStartedPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.signalYellow,
                      foregroundColor: AppTokens.nightNavy,
                      disabledBackgroundColor:
                          AppTokens.signalYellow.withValues(alpha: 0.6),
                      elevation: 8,
                      shadowColor:
                          AppTokens.signalYellow.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isNavigating
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
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                                color: AppTokens.nightNavy,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Secondary subtle action to open Profile Setup directly if desired
                GestureDetector(
                  onTap: _onSetupProfilePressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Configure Emergency Profile & Mesh Identity',
                      style: TextStyle(
                        color: AppTokens.darkInfo.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            AppTokens.darkInfo.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 5-dot indicator matching Screen 1 design
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isFirst = index == 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isFirst ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppTokens.signalYellow
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
