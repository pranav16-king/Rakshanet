import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final cardBg = theme.surface;
    final borderColor = theme.border;
    final textColor = theme.text;
    final textMuted = theme.textMuted;

    return Stack(
      children: [
        // Map Surface / Simulated Vector Canvas
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0F172A),
            child: CustomPaint(
              painter: _OfflineMapPainter(),
            ),
          ),
        ),

        // Floating Map Controls (Layers, Recenter)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapFab(
                icon: Icons.layers_outlined,
                tooltip: 'Map Layers',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _buildMapFab(
                icon: Icons.my_location,
                tooltip: 'Re-center',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom Banner (Mockup Screen 6: "2 people need help ~1.3 km • Last seen 25 min ago")
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTokens.sosRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTokens.sosRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '2 people need help',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~1.3 km • Last seen 25 min ago',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _OfflineMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines for topological map feel
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // River contour line
    final riverPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.45,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(path, riverPaint);

    // Peer cluster (center circle)
    final clusterFill = Paint()..color = const Color(0xFF0E8A94).withValues(alpha: 0.35);
    final clusterBorder = Paint()
      ..color = const Color(0xFF3CC6D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final clusterCenter = Offset(size.width * 0.5, size.height * 0.45);
    canvas.drawCircle(clusterCenter, 42, clusterFill);
    canvas.drawCircle(clusterCenter, 42, clusterBorder);

    // SOS Point 1
    final sos1 = Offset(size.width * 0.65, size.height * 0.28);
    _drawMarker(canvas, sos1, AppTokens.sosRed, 'SOS');

    // SOS Point 2
    final sos2 = Offset(size.width * 0.28, size.height * 0.52);
    _drawMarker(canvas, sos2, AppTokens.sosRed, 'SOS');

    // Rescue Shelter Point
    final shelter = Offset(size.width * 0.75, size.height * 0.6);
    _drawMarker(canvas, shelter, const Color(0xFF1E8E4E), 'Shelter');
  }

  void _drawMarker(Canvas canvas, Offset pos, Color color, String label) {
    // Pulse ring
    final ring = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(pos, 16, ring);

    // Dot
    final dot = Paint()..color = color;
    canvas.drawCircle(pos, 8, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
