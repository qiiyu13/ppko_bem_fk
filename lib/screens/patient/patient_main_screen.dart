import 'package:flutter/material.dart';
import '../../components/animated_line_navbar.dart';
import '../../constants/app_colors.dart';
import '../../models/family_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/profile_qr_dialog.dart';
import 'tabs/home_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/tanaman_toga_tab.dart';
import 'jadwal_saya_screen.dart';
import '../../utils/asset_helper.dart';
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
    'Jadwal Screening',
    'Berita',
    'Anggota Keluarga',
  ];

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return HomeTab(onSwitchTab: _onTabChanged);
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

  final List<NavBarItem> _navItems = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Beranda',
      svgIcon: AssetHelper.getIconPath('icons8-home.svg'),
    ),
    NavBarItem(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Jadwal',
      svgIcon: AssetHelper.getIconPath('icons8-schedule.svg'),
    ),
    NavBarItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      label: 'Berita',
      svgIcon: AssetHelper.getIconPath('icons8-magazine.svg'),
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Keluarga',
      svgIcon: AssetHelper.getIconPath('icons8-person.svg'),
    ),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _built.add(index);
    });
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
                  onPressed: () => showProfileQrDialog(context, profile),
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
              title: Text(_tabTitles[_currentIndex]),
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
                            ParallaxPageRoute(page: const SettingsTab()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ]
                  : null,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _navItems.length,
          (i) => _built.contains(i) ? _buildTab(i) : const SizedBox.shrink(),
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
