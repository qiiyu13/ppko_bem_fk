import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/tanaman_article.dart';
import '../../../utils/asset_helper.dart';
import '../tanaman_article_detail_screen.dart';

class TanamanTogaTab extends StatelessWidget {
  const TanamanTogaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = TanamanArticle.getMockArticles()
        .where((a) => a.isPublished && !a.isDeleted && a.imagePath.isNotEmpty)
        .toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: articles.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 96,
                ),
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return _ArticleCard(article: article);
                },
              ),
            ),

            // Bottom spacing for nav bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final TanamanArticle article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TanamanArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Hero(
              tag: 'article_image_${article.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.imagePath.isNotEmpty
                    ? Image.asset(
                        AssetHelper.getImagePath(article.imagePath.replaceFirst('assets/images/', '')),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppColors.textSecondary.withOpacity(0.5),
                          size: 32,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
