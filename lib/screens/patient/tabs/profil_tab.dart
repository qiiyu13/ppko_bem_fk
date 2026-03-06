import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';
import '../add_profile_screen.dart';
import '../edit_profile_screen.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final spacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<FamilyProfile>>(
          stream: ProfileService.instance.profilesStream,
          initialData: ProfileService.instance.profiles,
          builder: (context, snapshot) {
            final profiles = snapshot.data ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: spacing),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anggota Keluarga',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profiles.length} anggota terdaftar',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profiles.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing * 2),

                    // Active Profile Card
                    StreamBuilder<FamilyProfile?>(
                      stream: ProfileService.instance.activeProfileStream,
                      initialData: ProfileService.instance.activeProfile,
                      builder: (context, snapshot) {
                        final activeProfile = snapshot.data;
                        if (activeProfile == null) return const SizedBox.shrink();

                        return _buildActiveProfileCard(
                          activeProfile,
                          screenWidth,
                          padding,
                          spacing,
                          context,
                        );
                      },
                    ),

                    SizedBox(height: spacing * 2),

                    // Family Members List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Semua Anggota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddProfileDialog(context),
                          icon: Icon(
                            Icons.person_add,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Tambah Anggota',
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // List of all profiles
                    ...profiles.map((profile) => _buildProfileListItem(
                      profile,
                      screenWidth,
                      padding,
                      spacing,
                      context,
                    )),

                    SizedBox(height: spacing),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveProfileCard(
    FamilyProfile profile,
    double screenWidth,
    double padding,
    double spacing,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Avatar
          Container(
            width: screenWidth * 0.16,
            height: screenWidth * 0.16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.person,
              size: screenWidth * 0.07,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 16),
          // Right side: All info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PROFIL AKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Name
                Text(
                  profile.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                // NIK
                Text(
                  'NIK: ${profile.formattedNik}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                // Info chips row
                Row(
                  children: [
                    _buildInfoChipCompact('${profile.age} Tahun', Icons.cake),
                    const SizedBox(width: 8),
                    _buildInfoChipCompact(profile.gender, profile.gender == 'Pria' ? Icons.male : Icons.female),
                    if (profile.bloodType != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChipCompact(profile.bloodType!, Icons.water_drop),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChipCompact(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileListItem(
    FamilyProfile profile,
    double screenWidth,
    double padding,
    double spacing,
    BuildContext context,
  ) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        final isActive = activeProfile?.id == profile.id;

        return Container(
          margin: EdgeInsets.only(bottom: spacing),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showProfileOptions(context, profile, isActive),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(padding * 0.75),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 2)
                      : Border.all(color: AppColors.surface, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: padding * 0.75),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'AKTIF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.formattedNik,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.age} tahun • ${profile.gender}${profile.bloodType != null ? ' • ${profile.bloodType}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileOptions(BuildContext context, FamilyProfile profile, bool isActive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.switch_account, color: AppColors.primary),
                title: Text(
                  isActive ? 'Profil Aktif' : 'Pilih Profil Ini',
                  style: TextStyle(color: isActive ? AppColors.primary : AppColors.textPrimary),
                ),
                trailing: isActive ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () async {
                  if (!isActive) {
                    await ProfileService.instance.setActiveProfile(profile.id);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.textSecondary),
                title: const Text('Edit Profil'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(context, profile);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text('Hapus Profil', style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, profile);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProfileScreen()),
    );
  }

  void _showEditProfileDialog(BuildContext context, FamilyProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FamilyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Profil'),
        content: Text('Apakah Anda yakin ingin menghapus profil ${profile.name}? Semua data terkait akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await ProfileService.instance.deleteProfile(profile.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil ${profile.name} telah dihapus')),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}
