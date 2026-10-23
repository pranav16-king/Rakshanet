import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../providers/profile_provider.dart';
import '../../services/user_auth_service.dart';
import '../../theme/app_tokens.dart';
import '../shell/main_shell.dart';

enum StartupPhase {
  boot,
  loadLocalConfig,
  prepareOfflineStorage,
  checkCapabilities,
  ready,
  home,
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _breathingGlowAnimation;
  Timer? _delayTimer;

  Future<void> _safeDelay(Duration duration) {
    if (!mounted) return Future.value();
    final completer = Completer<void>();
    _delayTimer?.cancel();
    _delayTimer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  StartupPhase _currentPhase = StartupPhase.boot;
  StartupPhase get currentPhase => _currentPhase;
  String _statusMessage = 'Initializing secure communications';
  double _progressValue = 0.20;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (runs once on launch)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _entranceController.forward();

    // 2. Continuous ambient pulse & breathing glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _breathingGlowAnimation = Tween<double>(begin: 0.78, end: 1.18).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 3. Run the deterministic startup state machine
    _runStartupSequence();
  }

  /// Startup State Machine:
  /// BOOT -> LOAD_LOCAL_CONFIG -> PREPARE_OFFLINE_STORAGE -> CHECK_CAPABILITIES -> READY -> HOME
  Future<void> _runStartupSequence() async {
    // Phase 1: BOOT
    if (!mounted) return;
    setState(() {
      _currentPhase = StartupPhase.boot;
      _statusMessage = 'Initializing secure communications';
      _progressValue = 0.20;
    });
    await _safeDelay(const Duration(milliseconds: 380));
    if (!mounted) return;

    // Phase 2: LOAD_LOCAL_CONFIG
    setState(() {
      _currentPhase = StartupPhase.loadLocalConfig;
      _statusMessage = 'Preparing offline resources';
      _progressValue = 0.45;
    });
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider
          .loadProfile()
          .timeout(const Duration(milliseconds: 650), onTimeout: () {});
    } catch (e) {
      debugPrint('[SplashScreen] Config load notice: $e');
    }
    await _safeDelay(const Duration(milliseconds: 320));
    if (!mounted) return;

    // Phase 3: PREPARE_OFFLINE_STORAGE
    setState(() {
      _currentPhase = StartupPhase.prepareOfflineStorage;
      _statusMessage = 'Checking local network capabilities';
      _progressValue = 0.70;
    });
    try {
      await AppDatabase.instance.database
          .timeout(const Duration(milliseconds: 600), onTimeout: () {
        return AppDatabase.instance.database;
      });
    } catch (e) {
      debugPrint('[SplashScreen] Storage verify notice: $e');
    }
    await _safeDelay(const Duration(milliseconds: 320));
    if (!mounted) return;

    // Phase 4: CHECK_CAPABILITIES
    setState(() {
      _currentPhase = StartupPhase.checkCapabilities;
      _statusMessage = 'Loading emergency services';
      _progressValue = 0.90;
    });
    try {
      await UserAuthService.instance
          .checkOfflineLoginAvailable()
          .timeout(const Duration(milliseconds: 400), onTimeout: () => false);
    } catch (e) {
      debugPrint('[SplashScreen] Capability notice: $e');
    }
    await _safeDelay(const Duration(milliseconds: 280));
    if (!mounted) return;

    // Phase 5: READY
    setState(() {
      _currentPhase = StartupPhase.ready;
      _statusMessage = 'Ready for emergency response';
      _progressValue = 1.0;
    });
    await _safeDelay(const Duration(milliseconds: 380));
    if (!mounted) return;

    // Phase 6: HOME
    _transitionToHome();
  }

  void _transitionToHome() {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);

    // Non-blocking opportunistic sync in background
    UserAuthService.instance.syncNow();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTokens.splashBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTokens.splashBg, // Deep navy: #07111F
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Subtle Animated Mesh Nodes & Radial Cyan/Blue Ambient Lighting
            RepaintBoundary(
              child: CustomPaint(
                painter: _MeshConstellationPainter(
                  pulseValue:
                      disableAnimations ? 0.5 : _pulseController.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // 2. Safe Area Centered Branding & Balanced Loading
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Region with Soft Ambient Breathing Halo
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          final fade = disableAnimations
                              ? 1.0
                              : _logoFadeAnimation.value;
                          final scale = disableAnimations
                              ? 1.0
                              : _logoScaleAnimation.value;

                          return Opacity(
                            opacity: fade,
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final haloScale = disableAnimations
                                ? 1.0
                                : _breathingGlowAnimation.value;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft Cyan & Blue Ambient Radial Glow (Clean, No Mud)
                                Container(
                                  width: 156 * haloScale,
                                  height: 156 * haloScale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTokens.electricCyan
                                            .withValues(alpha: 0.22),
                                        AppTokens.emergencyBlue
                                            .withValues(alpha: 0.14),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),

                                // Complete RakshaNet Logo — Natural Transparency & Full Proportions (NO CROPPING)
                                Container(
                                  width: 140,
                                  height: 140,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/images/rakshanet_logo.png',
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: AppTokens.darkSurfaceElevated,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTokens.electricCyan,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.radar_rounded,
                                        size: 64,
                                        color: AppTokens.safetyAmber,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Brand Name + Compact Amber "AI" Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'RakshaNet',
                            style: TextStyle(
                              color: AppTokens.textPrimaryNavy, // #F5F8FC
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.safetyAmber, // #FFC107
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTokens.safetyAmber
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: AppTokens.splashBg, // #07111F
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'OFFLINE-FIRST DISASTER MESH NETWORK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTokens.electricCyan, // #20D9F3
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),

                      const SizedBox(height: 52),

                      // Professional Loading Experience & Real Status Track
                      SizedBox(
                        width: 240,
                        child: Column(
                          children: [
                            // Thin progress track with cyan-to-amber highlight gradient
                            Container(
                              height: 3.5,
                              width: 240,
                              decoration: BoxDecoration(
                                color: AppTokens.darkSurfaceElevated, // #13243A
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeInOut,
                                  widthFactor: _progressValue.clamp(0.05, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTokens.electricCyan, // #20D9F3
                                          AppTokens.safetyAmber,  // #FFC107
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTokens.electricCyan
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Small network initialization indicator & descriptive status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sensors_rounded,
                                  size: 14,
                                  color: AppTokens.electricCyan,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _statusMessage,
                                      key: ValueKey(_statusMessage),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTokens
                                            .textSecondaryNavy, // #9AAEC4
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

/// Link definition between two constellation node indices
class _MeshLink {
  final int from;
  final int to;
  const _MeshLink(this.from, this.to);
}

/// CustomPainter rendering a subtle, battery-conscious emergency mesh network constellation
class _MeshConstellationPainter extends CustomPainter {
  final double pulseValue;

  _MeshConstellationPainter({required this.pulseValue});

  // Normalized node coordinates across screen [0.0, 1.0]
  static const List<Offset> _nodes = [
    Offset(0.12, 0.16),
    Offset(0.38, 0.10),
    Offset(0.78, 0.14),
    Offset(0.88, 0.28),
    Offset(0.15, 0.38),
    Offset(0.84, 0.50),
    Offset(0.10, 0.68),
    Offset(0.26, 0.82),
    Offset(0.68, 0.76),
    Offset(0.88, 0.84),
    Offset(0.48, 0.92),
  ];

  static const List<_MeshLink> _links = [
    _MeshLink(0, 1),
    _MeshLink(1, 2),
    _MeshLink(2, 3),
    _MeshLink(0, 4),
    _MeshLink(3, 5),
    _MeshLink(4, 6),
    _MeshLink(6, 7),
    _MeshLink(7, 8),
    _MeshLink(8, 9),
    _MeshLink(8, 10),
    _MeshLink(5, 9),
    _MeshLink(1, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft radial cyan/blue ambient lighting
    final centerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTokens.emergencyBlue.withValues(alpha: 0.12),
          AppTokens.electricCyan.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.45),
          radius: size.width * 0.68,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.68,
      centerGlowPaint,
    );

    // 2. Mesh Connection Links
    final linkPaint = Paint()
      ..color = AppTokens.emergencyBlue.withValues(alpha: 0.10)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final link in _links) {
      final p1 = Offset(_nodes[link.from].dx * size.width,
          _nodes[link.from].dy * size.height);
      final p2 = Offset(
          _nodes[link.to].dx * size.width, _nodes[link.to].dy * size.height);
      canvas.drawLine(p1, p2, linkPaint);
    }

    // 3. Slow-moving connection pulses between nodes
    final pulseLinks = [0, 4, 7]; // designated active links
    final particlePaints = [
      Paint()..color = AppTokens.electricCyan.withValues(alpha: 0.85),
      Paint()..color = AppTokens.safetyAmber.withValues(alpha: 0.85),
      Paint()..color = AppTokens.electricCyan.withValues(alpha: 0.75),
    ];

    for (int i = 0; i < pulseLinks.length; i++) {
      final linkIndex = pulseLinks[i];
      final link = _links[linkIndex];
      final p1 = Offset(_nodes[link.from].dx * size.width,
          _nodes[link.from].dy * size.height);
      final p2 = Offset(
          _nodes[link.to].dx * size.width, _nodes[link.to].dy * size.height);

      // Interpolate packet position along link
      final progress = (pulseValue + (i * 0.33)) % 1.0;
      final packetPos = Offset.lerp(p1, p2, progress)!;

      // Glow halo
      final glowPaint = Paint()
        ..color = particlePaints[i].color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(packetPos, 5.0, glowPaint);

      // Core particle
      canvas.drawCircle(packetPos, 2.2, particlePaints[i]);
    }

    // 4. Subtle Nodes
    final nodePaint = Paint()
      ..color = AppTokens.textSecondaryNavy.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    for (final node in _nodes) {
      final pos = Offset(node.dx * size.width, node.dy * size.height);
      canvas.drawCircle(pos, 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshConstellationPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
