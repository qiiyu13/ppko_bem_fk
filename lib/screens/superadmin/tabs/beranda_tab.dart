import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../services/screening_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/region_service.dart';
import '../../../services/token_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';
import '../../../utils/responsive_size.dart';
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
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadStats();
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

  Future<void> _loadStats() async {
    try {
      final stats = await ScreeningService.getStats();
      final regionStats = await RegionService.getStats();

      final categoryCounts = stats['categories'] as Map<String, dynamic>? ?? {};
      final highRiskCount = (categoryCounts['high'] as num?)?.toInt() ?? 0;
      final attentionCount = (categoryCounts['attention'] as num?)?.toInt() ?? 0;
      final normalCount = (categoryCounts['normal'] as num?)?.toInt() ?? 0;

      setState(() {
        _totalPatients = (regionStats['profileCount'] as num?)?.toInt() ?? 0;
        _todayScreenings = (stats['total'] as num?)?.toInt() ?? 0;
        _highRiskCount = highRiskCount;
        _attentionCount = attentionCount;
        _normalCount = normalCount;
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(),
              Padding(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),

                    SizedBox(height: ResponsiveSize.spacingXLarge),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Aktivitas Terbaru',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontXLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
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
    );
  }

  Widget _buildGreetingHeader() {
    final name = _userName ?? 'Admin Desa';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        MediaQuery.of(context).padding.top + ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
      ),
      color: AppColors.card,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: ResponsiveSize.fontLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.instance.unreadCount,
            builder: (_, count, _) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.statusRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Jumlah Warga Terdaftar',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      NumberFormat('#,##0', 'id_ID').format(_totalPatients),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.paddingMedium,
              horizontal: ResponsiveSize.paddingSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStat(_todayScreenings, 'Screened', AppColors.primary),
                ),
                Container(width: 1, height: 40, color: AppColors.surface),
                Expanded(
                  child: _buildMiniStat(_highRiskCount, 'High Risk', AppColors.statusRed),
                ),
                Container(width: 1, height: 40, color: AppColors.surface),
                Expanded(
                  child: _buildMiniStat(_attentionCount, 'Attention', AppColors.statusAmber),
                ),
                Container(width: 1, height: 40, color: AppColors.surface),
                Expanded(
                  child: _buildMiniStat(_normalCount, 'Normal', AppColors.statusGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(int value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveSize.spacingSmall * 0.25),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return ValueListenableBuilder<List<NotificationModel>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (_, notifs, _) {
        if (notifs.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: ResponsiveSize.spacingXLarge),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  Text(
                    'Belum ada aktivitas',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
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
