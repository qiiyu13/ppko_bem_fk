import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../screens/common/settings/about_screen.dart';
import '../../../screens/common/settings/help_screen.dart';
import '../../../screens/common/settings/language_screen.dart';
import '../../../screens/common/settings/notification_settings_screen.dart';
import '../../../screens/welcome_screen.dart';
import '../../../services/profile_service.dart';
import '../../../utils/responsive_size.dart';
import 'package:mediku/utils/page_transitions.dart';

void _push(BuildContext context, Widget screen) {
  Navigator.push(context, ParallaxPageRoute(page: screen));
}

class SuperadminSettingsTab extends StatelessWidget {
  const SuperadminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Setelan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveSize.spacingMedium),

              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Atur notifikasi pengingat',
                onTap: () => _push(context, const NotificationSettingsScreen()),
              ),

              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                onTap: () => _push(context, const LanguageScreen()),
              ),

              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'Pusat bantuan dan FAQ',
                onTap: () => _push(context, const HelpScreen()),
              ),

              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0',
                onTap: () => _push(context, const AboutScreen()),
              ),

              SizedBox(height: ResponsiveSize.spacingMedium),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveSize.cardBorderRadius,
                          ),
                        ),
                        title: Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontXLarge,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        content: Text(
                          'Apakah Anda yakin ingin keluar?',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ProfileService.instance.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  ParallaxPageRoute(
                                    page:
                                        const WelcomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.logout,
                    size: ResponsiveSize.iconSmall,
                    color: AppColors.textOnPrimary,
                  ),
                  label: Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.paddingSmall * 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveSize.buttonBorderRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(ResponsiveSize.buttonBorderRadius),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingSmall * 0.6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              ResponsiveSize.buttonBorderRadius * 0.5,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: ResponsiveSize.iconSmall * 0.9,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveSize.fontMedium,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveSize.fontSmall,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: ResponsiveSize.iconSmall * 0.5,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
