import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final Widget fallback;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.fallback,
    required this.size,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final decoration = BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor!, width: borderWidth)
          : null,
    );

    Widget child;
    if (hasImage) {
      child = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(child: fallback),
      );
    } else {
      child = Center(child: fallback);
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: decoration,
        child: child,
      ),
    );
  }
}
