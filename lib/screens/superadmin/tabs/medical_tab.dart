import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import '../screens/jadwal_management_screen.dart';
import '../screens/medical_screening_screen.dart';
import '../screens/tambah_pasien_screen.dart';

class MedicalTab extends StatelessWidget {
  const MedicalTab({super.key});

  static const Color blueAccent = Color(0xFF2196F3);
  static const Color greenAccent = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Manajemen Medis',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih aktivitas yang ingin dilakukan',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontMedium,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: ResponsiveSize.spacingXLarge),

              _buildOptionCard(
                context,
                icon: Icons.assignment_outlined,
                title: 'Screening Pasien',
                subtitle:
                    'Tambah data screening untuk pasien yang sudah terdaftar',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicalScreeningScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: ResponsiveSize.spacingMedium),

              _buildOptionCard(
                context,
                icon: Icons.person_add_outlined,
                title: 'Tambah Pasien Baru',
                subtitle:
                    'Daftarkan pasien baru dan langsung tambahkan data screening',
                color: blueAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TambahPasienScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: ResponsiveSize.spacingMedium),

              _buildOptionCard(
                context,
                icon: Icons.calendar_today_outlined,
                title: 'Kelola Jadwal',
                subtitle: 'Atur jadwal pemeriksaan dan screening massal',
                color: greenAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JadwalManagementScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: ResponsiveSize.iconLarge),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
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
      ),
    );
  }
}
