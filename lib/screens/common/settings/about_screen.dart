import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _members = [
    'Oktavia Kurniawati',
    'Aida Maghfiroh',
    'Fathurrahman Muhammad',
    'Zoar Lewi Panjaitan',
    'Ivani Ramadhani Putri P',
    'Aulia Zaziroturrohmah',
    'Edward Joshua Sibarani',
    'Diva Ayu Hafsari Dewi',
    'Nayara Raya Kanahaya',
    'Fany Fitria Salsabilla',
    'Damar Syahid Nugraha',
    'Amalina Nayla Putri',
    'N. Rania Danisya Adriani',
    'Rintis Aulia Maharani',
    'Muhammad Fiqi Firmansyah',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _section(
                  title: 'Deskripsi',
                  child: const Text(
                    'MEDIKU adalah aplikasi kesehatan komunitas untuk mempermudah akses skrining, pencatatan rekam medis, janji temu, dan konsultasi tim medis di tingkat RT/RW.',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
                _section(
                  title: 'Tim Pengembang',
                  child: _buildTeamSection(),
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 240 + topPadding,
            child: Image.asset(
              'assets/images/Team-picture.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: Container(
            width: double.infinity,
            height: 240 + topPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.4, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: topPadding + 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'MEDIKU',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'TEAM PPKO BEM FK UNNES 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Made with ',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            Icon(Icons.favorite, size: 14, color: Colors.red),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'by TEAM PPKO BEM FK UNNES 2026',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_members.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _members[i],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Lukman Fauzi, S.K.M., M.P.H',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
