import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import '../../../screens/patient/laporan_saya_screen.dart';
import '../../../screens/patient/metrics/metric_detail_screen.dart';
import '../../../models/health_metric.dart';
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
          width: 6,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 4.5,
              height: 36 * height,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.5),
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

                  // Greeting Section
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: math.max(ResponsiveSize.paddingMedium, 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: math.min(ResponsiveSize.fontMedium, 16),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$userName!',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: math.min(ResponsiveSize.fontXXLarge, 28),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SvgPicture.asset(
                              'assets/svg/medical-research-centered (1).svg',
                              height: 72,
                              width: 72,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$daysUntilAppointment hari menuju',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _nextAppointment['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (showAppointmentBanner) const SizedBox(height: 16),

                  // Metrics Grid Section
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: math.max(ResponsiveSize.paddingMedium, 12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2x2 Metrics Grid - Fixed 2 columns with square cards
                        GridView.count(
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

                        SizedBox(
                          height: math.max(ResponsiveSize.spacingXLarge, 16.0),
                        ),

                        // Action Button
                        _buildActionButton(
                          icon: Icons.description_outlined,
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) {
              return MetricDetailScreen(metric: metric);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;
            },
          ),
        );
      },
      child: Hero(
        tag: 'metric_${metric.type.name}',
        createRectTween: (begin, end) {
          return MaterialRectArcTween(begin: begin, end: end);
        },
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Content - Layout for square card
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Spacer for chipped corner icon
                        const SizedBox(height: 8),

                        // Metric Name
                        Text(
                          metric.nameId,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Value + Unit (colored)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              metric.displayValue,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: metric.primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              metric.unit,
                              style: TextStyle(
                                fontSize: 11,
                                color: metric.primaryColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Mini Bar Chart - centered
                        Center(
                          child: MiniBarChart(
                            primaryColor: metric.primaryColor,
                            barCount: 9,
                          ),
                        ),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  // Chipped corner icon in top-right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: chipSize,
                      height: chipSize,
                      decoration: BoxDecoration(
                        color: metric.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          metric.icon,
                          color: metric.primaryColor,
                          size: iconSize.toDouble(),
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
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
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(
            math.max(ResponsiveSize.cardBorderRadius, 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                math.max(ResponsiveSize.paddingSmall + 4, 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.textOnPrimary, size: iconSize),
            ),
            SizedBox(width: math.max(ResponsiveSize.paddingMedium, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
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
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      fontSize: fontSubtitle,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.background,
                size: arrowSize,
              ),
            ),
          ],
        ),
      ),
    );
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
