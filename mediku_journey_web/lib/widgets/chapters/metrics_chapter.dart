// lib/widgets/chapters/metrics_chapter.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class MetricsChapter extends StatelessWidget {
  final Patient patient;

  const MetricsChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Perkembangan Kesehatan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (patient.metrics.containsKey('bloodPressure'))
              SlideInCard(
                delay: const Duration(milliseconds: 0),
                child: _buildMetricCard(
                  context,
                  title: 'Tekanan Darah',
                  metric: patient.metrics['bloodPressure']!,
                  color: Colors.red,
                  icon: Icons.favorite,
                  isBloodPressure: true,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('cholesterol'))
              SlideInCard(
                delay: const Duration(milliseconds: 300),
                child: _buildMetricCard(
                  context,
                  title: 'Kolesterol',
                  metric: patient.metrics['cholesterol']!,
                  color: Colors.orange,
                  icon: Icons.water_drop,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('bloodSugar'))
              SlideInCard(
                delay: const Duration(milliseconds: 600),
                child: _buildMetricCard(
                  context,
                  title: 'Gula Darah',
                  metric: patient.metrics['bloodSugar']!,
                  color: Colors.green,
                  icon: Icons.bloodtype,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('uricAcid'))
              SlideInCard(
                delay: const Duration(milliseconds: 900),
                child: _buildMetricCard(
                  context,
                  title: 'Asam Urat',
                  metric: patient.metrics['uricAcid']!,
                  color: Colors.purple,
                  icon: Icons.science,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required HealthMetricData metric,
    required Color color,
    required IconData icon,
    bool isBloodPressure = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${metric.current} ${metric.unit ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _buildLineChart(metric, color, isBloodPressure),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    HealthMetricData metric,
    Color color,
    bool isBloodPressure,
  ) {
    final spots = metric.history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
