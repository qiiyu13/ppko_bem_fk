import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../components/animated_line_navbar.dart';
import '../../constants/app_colors.dart';
import '../../models/family_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/sync_status_banner.dart';
import 'tabs/home_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/tanaman_toga_tab.dart';
import 'jadwal_saya_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;
  final Set<int> _built = {0};

  final List<String> _tabTitles = const [
    '',
    'Jadwal',
    'Tanaman Toga',
    'Profil',
  ];

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return const HomeTab();
      case 1:
        return JadwalSayaScreen(onBack: () {}, isEmbedded: true);
      case 2:
        return const TanamanTogaTab();
      case 3:
        return const ProfilTab();
      default:
        return const SizedBox.shrink();
    }
  }

  final List<NavBarItem> _navItems = const [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Beranda',
    ),
    NavBarItem(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Jadwal',
    ),
    NavBarItem(
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco,
      label: 'Tanaman',
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _built.add(index);
    });
  }

  void _showQRCodeDialog(BuildContext context, FamilyProfile profile) {
    final qrData = jsonEncode({
      'profileId': profile.id,
      'name': profile.name,
      'nik': profile.nik,
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          profile.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              embeddedImage: const AssetImage('assets/icon/logo_only.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(44, 44),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NIK: ${profile.formattedNik}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = _currentIndex != 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _currentIndex == 0
          ? StreamBuilder<FamilyProfile?>(
              stream: ProfileService.instance.activeProfileStream,
              initialData: ProfileService.instance.activeProfile,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                if (profile == null) return const SizedBox.shrink();
                return FloatingActionButton(
                  heroTag: 'patient_home_qr_fab',
                  onPressed: () => _showQRCodeDialog(context, profile),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.qr_code, color: Colors.white),
                );
              },
            )
          : null,
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
              actions: _currentIndex == 3
                  ? [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            ParallaxPageRoute(
                              page: const SettingsTab(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ]
                  : null,
            )
          : null,
      body: SyncStatusBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            _navItems.length,
            (i) => _built.contains(i) ? _buildTab(i) : const SizedBox.shrink(),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedLineNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: _navItems,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.textSecondary,
        backgroundColor: AppColors.background,
        indicatorWidth: 0.6,
      ),
    );
  }
}
