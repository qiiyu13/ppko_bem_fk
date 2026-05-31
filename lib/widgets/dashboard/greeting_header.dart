import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_size.dart';
import 'package:mediku/widgets/app_avatar.dart';
import 'notification_bell.dart';

class GreetingHeader extends StatelessWidget {
  final String? name;
  final String fallbackName;
  final String? roleBadge;
  final Color? roleBadgeColor;
  final String? imageUrl;
  final String? fallbackAsset;
  final bool bareFallbackAsset;
  final VoidCallback? onReportPressed;
  final VoidCallback? onProfilePressed;

  const GreetingHeader({
    super.key,
    required this.name,
    this.fallbackName = 'Pengguna',
    this.roleBadge,
    this.roleBadgeColor,
    this.imageUrl,
    this.fallbackAsset,
    this.bareFallbackAsset = false,
    this.onReportPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.isEmpty) ? fallbackName : name!;
    final initial = displayName[0].toUpperCase();

    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        MediaQuery.of(context).padding.top + ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
      ),
      color: AppColors.card,
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfilePressed,
            child: bareFallbackAsset &&
                    (imageUrl == null || imageUrl!.isEmpty) &&
                    fallbackAsset != null
                ? Image.asset(
                    fallbackAsset!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  )
                : AppAvatar(
                    imageUrl: imageUrl,
                    fallbackAsset: fallbackAsset,
                    size: 44,
                    backgroundColor: AppColors.primary,
                    fallback: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: GestureDetector(
              onTap: onProfilePressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (roleBadge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (roleBadgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (roleBadgeColor ?? AppColors.primary).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        roleBadge!,
                        style: TextStyle(
                          color: roleBadgeColor ?? AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onReportPressed != null)
            GestureDetector(
              onTap: onReportPressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          const NotificationBell(),
        ],
      ),
    );
  }
}
