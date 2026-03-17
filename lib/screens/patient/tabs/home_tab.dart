import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/asset_helper.dart';
import '../../../utils/responsive_size.dart';
import '../../../screens/patient/laporan_saya_screen.dart';
import '../../../screens/patient/metrics/metric_detail_screen.dart';
import '../../../models/health_metric.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';
// Profile selector is now integrated as dropdown in greeting section
import 'dart:math' as math;

// Bar Chart Widget
class MiniBarChart extends StatelessWidget {
  final Color primaryColor;
  final int barCount;

  const MiniBarChart({
    super.key,
    required this.primaryColor,
    this.barCount = 9,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(42); // Fixed seed for consistency

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (index) {
        // Random height between 0.3 and 1.0
        final height = 0.3 + random.nextDouble() * 0.7;
        // Every 3rd bar is highlighted
        final isHighlighted = index % 3 == 0;

        return Container(
          width: 8,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 6,
              height: 48 * height,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  // Mock appointment data
  final Map<String, dynamic> _nextAppointment = {
    'title': 'Medical Screening',
    'date': DateTime.now().add(const Duration(days: 5)),
    'location': 'Balai Desa Sukamaju',
  };

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  int _getDaysUntilAppointment() {
    final appointmentDate = _nextAppointment['date'] as DateTime;
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);
    return difference.inDays;
  }

  bool _shouldShowAppointmentBanner() {
    return _getDaysUntilAppointment() <= 7 && _getDaysUntilAppointment() >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    // Mock user data - in real app, this comes from user profile
    const userAge = 45;
    const userGender = 'Pria';
    const userName = 'Pak Budi';

    final metrics = HealthMetricData.getMockMetrics(
      age: userAge,
      gender: userGender,
    );

    final daysUntilAppointment = _getDaysUntilAppointment();
    final showAppointmentBanner = _shouldShowAppointmentBanner();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        // Left side: Greeting and Profile
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 8),
                              // Profile Dropdown Button
                              StreamBuilder<List<FamilyProfile>>(
                                stream: ProfileService.instance.profilesStream,
                                initialData: ProfileService.instance.profiles,
                                builder: (context, profilesSnapshot) {
                                  final profiles = profilesSnapshot.data ?? [];
                                  return StreamBuilder<FamilyProfile?>(
                                    stream: ProfileService
                                        .instance
                                        .activeProfileStream,
                                    initialData:
                                        ProfileService.instance.activeProfile,
                                    builder: (context, activeSnapshot) {
                                      final activeProfile = activeSnapshot.data;
                                      if (activeProfile == null)
                                        return const SizedBox.shrink();

                                      return GestureDetector(
                                        onTap: () => _showProfileDropdown(
                                          context,
                                          activeProfile,
                                          profiles,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              activeProfile.name,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Right side: Notification Icon
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to notifications screen or show dropdown
                          },
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
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  // Notification badge (uncomment when needed)
                                  // Positioned(
                                  //   right: 0,
                                  //   top: 0,
                                  //   child: Container(
                                  //     width: 8,
                                  //     height: 8,
                                  //     decoration: BoxDecoration(
                                  //       color: Colors.red,
                                  //       shape: BoxShape.circle,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Appointment Banner (conditional)
                  if (showAppointmentBanner)
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: math.max(ResponsiveSize.paddingMedium, 16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$daysUntilAppointment hari menuju',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _nextAppointment['title'] as String,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SvgPicture.asset(
                              AssetHelper.getSvgPath('medical-research-v2.svg'),
                              height: 86,
                              width: 86,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (showAppointmentBanner)
                    SizedBox(height: ResponsiveSize.spacingMedium),

                  // Metrics Grid Section
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: math.max(ResponsiveSize.paddingMedium, 12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2x2 Metrics Grid - Fixed 2 columns with square cards
                        // Calculate exact height: 2 rows of cards + 1 spacing
                        // Card width = (availableWidth - crossAxisSpacing) / 2
                        // Since aspect ratio is 1:1, card height = card width
                        // Grid height = (cardHeight * 2) + mainAxisSpacing
                        LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final gridWidth = gridConstraints.maxWidth;
                            final cardWidth = (gridWidth - 16) / 2;
                            final cardHeight = cardWidth; // 1:1 aspect ratio
                            final gridHeight = (cardHeight * 2) + 16;

                            return Container(
                              height: gridHeight,
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0, // Perfect square 1:1
                                children: metrics.map((metric) {
                                  return _buildMetricCard(
                                    context: context,
                                    metric: metric,
                                    screenWidth: screenWidth,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // Action Button
                        _buildActionButton(
                          title: 'Lihat Laporan Lengkap',
                          subtitle: 'Riwayat dan detail pemeriksaan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LaporanSayaScreen(),
                              ),
                            );
                          },
                          screenWidth: screenWidth,
                        ),

                        // Bottom spacer for nav bar clearance
                        SizedBox(
                          height: math.max(
                            ResponsiveSize.spacingXLarge * 2,
                            80.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required HealthMetric metric,
    required double screenWidth,
  }) {
    // Dynamic icon size based on screen width
    final iconSize = screenWidth < 360
        ? 18.0
        : (screenWidth < 400 ? 20.0 : 22.0);
    final chipSize = iconSize + 12.0;

    return _MetricCardWrapper(
      metric: metric,
      iconSize: iconSize,
      chipSize: chipSize,
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    // Adaptive sizes
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
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              AssetHelper.getSvgPath('document-icon.svg'),
              height: iconSize * 2.2,
              width: iconSize * 2.2,
              fit: BoxFit.contain,
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

  void _showProfileDropdown(
    BuildContext context,
    FamilyProfile activeProfile,
    List<FamilyProfile> profiles,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset(0, button.size.height + 8),
          ancestor: overlay,
        ),
        button.localToGlobal(
          Offset(button.size.width, button.size.height + 8),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.card,
      items: profiles.map((profile) {
        final isSelected = profile.id == activeProfile.id;
        return PopupMenuItem<String>(
          value: profile.id,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, color: AppColors.primary, size: 20),
                if (isSelected) const SizedBox(width: 8),
                Text(
                  profile.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).then((selectedId) {
      if (selectedId != null) {
        ProfileService.instance.setActiveProfile(selectedId);
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Custom RectTween that provides a smooth, linear expansion of the rect.
// We remove the internal curve transform to avoid the 'bounce' effect caused by double-curving.
class _SmoothAspectRatioRectTween extends RectTween {
  _SmoothAspectRatioRectTween({required Rect? begin, required Rect? end})
    : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    if (begin == null || end == null) return super.lerp(t) ?? Rect.zero;

    // Linear interpolation of all properties. The PageRoute's animation curve
    // already provides the necessary easing (e.g., easeInOut).
    return Rect.fromCenter(
      center: Offset(
        begin!.center.dx + (end!.center.dx - begin!.center.dx) * t,
        begin!.center.dy + (end!.center.dy - begin!.center.dy) * t,
      ),
      width: begin!.width + (end!.width - begin!.width) * t,
      height: begin!.height + (end!.height - begin!.height) * t,
    );
  }
}

// Separate widget for animated metric card with pre-flight animation
class _MetricCardWrapper extends StatefulWidget {
  final HealthMetric metric;
  final double iconSize;
  final double chipSize;

  const _MetricCardWrapper({
    required this.metric,
    required this.iconSize,
    required this.chipSize,
  });

  @override
  State<_MetricCardWrapper> createState() => _MetricCardWrapperState();
}

class _MetricCardWrapperState extends State<_MetricCardWrapper> {
  @override
  Widget build(BuildContext context) {
    final metricId = widget.metric.type.name;

    // Use our custom SmoothAspectRatioRectTween for linear, predictable movement
    RectTween createTween(Rect? begin, Rect? end) {
      return _SmoothAspectRatioRectTween(begin: begin, end: end);
    }

    return GestureDetector(
      onTap: _onCardTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Background Hero
          Positioned.fill(
            child: Hero(
              tag: 'metric_bg_$metricId',
              createRectTween: createTween,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.metric.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Mini Chart (NOT a hero - just static)
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: MiniBarChart(
              primaryColor: widget.metric.primaryColor,
              barCount: 9,
            ),
          ),

          // 3. Content: Title, Value, Unit (NOT heroes - just text)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.metric.nameId,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.card,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.metric.displayValue,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.card,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.metric.unit,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.card,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Icon Hero
          Positioned(
            top: 0,
            right: 0,
            child: Hero(
              tag: 'metric_icon_$metricId',
              createRectTween: createTween,
              child: Container(
                width: widget.chipSize,
                height: widget.chipSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.all(widget.chipSize * 0.2),
                child: Icon(
                  widget.metric.icon,
                  color: AppColors.card,
                  size: widget.iconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCardTap() {
    // Navigate with custom transparent route to keep home screen visible during animation
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Allow home screen to show through
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return MetricDetailScreen(
            metric: widget.metric,
            routeAnimation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // No fade transition - let hero animation be the only animation
          // This prevents compositing issues at animation boundaries
          return child;
        },
      ),
    );
  }
}
