import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_size.dart';

class StatCell extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool showIndicator;
  final double valueFontSize;

  const StatCell({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.showIndicator = false,
    this.valueFontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIndicator) ...[
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
        ],
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: showIndicator ? AppColors.textPrimary : color,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: showIndicator ? ResponsiveSize.spacingSmall * 0.25 : 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
