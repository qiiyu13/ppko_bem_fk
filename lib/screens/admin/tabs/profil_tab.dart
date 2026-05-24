import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_size.dart';
import '../../patient/tabs/settings_tab.dart';
import '../admin_profile_edit_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class AdminProfilTab extends StatefulWidget {
  const AdminProfilTab({super.key});

  @override
  State<AdminProfilTab> createState() => _AdminProfilTabState();
}

class _AdminProfilTabState extends State<AdminProfilTab> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final me = await AuthService.getMe(force: true);
    if (!mounted) return;
    setState(() {
      _user = me;
      _isLoading = false;
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'SUPERADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin Desa';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final name = _user?['responsibleName'] as String? ?? '—';
    final id = (_user?['id'] as String?) ?? '';
    final role = _user?['role'] as String? ?? '';
    final position = _user?['position'] as String? ?? '—';
    final phone = _user?['phone'] as String? ?? '—';
    final region = _user?['region'] as Map<String, dynamic>?;
    final wilayah = region?['name'] as String? ?? '—';
    final idDisplay = id.length > 8 ? '${id.substring(0, 8)}...' : id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profil Admin',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Setelan',
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: ResponsiveSize.spacingLarge),
                  _buildUnifiedCard(name, idDisplay, role, position, wilayah, phone),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildUnifiedCard(
    String name,
    String idDisplay,
    String role,
    String position,
    String wilayah,
    String phone,
  ) {
    final avatarSize = ResponsiveSize.screenWidth * 0.22;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                ResponsiveSize.paddingMedium,
                ResponsiveSize.paddingSmall,
                ResponsiveSize.paddingMedium,
                ResponsiveSize.paddingLarge,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveSize.paddingSmall * 0.5,
                        ),
                        child: Text(
                          'ID: $idDisplay',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.textOnPrimary,
                          size: ResponsiveSize.iconSmall,
                        ),
                        tooltip: 'Edit Profil',
                        onPressed: () async {
                          if (_user == null) return;
                          final result = await Navigator.push<bool>(
                            context,
                            ParallaxPageRoute(
                              page: AdminProfileEditScreen(user: _user!),
                            ),
                          );
                          if (result == true) _loadProfile();
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: ResponsiveSize.iconLarge,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.paddingMedium,
                      vertical: ResponsiveSize.paddingSmall * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.card,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.paddingMedium,
                vertical: ResponsiveSize.paddingSmall,
              ),
              child: Column(
                children: [
                  _buildInfoRow('Jabatan', position == '—' ? position : position),
                  _buildInfoRow('Wilayah Monitoring', wilayah),
                  _buildInfoRow('Kontak', phone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSize.paddingSmall * 1.1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontMedium,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: ResponsiveSize.spacingMedium),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.surface,
          ),
      ],
    );
  }
}
