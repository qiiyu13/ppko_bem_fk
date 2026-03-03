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
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _headerController;
  late AnimationController _chartController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _chartFadeAnimation;
  late Animation<Offset> _chartSlideAnimation;
  bool _isClosing = false;
  late List<MetricReading> _readings;

  @override
  void initState() {
    super.initState();
    _readings = HealthMetricData.getMockHistoryForType(widget.metric.type);

    // Background color: white -> metric color (100ms)
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _backgroundColorAnimation =
        ColorTween(
          begin: AppColors.card,
          end: widget.metric.primaryColor,
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Header fades in (100ms)
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );

    // Chart slides up (300ms)
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chartFadeAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _chartSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
        );

    // Use transition animation to drive content appearance
    if (widget.transitionAnimation != null) {
      widget.transitionAnimation!.addListener(_onTransitionUpdate);
    } else {
      // Fallback: animate immediately
      _colorController.forward();
      _headerController.forward();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _chartController.forward();
      });
    }
  }

  void _onTransitionUpdate() {
    if (!mounted) return;

    final value = widget.transitionAnimation!.value;
    if (value >= 1.0 && _colorController.status == AnimationStatus.dismissed) {
      // Hero complete: start color -> header -> chart sequence
      _colorController.forward().then((_) {
        if (!mounted) return;
        _headerController.forward().then((_) {
          if (mounted) _chartController.forward();
        });
      });
      widget.transitionAnimation!.removeListener(_onTransitionUpdate);
    }
  }

  @override
  void dispose() {
    widget.transitionAnimation?.removeListener(_onTransitionUpdate);
    _colorController.dispose();
    _headerController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    // Exit sequence: chart + header + color all together (300ms) -> wait (400ms) -> pop
    // Total: ~700ms before pop
    await Future.wait([
      _chartController.reverse(),
      _headerController.reverse(),
      _colorController.reverse(),
    ]);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundColorAnimation,
      builder: (context, child) {
        return Hero(
          tag: 'metric_${widget.metric.type.name}',
          child: Material(
            color: _backgroundColorAnimation.value,
            child: Scaffold(
              backgroundColor: _backgroundColorAnimation.value,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header with back button and metric info (fades in)
                    FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: _buildHeader(),
                    ),

                    // Chart section slides up after header
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _chartController,
                        builder: (context, child) {
                          final slideOffset =
                              (1 - _chartSlideAnimation.value.dy) * 30;
                          return Visibility(
                            visible: _chartFadeAnimation.value > 0.01,
                            child: Opacity(
                              opacity: _chartFadeAnimation.value,
                              child: Transform.translate(
                                offset: Offset(0, slideOffset),
                                child: child,
                              ),
                            ),
                          );
                        },
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
                              // Chart with proper constraints
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      child: MetricChart(
                                        type: widget.metric.type,
                                        readings: _readings,
                                        primaryColor:
                                            widget.metric.primaryColor,
                                      ),
                                    );
                                  },
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
      },
    );
  }

  Widget _buildHeader() {
    return Container(
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
