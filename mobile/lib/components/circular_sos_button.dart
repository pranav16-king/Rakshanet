import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class CircularSosButton extends StatefulWidget {
  final VoidCallback? onTriggered;
  final double size;

  const CircularSosButton({
    super.key,
    this.onTriggered,
    this.size = AppTokens.sosHomeSize, // 176dp
  });

  @override
  State<CircularSosButton> createState() => _CircularSosButtonState();
}

class _CircularSosButtonState extends State<CircularSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Center(
        child: GestureDetector(
          onTap: widget.onTriggered,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTokens.sosRed,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.sosRed.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 4,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sos,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Text(
                  'SOS',
                  key: Key('home_sos_text'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'HOLD 1.5S TO BROADCAST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white70,
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
