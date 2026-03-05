import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'tabs/home_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/settings_tab.dart';
import 'asisten_landing_screen.dart';
import 'jadwal_saya_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  final List<String> _tabTitles = [
    '',
    'Jadwal',
    'Tanaman Toga',
    'Asisten',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final showAppBar = _currentIndex != 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                _tabTitles[_currentIndex],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: _currentIndex == 4
                  ? [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.primary,
                        ),
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
                    ]
                  : null,
            )
          : null,
      body: Stack(
        children: [
          // Main content area - fills entire screen
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildTab(HomeTab()),
                _buildTab(JadwalSayaScreen(onBack: () {}, isEmbedded: true)),
                _buildTab(_buildTanamanTogaTab()),
                _buildTab(const AsistenLandingScreen()),
                _buildTab(const ProfilTab()),
              ],
            ),
          ),
          // Floating navbar positioned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 12,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(Widget child) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false, // Don't apply bottom safe area since we have navbar
        child: child,
      ),
    );
  }

  Widget _buildTanamanTogaTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_florist,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tanaman Toga',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
