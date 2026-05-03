import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/screening_service.dart';
import '../../../services/admin_service.dart';
import '../../../utils/responsive_size.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const Color purpleAccent = Color(0xFF9C27B0);
  static const Color orangeAccent = Color(0xFFFF9800);

  bool _isLoading = true;
  int _totalPatients = 0;
  int _todayScreenings = 0;
  int _activeSchedules = 0;
  int _needAttention = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ScreeningService.getStats();
      final patientData = await AdminService.getPatients(page: 1, limit: 1);
      final totalPatients = patientData['meta']?['total'] ?? 0;

      final categoryCounts = stats['categories'] as Map<String, dynamic>? ?? {};
      final attentionCount = (categoryCounts['attention'] as num?)?.toInt() ?? 0;
      final highRiskCount = (categoryCounts['high'] as num?)?.toInt() ?? 0;

      setState(() {
        _totalPatients = totalPatients;
        _todayScreenings = (stats['total'] as num?)?.toInt() ?? 0;
        _activeSchedules = 0; // Could be fetched from appointments API
        _needAttention = attentionCount + highRiskCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveSize.spacingMedium),

              // Header with greeting and date
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Pagi,',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                        Text(
                          'Admin Desa',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontXLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.paddingMedium,
                            vertical: ResponsiveSize.paddingSmall * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontSmall,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveSize.spacingXLarge),

              // Section Title
              Text(
                'Ringkasan Desa',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: ResponsiveSize.spacingMedium),

              // Stats Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Pasien',
                      _totalPatients.toString(),
                      Icons.people,
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Total Screening',
                      _todayScreenings.toString(),
                      Icons.medical_services,
                      AppColors.primarySurface,
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveSize.paddingSmall),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Jadwal Aktif',
                      _activeSchedules.toString(),
                      Icons.calendar_today,
                      purpleAccent,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Perlu Perhatian',
                      _needAttention.toString(),
                      Icons.warning,
                      orangeAccent,
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveSize.spacingXLarge),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Terbaru',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: ResponsiveSize.fontMedium,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveSize.spacingMedium),

              // Activity List (still placeholder - would need a real activity API)
              _buildActivityItem(
                'Pasien Baru Terdaftar',
                'Data pasien telah terdaftar',
                '2 jam lalu',
                Icons.person_add,
                AppColors.primary,
              ),
              _buildActivityItem(
                'Screening Selesai',
                'Pasien selesai screening',
                '4 jam lalu',
                Icons.check_circle,
                AppColors.success,
              ),
              _buildActivityItem(
                'Jadwal Baru',
                'Screening massal dijadwalkan',
                '1 hari lalu',
                Icons.calendar_today,
                purpleAccent,
              ),

              // Bottom spacing
              SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: ResponsiveSize.iconSmall),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: ResponsiveSize.iconSmall),
          ),
          SizedBox(width: ResponsiveSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
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
          Text(
            time,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
