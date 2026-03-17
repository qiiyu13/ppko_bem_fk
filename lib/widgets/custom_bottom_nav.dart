import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/asset_helper.dart';

/// Icon-only floating pill navigation bar with sliding active indicator.
/// Features: 5 evenly-spaced icons, animated sliding circular indicator.
/// Supports both IconData (Flutter icons) and image assets.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  static const double barHeight = 64;
  static const double indicatorSize = 44;

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

    // Responsive icon size
    final iconSize = screenWidth < 360
        ? 22.0
        : screenWidth < 400
        ? 24.0
        : 26.0;

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
                      iconSize: iconSize,
                    ),
                    _buildNavItem(
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_today,
                      index: 1,
                      iconSize: iconSize,
                    ),
                    _buildNavItem(
                      imagePath: AssetHelper.getIconPath('leaf_icon.png'),
                      index: 2,
                      iconSize: iconSize,
                    ),
                    _buildNavItem(
                      imagePath: AssetHelper.getIconPath('chat.png'),
                      index: 3,
                      iconSize: iconSize,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      index: 4,
                      iconSize: iconSize,
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
    IconData? icon,
    IconData? activeIcon,
    required int index,
    required double iconSize,
    String? imagePath,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: imagePath != null
                ? _buildImageIcon(imagePath, isSelected, iconSize, index)
                : _buildMaterialIcon(
                    icon: isSelected ? activeIcon! : icon!,
                    isSelected: isSelected,
                    iconSize: iconSize,
                    index: index,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialIcon({
    required IconData icon,
    required bool isSelected,
    required double iconSize,
    required int index,
  }) {
    return Icon(
      icon,
      key: ValueKey<int>(isSelected ? index + 100 : index),
      color: isSelected
          ? AppColors.primary
          : AppColors.textOnPrimary.withValues(alpha: 0.6),
      size: iconSize * 1.15,
    );
  }

  Widget _buildImageIcon(
    String imagePath,
    bool isSelected,
    double iconSize,
    int index,
  ) {
    // Multiply size by 1.15 to match visual size of Material icons (reduced from 1.3)
    final adjustedSize = iconSize * 1.15;
    return ColorFiltered(
      key: ValueKey<int>(isSelected ? index + 100 : index),
      colorFilter: ColorFilter.mode(
        isSelected
            ? AppColors.primary
            : AppColors.textOnPrimary.withValues(alpha: 0.6),
        BlendMode.srcIn,
      ),
      child: Image.asset(
        imagePath,
        width: adjustedSize,
        height: adjustedSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
