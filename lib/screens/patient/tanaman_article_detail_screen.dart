import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../constants/app_colors.dart';
import '../../models/tanaman_article.dart';
import '../../widgets/article_image.dart';

class TanamanArticleDetailScreen extends StatefulWidget {
  final TanamanArticle article;

  const TanamanArticleDetailScreen({super.key, required this.article});

  @override
  State<TanamanArticleDetailScreen> createState() =>
      _TanamanArticleDetailScreenState();
}

class _TanamanArticleDetailScreenState
    extends State<TanamanArticleDetailScreen> {
  late final QuillController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController(
      document: _parseContent(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // Content is stored as Quill Delta JSON. Legacy/seed articles hold plain
  // text, so fall back to a single insert when it isn't a Delta array.
  Document _parseContent() {
    final raw = widget.article.content.trim();
    if (raw.startsWith('[')) {
      try {
        return Document.fromJson(
          List<dynamic>.from(jsonDecode(raw) as List),
        );
      } catch (_) {}
    }
    return Document()..insert(0, raw.isEmpty ? '' : raw);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
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
                child: ArticleImage(
                  imagePath: article.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
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

                  // Content (rich text)
                  QuillEditor.basic(
                    controller: _contentController,
                    config: const QuillEditorConfig(
                      scrollable: false,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      padding: EdgeInsets.zero,
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
