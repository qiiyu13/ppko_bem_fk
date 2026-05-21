import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/superadmin_badge.dart';

class MedicalTab extends StatelessWidget {
  const MedicalTab({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Laporan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: const [SuperadminBadge()],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_chart_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                Text(
                  'Laporan & Analitik',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Text(
                  'Tren screening per desa, throughput admin, dan ekspor data akan tersedia di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.paddingMedium,
                    vertical: ResponsiveSize.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Segera Hadir',
                    style: TextStyle(
                      color: AppColors.statusAmber,
                      fontSize: ResponsiveSize.fontSmall,
                      fontWeight: FontWeight.w700,
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
}
