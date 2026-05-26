import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/tanaman_article.dart';
import '../../../services/article_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/article_image.dart';
import '../article_editor_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});

  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  List<TanamanArticle> _articles = [];
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
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

  int get _publishedCount =>
      _articles.where((a) => a.isPublished && !a.isDraft).length;
  int get _draftCount => _articles.where((a) => a.isDraft).length;

  List<TanamanArticle> get _filteredArticles {
    Iterable<TanamanArticle> list = _articles;
    switch (_selectedFilter) {
      case 'Dipublikasikan':
        list = list.where((a) => a.isPublished && !a.isDraft);
        break;
      case 'Draft':
        list = list.where((a) => a.isDraft);
        break;
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) =>
          a.title.toLowerCase().contains(q) ||
          a.tags.any((t) => t.toLowerCase().contains(q)));
    }
    return list.toList();
  }

  void _createNewArticle() async {
    final result = await Navigator.push(
      context,
      ParallaxPageRoute(
        page: const ArticleEditorScreen(),
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
      ParallaxPageRoute(
        page: ArticleEditorScreen(article: article),
      ),
    );

    if (!mounted) return;
    if (result != null && result is TanamanArticle) {
      // Editor's _saveArticle already persisted to server — just sync local list
      setState(() {
        final index = _articles.indexWhere((a) => a.id == result.id);
        if (index != -1) {
          _articles[index] = result;
        }
      });
      _showSnackBar('Artikel berhasil diperbarui');
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
                if (!mounted) return;
                setState(() {
                  final index = _articles.indexWhere((a) => a.id == article.id);
                  if (index != -1) {
                    _articles[index] = updated;
                  }
                });
                _showSnackBar('Artikel diubah ke draft');
              } catch (e) {
                if (!mounted) return;
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
      if (!mounted) return;
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
                if (!mounted) return;
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
    ResponsiveSize.init(context);
    final articles = _filteredArticles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (articles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              sliver: SliverList.separated(
                itemCount: articles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildArticleCard(articles[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_publish_fab',
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
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        MediaQuery.of(context).padding.top + ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              const Text(
                'Artikel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.article,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_publishedCount',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          _buildSearchField(),
          SizedBox(height: ResponsiveSize.spacingMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _filters.length; i++) ...[
                  _buildFilterChip(_filters[i]),
                  if (i != _filters.length - 1)
                    SizedBox(width: ResponsiveSize.paddingSmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          hintText: 'Cari artikel...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: ResponsiveSize.fontMedium,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Color _filterColor(String label) {
    switch (label) {
      case 'Dipublikasikan':
        return AppColors.statusGreen;
      case 'Draft':
        return AppColors.statusAmber;
      default:
        return AppColors.textPrimary;
    }
  }

  int _filterCount(String label) {
    switch (label) {
      case 'Dipublikasikan':
        return _publishedCount;
      case 'Draft':
        return _draftCount;
      default:
        return _articles.length;
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final color = _filterColor(label);
    final count = _filterCount(label);
    final showDot = label != 'Semua';
    return InkWell(
      onTap: () {
        if (_selectedFilter == label) return;
        setState(() => _selectedFilter = label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textOnPrimary : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(TanamanArticle article) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editArticle(article),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.background,
                    child: ArticleImage(
                      imagePath: article.imagePath,
                      width: 56,
                      height: 56,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: article.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: article.statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '· ${_formatDate(article.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
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
            size: 72,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada artikel ${_selectedFilter.toLowerCase()}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _createNewArticle,
            icon: const Icon(Icons.add),
            label: const Text('Buat Artikel Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}
