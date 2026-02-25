import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key});

  static const Color purpleAccent = Color(0xFF9C27B0);
  static const Color orangeAccent = Color(0xFFFF9800);

  static const String adminName = 'Admin Desa';

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

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
                          adminName,
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
                            '24 Oktober 2023',
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
                      '1,240',
                      Icons.people,
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Screening Hari Ini',
                      '15',
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
                      '3',
                      Icons.calendar_today,
                      purpleAccent,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Perlu Perhatian',
                      '5',
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

              // Activity List
              _buildActivityItem(
                'Pasien Baru Terdaftar',
                'Budi Santoso telah terdaftar',
                '2 jam lalu',
                Icons.person_add,
                AppColors.primary,
              ),
              _buildActivityItem(
                'Screening Selesai',
                '12 pasien selesai screening',
                '4 jam lalu',
                Icons.check_circle,
                AppColors.success,
              ),
              _buildActivityItem(
                'Jadwal Baru',
                'Screening massal RW 01',
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
