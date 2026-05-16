import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/tanaman_article.dart';
import '../../../services/article_service.dart';
import '../article_editor_screen.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});

  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  List<TanamanArticle> _articles = [];
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Dipublikasikan', 'Draft'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await ArticleService.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _articles = TanamanArticle.getMockArticles();
        _isLoading = false;
      });
      _showSnackBar('Gagal memuat artikel dari server. Menampilkan data lokal.');
    }
  }

  List<TanamanArticle> get _filteredArticles {
    switch (_selectedFilter) {
      case 'Dipublikasikan':
        return _articles.where((a) => a.isPublished && !a.isDraft).toList();
      case 'Draft':
        return _articles.where((a) => a.isDraft).toList();
      default:
        return _articles;
    }
  }

  void _createNewArticle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ArticleEditorScreen(),
      ),
    );

    if (!mounted) return;
    if (result != null && result is TanamanArticle) {
      setState(() {
        _articles.insert(0, result);
      });
      _showSnackBar('Artikel berhasil dibuat');
    }
  }

  void _editArticle(TanamanArticle article) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditorScreen(article: article),
      ),
    );

    if (!mounted) return;
    if (result != null && result is TanamanArticle) {
      try {
        final updated = await ArticleService.updateArticle(
          result.id,
          title: result.title,
          content: result.content,
          imagePath: result.imagePath.isNotEmpty ? result.imagePath : null,
          tags: result.tags,
          isDraft: result.isDraft,
          isPublished: result.isPublished,
          updatedAt: result.updatedAt,
        );
        if (!mounted) return;
        setState(() {
          final index = _articles.indexWhere((a) => a.id == updated.id);
          if (index != -1) {
            _articles[index] = updated;
          }
        });
        _showSnackBar('Artikel berhasil diperbarui');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          final index = _articles.indexWhere((a) => a.id == result.id);
          if (index != -1) {
            _articles[index] = result;
          }
        });
        _showSnackBar('Artikel diperbarui secara lokal');
      }
    }
  }

  void _unpublishArticle(TanamanArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish Artikel'),
        content: Text('Artikel "${article.title}" akan diubah ke draft. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updated = await ArticleService.updateArticle(
                  article.id,
                  isDraft: true,
                  isPublished: false,
                  updatedAt: article.updatedAt,
                );
                setState(() {
                  final index = _articles.indexWhere((a) => a.id == article.id);
                  if (index != -1) {
                    _articles[index] = updated;
                  }
                });
                _showSnackBar('Artikel diubah ke draft');
              } catch (e) {
                _showSnackBar('Gagal mengubah status artikel');
              }
            },
            child: const Text('Unpublish', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _publishArticle(TanamanArticle article) async {
    try {
      await ArticleService.publishArticle(article.id, article.updatedAt);
      final updated = article.copyWith(isPublished: true, isDraft: false);
      setState(() {
        final index = _articles.indexWhere((a) => a.id == article.id);
        if (index != -1) {
          _articles[index] = updated;
        }
      });
      _showSnackBar('Artikel berhasil dipublikasikan');
    } catch (e) {
      _showSnackBar('Gagal memublikasikan artikel');
    }
  }

  void _deleteArticle(TanamanArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Artikel'),
        content: Text('Artikel "${article.title}" akan dihapus secara permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ArticleService.deleteArticle(article.id, article.updatedAt);
                setState(() {
                  _articles.removeWhere((a) => a.id == article.id);
                });
                _showSnackBar('Artikel berhasil dihapus');
              } catch (e) {
                _showSnackBar('Gagal menghapus artikel');
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredArticles.isEmpty
                      ? _buildEmptyState()
                      : _buildArticleList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewArticle,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Artikel Baru',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Artikel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_articles.length} artikel',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.article, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_articles.where((a) => a.isPublished && !a.isDraft).length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  }
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArticles.length,
      itemBuilder: (context, index) {
        final article = _filteredArticles[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(TanamanArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editArticle(article),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.background,
                  child: article.imagePath.isNotEmpty
                      ? Image.asset(
                          article.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.image,
                                color: AppColors.primary.withOpacity(0.5),
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.primary.withOpacity(0.5),
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
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: article.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: article.statusColor,
                            ),
                          ),
                        ),
                        if (article.isPublished && !article.isDraft) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Publik',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terakhir diupdate: ${_formatDate(article.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (article.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: article.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editArticle(article);
                      break;
                    case 'unpublish':
                      _unpublishArticle(article);
                      break;
                    case 'publish':
                      _publishArticle(article);
                      break;
                    case 'delete':
                      _deleteArticle(article);
                      break;
                  }
                },
                itemBuilder: (context) {
                  if (article.isPublished && !article.isDraft) {
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'unpublish',
                        child: Row(
                          children: [
                            Icon(Icons.unpublished, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Unpublish'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ];
                  }
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'publish',
                      child: Row(
                        children: [
                          Icon(Icons.publish, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Publikasikan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada artikel ${_selectedFilter.toLowerCase()}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _createNewArticle,
            icon: const Icon(Icons.add),
            label: const Text('Buat Artikel Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes < 1) return 'Baru saja';
        return '${difference.inMinutes} menit lalu';
      }
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}
