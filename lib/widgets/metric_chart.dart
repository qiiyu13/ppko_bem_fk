import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/health_metric.dart';
import '../constants/app_colors.dart';

class MetricChart extends StatefulWidget {
  final MetricType type;
  final List<MetricReading> readings;
  final Color primaryColor;

  const MetricChart({
    super.key,
    required this.type,
    required this.readings,
    required this.primaryColor,
  });

  @override
  State<MetricChart> createState() => _MetricChartState();
}

class _MetricChartState extends State<MetricChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.readings.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data historis',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Chart Container - fills the fixed height from parent
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ),
        // Legend
        _buildLegend(),
        const SizedBox(height: 16),
      ],
    );
  }

  LineChartData _buildChartData() {
    final spots = _getSpots();
    final minY = _getMinY();
    final maxY = _getMaxY();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getHorizontalInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getBottomInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.readings.length) {
                final date = widget.readings[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getHorizontalInterval(),
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(
                  widget.type == MetricType.uricAcid ? 1 : 0,
                ),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.readings.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // Reference zones (background) - clipped to chart bounds
        ..._buildReferenceZones(minY, maxY),
        // Main data line
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: widget.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isTouched = touchedIndex == index;
              return FlDotCirclePainter(
                radius: isTouched ? 8 : 5,
                color: widget.primaryColor,
                strokeWidth: isTouched ? 3 : 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: widget.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (touchedSpots) {
            // Must return same number of items as touchedSpots (one per line)
            return touchedSpots.map((spot) {
              // Only show tooltip for main data line (last in list)
              if (spot == touchedSpots.last) {
                final index = spot.x.toInt();
                if (index >= 0 && index < widget.readings.length) {
                  final reading = widget.readings[index];
                  return LineTooltipItem(
                    _getTooltipText(reading),
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
              }
              // Return null for reference zones (no tooltip)
              return null;
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          if (!event.isInterestedForInteractions ||
              touchResponse?.lineBarSpots == null ||
              touchResponse!.lineBarSpots!.isEmpty) {
            setState(() {
              touchedIndex = null;
            });
            return;
          }
          setState(() {
            touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
          });
        },
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return widget.readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  List<LineChartBarData> _buildReferenceZones(
    double chartMinY,
    double chartMaxY,
  ) {
    final zones = <LineChartBarData>[];

    // Helper to clip zone to chart bounds
    LineChartBarData? createClippedZone(
      double zoneMin,
      double zoneMax,
      Color color,
    ) {
      // Clip zone to chart bounds
      final clippedMin = zoneMin.clamp(chartMinY, chartMaxY);
      final clippedMax = zoneMax.clamp(chartMinY, chartMaxY);

      // Skip if zone is completely outside chart bounds
      if (clippedMin >= clippedMax) return null;

      return _createZoneLine(clippedMax, clippedMin, color);
    }

    switch (widget.type) {
      case MetricType.bloodPressure:
        // Normal zone: 90-120 (systolic) - clipped to chart bounds
        final normalZone = createClippedZone(
          90,
          120,
          AppColors.success.withValues(alpha: 0.15),
        );
        if (normalZone != null) zones.add(normalZone);

        // Warning zone: 120-140 - clipped to chart bounds
        final warningZone = createClippedZone(
          120,
          140,
          AppColors.warning.withValues(alpha: 0.15),
        );
        if (warningZone != null) zones.add(warningZone);

        // Critical zone: 140+ - clipped to chart bounds
        final criticalZone = createClippedZone(
          140,
          chartMaxY,
          AppColors.error.withValues(alpha: 0.15),
        );
        if (criticalZone != null) zones.add(criticalZone);
        break;
      case MetricType.cholesterol:
        // Normal: <200 - clipped to chart bounds
        final normalZone = createClippedZone(
          chartMinY,
          200,
          AppColors.success.withValues(alpha: 0.15),
        );
        if (normalZone != null) zones.add(normalZone);

        // Warning: 200-240 - clipped to chart bounds
        final warningZone = createClippedZone(
          200,
          240,
          AppColors.warning.withValues(alpha: 0.15),
        );
        if (warningZone != null) zones.add(warningZone);

        // Critical: >240 - clipped to chart bounds
        final criticalZone = createClippedZone(
          240,
          chartMaxY,
          AppColors.error.withValues(alpha: 0.15),
        );
        if (criticalZone != null) zones.add(criticalZone);
        break;
      case MetricType.bloodSugar:
        // Low: <70 - clipped to chart bounds
        final lowZone = createClippedZone(
          chartMinY,
          70,
          AppColors.error.withValues(alpha: 0.15),
        );
        if (lowZone != null) zones.add(lowZone);

        // Normal: 70-100 - clipped to chart bounds
        final normalZone = createClippedZone(
          70,
          100,
          AppColors.success.withValues(alpha: 0.15),
        );
        if (normalZone != null) zones.add(normalZone);

        // Warning: 100-126 - clipped to chart bounds
        final warningZone = createClippedZone(
          100,
          126,
          AppColors.warning.withValues(alpha: 0.15),
        );
        if (warningZone != null) zones.add(warningZone);

        // Critical: >126 - clipped to chart bounds
        final criticalZone = createClippedZone(
          126,
          chartMaxY,
          AppColors.error.withValues(alpha: 0.15),
        );
        if (criticalZone != null) zones.add(criticalZone);
        break;
      case MetricType.uricAcid:
        // Male: 3.5-7.2 - clipped to chart bounds
        final normalZone = createClippedZone(
          3.5,
          7.2,
          AppColors.success.withValues(alpha: 0.15),
        );
        if (normalZone != null) zones.add(normalZone);

        // Above normal: >7.2 - clipped to chart bounds
        final warningZone = createClippedZone(
          7.2,
          chartMaxY,
          AppColors.warning.withValues(alpha: 0.15),
        );
        if (warningZone != null) zones.add(warningZone);
        break;
    }

    return zones;
  }

  LineChartBarData _createZoneLine(double maxVal, double minVal, Color color) {
    return LineChartBarData(
      spots: [
        FlSpot(0, minVal),
        FlSpot((widget.readings.length - 1).toDouble(), minVal),
        FlSpot((widget.readings.length - 1).toDouble(), maxVal),
        FlSpot(0, maxVal),
      ],
      color: color,
      barWidth: 0,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color),
    );
  }

  double _getMinY() {
    final values = widget.readings.map((r) => r.value);
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble();
  }

  double _getMaxY() {
    final values = widget.readings.map((r) => r.value);
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble();
  }

  double _getHorizontalInterval() {
    final range = _getMaxY() - _getMinY();
    if (widget.type == MetricType.uricAcid) {
      return 1.0;
    }
    return (range / 5).roundToDouble();
  }

  double _getBottomInterval() {
    final count = widget.readings.length;
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    return (count / 6).ceilToDouble();
  }

  String _getTooltipText(MetricReading reading) {
    final dateStr = DateFormat('dd MMM yyyy').format(reading.date);
    final valueStr = widget.type == MetricType.uricAcid
        ? reading.value.toStringAsFixed(1)
        : reading.value.toStringAsFixed(0);

    if (widget.type == MetricType.bloodPressure &&
        reading.secondaryValue != null) {
      return '$dateStr\n$valueStr/${reading.secondaryValue!.toStringAsFixed(0)} ${widget.readings.first == reading
          ? ''
          : widget.readings.first.toString().contains('unit')
          ? ''
          : 'mmHg'}';
    }

    return '$dateStr\n$valueStr';
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem('Normal', AppColors.success),
          _buildLegendItem('Waspada', AppColors.warning),
          _buildLegendItem('Perhatian', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}
