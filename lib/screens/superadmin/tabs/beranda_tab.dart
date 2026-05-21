import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/feature_flags.dart';
import '../../../services/admin_service.dart';
import '../../../services/appointment_service.dart';
import '../../../services/screening_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/region_service.dart';
import '../../../services/token_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/dashboard/greeting_header.dart';
import '../../admin/qr_scanner_screen.dart';
import '../../patient/notification_screen.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const Color purpleAccent = Color(0xFF7B1FA2);
  static const Color blueAccent = Color(0xFF1976D2);

  bool _isLoading = true;
  int _totalPatients = 0;
  int _todayScreenings = 0;
  int _highRiskCount = 0;
  int _attentionCount = 0;
  int _normalCount = 0;
  List<Map<String, dynamic>> _villageBreakdown = [];
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadUser();
    NotificationService.instance.fetchFromApi();
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
    });
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ScreeningService.getStats(),
        RegionService.getStats(),
        if (FeatureFlags.superadminAdminThroughput)
          AdminService.getUsers(role: 'ADMIN')
        else
          Future.value(<Map<String, dynamic>>[]),
        AppointmentService.getAppointments(),
        if (FeatureFlags.superadminAdminThroughput)
          AdminService.getThroughput()
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final stats = results[0] as Map<String, dynamic>;
      final regionStats = results[1] as Map<String, dynamic>;
      final adminsRaw = (results[2] as List).cast<Map<String, dynamic>>();
      final allAppointments = (results[3] as List).cast<Map<String, dynamic>>();
      final throughput = (results[4] as List).cast<Map<String, dynamic>>();

      final throughputById = {
        for (final t in throughput) t['userId']?.toString() ?? '': t,
      };
      final admins = adminsRaw.map((a) {
        final id = a['id']?.toString() ?? '';
        final t = throughputById[id];
        if (t == null) return a;
        return {
          ...a,
          'screeningsLast7d': t['screeningsLast7d'] ?? a['screeningsLast7d'],
          'patientCount': t['patientCount'] ?? a['patientCount'],
        };
      }).toList();

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

      final villagesRaw = regionStats['villages'] as List<dynamic>? ?? [];
      final villages = villagesRaw.cast<Map<String, dynamic>>();

      setState(() {
        _totalPatients = (regionStats['profileCount'] as num?)?.toInt() ?? 0;
        _todayScreenings = (stats['total'] as num?)?.toInt() ?? 0;
        _highRiskCount = highRiskCount;
        _attentionCount = attentionCount;
        _normalCount = normalCount;
        _villageBreakdown = villages;
        _admins = admins;
        _upcomingAppointments = upcoming.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat statistik')),
      );
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadAll(),
      NotificationService.instance.fetchFromApi(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton(
          heroTag: 'superadmin_beranda_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
                ),
                Padding(
                  padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCard(),

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      _sectionTitle('Breakdown per Desa'),
                      SizedBox(height: ResponsiveSize.spacingMedium),
                      _buildVillageBreakdown(),

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      _sectionTitle('Throughput Admin'),
                      SizedBox(height: ResponsiveSize.spacingMedium),
                      _buildAdminThroughput(),

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'Read-only',
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

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(FeatureFlags.superadminAuditFeed
                              ? 'Audit Log'
                              : 'Aktivitas Terbaru'),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                            child: Text(
                              'Lihat Semua',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: ResponsiveSize.fontMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveSize.spacingMedium),
                      _buildActivityList(),

                      SizedBox(height: ResponsiveSize.spacingXLarge * 2),
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
              _miniStat('Screened', _todayScreenings, AppColors.primary),
              _miniStat('High', _highRiskCount, AppColors.statusRed),
              _miniStat('Attn', _attentionCount, AppColors.statusAmber),
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

  Widget _buildVillageBreakdown() {
    if (!FeatureFlags.superadminPerVillageStats || _villageBreakdown.isEmpty) {
      return _emptyCard(
        Icons.location_city_outlined,
        _villageBreakdown.isEmpty
            ? 'Belum ada data per desa'
            : 'Fitur belum tersedia',
      );
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
            _villageHeader(),
            Container(height: 1, color: AppColors.divider),
            for (var i = 0; i < _villageBreakdown.length; i++) ...[
              _villageRow(_villageBreakdown[i]),
              if (i != _villageBreakdown.length - 1)
                Container(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _villageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Desa',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _colHeader('Total'),
          _colHeader('High', AppColors.statusRed),
          _colHeader('Attn', AppColors.statusAmber),
          _colHeader('Norm', AppColors.statusGreen),
        ],
      ),
    );
  }

  Widget _colHeader(String label, [Color? color]) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _villageRow(Map<String, dynamic> v) {
    final name = v['name']?.toString() ?? '-';
    final total = (v['profileCount'] as num?)?.toInt() ?? 0;
    final high = (v['high'] as num?)?.toInt() ?? 0;
    final attn = (v['attention'] as num?)?.toInt() ?? 0;
    final norm = (v['normal'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _cell('$total'),
          _cell('$high', AppColors.statusRed),
          _cell('$attn', AppColors.statusAmber),
          _cell('$norm', AppColors.statusGreen),
        ],
      ),
    );
  }

  Widget _cell(String value, [Color? color]) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: ResponsiveSize.fontSmall,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAdminThroughput() {
    if (!FeatureFlags.superadminAdminThroughput || _admins.isEmpty) {
      return _emptyCard(
        Icons.people_outline,
        _admins.isEmpty ? 'Belum ada admin terdaftar' : 'Fitur belum tersedia',
      );
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
            for (var i = 0; i < _admins.length; i++) ...[
              _adminRow(_admins[i]),
              if (i != _admins.length - 1)
                Container(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _adminRow(Map<String, dynamic> admin) {
    final name = admin['responsibleName']?.toString() ??
        admin['name']?.toString() ??
        'Admin';
    final region = admin['region'] as Map<String, dynamic>?;
    final villageName = region?['name']?.toString() ?? 'Belum ditugaskan';
    final last7 = (admin['screeningsLast7d'] as num?)?.toInt();
    final patientCount = (admin['patientCount'] as num?)?.toInt();
    final isActive = admin['isActive'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 20,
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
                    fontSize: ResponsiveSize.fontSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  villageName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _miniMetric('7h', last7),
          const SizedBox(width: 12),
          _miniMetric('KK', patientCount),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, int? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value?.toString() ?? '—',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

    return Padding(
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
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ValueListenableBuilder<List<NotificationModel>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (_, notifs, _) {
        if (notifs.isEmpty) {
          return _emptyCard(Icons.notifications_none_outlined, 'Belum ada aktivitas');
        }

        final recent = notifs.take(5).toList();
        return Column(
          children: [
            for (var i = 0; i < recent.length; i++)
              _buildTimelineItem(recent[i], isLast: i == recent.length - 1),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(NotificationModel notif, {required bool isLast}) {
    final (icon, color) = switch (notif.type) {
      NotificationType.appointment => (Icons.calendar_today, blueAccent),
      NotificationType.screeningResult => (Icons.assignment, purpleAccent),
      NotificationType.general => (Icons.info_outline, AppColors.primary),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : ResponsiveSize.spacingMedium,
              ),
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
                decoration: BoxDecoration(
                  color: notif.isRead
                      ? AppColors.card
                      : AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontMedium,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (notif.body.isNotEmpty) ...[
                            SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                            Text(
                              notif.body,
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSmall,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _relativeTime(notif.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 7).floor()} mgg lalu';
  }
}
