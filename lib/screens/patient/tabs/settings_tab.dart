import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../screens/welcome_screen.dart';
import '../../../services/profile_service.dart';

const String _kAppVersion = '1.0.0';

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature segera hadir')),
  );
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final spacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: spacing),

              // Settings Items - White cards
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Atur notifikasi pengingat',
                onTap: () => _showComingSoon(context, 'Notifikasi'),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                onTap: () => _showComingSoon(context, 'Bahasa'),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'Pusat bantuan dan FAQ',
                onTap: () => _showComingSoon(context, 'Bantuan'),
                padding: padding,
                spacing: spacing,
              ),

              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi $_kAppVersion',
                onTap: () {},
                padding: padding,
                spacing: spacing,
              ),

              SizedBox(height: spacing),

              // Logout Button - Dark teal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await ProfileService.instance.logout();
                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'Keluar',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.logout,
                    size: 20,
                    color: AppColors.background,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(fontSize: 16, color: AppColors.background),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    required double padding,
    required double spacing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
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
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
