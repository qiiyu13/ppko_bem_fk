import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/profile_qr_dialog.dart';
import '../add_profile_screen.dart';
import '../edit_profile_screen.dart';
import 'package:mediku/utils/page_transitions.dart';
import 'package:mediku/widgets/app_avatar.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 16.0;
    const spacing = 12.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<FamilyProfile>>(
          stream: ProfileService.instance.profilesStream,
          initialData: ProfileService.instance.profiles,
          builder: (context, profilesSnapshot) {
            final profiles = profilesSnapshot.data ?? [];

            return StreamBuilder<FamilyProfile?>(
              stream: ProfileService.instance.activeProfileStream,
              initialData: ProfileService.instance.activeProfile,
              builder: (context, activeSnapshot) {
                final activeProfile = activeSnapshot.data;

                return ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.92, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title lives in the main AppBar ('Anggota Keluarga')
                          // — no duplicate in-body header.

                          // Active Profile Card
                          if (activeProfile != null)
                            _buildActiveProfileCard(
                              activeProfile,
                              screenWidth,
                              padding,
                              spacing,
                              context,
                            ),

                          const SizedBox(height: spacing * 2),

                          // Family Members List Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Semua Anggota',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${profiles.length}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  ParallaxPageRoute(
                                    page: const AddProfileScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.person_add,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Tambah Anggota',
                              ),
                            ],
                          ),

                          const SizedBox(height: spacing),

                          if (profiles.isEmpty)
                            _buildEmptyState(spacing)
                          else
                            ...profiles.map(
                              (profile) => _buildProfileListItem(
                                profile,
                                activeProfile?.id == profile.id,
                                screenWidth,
                                padding,
                                spacing,
                                context,
                              ),
                            ),

                          const SizedBox(height: spacing),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(double spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing * 2),
      child: const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'Belum ada anggota keluarga',
        subtitle: 'Tambahkan anggota dengan tombol + di atas',
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
          AppAvatar(
            imageUrl: profile.avatarUrl,
            size: screenWidth * 0.16,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            borderColor: Colors.white,
            borderWidth: 3,
            fallback: Icon(
              profile.gender == 'Pria' ? Icons.male : Icons.female,
              size: screenWidth * 0.07,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 16),
          // Right side: All info
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIK: ${profile.formattedNik}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showProfileQrDialog(context, profile),
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  tooltip: 'Tampilkan QR',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileListItem(
    FamilyProfile profile,
    bool isActive,
    double screenWidth,
    double padding,
    double spacing,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showProfileOptions(context, profile, isActive),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(padding * 0.75),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isActive
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: AppColors.surface, width: 1),
            ),
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: profile.avatarUrl,
                  size: 48,
                  backgroundColor: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  fallback: Icon(
                    profile.gender == 'Pria' ? Icons.male : Icons.female,
                    size: 24,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
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
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 11,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.age != null ? '${profile.age} tahun • ' : ''}${profile.gender}${profile.bloodType != null ? ' • ${profile.bloodType}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.qr_code,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => showProfileQrDialog(context, profile),
                  tooltip: 'Tampilkan QR',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      _showProfileOptions(context, profile, isActive),
                  tooltip: 'Opsi profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(
    BuildContext context,
    FamilyProfile profile,
    bool isActive,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.switch_account,
                  color: AppColors.primary,
                ),
                title: Text(
                  isActive ? 'Profil Aktif' : 'Pilih Profil Ini',
                  style: TextStyle(
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () async {
                  if (!isActive) {
                    await ProfileService.instance.setActiveProfile(profile.id);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.textSecondary),
                title: const Text('Edit Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    ParallaxPageRoute(
                      page: EditProfileScreen(profile: profile),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.statusRed),
                title: const Text(
                  'Hapus Profil',
                  style: TextStyle(color: AppColors.statusRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, profile, isActive);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FamilyProfile profile,
    bool isActive,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus profil ${profile.name}? Semua data terkait akan dihapus.',
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.statusAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusAmber,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ini adalah profil aktif saat ini.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.statusAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await ProfileService.instance.deleteProfile(
                profile.id,
                profile.updatedAt,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profil ${profile.name} telah dihapus'),
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
  }
}
