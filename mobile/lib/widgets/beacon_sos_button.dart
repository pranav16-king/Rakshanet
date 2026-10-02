import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_tokens.dart';

class BeaconSosButton extends StatefulWidget {
  final VoidCallback onTriggered;
  final double size;

  const BeaconSosButton({
    super.key,
    required this.onTriggered,
    this.size = AppTokens.sosHomeSize,
  });

  @override
  State<BeaconSosButton> createState() => _BeaconSosButtonState();
}

class _BeaconSosButtonState extends State<BeaconSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _holdCompleted = false;
  static const int _holdDurationMs = 3000; // 3 seconds hold to trigger
  static const int _tickIntervalMs = 50;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    _holdCompleted = false;
    HapticFeedback.mediumImpact();
    setState(() {
      _holdProgress = 0.0;
    });

    _holdTimer?.cancel();
    int elapsed = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: _tickIntervalMs), (timer) {
      elapsed += _tickIntervalMs;
      if (mounted) {
        setState(() {
          _holdProgress = (elapsed / _holdDurationMs).clamp(0.0, 1.0);
        });
      }

      if (elapsed >= _holdDurationMs) {
        timer.cancel();
        _holdCompleted = true;
        HapticFeedback.heavyImpact();
        widget.onTriggered();
        if (mounted) {
          setState(() {
            _holdProgress = 0.0;
          });
        }
      }
    });
  }

  void _cancelHolding() {
    if (_holdProgress < 1.0) {
      _holdTimer?.cancel();
      if (mounted) {
        setState(() {
          _holdProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.size;

    return Center(
      child: Semantics(
        label: 'SOS Emergency Button. Tap or hold for 3 seconds to report emergency.',
        button: true,
        child: GestureDetector(
          onTapDown: (_) => _startHolding(),
          onTapUp: (_) {
            if (_holdCompleted) {
              _holdCompleted = false;
              return;
            }
            _cancelHolding();
            widget.onTriggered();
          },
          onTapCancel: _cancelHolding,
          child: SizedBox(
            width: buttonSize * 1.35,
            height: buttonSize * 1.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring 2
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: buttonSize * _pulseAnimation.value,
                      height: buttonSize * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTokens.sosRed.withValues(alpha: _opacityAnimation.value * 0.4),
                      ),
                    );
                  },
                ),
                // Outer Pulse Ring 1 (Closer)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseAnimation.value - 1.0) * 0.6;
                    final op = (_opacityAnimation.value * 0.7).clamp(0.0, 1.0);
                    return Container(
                      width: buttonSize * scale,
                      height: buttonSize * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTokens.sosRed.withValues(alpha: op),
                      ),
                    );
                  },
                ),
                // Hold Progress Indicator Ring
                if (_holdProgress > 0)
                  SizedBox(
                    width: buttonSize + 16,
                    height: buttonSize + 16,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 6,
                      color: AppTokens.signalYellow,
                      backgroundColor: AppTokens.sosRed.withValues(alpha: 0.3),
                    ),
                  ),
                // Central SOS Button
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      radius: 0.85,
                      colors: [
                        Color(0xFFFF5A4E),
                        AppTokens.sosRed,
                        Color(0xFF8B120B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTokens.sosRed.withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          _holdProgress > 0
                              ? 'Holding... ${(_holdProgress * 100).toInt()}%'
                              : 'Hold 3s to broadcast',
                          style: TextStyle(
                            color: _holdProgress > 0 ? AppTokens.signalYellow : Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
