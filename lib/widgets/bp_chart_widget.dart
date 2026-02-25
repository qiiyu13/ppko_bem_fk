import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/responsive_size.dart';
import '../../constants/app_colors.dart';

class BloodPressureChart extends StatelessWidget {
  final List<BPScreeningData> data;

  const BloodPressureChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Belum ada data screening'));
    }

    // Sort data by date
    final sortedData = List<BPScreeningData>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get min/max for Y axis
    final allValues = sortedData.expand((d) => [d.systolic, d.diastolic]);
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 10).toDouble();
    final maxY = (allValues.reduce((a, b) => a > b ? a : b) + 10).toDouble();

    // Create spots for both lines
    final systolicSpots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolic.toDouble());
    }).toList();

    final diastolicSpots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolic.toDouble());
    }).toList();

    // Get latest reading
    final latest = sortedData.last;

    return Column(
      children: [
        // Latest reading display
        Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveSize.cardBorderRadius,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: ResponsiveSize.iconMedium,
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Text(
                'Terbaru: ${latest.systolic}/${latest.diastolic} mmHg',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingMedium),
        // Chart
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.surface, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: ResponsiveSize.fontSmall,
                        ),
                      );
                    },
                  ),
                  axisNameWidget: Text(
                    'mmHg',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveSize.fontSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedData.length) {
                        final date = sortedData[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveSize.fontSmall,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: AppColors.surface),
                  left: BorderSide(color: AppColors.surface),
                ),
              ),
              minX: 0,
              maxX: (sortedData.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                // Systolic line
                LineChartBarData(
                  spots: systolicSpots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.background,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                // Diastolic line
                LineChartBarData(
                  spots: diastolicSpots,
                  isCurved: true,
                  color: AppColors.primarySurface,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.primarySurface,
                        strokeWidth: 2,
                        strokeColor: AppColors.background,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primarySurface.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => AppColors.background,
                  tooltipBorder: BorderSide(color: AppColors.surface),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isSystolic = spot.barIndex == 0;
                      final value = spot.y.toInt();
                      return LineTooltipItem(
                        '${isSystolic ? 'Sistolik' : 'Diastolik'}: $value mmHg',
                        TextStyle(
                          color: isSystolic
                              ? AppColors.primary
                              : AppColors.primarySurface,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveSize.fontSmall,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingMedium),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Sistolik', AppColors.primary),
            SizedBox(width: ResponsiveSize.spacingLarge),
            _buildLegendItem('Diastolik', AppColors.primarySurface),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.fontSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class BPScreeningData {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final double weight;
  final double height;
  final double bloodSugar;
  final double uricAcid;
  final double cholesterol;

  BPScreeningData({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.weight,
    required this.height,
    required this.bloodSugar,
    required this.uricAcid,
    required this.cholesterol,
  });

  // Calculate BMI
  double get bmi {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String get bmiCategory {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }
}
