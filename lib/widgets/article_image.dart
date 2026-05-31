import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../constants/app_colors.dart';
import '../utils/asset_helper.dart';

/// Renders an article cover image. Uploaded images come back as
/// `/uploads/...` paths (served over the network); seeded demo articles
/// reference bundled assets like `assets/images/Jahe.webp`.
class ArticleImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ArticleImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork =>
      imagePath.startsWith('/uploads') || imagePath.startsWith('http');

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.image_not_supported,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) return _placeholder();

    if (_isNetwork) {
      final url = imagePath.startsWith('http')
          ? imagePath
          : '${Env.serverBaseUrl}$imagePath';
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }

    return Image.asset(
      AssetHelper.getArticleImagePath(imagePath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }
}
