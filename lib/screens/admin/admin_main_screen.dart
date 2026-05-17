import 'package:flutter/material.dart';
import '../../components/animated_line_navbar.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/sync_status_banner.dart';
import '../patient/tabs/settings_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/publish_tab.dart';
import 'schedule_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const ScheduleScreen(),
    const PublishTab(),
    const AdminProfilTab(),
    const SettingsTab(),
  ];

  final List<NavBarItem> _navItems = const [
    NavBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavBarItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Jadwal',
    ),
    NavBarItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      label: 'Publikasi',
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
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
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: AnimatedLineNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: _navItems,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.textSecondary,
        backgroundColor: AppColors.background,
        indicatorWidth: 0.6,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
