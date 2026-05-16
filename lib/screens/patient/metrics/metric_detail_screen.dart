import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/health_metric.dart';
import '../../../widgets/metric_chart.dart';
import '../../../services/api_service.dart';
import '../../../services/profile_service.dart';

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
  late Animation<Offset> _slideAnimation;
  bool _isClosing = false;
  List<MetricReading> _readings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    _contentFadeAnimation = CurvedAnimation(
      parent: widget.routeAnimation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _chartFadeAnimation = CurvedAnimation(
      parent: widget.routeAnimation,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.routeAnimation,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final profileId = ProfileService.instance.activeProfile?.id;
      if (profileId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Tidak ada profil aktif';
        });
        return;
      }

      final typePath = _metricTypeToPath(widget.metric.type);
      final response = await ApiService.get(
        '/metrics/$typePath/history',
        queryParameters: {'profileId': profileId},
      );

      final data = response.data['data'] as List? ?? [];
      setState(() {
        _readings = data.map((json) {
          final map = json as Map<String, dynamic>;
          return MetricReading(
            date: DateTime.parse(map['date'] as String),
            value: (map['value'] as num).toDouble(),
            secondaryValue: map['secondaryValue'] != null
                ? (map['secondaryValue'] as num).toDouble()
                : null,
            notes: map['notes'] as String?,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat riwayat: $e';
      });
    }
  }

  String _metricTypeToPath(MetricType type) {
    switch (type) {
      case MetricType.bloodPressure: return 'blood_pressure';
      case MetricType.cholesterol: return 'cholesterol';
      case MetricType.bloodSugar: return 'blood_sugar';
      case MetricType.uricAcid: return 'uric_acid';
    }
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final metricId = widget.metric.type.name;

    RectTween createTween(Rect? begin, Rect? end) {
      return _SmoothAspectRatioRectTween(begin: begin, end: end);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'metric_bg_$metricId',
            transitionOnUserGestures: false,
            createRectTween: createTween,
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(Colors.white, widget.metric.primaryColor, 0.15),
                borderRadius: BorderRadius.zero,
                boxShadow: const [],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(createTween),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _slideAnimation,
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
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
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
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            )
                          else if (_error != null)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.cloud_off, size: 40, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadHistory,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const _kTallScreenThreshold = 750.0;
                                final chartHeight = constraints.maxHeight > _kTallScreenThreshold
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
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
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
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Text(
                        widget.metric.nameId,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Text(
                        widget.metric.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Hero(
                tag: 'metric_icon_$metricId',
                transitionOnUserGestures: false,
                createRectTween: createTween,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(-2, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.metric.icon,
                    color: widget.metric.primaryColor,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: Text(
                  widget.metric.unit,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _contentFadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    HealthMetricData.getStatusIcon(widget.metric.status),
                    color: widget.metric.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    HealthMetricData.getStatusLabel(widget.metric.status),
                    style: TextStyle(
                      color: widget.metric.primaryColor,
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

class _SmoothAspectRatioRectTween extends RectTween {
  _SmoothAspectRatioRectTween({required super.begin, required super.end});

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
