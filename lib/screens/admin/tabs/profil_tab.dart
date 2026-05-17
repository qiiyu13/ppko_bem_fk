import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import '../../patient/tabs/settings_tab.dart';

class AdminProfilTab extends StatelessWidget {
  const AdminProfilTab({super.key});

  static const String adminName = 'Dr. Windah Basudara';
  static const String adminId = '1312';
  static const String adminRole = 'Dokter perut';
  static const String adminWilayah = 'Kecamatan Simokerto';
  static const String adminKontak = '081234567890';
  static const String adminAlamat = 'Jl. Kesehatan No. 45, Kec. Simokerto';

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Setelan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsTab(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveSize.spacingLarge),
            _buildUnifiedCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedCard() {
    final avatarSize = ResponsiveSize.screenWidth * 0.22;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        child: Column(
          children: [
            // Zone A — Hero header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                ResponsiveSize.paddingMedium,
                ResponsiveSize.paddingSmall,
                ResponsiveSize.paddingMedium,
                ResponsiveSize.paddingLarge,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveSize.paddingSmall * 0.5,
                        ),
                        child: Text(
                          'ID: $adminId',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.textOnPrimary,
                          size: ResponsiveSize.iconSmall,
                        ),
                        tooltip: 'Edit Profil',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: ResponsiveSize.iconLarge,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  Text(
                    adminName,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.paddingMedium,
                      vertical: ResponsiveSize.paddingSmall * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      adminRole,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zone B — Info rows
            Container(
              width: double.infinity,
              color: AppColors.card,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.paddingMedium,
                vertical: ResponsiveSize.paddingSmall,
              ),
              child: Column(
                children: [
                  _buildInfoRow('Jabatan', adminRole),
                  _buildInfoRow('Wilayah Monitoring', adminWilayah),
                  _buildInfoRow('Kontak', adminKontak),
                  _buildInfoRow('Alamat', adminAlamat, last: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSize.paddingSmall * 1.1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontMedium,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: ResponsiveSize.spacingMedium),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.surface,
          ),
      ],
    );
  }
}
