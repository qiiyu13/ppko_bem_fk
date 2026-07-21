import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/asset_helper.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../screens/patient/laporan_saya_screen.dart';
import '../../../screens/patient/metrics/metric_detail_screen.dart';
import '../../../models/health_metric.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/api_service.dart';
import '../../../services/websocket_service.dart';
import '../../../widgets/dashboard/notification_bell.dart';
import '../../../widgets/mini_sparkline.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:mediku/utils/page_transitions.dart';
import 'package:mediku/widgets/app_avatar.dart';
import 'package:mediku/widgets/profile_selector.dart';

// Metric identity colors — single source for cards, detail screens, and
// sparklines, harmonized with the muted design-system palette.
const Color _bloodPressureColor = AppColors.statusRed;
const Color _bloodSugarColor = AppColors.statusGreen;
const Color _cholesterolColor = AppColors.statusAmber;
const Color _uricAcidColor = Color(0xFF6B5CA5);

class HomeTab extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const HomeTab({super.key, this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<HealthMetric> _metrics = [];
  Map<String, dynamic>? _nextAppointment;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<FamilyProfile?>? _profileSubscription;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _profileSubscription = ProfileService.instance.activeProfileStream.listen((
      _,
    ) {
      _loadData();
    });
    _wsSub = WebSocketService.instance.dataUpdateStream.listen((payload) {
      final type = payload['type'];
      if ((type == 'appointments' || type == 'metrics') && mounted) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _wsSub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Pull-to-refresh is an explicit "give me fresh data": drop the in-memory
  /// cache for the resources shown here (disk copies stay as the offline
  /// fallback) so the GETs in [_loadData] hit the network instead of being
  /// served a cached response for the rest of its TTL.
  Future<void> _refresh() {
    ApiService.cacheInterceptor.invalidateMemory('/metrics');
    ApiService.cacheInterceptor.invalidateMemory('/appointments');
    return _loadData();
  }

  Future<void> _loadData() async {
    final hasExistingData = _metrics.isNotEmpty;
    if (!hasExistingData) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profileId = ProfileService.instance.activeProfile?.id;
      if (profileId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Tidak ada profil aktif';
        });
        return;
      }

      final results = await Future.wait([
        ApiService.get(
          '/metrics/latest',
          queryParameters: {'profileId': profileId},
        ),
        ApiService.get(
          '/appointments',
          queryParameters: {'profileId': profileId},
        ),
      ]);

      final metricsResponse = results[0];
      final appointmentsResponse = results[1];

      final metricsData = metricsResponse.data['data'] as List? ?? [];
      final appointmentsData = appointmentsResponse.data['data'] as List? ?? [];

      final profile = ProfileService.instance.activeProfile;
      final age = profile?.age ?? 0;
      final gender = profile?.gender ?? 'Pria';

      if (!mounted) return;
      setState(() {
        final parsed = metricsData
            .map(
              (json) => _parseMetric(json as Map<String, dynamic>, age, gender),
            )
            .toList();
        const allTypes = [
          MetricType.bloodPressure,
          MetricType.bloodSugar,
          MetricType.cholesterol,
          MetricType.uricAcid,
        ];
        final presentTypes = parsed.map((m) => m.type).toSet();
        for (final type in allTypes) {
          if (!presentTypes.contains(type)) {
            parsed.add(_buildPlaceholderMetric(type, age, gender));
          }
        }
        _metrics = parsed
          ..sort((a, b) {
            return allTypes.indexOf(a.type).compareTo(allTypes.indexOf(b.type));
          });
        _nextAppointment = _pickNextAppointment(appointmentsData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (hasExistingData) {
        // Keep showing existing data, but tell the user the refresh failed.
        setState(() => _isLoading = false);
        showAppSnackBar(
          context,
          'Gagal memperbarui data. Periksa koneksi Anda.',
          error: true,
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data. Periksa koneksi Anda.';
        });
      }
    }
  }

  /// Soonest upcoming appointment (today or later), or null. Never trusts
  /// API ordering, and clears stale data when the active profile has none.
  Map<String, dynamic>? _pickNextAppointment(List<dynamic> raw) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<String, dynamic>? best;
    DateTime? bestDate;
    for (final item in raw) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final dateStr = map['date'];
      if (dateStr is! String) continue;
      final date = DateTime.tryParse(dateStr)?.toLocal();
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(today)) continue;
      if (bestDate == null || date.isBefore(bestDate)) {
        best = map;
        bestDate = date;
      }
    }
    return best;
  }

  HealthMetric _parseMetric(Map<String, dynamic> json, int age, String gender) {
    final type = _parseMetricType(json['type'] as String? ?? '');
    switch (type) {
      case MetricType.bloodPressure:
        final systolic = (json['value'] as num?)?.toInt() ?? 120;
        final diastolic = (json['secondaryValue'] as num?)?.toInt() ?? 80;
        return HealthMetric(
          type: type,
          name: 'Blood Pressure',
          nameId: 'Tekanan Darah',
          unit: 'mmHg',
          displayValue: '$systolic/$diastolic',
          lastUpdated: _parseDate(json['lastUpdated']),
          status: HealthMetricData.getBloodPressureStatus(
            systolic,
            diastolic,
            age,
          ),
          icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
          primaryColor: _bloodPressureColor,
          recentValues: _parseRecentValues(json['recentValues']),
          svgIcon: AssetHelper.getIconPath('icons8-sphygmomanometer.svg'),
          svgBackground: AssetHelper.getSvgPath('blood_pressure.svg'),
        );
      case MetricType.cholesterol:
        final value = (json['value'] as num?)?.toDouble() ?? 0;
        return HealthMetric(
          type: type,
          name: 'Cholesterol',
          nameId: 'Kolesterol',
          unit: 'mg/dL',
          displayValue: value.toStringAsFixed(0),
          lastUpdated: _parseDate(json['lastUpdated']),
          status: HealthMetricData.getCholesterolStatus(value, age),
          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
          primaryColor: _cholesterolColor,
          recentValues: _parseRecentValues(json['recentValues']),
          svgBackground: AssetHelper.getSvgPath('cholestrol.svg'),
        );
      case MetricType.bloodSugar:
        final value = (json['value'] as num?)?.toDouble() ?? 0;
        return HealthMetric(
          type: type,
          name: 'Blood Sugar',
          nameId: 'Gula Darah',
          unit: 'mg/dL',
          displayValue: value.toStringAsFixed(0),
          lastUpdated: _parseDate(json['lastUpdated']),
          status: HealthMetricData.getBloodSugarStatus(value, age),
          icon: PhosphorIcons.testTube(PhosphorIconsStyle.fill),
          primaryColor: _bloodSugarColor,
          recentValues: _parseRecentValues(json['recentValues']),
          svgIcon: AssetHelper.getIconPath('icons8-sugar-cubes.svg'),
          svgBackground: AssetHelper.getSvgPath('blood_sugar.svg'),
        );
      case MetricType.uricAcid:
        final value = (json['value'] as num?)?.toDouble() ?? 0;
        return HealthMetric(
          type: type,
          name: 'Uric Acid',
          nameId: 'Asam Urat',
          unit: 'mg/dL',
          displayValue: value.toStringAsFixed(1),
          lastUpdated: _parseDate(json['lastUpdated']),
          status: HealthMetricData.getUricAcidStatus(value, age, gender),
          icon: PhosphorIcons.flask(PhosphorIconsStyle.fill),
          primaryColor: _uricAcidColor,
          recentValues: _parseRecentValues(json['recentValues']),
          svgBackground: AssetHelper.getSvgPath('uric_acid.svg'),
        );
    }
  }

  MetricType _parseMetricType(String type) {
    switch (type) {
      case 'blood_pressure':
        return MetricType.bloodPressure;
      case 'cholesterol':
        return MetricType.cholesterol;
      case 'blood_sugar':
        return MetricType.bloodSugar;
      case 'uric_acid':
        return MetricType.uricAcid;
      default:
        return MetricType.bloodPressure;
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }

  List<double> _parseRecentValues(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((v) => (v as num).toDouble()).toList();
    }
    return [];
  }

  HealthMetric _buildPlaceholderMetric(
    MetricType type,
    int age,
    String gender,
  ) {
    switch (type) {
      case MetricType.bloodPressure:
        return HealthMetric(
          type: type,
          name: 'Blood Pressure',
          nameId: 'Tekanan Darah',
          unit: 'mmHg',
          displayValue: '--',
          lastUpdated: DateTime.now(),
          status: HealthMetricData.getBloodPressureStatus(0, 0, age),
          icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
          primaryColor: _bloodPressureColor,
          recentValues: const [],
          isPlaceholder: true,
          svgIcon: AssetHelper.getIconPath('icons8-sphygmomanometer.svg'),
          svgBackground: AssetHelper.getSvgPath('blood_pressure.svg'),
        );
      case MetricType.bloodSugar:
        return HealthMetric(
          type: type,
          name: 'Blood Sugar',
          nameId: 'Gula Darah',
          unit: 'mg/dL',
          displayValue: '--',
          lastUpdated: DateTime.now(),
          status: HealthMetricData.getBloodSugarStatus(0, age),
          icon: PhosphorIcons.testTube(PhosphorIconsStyle.fill),
          primaryColor: _bloodSugarColor,
          recentValues: const [],
          isPlaceholder: true,
          svgIcon: AssetHelper.getIconPath('icons8-sugar-cubes.svg'),
          svgBackground: AssetHelper.getSvgPath('blood_sugar.svg'),
        );
      case MetricType.cholesterol:
        return HealthMetric(
          type: type,
          name: 'Cholesterol',
          nameId: 'Kolesterol',
          unit: 'mg/dL',
          displayValue: '--',
          lastUpdated: DateTime.now(),
          status: HealthMetricData.getCholesterolStatus(0, age),
          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
          primaryColor: _cholesterolColor,
          recentValues: const [],
          isPlaceholder: true,
          svgBackground: AssetHelper.getSvgPath('cholestrol.svg'),
        );
      case MetricType.uricAcid:
        return HealthMetric(
          type: type,
          name: 'Uric Acid',
          nameId: 'Asam Urat',
          unit: 'mg/dL',
          displayValue: '--',
          lastUpdated: DateTime.now(),
          status: HealthMetricData.getUricAcidStatus(0, age, gender),
          icon: PhosphorIcons.flask(PhosphorIconsStyle.fill),
          primaryColor: _uricAcidColor,
          recentValues: const [],
          isPlaceholder: true,
          svgBackground: AssetHelper.getSvgPath('uric_acid.svg'),
        );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 3) return 'Selamat Dini Hari,';
    if (hour < 5) return 'Selamat Subuh,';
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  int _getDaysUntilAppointment() {
    if (_nextAppointment == null) return -1;
    final dateStr = _nextAppointment!['date'];
    DateTime appointmentDate;
    if (dateStr is DateTime) {
      appointmentDate = dateStr;
    } else if (dateStr is String) {
      appointmentDate = DateTime.parse(dateStr);
    } else {
      return -1;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    return apptDay.difference(today).inDays;
  }

  bool _shouldShowAppointmentBanner() {
    if (_nextAppointment == null) return false;
    final days = _getDaysUntilAppointment();
    return days <= 7 && days >= 0;
  }

  String _appointmentCountdownLabel(int days) {
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _metrics.isEmpty) {
      return ErrorStateWidget(message: _error!, onRetry: _refresh);
    }

    final profile = ProfileService.instance.activeProfile;
    final userGender = profile?.gender ?? 'Pria';

    final daysUntilAppointment = _getDaysUntilAppointment();
    final showAppointmentBanner = _shouldShowAppointmentBanner();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                color: AppColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 16),

                    // Greeting Section with Profile Dropdown and Notification Icon
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: math.max(ResponsiveSize.paddingMedium, 16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<FamilyProfile?>(
                              stream:
                                  ProfileService.instance.activeProfileStream,
                              initialData:
                                  ProfileService.instance.activeProfile,
                              builder: (context, activeSnapshot) {
                                final activeProfile = activeSnapshot.data;
                                final multiProfile =
                                    ProfileService.instance.profiles.length > 1;

                                // One gesture for the whole header: with
                                // multiple profiles it opens the switcher,
                                // otherwise it goes to the Profil tab.
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: multiProfile
                                      ? _showProfileSwitcher
                                      : () => widget.onSwitchTab?.call(3),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppAvatar(
                                        imageUrl: activeProfile?.avatarUrl,
                                        size: 44,
                                        backgroundColor: AppColors
                                            .primarySurface
                                            .withValues(alpha: 0.3),
                                        borderColor: AppColors.primary
                                            .withValues(alpha: 0.2),
                                        borderWidth: 2,
                                        fallback: Icon(
                                          activeProfile != null
                                              ? _getGenderIcon(
                                                  activeProfile.gender,
                                                )
                                              : Icons.person_outline,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getGreeting(),
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontSize: math.min(
                                                  ResponsiveSize.fontMedium,
                                                  16,
                                                ),
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activeProfile?.name ?? 'Pengguna',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize:
                                                    ResponsiveSize.fontXLarge,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (activeProfile != null && multiProfile)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const NotificationBell(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAppointmentBanner) ...[
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: math.max(
                                ResponsiveSize.paddingMedium,
                                16,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.cardShadowLight,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _appointmentCountdownLabel(
                                            daysUntilAppointment,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _nextAppointment?['title']
                                                  as String? ??
                                              'Janji Temu',
                                          style: TextStyle(
                                            fontSize: ResponsiveSize.fontXLarge,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Image.asset(
                                    AssetHelper.getIllustrationPath(
                                      'Mediana-banner.webp',
                                    ),
                                    height: math.min(screenWidth * 0.22, 120),
                                    width: math.min(screenWidth * 0.22, 120),
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveSize.spacingMedium),
                        ],

                        // Metrics Grid Section
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: math.max(
                              ResponsiveSize.paddingMedium,
                              12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0,
                                padding: EdgeInsets.zero,
                                children: _metrics
                                    .map(_buildMetricCard)
                                    .toList(),
                              ),

                              const SizedBox(height: 10),

                              // Action Button
                              _buildActionButton(
                                title: 'Lihat Laporan Lengkap',
                                subtitle: 'Riwayat dan detail pemeriksaan',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    ParallaxPageRoute(
                                      page: LaporanSayaScreen(
                                        gender: userGender,
                                      ),
                                    ),
                                  );
                                },
                                screenWidth: screenWidth,
                              ),

                              SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 16,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildMetricCard(HealthMetric metric) {
    return _MetricCardWrapper(metric: metric);
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    final iconSize = math.min(
      ResponsiveSize.iconLarge * 0.8,
      screenWidth * 0.08,
    );
    final fontTitle = math.min(ResponsiveSize.fontLarge, screenWidth * 0.04);
    final fontSubtitle = math.min(
      ResponsiveSize.fontSmall,
      screenWidth * 0.032,
    );
    final arrowSize = math.min(ResponsiveSize.iconSmall * 0.7, 16.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(math.max(ResponsiveSize.paddingMedium, 14)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(
            math.max(ResponsiveSize.cardBorderRadius, 16),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              AssetHelper.getIconPath('icons8-combo-chart.svg'),
              height: iconSize * 2.2,
              width: iconSize * 2.2,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: math.max(ResponsiveSize.paddingMedium, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: fontTitle,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: math.max(ResponsiveSize.spacingSmall * 0.5, 4),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: fontSubtitle,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: arrowSize,
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ProfileSwitcherSheet(),
    );
  }

  IconData _getGenderIcon(String gender) {
    return gender == 'Pria' ? Icons.male : Icons.female;
  }
}

class _MetricCardWrapper extends StatelessWidget {
  final HealthMetric metric;

  const _MetricCardWrapper({required this.metric});

  @override
  Widget build(BuildContext context) {
    final cardColor = Color.lerp(Colors.white, metric.primaryColor, 0.15)!;

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 450),
      closedElevation: 0,
      openElevation: 0,
      closedColor: cardColor,
      openColor: cardColor,
      middleColor: cardColor,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      closedBuilder: (context, openContainer) {
        return _MetricCardContent(metric: metric);
      },
      openBuilder: (context, closeContainer) {
        return MetricDetailScreen(metric: metric);
      },
    );
  }
}

class _MetricCardContent extends StatelessWidget {
  final HealthMetric metric;

  const _MetricCardContent({required this.metric});

  @override
  Widget build(BuildContext context) {
    final cardColor = Color.lerp(Colors.white, metric.primaryColor, 0.15)!;

    // Per-metric background illustration treatment.
    final ({BoxFit fit, Alignment align, double opacity, double scale}) bg =
        switch (metric.type) {
          MetricType.bloodPressure => (
            fit: BoxFit.contain,
            align: Alignment.center,
            opacity: 0.65,
            scale: 0.65,
          ),
          MetricType.bloodSugar => (
            fit: BoxFit.fitWidth,
            align: Alignment.center,
            opacity: 0.7,
            scale: 1.0,
          ),
          MetricType.cholesterol => (
            fit: BoxFit.fitWidth,
            align: Alignment.center,
            opacity: 0.7,
            scale: 1.0,
          ),
          MetricType.uricAcid => (
            fit: BoxFit.contain,
            align: Alignment.center,
            opacity: 0.7,
            scale: 1.0,
          ),
        };

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Illustration behind everything (clipped to the card by OpenContainer)
        if (metric.svgBackground != null) ...[
          Positioned.fill(
            child: RepaintBoundary(
              child: Opacity(
                opacity: bg.opacity,
                child: Transform.scale(
                  scale: bg.scale,
                  child: SvgPicture.asset(
                    metric.svgBackground!,
                    fit: bg.fit,
                    alignment: bg.align,
                  ),
                ),
              ),
            ),
          ),
          // Identity-color wash: strong over name/value (top-left),
          // fading out fast so the enlarged art stays visible elsewhere.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor.withValues(alpha: 0.9),
                    cardColor.withValues(alpha: 0.15),
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
        ],
        if (!metric.isPlaceholder && metric.recentValues.length >= 2)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 52,
            child: Semantics(
              label: 'Grafik tren ${metric.nameId}',
              child: MiniSparkline(
                primaryColor: metric.primaryColor,
                values: metric.recentValues,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                metric.nameId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (metric.isPlaceholder)
                const Text(
                  'Belum ada data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      metric.displayValue,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      metric.unit,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
