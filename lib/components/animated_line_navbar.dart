import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AnimatedLineNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;
  final Color selectedColor;
  final Color unselectedColor;
  final Color backgroundColor;
  final double indicatorWidth;
  final Duration animationDuration;

  const AnimatedLineNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.selectedColor,
    required this.unselectedColor,
    this.backgroundColor = AppColors.background,
    this.indicatorWidth = 0.6,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;
            final indicatorWidthPx = tabWidth * indicatorWidth;

            return SizedBox(
              height: 70,
              child: Stack(
                children: [
                  // Tab items row
                  Row(
                    children: List.generate(
                      items.length,
                      (index) => Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    currentIndex == index
                                        ? items[index].activeIcon
                                        : items[index].icon,
                                    key: ValueKey<int>(
                                      currentIndex == index
                                          ? index + 100
                                          : index,
                                    ),
                                    color: currentIndex == index
                                        ? selectedColor
                                        : unselectedColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  style: TextStyle(
                                    color: currentIndex == index
                                        ? selectedColor
                                        : unselectedColor,
                                    fontSize: 11,
                                    fontWeight: currentIndex == index
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  child: Text(items[index].label),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Animated indicator line
                  AnimatedPositioned(
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left:
                        (currentIndex * tabWidth) +
                        (tabWidth - indicatorWidthPx) / 2,
                    child: Container(
                      width: indicatorWidthPx,
                      height: 3,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
