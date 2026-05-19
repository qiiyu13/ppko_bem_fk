import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/family_profile.dart';
import '../services/profile_service.dart';
import '../screens/patient/add_profile_screen.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        
        if (activeProfile == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _showProfileSwitcher(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surface, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeProfile.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ProfileSwitcherSheet(),
    );
  }
}

class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Pilih Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Profile list
            StreamBuilder<List<FamilyProfile>>(
              stream: ProfileService.instance.profilesStream,
              initialData: ProfileService.instance.profiles,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? [];
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _ProfileListTile(profile: profile);
                  },
                );
              },
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Anggota Keluarga'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final FamilyProfile profile;

  const _ProfileListTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        final isActive = activeProfile?.id == profile.id;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          title: Text(
            profile.name,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            profile.formattedNik,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
          onTap: () async {
            await ProfileService.instance.setActiveProfile(profile.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
