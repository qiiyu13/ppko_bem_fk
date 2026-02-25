import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class AdminProfilTab extends StatelessWidget {
  const AdminProfilTab({super.key});

  // Admin hard-coded data
  static const String adminName = 'Dr. Windah Basudara';
  static const String adminId = '1312';
  static const String adminRole = 'Dokter perut';
  static const String adminWilayah = 'Kecamatan Simokerto';
  static const String adminKontak = '081234567890';
  static const String adminAlamat = 'Jl. Kesehatan No. 45, Kec. Simokerto';

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profil Admin',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      // Profile Card - White background
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            ResponsiveSize.cardBorderRadius,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: ResponsiveSize.screenWidth * 0.2,
                              height: ResponsiveSize.screenWidth * 0.2,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.local_hospital,
                                size: ResponsiveSize.iconLarge,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingMedium),
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                adminRole,
                                style: TextStyle(
                                  fontSize: ResponsiveSize.fontMedium,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingSmall),
                            Text(
                              'ID: $adminId',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      // Info Items - White cards with light gray accents
                      _buildInfoItem('ID', adminId),
                      _buildInfoItem('Jabatan', adminRole),
                      _buildInfoItem('Wilayah Monitoring', adminWilayah),
                      _buildInfoItem('Kontak', adminKontak),
                      _buildInfoItem('Alamat', adminAlamat),

                      const Spacer(),

                      SizedBox(height: ResponsiveSize.spacingMedium),

                      // Edit Button - Dark teal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.edit,
                            size: ResponsiveSize.iconSmall,
                            color: AppColors.textOnPrimary,
                          ),
                          label: Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontMedium,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveSize.paddingSmall * 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveSize.buttonBorderRadius,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      // Bottom spacer for nav bar clearance
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingSmall * 1.2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(ResponsiveSize.buttonBorderRadius),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
