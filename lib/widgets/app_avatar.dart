import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAsset;
  final Widget fallback;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    required this.fallback,
    required this.size,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    Widget child;
    if (hasImage) {
      child = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(child: fallback),
      );
    } else if (fallbackAsset != null) {
      child = Image.asset(
        fallbackAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      child = Center(child: fallback);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      foregroundDecoration: borderWidth > 0 && borderColor != null
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!, width: borderWidth),
            )
          : null,
      child: ClipOval(child: child),
    );
  }
}
