import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Icon-only floating pill navigation bar with sliding active indicator.
/// Features: 5 evenly-spaced Material icons, animated sliding circular indicator.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  static const double barHeight = 64;
  static const double indicatorSize = 44;
  static const double iconSize = 28;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive margins based on screen size
    final horizontalMargin = screenWidth < 360
        ? 16.0
        : screenWidth < 400
        ? 20.0
        : 24.0;

    // Max width constraint to prevent stretching on large screens
    final maxWidth = screenWidth < 500
        ? screenWidth - (horizontalMargin * 2)
        : 420.0;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        width: maxWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5;

            return Stack(
              children: [
                // Animated sliding indicator (circular)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  left:
                      (currentIndex * itemWidth) +
                      (itemWidth - indicatorSize) / 2,
                  top: (barHeight - indicatorSize) / 2,
                  child: Container(
                    width: indicatorSize,
                    height: indicatorSize,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                // Row of 5 icon buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.event_note_outlined,
                      activeIcon: Icons.event_note,
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.eco_outlined,
                      activeIcon: Icons.eco,
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.chat_outlined,
                      activeIcon: Icons.chat,
                      index: 3,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      index: 4,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(32),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey<int>(isSelected ? index + 100 : index),
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textOnPrimary.withValues(alpha: 0.6),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
