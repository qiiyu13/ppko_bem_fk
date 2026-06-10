import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/tanaman_article.dart';
import '../../../services/article_service.dart';
import '../../../services/websocket_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/article_image.dart';
import '../../../widgets/dashboard/notification_bell.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['Semua', 'Dipublikasikan', 'Draft'];
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _wsSub = WebSocketService.instance.dataUpdateStream.listen((payload) {
      if (payload['type'] == 'articles' && mounted) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) _loadArticles(showLoading: false);
        });
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final articles = await ArticleService.getAllArticles();
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Keep whatever was already on screen; flag error only when empty.
        _hasError = _articles.isEmpty;
      });
      if (_articles.isNotEmpty) {
        _showSnackBar('Gagal memperbarui daftar artikel');
      }
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
      _showSnackBar(result.id.startsWith('local_')
          ? 'Artikel disimpan offline. Akan dikirim saat kembali online.'
          : 'Artikel berhasil dibuat');
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
        title: const Text('Jadikan Draft'),
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
            child: const Text('Jadikan Draft',
                style: TextStyle(color: AppColors.statusAmber)),
          ),
        ],
      ),
    );
  }

  void _publishArticle(TanamanArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publikasikan Artikel'),
        content: Text(
            'Artikel "${article.title}" akan tampil untuk semua pasien. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publikasikan',
                style: TextStyle(color: AppColors.statusGreen)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.statusRed)),
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
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        color: AppColors.primary,
        child: CustomScrollView(
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
          else if (_hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorStateWidget(
                message: 'Gagal memuat artikel.\nPeriksa koneksi lalu coba lagi.',
                onRetry: _loadArticles,
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
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Artikel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.article,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_publishedCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const NotificationBell(),
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
        controller: _searchController,
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
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
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
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
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
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
                  tooltip: 'Opsi artikel',
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
                    final isLive = article.isPublished && !article.isDraft;
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (isLive)
                        const PopupMenuItem(
                          value: 'unpublish',
                          child: Row(
                            children: [
                              Icon(Icons.unpublished,
                                  color: AppColors.statusAmber),
                              SizedBox(width: 8),
                              Text('Jadikan Draft'),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(Icons.publish, color: AppColors.statusGreen),
                              SizedBox(width: 8),
                              Text('Publikasikan'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.statusRed),
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
    final String title;
    if (_searchQuery.trim().isNotEmpty) {
      title = 'Tidak ada artikel yang cocok';
    } else if (_selectedFilter == 'Dipublikasikan') {
      title = 'Belum ada artikel dipublikasikan';
    } else if (_selectedFilter == 'Draft') {
      title = 'Belum ada draft';
    } else {
      title = 'Belum ada artikel';
    }
    return EmptyStateWidget(
      icon: Icons.article_outlined,
      title: title,
      subtitle: _searchQuery.trim().isNotEmpty
          ? 'Coba kata kunci lain'
          : 'Tekan "Artikel Baru" untuk mulai menulis',
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
