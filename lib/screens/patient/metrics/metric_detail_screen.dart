import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/health_metric.dart';
import '../../../widgets/metric_chart.dart';

class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;
  final Animation<double>? transitionAnimation;

  const MetricDetailScreen({
    super.key,
    required this.metric,
    this.transitionAnimation,
  });

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  bool _isClosing = false;
  late List<MetricReading> _readings;

  @override
  void initState() {
    super.initState();
    _readings = HealthMetricData.getMockHistoryForType(widget.metric.type);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    // Use transition animation to drive content appearance
    if (widget.transitionAnimation != null) {
      // Listen to Hero transition and trigger content at 60%
      widget.transitionAnimation!.addListener(_onTransitionUpdate);
    }
  }

  void _onTransitionUpdate() {
    if (!mounted) return;

    final value = widget.transitionAnimation!.value;
    // Start content animation at 60% of Hero completion
    if (value >= 0.6 &&
        _contentController.status == AnimationStatus.dismissed) {
      _contentController.forward();
      widget.transitionAnimation!.removeListener(_onTransitionUpdate);
    }
  }

  @override
  void dispose() {
    widget.transitionAnimation?.removeListener(_onTransitionUpdate);
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    // Fade out content first
    await _contentController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'metric_${widget.metric.type.name}',
      child: Material(
        color: widget.metric.primaryColor,
        child: Scaffold(
          backgroundColor: widget.metric.primaryColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header with back button and metric info (part of hero)
                _buildHeader(),

                // Content that fades in
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
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
                          // Chart
                          Expanded(
                            child: MetricChart(
                              type: widget.metric.type,
                              readings: _readings,
                              primaryColor: widget.metric.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: widget.metric.primaryColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: _closeScreen,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.metric.nameId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.metric.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Status icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.metric.icon, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Value display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.metric.displayValue,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.metric.unit,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status badge
          Container(
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
        ],
      ),
    );
  }
}
