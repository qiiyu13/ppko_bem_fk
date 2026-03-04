import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Custom clipper that creates a gentle, UNNES-style circular notch
/// in the top-center of the bar using smooth cubic bezier curves.
class BottomBarNotchClipper extends CustomClipper<Path> {
  final double notchWidth;
  final double notchDepth;

  BottomBarNotchClipper({required this.notchWidth, required this.notchDepth});

  @override
  Path getClip(Size size) {
    final double centerX = size.width / 2;
    final double w = notchWidth;
    final double depth = notchDepth;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - w, 0);

    // Use quadratic bezier for deep bowl-shaped curve
    path.quadraticBezierTo(centerX, depth, centerX + w, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BottomBarNotchClipper oldClipper) {
    return oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth;
  }
}

/// Paints a shadow for the notched bar shape.
/// This is drawn BEHIND the clipped white bar so the shadow is visible
/// around the entire edge, including the notch curve.
class _NavBarShadowPainter extends CustomPainter {
  final double notchWidth;
  final double notchDepth;

  _NavBarShadowPainter({required this.notchWidth, required this.notchDepth});

  @override
  void paint(Canvas canvas, Size size) {
    final path = BottomBarNotchClipper(
      notchWidth: notchWidth,
      notchDepth: notchDepth,
    ).getClip(size);

    // Draw multiple blurred strokes for a soft shadow around the edges
    for (int i = 3; i >= 1; i--) {
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i * 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 2.0);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NavBarShadowPainter oldDelegate) {
    return oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth;
  }
}

/// The bottom navigation bar with a notched cutout in the center.
/// Uses ClipPath for a guaranteed-transparent notch and CustomPaint
/// for the shadow effect.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  static const double barHeight = 65;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate clamped notch width: 16% of screen, min 50px, max 80px
    final double notchWidth = (screenWidth * 0.16).clamp(50.0, 80.0);
    // Shallow curve: 135% of notch width for gentle U-shape
    final double notchDepth = notchWidth * 1.35;
    // Spacer matches the notch width
    final double notchSpacerWidth = notchWidth * 2;

    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          // Shadow layer (behind the clipped bar)
          Positioned.fill(
            child: CustomPaint(
              painter: _NavBarShadowPainter(
                notchWidth: notchWidth,
                notchDepth: notchDepth,
              ),
            ),
          ),
          // White bar clipped with transparent notch
          ClipPath(
            clipper: BottomBarNotchClipper(
              notchWidth: notchWidth,
              notchDepth: notchDepth,
            ),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Left side: Home and Jadwal (flex: 37% each side)
                  Expanded(
                    flex: 37,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(context, Icons.home_outlined, 'Home', 0),
                        _buildNavItem(
                          context,
                          Icons.event_outlined,
                          'Jadwal',
                          1,
                        ),
                      ],
                    ),
                  ),
                  // Responsive spacer for center notch (36% of width)
                  SizedBox(width: notchSpacerWidth),
                  // Right side: Profil and Settings (flex: 37% each side)
                  Expanded(
                    flex: 37,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          context,
                          Icons.person_outline,
                          'Profil',
                          3,
                        ),
                        _buildNavItem(
                          context,
                          Icons.settings_outlined,
                          'Setelan',
                          4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isSelected = currentIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive sizing for icons and fonts based on screen width
    final iconSize = screenWidth < 360
        ? 20.0
        : (screenWidth < 400 ? 22.0 : 24.0);
    final fontSize = screenWidth < 360
        ? 9.0
        : (screenWidth < 400 ? 10.0 : 11.0);

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: screenWidth < 360 ? 50 : 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// The animated center button that floats independently of the navbar.
class CenterActionButton extends StatelessWidget {
  final double animationValue;
  final double size;
  final VoidCallback onTap;

  const CenterActionButton({
    super.key,
    required this.animationValue,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.55;
    final bool isSendMode = animationValue > 0.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(80),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: isSendMode
                ? Icon(
                    Icons.send_rounded,
                    key: const ValueKey('send'),
                    color: AppColors.textOnPrimary,
                    size: iconSize,
                  )
                : SizedBox(
                    key: const ValueKey('heart'),
                    width: iconSize,
                    height: iconSize,
                    child: SvgPicture.asset(
                      'assets/svg/heart_pulse.svg',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textOnPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
