import 'package:flutter/material.dart';
import '../../../config/env.dart';
import '../../../constants/app_colors.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/app_avatar.dart';
import '../../admin/admin_family_detail_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class FamilyAccountsScreen extends StatefulWidget {
  final String rtId;
  final String rtName;
  final String rwName;

  const FamilyAccountsScreen({
    super.key,
    required this.rtId,
    required this.rtName,
    required this.rwName,
  });

  @override
  State<FamilyAccountsScreen> createState() => _FamilyAccountsScreenState();
}

class _FamilyAccountsScreenState extends State<FamilyAccountsScreen> {
  List<Map<String, dynamic>> _families = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    try {
      final data = await RegionService.getUsersByRegion(widget.rtId);
      setState(() {
        _families = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.rtName} - ${widget.rwName}',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadFamilies,
                color: AppColors.primary,
                child: _families.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada akun keluarga',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                        itemCount: _families.length,
                        itemBuilder: (context, index) {
                          final family = _families[index];
                          return _buildFamilyCard(family);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> family) {
    final name = family['responsibleName'] ?? 'Unknown';
    final kkNumber = family['kkNumber'] ?? '';
    final count = family['_count'] as Map<String, dynamic>? ?? {};
    final memberCount = count['familyProfiles'] as int? ?? 0;
    final isActive = family['isActive'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            ParallaxPageRoute(
              page: AdminFamilyDetailScreen(
                family: {
                  'id': family['id'],
                  'name': name,
                  'nik': kkNumber,
                  'phone': family['phone'],
                },
                readOnly: true,
              ),
            ),
          );
        },
        child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: (family['avatarPath'] as String?)?.isNotEmpty == true
                  ? '${Env.serverBaseUrl}${family['avatarPath']}'
                  : null,
              fallback: const Icon(Icons.family_restroom, color: AppColors.primary, size: 28),
              size: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            SizedBox(width: ResponsiveSize.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Text(
                    'No. KK: $kkNumber',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.paddingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.statusGreen.withValues(alpha: 0.1)
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.statusGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall),
                      Text(
                        '$memberCount anggota',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
