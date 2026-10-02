import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDanger;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isDanger = false,
    this.height = AppTokens.buttonPrimary, // 56dp
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDanger ? AppTokens.sosRed : AppTokens.signalYellow;
    final fgColor = isDanger ? Colors.white : AppTokens.lightOnPrimary;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppTokens.touchMin, // >= 48dp minimum touch target
        minWidth: 120,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
