import 'package:flutter/material.dart';
import '../../components/animated_line_navbar.dart';
import '../../constants/app_colors.dart';
import '../../utils/asset_helper.dart';
import '../../widgets/sync_status_banner.dart';
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
  final Set<int> _built = {0};

  final _navItems = <NavBarItem>[
    NavBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      svgIcon: AssetHelper.getIconPath('icons8-dashboard.svg'),
    ),
    NavBarItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Jadwal',
      svgIcon: AssetHelper.getIconPath('icons8-calender.svg'),
    ),
    NavBarItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      label: 'Publikasi',
      svgIcon: AssetHelper.getIconPath('icons8-magazine.svg'),
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      svgIcon: AssetHelper.getIconPath('icons8-person.svg'),
    ),
  ];

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return DashboardTab(onSwitchTab: _onTabChanged);
      case 1:
        return const ScheduleScreen();
      case 2:
        return const PublishTab();
      case 3:
        return const AdminProfilTab();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _built.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
