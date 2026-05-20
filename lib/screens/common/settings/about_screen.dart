import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.medical_services, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'MEDIKU',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Versi $_version',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Deskripsi',
            child: const Text(
              'MEDIKU adalah aplikasi kesehatan komunitas untuk mempermudah akses skrining, pencatatan rekam medis, janji temu, dan konsultasi tim medis di tingkat RT/RW.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
            ),
          ),
          _section(
            title: 'Tim Pengembang',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PPKO BEM FK 2026',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                SizedBox(height: 6),
                Text(
                  'Program Penguatan Kapasitas Organisasi Mahasiswa\nBadan Eksekutif Mahasiswa Fakultas Kedokteran',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text('Made with ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Icon(Icons.favorite, size: 14, color: Colors.red),
                    Text(' by qyu (Fiqi)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          _section(
            title: 'Kontak',
            child: const Text(
              'fiqifirmansyah5535@gmail.com',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          _section(
            title: 'Lisensi',
            child: const Text(
              '© 2026 PPKO BEM FK. Hak cipta dilindungi.\nDistribusi terbatas untuk komunitas binaan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
