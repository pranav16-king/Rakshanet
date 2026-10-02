import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _sosTriggered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    setState(() {
      _holdProgress = 0.0;
      _sosTriggered = false;
    });

    const stepMs = 50;
    const totalMs = 1500; // 1.5 seconds hold per design.md

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      setState(() {
        _holdProgress += stepMs / totalMs;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          _sosTriggered = true;
          timer.cancel();
          _showSosSentDialog();
        }
      });
    });
  }

  void _cancelHolding() {
    _holdTimer?.cancel();
    if (!_sosTriggered) {
      setState(() {
        _holdProgress = 0.0;
      });
    }
  }

  void _showSosSentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162036),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CD08A), size: 28),
            SizedBox(width: 10),
            Text('SOS Broadcasted', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your emergency beacon has been saved locally and relayed across 12 nearby mesh nodes. '
          'Rescuers within range will receive your distress signal.',
          style: TextStyle(color: Color(0xFFEEF2F8)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.signalYellow,
              foregroundColor: AppTokens.lightOnPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _holdProgress = 0.0;
                _sosTriggered = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mesh = context.watch<MeshProvider>();

    final cardBg = theme.surface;
    final borderColor = theme.border;
    final textColor = theme.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 Status Pill Cards in 2x2 Grid (Mockup Screen 3)
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.radar,
                  iconColor: AppTokens.beaconTeal,
                  title: 'Mesh',
                  subtitle: 'Connected\n${mesh.connectedPeerCount} devices',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.wifi_off,
                  iconColor: AppTokens.sosRed,
                  title: 'Internet',
                  subtitle: 'Not available\nOffline',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.location_off,
                  iconColor: Colors.orange,
                  title: 'GPS',
                  subtitle: 'Last known\nCached fix',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.battery_charging_full,
                  iconColor: AppTokens.signalYellow,
                  title: 'Battery',
                  subtitle: '68%\nRadio saving',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Big 176dp Hero SOS Button with Ring Indicator (Mockup Screen 3)
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startHolding(),
              onTapUp: (_) => _cancelHolding(),
              onTapCancel: () => _cancelHolding(),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseScale = 1.0 + (_pulseController.value * 0.05);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulse Aura
                      Container(
                        width: AppTokens.sosHomeSize + 28,
                        height: AppTokens.sosHomeSize + 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTokens.sosRed.withOpacity(0.15 * pulseScale),
                        ),
                      ),

                      // Progress Ring
                      SizedBox(
                        width: AppTokens.sosHomeSize + 12,
                        height: AppTokens.sosHomeSize + 12,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 5,
                          backgroundColor: AppTokens.sosRed.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTokens.signalYellow,
                          ),
                        ),
                      ),

                      // SOS Hero Button
                      Container(
                        width: AppTokens.sosHomeSize,
                        height: AppTokens.sosHomeSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFFFF5A4E),
                              Color(0xFFD92D20),
                              Color(0xFF8A130A),
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTokens.sosRed.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _holdProgress > 0
                                  ? 'Hold... ${(1.5 * (1 - _holdProgress)).toStringAsFixed(1)}s'
                                  : 'Tap and hold\nfor 1.5s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Offline Warning Banner (Mockup Screen 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTokens.signalYellow,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF1A1400),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are in offline mode',
                        style: TextStyle(
                          color: Color(0xFF1A1400),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Messages will be sent when a network is available.',
                        style: TextStyle(
                          color: Color(0xFF332A00),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                    height: 1.2,
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
