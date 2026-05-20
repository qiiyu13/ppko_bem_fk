import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/patient_utils.dart';
import '../../../utils/responsive_size.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_service.dart';
import '../../../services/screening_service.dart';
import '../../../services/region_service.dart';
import '../admin_family_detail_screen.dart';
import '../qr_scanner_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

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

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _loadUser();
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
    });
  }

  Future<Map<String, dynamic>> _safeStats() async {
    try {
      return await ScreeningService.getStats();
    } catch (_) {
      return {'total': 0, 'categories': {}};
    }
  }

  Future<Map<String, dynamic>> _safeRegionStats() async {
    try {
      return await RegionService.getStats();
    } catch (_) {
      return {};
    }
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
        final results = await Future.wait([
          _safeStats(),
          _safeRegionStats(),
          ApiService.get('/admin/patients', queryParameters: queryParams),
        ]);
        final screeningStats = results[0] as Map<String, dynamic>;
        final regionStats = results[1] as Map<String, dynamic>;
        final patientResponse = results[2] as dynamic;
        final List<dynamic> data = patientResponse.data['data'] ?? [];
        final meta = patientResponse.data['meta'];

        if (!mounted) return;

        final categories = screeningStats['categories'] as Map<String, dynamic>? ?? {};
        final profileCount = (regionStats['profileCount'] as num?)?.toInt() ?? 0;
        final highRiskProfiles = (categories['high'] as num?)?.toInt() ?? 0;
        final attentionProfiles = (categories['attention'] as num?)?.toInt() ?? 0;
        final normalProfiles = (categories['normal'] as num?)?.toInt() ?? 0;

        final fallbackTotal = meta?['total'] as int? ?? data.length;
        final fallbackHigh = meta?['totalHighRisk'] as int? ?? 0;
        final fallbackAttention = meta?['totalAttention'] as int? ?? 0;
        final fallbackNormal = meta?['totalNormal'] as int? ?? 0;

        setState(() {
          _patients = data.cast<Map<String, dynamic>>();
          _totalProfiles = profileCount > 0 ? profileCount : fallbackTotal;
          _totalHighRiskProfiles = highRiskProfiles > 0 ? highRiskProfiles : fallbackHigh;
          _totalAttentionProfiles = attentionProfiles > 0 ? attentionProfiles : fallbackAttention;
          _totalNormalProfiles = normalProfiles > 0 ? normalProfiles : fallbackNormal;
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
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
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


  void _showActionModal(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                Text(
                  patient['name'] ?? '-',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Text(
                  'KK: ${patient['nik'] ?? '-'}',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingXLarge),
                _buildActionButton(
                  icon: Icons.phone,
                  title: 'Contact Patient',
                  subtitle: 'Call or message the patient',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildActionButton(
                  icon: Icons.local_hospital,
                  title: 'Refer to Doctor',
                  subtitle: 'Send referral to medical professional',
                  color: AppColors.statusRed,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildActionButton(
                  icon: Icons.check_circle,
                  title: 'Mark as Resolved',
                  subtitle: 'Patient condition has improved',
                  color: AppColors.statusGreen,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildActionButton(
                  icon: Icons.calendar_today,
                  title: 'Schedule Follow-up',
                  subtitle: 'Set next screening appointment',
                  color: AppColors.statusAmber,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingXLarge),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.paddingMedium,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: ResponsiveSize.fontLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: ResponsiveSize.iconMedium),
            ),
            SizedBox(width: ResponsiveSize.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: ResponsiveSize.iconSmall,
            ),
          ],
        ),
      ),
    );
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
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
            SliverToBoxAdapter(child: _buildGreetingHeader()),

            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                color: AppColors.card,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
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
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
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
                        ),
                        SizedBox(width: ResponsiveSize.paddingSmall),
                        Container(
                          height: 44,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.paddingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: ResponsiveSize.iconSmall,
                              ),
                              SizedBox(
                                width: ResponsiveSize.paddingSmall * 0.5,
                              ),
                              Text(
                                'Desa',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: ResponsiveSize.fontMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                                size: ResponsiveSize.iconSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildGreetingHeader() {
    final name = _userName ?? 'Pengguna';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        MediaQuery.of(context).padding.top + ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
      ),
      color: AppColors.card,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    if (_totalHighRiskProfiles > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.statusRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _totalHighRiskProfiles > 9
                                  ? '9+'
                                  : '$_totalHighRiskProfiles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        children: [
          Expanded(
            child: _statCell(
              _totalProfiles,
              'Total Pasien',
              AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _statCell(
              _totalHighRiskProfiles,
              'High Risk',
              AppColors.statusRed,
            ),
          ),
          Expanded(
            child: _statCell(
              _totalAttentionProfiles,
              'Attn',
              AppColors.statusAmber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(int value, String label, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminFamilyDetailScreen(family: patient),
          ),
        );
      },
      onLongPress: () => _showActionModal(patient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
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
