import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/patient_utils.dart';
import '../../../utils/responsive_size.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/dashboard/greeting_header.dart';
import '../../../widgets/dashboard/stat_cell.dart';
import '../admin_family_detail_screen.dart';
import '../qr_scanner_screen.dart';
import '../../superadmin/screens/screening_report_screen.dart';
import 'package:mediku/utils/page_transitions.dart';
import 'package:mediku/config/env.dart';
import 'package:mediku/widgets/app_avatar.dart';

class DashboardTab extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const DashboardTab({super.key, this.onSwitchTab});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _patients = [];
  int _totalProfiles = 0;
  int _totalHighRiskProfiles = 0;
  int _totalAttentionProfiles = 0;
  int _totalNormalProfiles = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  Timer? _searchDebounce;
  String? _userName;
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _loadUser();
    AuthService.avatarRevision.addListener(_loadUser);
    NotificationService.instance.fetchFromApi();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    AuthService.avatarRevision.removeListener(_loadUser);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final cachedName = await TokenService.getResponsibleName();
    if (mounted && cachedName != null && cachedName.isNotEmpty) {
      setState(() => _userName = cachedName);
    }
    final me = await AuthService.getMe();
    if (!mounted || me == null) return;
    final name = (me['name'] ?? me['responsibleName']) as String? ?? _userName;
    setState(() {
      _userName = name;
      _userAvatarUrl = AuthService.userAvatarUrl(me);
    });
  }


  Future<void> _fetchPatients({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
      _currentPage = 1;
    }

    try {
      final irdCategoryMap = {
        'High Risk': 'high',
        'Attention': 'attention',
        'Normal': 'normal',
      };
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_selectedFilter != 'All') queryParams['irdCategory'] = irdCategoryMap[_selectedFilter];

      if (loadMore) {
        final response = await ApiService.get(
          '/admin/patients',
          queryParameters: queryParams,
        );
        final List<dynamic> data = response.data['data'] ?? [];
        final meta = response.data['meta'];

        setState(() {
          _patients.addAll(data.cast<Map<String, dynamic>>());
          _totalPages = meta?['totalPages'] ?? 1;
        });
      } else {
        final response = await ApiService.get('/admin/patients', queryParameters: queryParams);
        final List<dynamic> data = response.data['data'] ?? [];
        final meta = response.data['meta'];

        if (!mounted) return;

        final total = meta?['total'] as int? ?? data.length;
        final high = meta?['totalHighRisk'] as int? ?? 0;
        final attention = meta?['totalAttention'] as int? ?? 0;
        final normal = meta?['totalNormal'] as int? ?? 0;

        setState(() {
          _patients = data.cast<Map<String, dynamic>>();
          _totalProfiles = (high + attention + normal) > 0 ? (high + attention + normal) : total;
          _totalHighRiskProfiles = high;
          _totalAttentionProfiles = attention;
          _totalNormalProfiles = normal;
          _totalPages = meta?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      if (!loadMore) {
        if (!mounted) return;
        setState(() {
          _patients = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data pasien')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_currentPage < _totalPages && !_isLoadingMore) {
      _currentPage++;
      _fetchPatients(loadMore: true);
    }
  }

  String? _getRiskCategory(Map<String, dynamic> patient) {
    final latestIrd = patient['latestIrd'];
    if (latestIrd is Map) {
      return latestIrd['irdCategory'] as String?;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_dashboard_fab',
        onPressed: () {
          Navigator.push(
            context,
            ParallaxPageRoute(page: const QrScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
            SliverToBoxAdapter(
              child: GreetingHeader(
                name: _userName,
                fallbackName: 'Pengguna',
                imageUrl: _userAvatarUrl,
                onReportPressed: () {
                  Navigator.push(
                    context,
                    ParallaxPageRoute(page: const ScreeningReportScreen()),
                  );
                },
                onProfilePressed: () => widget.onSwitchTab?.call(3),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                color: AppColors.card,
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                            setState(() {
                              _searchQuery = value;
                            });
                            _fetchPatients();
                          });
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          hintText: 'Cari KK atau NIK...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: ResponsiveSize.fontMedium,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: ResponsiveSize.iconSmall,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.paddingSmall,
                            vertical: ResponsiveSize.paddingSmall,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingMedium),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', _totalProfiles, AppColors.textPrimary),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip('High Risk', _totalHighRiskProfiles, AppColors.statusRed),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip('Attention', _totalAttentionProfiles, AppColors.statusAmber),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip('Normal', _totalNormalProfiles, AppColors.statusGreen),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildStatsRow()),

            SliverToBoxAdapter(child: _buildListBlock()),

            SliverToBoxAdapter(
              child: SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            ),
          ],
        ),
      ),
    );
  }  // AnnotatedRegion closes Scaffold above

  Widget _buildFilterChip(String label, int count, Color color) {
    final isSelected = _selectedFilter == label;
    final showDot = label != 'All';
    return InkWell(
      onTap: () {
        if (_selectedFilter == label) return;
        setState(() => _selectedFilter = label);
        _fetchPatients();
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
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
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

  Widget _buildStatsRow() {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: StatCell(
              value: _totalProfiles,
              label: 'Total Pasien',
              color: AppColors.textPrimary,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.divider),
          Expanded(
            child: StatCell(
              value: _totalHighRiskProfiles,
              label: 'High Risk',
              color: AppColors.statusRed,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.divider),
          Expanded(
            child: StatCell(
              value: _totalAttentionProfiles,
              label: 'Attention',
              color: AppColors.statusAmber,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.divider),
          Expanded(
            child: StatCell(
              value: _totalNormalProfiles,
              label: 'Normal',
              color: AppColors.statusGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBlock() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_patients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(Icons.person_search,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada warga ditemukan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: ResponsiveSize.fontMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              _selectedFilter == 'All'
                  ? _buildGroupedList()
                  : _buildFlatList(),
            if (!_isLoading && _patients.isNotEmpty && _currentPage < _totalPages)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _isLoadingMore ? null : _loadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Muat Lebih Banyak'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatList() {
    return Column(
      children: [
        for (var i = 0; i < _patients.length; i++) ...[
          _buildPatientCard(_patients[i]),
          if (i != _patients.length - 1)
            Container(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }

  Widget _buildGroupedList() {
    final highRisk = _patients
        .where((p) => _getRiskCategory(p) == 'high')
        .toList();
    final attention = _patients
        .where((p) => _getRiskCategory(p) == 'attention')
        .toList();
    final normal = _patients
        .where((p) => _getRiskCategory(p) == 'normal')
        .toList();
    final other = _patients
        .where((p) {
          final c = _getRiskCategory(p);
          return c != 'high' && c != 'attention' && c != 'normal';
        })
        .toList();

    final sections = <Widget>[];
    void addSection(String label, Color color, List<Map<String, dynamic>> list) {
      if (list.isEmpty) return;
      sections.add(_buildSectionHeader(label, list.length, color));
      for (var i = 0; i < list.length; i++) {
        sections.add(_buildPatientCard(list[i]));
        if (i != list.length - 1) {
          sections.add(Container(height: 1, color: AppColors.divider));
        }
      }
    }

    addSection('High Risk', AppColors.statusRed, highRisk);
    addSection('Attention', AppColors.statusAmber, attention);
    addSection('Normal', AppColors.statusGreen, normal);
    addSection('Lainnya', AppColors.textSecondary, other);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  Widget _buildSectionHeader(String label, int count, Color color) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count keluarga',
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  String _formatScreeningDate(Map<String, dynamic> patient) {
    final latestIrd = patient['latestIrd'];
    if (latestIrd is! Map) return '';
    final raw = latestIrd['screeningAt']?.toString() ?? '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final riskLevel = _getRiskCategory(patient) ?? 'normal';
    final riskColor = PatientUtils.riskColor(riskLevel);
    final name = (patient['name'] as String?) ?? '-';
    final initial = name.isNotEmpty && name != '-'
        ? name.replaceFirst(RegExp(r'^Keluarga\s+', caseSensitive: false), '')[0]
            .toUpperCase()
        : '?';
    final kk = (patient['nik'] as String?) ?? '';
    final kkTail = kk.length > 3 ? kk.substring(kk.length - 3) : kk;
    final lastScreened = _formatScreeningDate(patient);
    final subtitle = [
      if (kkTail.isNotEmpty) 'KK …$kkTail',
      if (lastScreened.isNotEmpty) lastScreened,
    ].join(' · ');
    final avatarPath = patient['avatarPath'] as String?;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? '${Env.serverBaseUrl}$avatarPath'
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          ParallaxPageRoute(
            page: AdminFamilyDetailScreen(family: patient),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: avatarUrl,
              size: 36,
              backgroundColor: riskColor.withValues(alpha: 0.15),
              fallback: Text(
                initial,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: ResponsiveSize.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}
