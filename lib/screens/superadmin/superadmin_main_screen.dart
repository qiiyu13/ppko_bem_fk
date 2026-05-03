import 'package:flutter/material.dart';
import '../../components/animated_line_navbar.dart';
import '../../constants/app_colors.dart';
import '../../widgets/sync_status_banner.dart';
import 'tabs/settings_tab.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/medical_tab.dart';
import 'tabs/users_tab.dart';

class SuperadminMainScreen extends StatefulWidget {
  const SuperadminMainScreen({super.key});

  @override
  State<SuperadminMainScreen> createState() => _SuperadminMainScreenState();
}

class _SuperadminMainScreenState extends State<SuperadminMainScreen> {
  int _currentIndex = 0;

  static const Color inactiveGray = Color(0xFF9E9E9E);

  final List<Widget> _screens = [
    const BerandaTab(),
    const MedicalTab(),
    const UsersTab(),
    const SuperadminSettingsTab(),
  ];

  final List<NavBarItem> _navItems = const [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Beranda',
    ),
    NavBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Manajemen',
    ),
    NavBarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Users',
    ),
    NavBarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Setelan',
    ),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SyncStatusBanner(
        child: SafeArea(child: _screens[_currentIndex]),
      ),
      bottomNavigationBar: AnimatedLineNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: _navItems,
        selectedColor: AppColors.primary,
        unselectedColor: inactiveGray,
        backgroundColor: AppColors.background,
        indicatorWidth: 0.6,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
