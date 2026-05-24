import 'package:flutter/material.dart';
import 'package:mediku/widgets/app_avatar.dart';
import '../../config/env.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/audit_service.dart';
import '../../utils/patient_utils.dart';
import '../../utils/responsive_size.dart';
import 'admin_patient_detail_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class AdminFamilyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> family;
  final bool readOnly;

  const AdminFamilyDetailScreen({
    super.key,
    required this.family,
    this.readOnly = false,
  });

  @override
  State<AdminFamilyDetailScreen> createState() =>
      _AdminFamilyDetailScreenState();
}

class _AdminFamilyDetailScreenState extends State<AdminFamilyDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response =
          await ApiService.get('/admin/patients/${widget.family['id']}');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data keluarga')),
      );
    }
  }

  String _maskKk(String kk) {
    if (kk.length <= 4) return kk;
    return '${'•' * (kk.length - 4)}${kk.substring(kk.length - 4)}';
  }

  String? _profileRisk(Map<String, dynamic> profile) {
    final screenings = profile['screenings'] as List<dynamic>?;
    if (screenings == null || screenings.isEmpty) return null;
    final first = screenings.first;
    if (first is Map) return first['irdCategory'] as String?;
    return null;
  }

  int? _ageFromBirthDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      final now = DateTime.now();
      var age = now.year - dt.year;
      if (now.month < dt.month ||
          (now.month == dt.month && now.day < dt.day)) {
        age--;
      }
      return age >= 0 ? age : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final name = (_data?['responsibleName'] ?? widget.family['name'] ?? '-')
        .toString();
    final kk = (_data?['kkNumber'] ?? widget.family['nik'] ?? '').toString();
    final phone = (_data?['phone'] ?? widget.family['phone'] ?? '').toString();
    final profiles = (_data?['familyProfiles'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              children: [
                _buildHeaderCard(name, kk, phone, profiles.length),
                SizedBox(height: ResponsiveSize.spacingLarge),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Anggota Keluarga',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (profiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.group_off,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada profil terdaftar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveSize.fontMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          for (var i = 0; i < profiles.length; i++) ...[
                            _buildProfileTile(profiles[i], name),
                            if (i != profiles.length - 1)
                              Container(
                                  height: 1, color: AppColors.divider),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(String name, String kk, String phone, int count) {
    final avatarPath = (_data?['avatarPath'] ?? widget.family['avatarPath']) as String?;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? '${Env.serverBaseUrl}$avatarPath'
        : null;
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                size: 52,
                backgroundColor: AppColors.primary,
                fallback: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      'KK ${_maskKk(kk)}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.group, '$count anggota'),
              const SizedBox(width: 8),
              if (phone.isNotEmpty) _infoChip(Icons.phone, phone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(Map<String, dynamic> profile, String familyName) {
    final name = (profile['name'] as String?) ?? '-';
    final nik = (profile['nik'] as String?) ?? '';
    final nikTail = nik.length > 3 ? nik.substring(nik.length - 3) : nik;
    final gender = (profile['gender'] as String?) ?? '';
    final age = _ageFromBirthDate(profile['birthDate']);
    final risk = _profileRisk(profile);
    final riskColor = risk != null
        ? PatientUtils.riskColor(risk)
        : AppColors.textSecondary;
    final initial = name.isNotEmpty && name != '-'
        ? name[0].toUpperCase()
        : '?';
    final subtitle = [
      if (nikTail.isNotEmpty) 'NIK …$nikTail',
      if (gender.isNotEmpty) gender,
      if (age != null) '$age th',
    ].join(' · ');

    return InkWell(
      onTap: () async {
        if (widget.readOnly) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Buka data pasien'),
              content: const Text(
                  'Anda mengakses sebagai SUPERADMIN. Setiap perubahan akan tercatat di audit log.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Lanjutkan',
                      style: TextStyle(color: AppColors.textOnPrimary)),
                ),
              ],
            ),
          );
          if (proceed != true) return;
          await AuditService.logAdminAction(
            action: 'PATIENT_VIEW',
            targetType: 'PROFILE',
            targetId: (profile['id'] as String?) ?? '',
            metadata: {'familyId': widget.family['id']},
          );
        }
        if (!mounted) return;
        Navigator.push(
          context,
          ParallaxPageRoute(
            page: AdminPatientDetailScreen(
              preloaded: true,
              readOnly: widget.readOnly,
              patient: {
                ...profile,
                'familyName': familyName,
              },
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: (() {
                final p = profile['avatarPath'] as String?;
                return (p != null && p.isNotEmpty) ? '${Env.serverBaseUrl}$p' : null;
              })(),
              size: 40,
              backgroundColor: riskColor.withValues(alpha: 0.15),
              fallback: Text(
                initial,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _riskBadge(risk),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: ResponsiveSize.iconSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskBadge(String? risk) {
    final color =
        risk != null ? PatientUtils.riskColor(risk) : AppColors.textSecondary;
    final label = risk != null ? PatientUtils.riskLabel(risk) : 'Belum skrining';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
