import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants/app_colors.dart';
import '../../../models/health_metric.dart';
import '../../../widgets/metric_chart.dart';
import '../../../services/api_service.dart';
import '../../../services/profile_service.dart';

class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  List<MetricReading> _readings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

  @override
  Widget build(BuildContext context) {
    final cardColor = Color.lerp(
      Colors.white,
      widget.metric.primaryColor,
      0.15,
    )!;

    return Scaffold(
      backgroundColor: cardColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.metric.nameId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.metric.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
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
                        child: widget.metric.svgIcon != null
                            ? SvgPicture.asset(
                                widget.metric.svgIcon!,
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  widget.metric.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(
                                widget.metric.icon,
                                color: widget.metric.primaryColor,
                                size: 28,
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
                      Text(
                        widget.metric.displayValue,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.metric.unit,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
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
                        const Text(
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
                  Expanded(child: _buildChartArea()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return MetricChart(
      type: widget.metric.type,
      readings: _readings,
      primaryColor: widget.metric.primaryColor,
    );
  }
}
