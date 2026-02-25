import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import 'dart:ui';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
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
                          color: AppColors.card,
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
                                Icons.person,
                                size: ResponsiveSize.iconLarge,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingMedium),
                            Text(
                              'Pak Budi Santoso',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontXLarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                            Text(
                              'NIK: 3375011234567890',
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
                      _buildInfoItem('Umur', '65 Tahun'),
                      _buildInfoItem('Golongan Darah', 'O+'),
                      _buildInfoItem(
                        'Alamat',
                        'Desa Ngemplak, Kecamatan Simokerto',
                      ),
                      _buildInfoItem('Nomor Telepon', '081234567890'),

                      const Spacer(),

                      SizedBox(height: ResponsiveSize.spacingMedium),

                      // Edit Button - Dark teal (like MASUK button)
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
                            foregroundColor: AppColors.background,
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
      padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
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
