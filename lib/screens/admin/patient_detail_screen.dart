import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../utils/date_utils.dart';
import '../../utils/patient_utils.dart';
import '../../utils/responsive_size.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  // Mock medical history data
  List<Map<String, dynamic>> get _medicalHistory {
    return [
      {
        'date': DateTime(2023, 11, 9),
        'systolic': 118,
        'diastolic': 76,
        'weight': 69.5,
        'height': 168,
        'bloodSugar': 87,
        'uricAcid': 4.7,
        'cholesterol': 162,
      },
      {
        'date': DateTime(2023, 11, 2),
        'systolic': 121,
        'diastolic': 78,
        'weight': 69.8,
        'height': 168,
        'bloodSugar': 91,
        'uricAcid': 5.1,
        'cholesterol': 175,
      },
      {
        'date': DateTime(2023, 10, 26),
        'systolic': 119,
        'diastolic': 77,
        'weight': 70.2,
        'height': 168,
        'bloodSugar': 89,
        'uricAcid': 4.9,
        'cholesterol': 170,
      },
      {
        'date': DateTime(2023, 10, 19),
        'systolic': patient['systolic'],
        'diastolic': patient['diastolic'],
        'weight': 70.5,
        'height': 168,
        'bloodSugar': 86,
        'uricAcid': 4.8,
        'cholesterol': 165,
      },
    ];
  }

  double _calculateBMI(double weight, double height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  String _getBPStatus(int systolic, int diastolic) {
    if (systolic <= 90 && diastolic <= 60) return 'RENDAH';
    if (systolic >= 140 || diastolic >= 90) return 'TINGGI';
    if (systolic >= 120 && systolic <= 129 && diastolic <= 80)
      return 'ELEVATED';
    if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 81 && diastolic <= 89)) {
      return 'TINGGI STAGE 1';
    }
    return 'NORMAL';
  }

  Color _getBPStatusColor(String status) {
    switch (status) {
      case 'NORMAL':
      case 'ELEVATED':
        return AppColors.success;
      case 'RENDAH':
      case 'TINGGI':
      case 'TINGGI STAGE 1':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }


  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final riskColor = PatientUtils.riskColor(patient['riskLevel']);
    final latestData = _medicalHistory.first;
    final bmi = _calculateBMI(latestData['weight'], latestData['height']);
    final bmiCategory = _getBMICategory(bmi);
    final bpStatus = _getBPStatus(patient['systolic'], patient['diastolic']);
    final bpStatusColor = _getBPStatusColor(bpStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Pasien',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingMedium),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient['name'],
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontXXLarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                            Text(
                              'NIK: ${patient['nik']}',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacingSmall),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.textSecondary,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  patient['village'],
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.fontMedium,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  Divider(color: AppColors.surface),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Risk Level Badge
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: riskColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          patient['riskLevel'] == 'high'
                              ? Icons.warning
                              : patient['riskLevel'] == 'attention'
                              ? Icons.info
                              : Icons.check_circle,
                          color: riskColor,
                          size: ResponsiveSize.iconMedium,
                        ),
                        SizedBox(width: ResponsiveSize.paddingSmall),
                        Text(
                          'Status: ${PatientUtils.riskLabel(patient['riskLevel'])}',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: ResponsiveSize.fontLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.spacingXLarge),

            // Latest Vitals
            _buildSectionHeader('Vital Signs Terkini'),
            SizedBox(height: ResponsiveSize.spacingMedium),
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1),
              ),
              child: Column(
                children: [
                  // Blood Pressure
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalCard(
                          'Tekanan Darah',
                          '${patient['systolic']}/${patient['diastolic']}',
                          'mmHg',
                          bpStatus,
                          bpStatusColor,
                          Icons.favorite,
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall),
                      Expanded(
                        child: _buildVitalCard(
                          'BMI',
                          bmi.toStringAsFixed(1),
                          bmiCategory,
                          bmiCategory.toUpperCase(),
                          bmi < 25
                              ? AppColors.success
                              : AppColors.primarySurface,
                          Icons.monitor_weight_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Weight and Height
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleVitalCard(
                          'Berat Badan',
                          '${latestData['weight']}',
                          'kg',
                          Icons.scale_outlined,
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall),
                      Expanded(
                        child: _buildSimpleVitalCard(
                          'Tinggi Badan',
                          '${latestData['height']}',
                          'cm',
                          Icons.height,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.spacingXLarge),

            // Blood Pressure Chart
            _buildSectionHeader('Riwayat Tekanan Darah'),
            SizedBox(height: ResponsiveSize.spacingMedium),
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perkembangan 4 Minggu Terakhir',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  SizedBox(height: 200, child: _buildBPChart()),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Sistolik', AppColors.primary),
                      SizedBox(width: ResponsiveSize.spacingLarge),
                      _buildLegendItem('Diastolik', AppColors.primarySurface),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.spacingXLarge),

            // Lab Results
            _buildSectionHeader('Hasil Laboratorium Terkini'),
            SizedBox(height: ResponsiveSize.spacingMedium),
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1),
              ),
              child: Column(
                children: [
                  _buildLabResultRow(
                    'Gula Darah',
                    '${latestData['bloodSugar']}',
                    'mg/dL',
                    latestData['bloodSugar'] < 100
                        ? AppColors.success
                        : AppColors.primarySurface,
                  ),
                  Divider(color: AppColors.surface),
                  _buildLabResultRow(
                    'Asam Urat',
                    '${latestData['uricAcid']}',
                    'mg/dL',
                    latestData['uricAcid'] < 7
                        ? AppColors.success
                        : AppColors.primarySurface,
                  ),
                  Divider(color: AppColors.surface),
                  _buildLabResultRow(
                    'Kolesterol',
                    '${latestData['cholesterol']}',
                    'mg/dL',
                    latestData['cholesterol'] < 200
                        ? AppColors.success
                        : AppColors.primarySurface,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.spacingXLarge),

            // Medical History
            _buildSectionHeader('Riwayat Pemeriksaan'),
            SizedBox(height: ResponsiveSize.spacingMedium),
            ..._medicalHistory.map((record) => _buildHistoryCard(record)),

            // Bottom spacing
            SizedBox(height: ResponsiveSize.spacingXLarge * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveSize.fontXLarge,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildVitalCard(
    String label,
    String value,
    String unit,
    String status,
    Color statusColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontXXLarge,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingSmall,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleVitalCard(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontXXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBPChart() {
    final sortedData = List<Map<String, dynamic>>.from(
      _medicalHistory,
    )..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final systolicSpots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['systolic'].toDouble());
    }).toList();

    final diastolicSpots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['diastolic'].toDouble());
    }).toList();

    return LineChart(
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
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedData.length) {
                  final date = sortedData[index]['date'] as DateTime;
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
        minY: 60,
        maxY: 200,
        lineBarsData: [
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
      ),
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

  Widget _buildLabResultRow(
    String label,
    String value,
    String unit,
    Color statusColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.spacingMedium),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final date = record['date'] as DateTime;
    final bpStatus = _getBPStatus(record['systolic'], record['diastolic']);
    final bpStatusColor = _getBPStatusColor(bpStatus);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day} ${IndonesianDate.shortMonth(date.month)} ${date.year}',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.paddingSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: bpStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: bpStatusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  bpStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: bpStatusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildHistoryItem(
                  Icons.favorite,
                  '${record['systolic']}/${record['diastolic']}',
                  'mmHg',
                  bpStatusColor,
                ),
              ),
              Expanded(
                child: _buildHistoryItem(
                  Icons.scale_outlined,
                  '${record['weight']}',
                  'kg',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildHistoryItem(
                  Icons.height,
                  '${record['height']}',
                  'cm',
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    IconData icon,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.fontMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

}
