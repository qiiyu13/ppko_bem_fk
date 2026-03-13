import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/health_metric.dart';
import '../../../widgets/metric_chart.dart';

class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;
  final Animation<double> routeAnimation;

  const MetricDetailScreen({
    super.key,
    required this.metric,
    required this.routeAnimation,
  });

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen>
    with TickerProviderStateMixin {
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _chartFadeAnimation;
  bool _isClosing = false;
  late List<MetricReading> _readings;

  @override
  void initState() {
    super.initState();
    _readings = HealthMetricData.getMockHistoryForType(widget.metric.type);

    // Content fade animation synchronized with route animation
    // Content appears after hero is 75% complete (prevents flicker at boundaries)
    _contentFadeAnimation = CurvedAnimation(
      parent: widget.routeAnimation,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
    );

    // Chart fades in slightly later for staggered effect
    _chartFadeAnimation = CurvedAnimation(
      parent: widget.routeAnimation,
      curve: const Interval(0.80, 1.0, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    // Pop immediately - the route's reverse animation will handle content fade
    // Content fades out during first 25% of reverse animation
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final metricId = widget.metric.type.name;

    // Use our custom SmoothAspectRatioRectTween for linear, predictable movement
    RectTween createTween(Rect? begin, Rect? end) {
      return _SmoothAspectRatioRectTween(begin: begin, end: end);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero 1: Background surface
          Hero(
            tag: 'metric_bg_$metricId',
            transitionOnUserGestures: false,
            createRectTween: createTween,
            child: Container(
              decoration: BoxDecoration(
                color: widget.metric.primaryColor,
                // These will interpolate from the card's radius/shadow
                borderRadius: BorderRadius.zero,
                boxShadow: const [],
              ),
            ),
          ),

          // Content layer
          SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Header section with Heros - positioned at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(createTween),
                ),
                // Chart section - positioned at bottom, shrink-to-fit
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Chart title
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  color: widget.metric.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Riwayat Pengukuran',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Chart content - fades in with chart animation
                          // Adaptive height: 450px for taller screens, 280px for standard
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final chartHeight = constraints.maxHeight > 750
                                  ? 450.0
                                  : 280.0;
                              return SizedBox(
                                height: chartHeight,
                                child: FadeTransition(
                                  opacity: _chartFadeAnimation,
                                  child: MetricChart(
                                    type: widget.metric.type,
                                    readings: _readings,
                                    primaryColor: widget.metric.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RectTween Function(Rect? begin, Rect? end) createTween) {
    final metricId = widget.metric.type.name;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Back button (fades in) - always clickable
              AnimatedBuilder(
                animation: _contentFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: IgnorePointer(
                      ignoring: _contentFadeAnimation.value < 0.1,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _closeScreen,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - fades in with content
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Text(
                        widget.metric.nameId,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle (fades in)
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Text(
                        widget.metric.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Hero 5: Icon (always visible to destination)
              Hero(
                tag: 'metric_icon_$metricId',
                transitionOnUserGestures: false,
                createRectTween: createTween,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.metric.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Value display with Heros
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Value - fades in with content
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: Text(
                  widget.metric.displayValue,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Unit - fades in with content
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: Text(
                  widget.metric.unit,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status badge (fades in)
          FadeTransition(
            opacity: _contentFadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    HealthMetricData.getStatusIcon(widget.metric.status),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    HealthMetricData.getStatusLabel(widget.metric.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom RectTween that provides a smooth, linear expansion of the rect.
class _SmoothAspectRatioRectTween extends RectTween {
  _SmoothAspectRatioRectTween({required Rect? begin, required Rect? end})
    : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    if (begin == null || end == null) return super.lerp(t) ?? Rect.zero;

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
