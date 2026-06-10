import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../screens/welcome_screen.dart';
import '../../../screens/common/settings/about_screen.dart';
import '../../../screens/common/settings/help_screen.dart';
import '../../../screens/common/settings/language_screen.dart';
import '../../../screens/common/settings/notification_settings_screen.dart';
import '../../../services/profile_service.dart';
import 'package:mediku/utils/page_transitions.dart';

void _push(BuildContext context, Widget screen) {
  Navigator.push(context, ParallaxPageRoute(page: screen));
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    const padding = 16.0;
    const spacing = 12.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: spacing),

              // Settings Items - White cards
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Atur notifikasi pengingat',
                onTap: () => _push(context, const NotificationSettingsScreen()),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                onTap: () => _push(context, const LanguageScreen()),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'Pusat bantuan dan FAQ',
                onTap: () => _push(context, const HelpScreen()),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: _appVersion.isEmpty ? 'Versi' : 'Versi $_appVersion',
                onTap: () => _push(context, const AboutScreen()),
                padding: padding,
                spacing: spacing,
              ),

              const SizedBox(height: spacing),

              // Logout - destructive action styled as such (outlined, red)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(
                    Icons.logout,
                    size: 20,
                    color: AppColors.statusRed,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(fontSize: 16, color: AppColors.statusRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRed,
                    side: const BorderSide(color: AppColors.statusRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ProfileService.instance.logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  ParallaxPageRoute(page: const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double padding,
    required double spacing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: AppTheme.cardShadowLight,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(padding * 0.5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
