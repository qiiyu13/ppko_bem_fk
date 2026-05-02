import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import '../../../services/api_service.dart';
import '../admin_patient_detail_screen.dart';
import '../qr_scanner_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const Color normalGreen = Color(0xFF4CAF50);

  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _patients = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
      _currentPage = 1;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      final response = await ApiService.get(
        '/admin/patients',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'] ?? [];
      final meta = response.data['meta'];

      setState(() {
        if (loadMore) {
          _patients.addAll(data.cast<Map<String, dynamic>>());
        } else {
          _patients = data.cast<Map<String, dynamic>>();
        }
        _totalCount = meta?['total'] ?? _patients.length;
        _totalPages = meta?['totalPages'] ?? 1;
      });
    } catch (e) {
      if (!loadMore) {
        setState(() {
          _patients = [];
          _totalCount = 0;
        });
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

  List<Map<String, dynamic>> get _filteredPatients {
    return _patients.where((patient) {
      final riskLevel = _getRiskCategory(patient) ?? 'normal';
      if (_selectedFilter != 'All') {
        final riskMap = {
          'High Risk': 'high',
          'Attention': 'attention',
          'Normal': 'normal',
        };
        if (riskLevel != riskMap[_selectedFilter]) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, int> get _riskCounts {
    return {
      'All': _patients.length,
      'High Risk': _patients.where((p) => _getRiskCategory(p) == 'high').length,
      'Attention': _patients.where((p) => _getRiskCategory(p) == 'attention').length,
      'Normal': _patients.where((p) {
        final c = _getRiskCategory(p);
        return c == null || c == 'normal';
      }).length,
    };
  }

  void _showActionModal(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  patient['name'],
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Text(
                  'NIK: ${patient['nik']}',
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
                  color: normalGreen,
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
    final responsive = ResponsiveSize();
    responsive.init(context);

    final riskCounts = _riskCounts;
    final highRiskCount = riskCounts['High Risk'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                color: AppColors.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                          size: ResponsiveSize.iconLarge,
                        ),
                        SizedBox(width: ResponsiveSize.paddingSmall),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEDIKU',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontLarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Monitoring Dashboard',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textPrimary,
                            size: ResponsiveSize.iconMedium,
                          ),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

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
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                                _fetchPatients();
                              },
                              decoration: InputDecoration(
                                hintText: 'Search NIK or Name...',
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
                                  horizontal: ResponsiveSize.paddingMedium,
                                  vertical: ResponsiveSize.paddingMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveSize.paddingSmall),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.paddingMedium,
                            vertical: ResponsiveSize.paddingSmall,
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
                          _buildFilterChip(
                            'All',
                            riskCounts['All'] ?? 0,
                            AppColors.textPrimary,
                          ),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip(
                            'High Risk',
                            riskCounts['High Risk'] ?? 0,
                            AppColors.error,
                          ),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip(
                            'Attention',
                            riskCounts['Attention'] ?? 0,
                            AppColors.warning,
                          ),
                          SizedBox(width: ResponsiveSize.paddingSmall),
                          _buildFilterChip(
                            'Normal',
                            riskCounts['Normal'] ?? 0,
                            normalGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.paddingMedium,
                  vertical: ResponsiveSize.spacingMedium,
                ),
                color: AppColors.card,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Screened',
                        _totalCount.toString(),
                        AppColors.textPrimary,
                        Icons.people_outline,
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall),
                    Expanded(
                      child: _buildStatCard(
                        'High Risk',
                        highRiskCount.toString(),
                        AppColors.error,
                        Icons.warning_amber,
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                color: AppColors.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Patient List',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontXLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final patient = _filteredPatients[index];
                  return _buildPatientCard(patient);
                }, childCount: _filteredPatients.length),
              ),

            if (_currentPage < _totalPages)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.paddingMedium,
                    vertical: ResponsiveSize.spacingMedium,
                  ),
                  child: _isLoadingMore
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _loadMore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Muat Lebih Banyak'),
                        ),
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.paddingMedium,
          vertical: ResponsiveSize.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.surface,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.paddingSmall * 0.5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? color : color,
                    fontSize: ResponsiveSize.fontSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingSmall,
        vertical: ResponsiveSize.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.3)
              : AppColors.surface,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: ResponsiveSize.iconMedium),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final riskCategory = _getRiskCategory(patient);
    final riskLevel = riskCategory ?? 'normal';
    final riskColor = riskLevel == 'high'
        ? AppColors.error
        : riskLevel == 'attention'
        ? AppColors.warning
        : normalGreen;
    final riskLabel = riskLevel == 'high'
        ? 'High Risk'
        : riskLevel == 'attention'
        ? 'Attention'
        : 'Normal';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPatientDetailScreen(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'],
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                        Text(
                          'NIK: ${patient['nik']}',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      riskLabel,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: riskColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacingMedium),
              if (patient['village'] != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: ResponsiveSize.iconSmall,
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
                    Text(
                      patient['village'],
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
