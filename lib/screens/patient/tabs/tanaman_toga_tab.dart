import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/tanaman_article.dart';
import '../../../services/article_service.dart';
import '../../../utils/asset_helper.dart';
import '../tanaman_article_detail_screen.dart';

class TanamanTogaTab extends StatefulWidget {
  const TanamanTogaTab({super.key});

  @override
  State<TanamanTogaTab> createState() => _TanamanTogaTabState();
}

class _TanamanTogaTabState extends State<TanamanTogaTab> {
  List<TanamanArticle> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await ArticleService.getPublishedArticles();
      setState(() {
        _articles = articles.where((a) => a.imagePath.isNotEmpty).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      // Fallback to mock data if API fails
      final mockArticles = TanamanArticle.getMockArticles()
          .where((a) => a.isPublished && !a.isDeleted && a.imagePath.isNotEmpty)
          .toList();
      setState(() {
        _articles = mockArticles;
        _isLoading = false;
        _error = 'Gagal memuat artikel dari server. Menampilkan data lokal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.warning.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // Article List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadArticles,
                color: AppColors.primary,
                child: _articles.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada artikel',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _articles.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: AppColors.divider,
                          indent: 96,
                        ),
                        itemBuilder: (context, index) {
                          final article = _articles[index];
                          return _ArticleCard(article: article);
                        },
                      ),
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
                        AssetHelper.getArticleImagePath(article.imagePath),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            AssetHelper.getImagePath(
                              article.imagePath.replaceFirst('assets/images/', ''),
                            ),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          );
                        },
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
