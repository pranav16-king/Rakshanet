// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized Navigation Constants for SignalRescue AI Bottom Dock
class NavConstants {
  NavConstants._();

  static const double navBarHeight = 74.0;
  static const double navBarHeightCompact = 68.0;
  static const double navBarRadius = 26.0;
  static const double sosButtonSize = 62.0;
  static const double sosButtonSizeCompact = 58.0;
  static const EdgeInsets navBarPadding = EdgeInsets.fromLTRB(14, 0, 14, 10);
  static const Duration navAnimationDuration = Duration(milliseconds: 180);

  // Palette Tokens (Section 20)
  static const Color background = Color(0xFF070D18);
  static const Color navSurface = Color(0xFF0B1322);
  static const Color navBorder = Color(0xFF263754);
  static const Color inactiveColor = Color(0xFF8FA0B8);
  static const Color activeText = Color(0xFFF5F7FA);
  static const Color sosPrimary = Color(0xFFEF4444);
  static const Color sosSecondary = Color(0xFFDC2626);
  static const Color sosDark = Color(0xFFB91C1C);
  static const Color primaryAmber = Color(0xFFFFB800);
  static const Color cyanAccent = Color(0xFF22D3EE);
}

// Top-level constant aliases matching specification requirements
const double NavBarHeight = NavConstants.navBarHeight;
const double NavBarRadius = NavConstants.navBarRadius;
const double SOSButtonSize = NavConstants.sosButtonSize;
const EdgeInsets NavBarPadding = NavConstants.navBarPadding;
const Duration NavAnimationDuration = NavConstants.navAnimationDuration;

/// 1. Controlled localized red ambient glow for the central SOS button.
class SOSGlow extends StatelessWidget {
  final double size;
  final bool isActive;
  final bool isPressed;
  final double pulseValue;

  const SOSGlow({
    super.key,
    required this.size,
    required this.isActive,
    required this.isPressed,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final double baseSpread = isPressed ? 14.0 : (isActive ? 10.0 : 6.0);
    final double outerOpacity = isPressed
        ? 0.38
        : isActive
            ? (0.22 + (pulseValue * 0.08))
            : 0.15;
    final double ambientOpacity = isPressed
        ? 0.20
        : isActive
            ? 0.12
            : 0.07;

    return IgnorePointer(
      child: Container(
        width: size + (pulseValue * 6.0),
        height: size + (pulseValue * 6.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Outer controlled red halo (8–16dp spread)
            BoxShadow(
              color: NavConstants.sosPrimary.withValues(alpha: outerOpacity),
              blurRadius: 16,
              spreadRadius: baseSpread * 0.45,
            ),
            // Second soft ambient glow
            BoxShadow(
              color: NavConstants.sosSecondary.withValues(alpha: ambientOpacity),
              blurRadius: 24,
              spreadRadius: baseSpread * 0.75,
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Circular progress ring around the FloatingSOSButton during 3-second hold.
class SOSProgressIndicator extends StatelessWidget {
  final double size;
  final double progress;

  const SOSProgressIndicator({
    super.key,
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0) return const SizedBox.shrink();

    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: CircularProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        strokeWidth: 3.5,
        color: NavConstants.primaryAmber,
        backgroundColor: NavConstants.sosPrimary.withValues(alpha: 0.25),
      ),
    );
  }
}

/// 3. Elevated Central Floating SOS Button with 3-second hold-to-broadcast
/// and single-tap tab selection.
class FloatingSOSButton extends StatefulWidget {
  final bool isActive;
  final double size;
  final VoidCallback onSelectSosTab;
  final VoidCallback onHoldTriggered;

  const FloatingSOSButton({
    super.key,
    required this.isActive,
    required this.size,
    required this.onSelectSosTab,
    required this.onHoldTriggered,
  });

  @override
  State<FloatingSOSButton> createState() => _FloatingSOSButtonState();
}

class _FloatingSOSButtonState extends State<FloatingSOSButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isPressed = false;
  bool _holdCompleted = false;

  static const int _holdDurationMs = 3000;
  static const int _tickMs = 40;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _holdCompleted = false;
    HapticFeedback.selectionClick();
    setState(() {
      _isPressed = true;
      _holdProgress = 0.0;
    });

    _holdTimer?.cancel();
    int elapsed = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      elapsed += _tickMs;
      if (mounted) {
        setState(() {
          _holdProgress = (elapsed / _holdDurationMs).clamp(0.0, 1.0);
        });
      }
      if (elapsed >= _holdDurationMs) {
        timer.cancel();
        _holdCompleted = true;
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _isPressed = false;
            _holdProgress = 0.0;
          });
        }
        widget.onHoldTriggered();
      }
    });
  }

  void _handleTapUp(TapUpDetails _) {
    _holdTimer?.cancel();
    final wasCompleted = _holdCompleted;
    setState(() {
      _isPressed = false;
      _holdProgress = 0.0;
    });
    // Single tap selects the SOS tab without accidentally broadcasting an emergency
    if (!wasCompleted) {
      HapticFeedback.lightImpact();
      widget.onSelectSosTab();
    }
  }

  void _handleTapCancel() {
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPressed = false;
        _holdProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double btnSize = widget.size;

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: 'SOS Emergency Tab. Tap to view SOS screen, or hold 3 seconds to broadcast emergency.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: SizedBox(
          width: btnSize + 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Floating "Hold 3 sec" tooltip pill when pressing/holding
              if (_isPressed && _holdProgress > 0.04)
                Positioned(
                  top: -32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NavConstants.navSurface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: NavConstants.sosPrimary.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Hold 3 sec (${((1.0 - _holdProgress) * 3.0).ceil()}s)',
                      style: const TextStyle(
                        color: NavConstants.activeText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // Protruding Circular SOS Button + Label Column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    AnimatedScale(
                      scale: _isPressed ? 0.93 : (widget.isActive ? 1.02 : 1.0),
                      duration: NavConstants.navAnimationDuration,
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: btnSize + 4,
                        height: btnSize + 4,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Controlled localized red halo
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return SOSGlow(
                                  size: btnSize,
                                  isActive: widget.isActive,
                                  isPressed: _isPressed,
                                  pulseValue: _pulseController.value,
                                );
                              },
                            ),

                            // Hold-to-trigger progress indicator ring
                            SOSProgressIndicator(
                              size: btnSize,
                              progress: _holdProgress,
                            ),

                            // Physical 3D-elevated circular SOS button
                            Container(
                              width: btnSize,
                              height: btnSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF87171), // Subtle lighter top surface
                                    NavConstants.sosPrimary, // #EF4444
                                    NavConstants.sosSecondary, // #DC2626
                                    NavConstants.sosDark, // #B91C1C
                                  ],
                                  stops: [0.0, 0.35, 0.75, 1.0],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: widget.isActive ? 0.35 : 0.22,
                                  ),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  // Dark physical drop shadow
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.gpp_maybe_rounded,
                                  color: Colors.white,
                                  size: btnSize >= 60 ? 30 : 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: widget.isActive
                            ? NavConstants.activeText
                            : NavConstants.sosPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. Individual Standard Navigation Item (Chat, Map, Tools, AI) with >= 44x44dp touch target.
class NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isSelected ? NavConstants.cyanAccent : NavConstants.inactiveColor;
    final Color labelColor =
        isSelected ? NavConstants.activeText : NavConstants.inactiveColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label tab',
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: NavConstants.navAnimationDuration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? NavConstants.cyanAccent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? NavConstants.cyanAccent.withValues(alpha: 0.28)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 23,
                    color: iconColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.15,
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

/// 5. Complete Floating Rounded Capsule Bottom Navigation Dock for SignalRescue AI.
class SignalRescueBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSosHoldTriggered;

  const SignalRescueBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onSosHoldTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isCompact = screenWidth < 375;

    final double barHeight =
        isCompact ? NavConstants.navBarHeightCompact : NavConstants.navBarHeight;
    final double sosSize =
        isCompact ? NavConstants.sosButtonSizeCompact : NavConstants.sosButtonSize;

    return SafeArea(
      top: false,
      child: Padding(
        padding: NavConstants.navBarPadding,
        child: SizedBox(
          height: barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Subtle localized ambient red glow behind the center of the dock
              Positioned(
                top: -8,
                child: IgnorePointer(
                  child: Container(
                    width: sosSize + 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: NavConstants.sosPrimary.withValues(alpha: 0.14),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Rounded Dock Container (#0B1322 with 1px #263754 border + top edge highlight)
              ClipRRect(
                borderRadius: BorderRadius.circular(NavConstants.navBarRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: NavConstants.navSurface.withValues(alpha: 0.96),
                      borderRadius:
                          BorderRadius.circular(NavConstants.navBarRadius),
                      border: Border.all(
                        color: NavConstants.navBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        // Soft dark floating elevation shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                        // Subtle ambient shadow
                        BoxShadow(
                          color: const Color(0xFF040812).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Top 1px subtle highlight edge along the capsule
                        Positioned(
                          top: 0,
                          left: 24,
                          right: 24,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF6482AD).withValues(alpha: 0.32),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Evenly distributed left & right navigation items with center spacer
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              NavItem(
                                label: 'Chat',
                                icon: Icons.chat_bubble_outline_rounded,
                                isSelected: currentIndex == 0,
                                onTap: () => onTabSelected(0),
                              ),
                              NavItem(
                                label: 'Map',
                                icon: Icons.map_outlined,
                                isSelected: currentIndex == 1,
                                onTap: () => onTabSelected(1),
                              ),
                              // Space reserved for the elevated center SOS button
                              SizedBox(width: sosSize + 22),
                              NavItem(
                                label: 'Tools',
                                icon: Icons.handyman_outlined,
                                isSelected: currentIndex == 3,
                                onTap: () => onTabSelected(3),
                              ),
                              NavItem(
                                label: 'AI',
                                icon: Icons.psychology_outlined,
                                isSelected: currentIndex == 4,
                                onTap: () => onTabSelected(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Elevated Protruding Central SOS Button
              Positioned(
                top: -18,
                child: FloatingSOSButton(
                  isActive: currentIndex == 2,
                  size: sosSize,
                  onSelectSosTab: () => onTabSelected(2),
                  onHoldTriggered: onSosHoldTriggered,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
