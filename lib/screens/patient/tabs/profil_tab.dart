import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';
import '../add_profile_screen.dart';
import '../edit_profile_screen.dart';
import 'package:mediku/utils/page_transitions.dart';
import 'package:mediku/widgets/app_avatar.dart';

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
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.92, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Anggota Keluarga',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profiles.length}',
                                    style: const TextStyle(
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

                        SizedBox(height: spacing * 1.5),

                        // Active Profile Card
                        if (activeProfile != null)
                          _buildActiveProfileCard(
                            activeProfile,
                            screenWidth,
                            padding,
                            spacing,
                            context,
                          ),

                        SizedBox(height: spacing * 2),

                        // Family Members List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Semua Anggota',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
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

                        SizedBox(height: spacing),

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

                        SizedBox(height: spacing),
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
      padding: EdgeInsets.symmetric(vertical: spacing * 3),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 56, color: AppColors.textSecondary),
            SizedBox(height: spacing),
            const Text(
              'Belum ada anggota keluarga',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'Tambahkan anggota dengan tombol + di atas',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PROFIL AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showQRCodeDialog(context, profile),
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Tampilkan QR',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Name
                Text(
                  profile.name,
                  style: const TextStyle(
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
                    _buildInfoChipCompact(
                      profile.gender,
                      profile.gender == 'Pria' ? Icons.male : Icons.female,
                    ),
                    if (profile.bloodType != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChipCompact(
                        profile.bloodType!,
                        Icons.water_drop,
                      ),
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
                        style: const TextStyle(
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
                IconButton(
                  icon: const Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                  onPressed: () => _showQRCodeDialog(context, profile),
                  tooltip: 'Tampilkan QR',
                ),
                const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, FamilyProfile profile) {
    final qrData = jsonEncode({
      'profileId': profile.id,
      'name': profile.name,
      'nik': profile.nik,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          profile.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              embeddedImage: const AssetImage('assets/icon/logo_only.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(44, 44),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NIK: ${profile.formattedNik}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account, color: AppColors.primary),
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
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text(
                  'Hapus Profil',
                  style: TextStyle(color: Colors.red[400]),
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ini adalah profil aktif saat ini.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
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
            child: Text('Hapus', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}
