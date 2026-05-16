import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/tanaman_article.dart';
import '../../utils/asset_helper.dart';

class TanamanArticleDetailScreen extends StatelessWidget {
  final TanamanArticle article;

  const TanamanArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_image_${article.id}',
                child: Image.asset(
                  AssetHelper.getArticleImagePath(article.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      AssetHelper.getImagePath(
                        article.imagePath.replaceFirst('assets/images/', ''),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    article.formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content
                  Text(
                    article.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tags
                  if (article.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: article.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Bottom spacing for nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
