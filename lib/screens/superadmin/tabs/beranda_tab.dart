import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../services/appointment_service.dart';
import '../../../services/screening_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/region_service.dart';
import '../../../services/token_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/dashboard/greeting_header.dart';
import '../../../widgets/error_state_widget.dart';
import '../../admin/qr_scanner_screen.dart';
import '../screens/appointment_detail_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const Color purpleAccent = Color(0xFF7B1FA2);
  static const Color blueAccent = Color(0xFF1976D2);

  bool _isLoading = true;
  bool _loadFailed = false;
  int _totalPatients = 0;
  int _totalScreenings = 0;
  int _highRiskCount = 0;
  int _attentionCount = 0;
  int _normalCount = 0;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  String? _userName;
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final cachedName = await TokenService.getResponsibleName();
    if (mounted && cachedName != null && cachedName.isNotEmpty) {
      setState(() => _userName = cachedName);
    }
    final me = await AuthService.getMe();
    if (!mounted || me == null) return;
    final name = (me['name'] ?? me['responsibleName']) as String? ?? _userName;
    setState(() {
      _userName = name;
      _userAvatarUrl = AuthService.userAvatarUrl(me);
    });
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ScreeningService.getStats(),
        RegionService.getStats(),
        AppointmentService.getAppointments(),
      ]);
      if (!mounted) return;
      final stats = results[0] as Map<String, dynamic>;
      final regionStats = results[1] as Map<String, dynamic>;
      final allAppointments = (results[2] as List).cast<Map<String, dynamic>>();

      final now = DateTime.now();
      final upcoming = allAppointments
          .where((a) {
            try {
              return DateTime.parse(a['date'] as String).isAfter(now);
            } catch (_) {
              return false;
            }
          })
          .toList()
        ..sort((a, b) {
          final da = DateTime.parse(a['date'] as String);
          final db = DateTime.parse(b['date'] as String);
          return da.compareTo(db);
        });

      final categoryCounts = stats['categories'] as Map<String, dynamic>? ?? {};
      final highRiskCount = (categoryCounts['high'] as num?)?.toInt() ?? 0;
      final attentionCount = (categoryCounts['attention'] as num?)?.toInt() ?? 0;
      final normalCount = (categoryCounts['normal'] as num?)?.toInt() ?? 0;

      setState(() {
        _totalPatients = (regionStats['profileCount'] as num?)?.toInt() ?? 0;
        _totalScreenings = (stats['total'] as num?)?.toInt() ?? 0;
        _highRiskCount = highRiskCount;
        _attentionCount = attentionCount;
        _normalCount = normalCount;
        _upcomingAppointments = upcoming.take(3).toList();
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadAll(), _loadUser()]);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'superadmin_beranda_fab',
          onPressed: () {
            Navigator.push(
              context,
              ParallaxPageRoute(page: const QrScannerScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: const Text('Scan QR', style: TextStyle(color: Colors.white)),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GreetingHeader(
                  name: _userName,
                  fallbackName: 'Superadmin',
                  roleBadge: 'SUPERADMIN',
                  roleBadgeColor: purpleAccent,
                  imageUrl: _userAvatarUrl,
                  fallbackAsset: 'assets/icon/logo_only.png',
                  bareFallbackAsset: true,
                ),
                Padding(
                  padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                  child: _isLoading
                      ? _buildSkeleton()
                      : _loadFailed
                          ? ErrorStateWidget(
                              message:
                                  'Gagal memuat statistik.\nPeriksa koneksi lalu coba lagi.',
                              onRetry: () {
                                setState(() => _isLoading = true);
                                _loadAll();
                              },
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCard(),

                                SizedBox(height: ResponsiveSize.spacingXLarge),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _sectionTitle('Jadwal Mendatang'),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Hanya Lihat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveSize.spacingMedium),
                                _buildUpcomingAppointments(),

                                SizedBox(
                                    height: ResponsiveSize.spacingXLarge * 2),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox(double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skeletonBox(132),
        SizedBox(height: ResponsiveSize.spacingXLarge),
        _skeletonBox(24),
        SizedBox(height: ResponsiveSize.spacingMedium),
        _skeletonBox(180),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveSize.fontXLarge,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Warga Terdaftar',
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,##0', 'id_ID').format(_totalPatients),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          Container(height: 1, color: AppColors.surface),
          SizedBox(height: ResponsiveSize.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Skrining', _totalScreenings, AppColors.primary),
              _miniStat('Tinggi', _highRiskCount, AppColors.statusRed),
              _miniStat('Waspada', _attentionCount, AppColors.statusAmber),
              _miniStat('Normal', _normalCount, AppColors.statusGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          SizedBox(height: ResponsiveSize.spacingSmall),
          Text(
            message,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return _emptyCard(Icons.event_busy_outlined, 'Belum ada jadwal mendatang');
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            for (var i = 0; i < _upcomingAppointments.length; i++) ...[
              _appointmentRow(_upcomingAppointments[i]),
              if (i != _upcomingAppointments.length - 1)
                Container(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _appointmentRow(Map<String, dynamic> appt) {
    final title = appt['title']?.toString() ?? '-';
    DateTime? date;
    try {
      date = DateTime.parse(appt['date'] as String).toLocal();
    } catch (_) {}
    final dateStr = date != null
        ? DateFormat('d MMM, HH:mm', 'id_ID').format(date)
        : '-';
    final type = appt['type']?.toString() ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          ParallaxPageRoute(
            page: AppointmentDetailScreen(appointment: appt),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: blueAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.calendar_today,
                  color: blueAccent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.isEmpty ? dateStr : '$dateStr · $type',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

}
