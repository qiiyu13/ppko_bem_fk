import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_size.dart';

class AdminPatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  AdminPatientDetailScreen({super.key, required this.patient});

  static const Color attentionOrange = Color(0xFFFF9800);

  Map<String, dynamic> get _extendedData {
    return {
      'age': 68,
      'gender': 'Laki-laki',
      'glucose': 110,
      'weight': 62,
      'height': 165,
      'uricAcid': 5.8,
      'cholesterol': 185,
      ...patient,
    };
  }

  double get _bmi {
    final heightInMeters = (_extendedData['height'] as int) / 100;
    return _extendedData['weight'] / (heightInMeters * heightInMeters);
  }

  String get _bmiCategory {
    if (_bmi < 18.5) return 'Kurus';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  // Mock BP history
  final List<Map<String, dynamic>> _bpHistory = [
    {
      'systolic': 140,
      'diastolic': 90,
      'status': 'attention',
      'statusLabel': 'Perlu Pemantauan',
      'date': '12 Okt 2023',
    },
    {
      'systolic': 130,
      'diastolic': 85,
      'status': 'normal',
      'statusLabel': 'Normal',
      'date': '10 Sep 2023',
    },
    {
      'systolic': 150,
      'diastolic': 95,
      'status': 'high',
      'statusLabel': 'Bahaya - Segera Periksa',
      'date': '14 Agu 2023',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'high':
        return AppColors.error;
      case 'attention':
        return attentionOrange;
      case 'normal':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'high':
        return Icons.local_hospital;
      case 'attention':
        return Icons.warning_amber_rounded;
      case 'normal':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    final data = _extendedData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pasien',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Section
            _buildProfileSection(data),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            // Vital Stats Cards
            _buildVitalStatsRow(data),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            // BP History Section
            _buildBPHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data) {
    return Column(
      children: [
        // Avatar with status dot
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: AppColors.textSecondary,
              ),
            ),
            // Green status dot
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.spacingMedium),
        // Patient Name
        Text(
          data['name'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall),
        // Age and Gender
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              '${data['age']} Tahun • ${data['gender']}',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalStatsRow(Map<String, dynamic> data) {
    return Column(
      children: [
        // Row 1: Tensi, Gula, Berat
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                label: 'TENSI',
                value: '${data['systolic']}/${data['diastolic']}',
                status: 'Tinggi',
                borderColor: attentionOrange,
                statusColor: attentionOrange,
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'GULA',
                value: '${data['glucose']}',
                status: 'Normal',
                borderColor: AppColors.success,
                statusColor: AppColors.success,
                unit: '',
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'BERAT',
                value: '${data['weight']}',
                status: 'Stabil',
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
                unit: 'kg',
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.paddingSmall),
        // Row 2: Tinggi, BMI, Asam Urat
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                label: 'TINGGI',
                value: '${data['height']}',
                status: '-',
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
                unit: 'cm',
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'BMI',
                value: _bmi.toStringAsFixed(1),
                status: _bmiCategory,
                borderColor: _bmi < 25 ? AppColors.success : attentionOrange,
                statusColor: _bmi < 25 ? AppColors.success : attentionOrange,
                unit: '',
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'ASAM URAT',
                value: '${data['uricAcid']}',
                status: 'Normal',
                borderColor: AppColors.success,
                statusColor: AppColors.success,
                unit: '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard({
    required String label,
    required String value,
    required String status,
    required Color borderColor,
    required Color statusColor,
    String? unit,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6),
          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (unit != null && unit.isNotEmpty) ...[
                  SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 6),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBPHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Riwayat Tensi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingMedium),
        // History List
        ..._bpHistory.map((record) => _buildBPHistoryItem(record)),
      ],
    );
  }

  Widget _buildBPHistoryItem(Map<String, dynamic> record) {
    final statusColor = _getStatusColor(record['status']);
    final statusIcon = _getStatusIcon(record['status']);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          SizedBox(width: ResponsiveSize.paddingMedium),
          // BP Value and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record['systolic']}/${record['diastolic']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  record['statusLabel'],
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Date
          Text(
            record['date'],
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
