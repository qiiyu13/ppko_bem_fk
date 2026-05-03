import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_size.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const AdminPatientDetailScreen({super.key, required this.patient});

  @override
  State<AdminPatientDetailScreen> createState() =>
      _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen> {
  static const Color attentionOrange = Color(0xFFFF9800);

  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    _fetchPatientDetail();
  }

  Future<void> _fetchPatientDetail() async {
    final patientId =
        widget.patient['profileId'] ?? widget.patient['id'];
    try {
      final response =
          await ApiService.get('/admin/patients/$patientId');
      final data =
          response.data['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> screenings = data['screenings'] ?? [];
      setState(() {
        _patientData = data;
        _screenings = screenings.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _extendedData {
    if (_patientData == null) return {...widget.patient};
    final metrics =
        _patientData!['metrics'] as Map<String, dynamic>? ?? {};
    return {
      'name': _patientData!['name'] ?? widget.patient['name'] ?? '',
      'nik': _patientData!['nik'] ?? widget.patient['nik'] ?? '',
      'age': _patientData!['age'] ?? 0,
      'gender': _patientData!['gender'] ?? '',
      'systolic': metrics['systolic'] ?? 0,
      'diastolic': metrics['diastolic'] ?? 0,
      'glucose': metrics['bloodSugar'] ?? metrics['glucose'] ?? 0,
      'weight': metrics['weight'] ?? 0,
      'height': metrics['height'] ?? 0,
      'uricAcid': metrics['uricAcid'] ?? 0,
      'cholesterol': metrics['cholesterol'] ?? 0,
    };
  }

  double get _bmi {
    final height = (_extendedData['height'] as num?)?.toDouble() ?? 0;
    final weight = (_extendedData['weight'] as num?)?.toDouble() ?? 0;
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String get _bmiCategory {
    if (_bmi <= 0) return '-';
    if (_bmi < 18.5) return 'Kurus';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  List<Map<String, dynamic>> get _bpHistory {
    if (_screenings.isEmpty) {
      return [
        {
          'systolic': _extendedData['systolic'] ?? 0,
          'diastolic': _extendedData['diastolic'] ?? 0,
          'status': 'normal',
          'statusLabel': 'Belum ada data screening',
          'date': '-',
        }
      ];
    }
    return _screenings.map((s) {
      final sys = (s['systolic'] ?? 0) as num;
      final dia = (s['diastolic'] ?? 0) as num;
      String status;
      if (sys >= 180 || dia >= 120) {
        status = 'high';
      } else if (sys >= 140 || dia >= 90) {
        status = 'attention';
      } else {
        status = 'normal';
      }
      String statusLabel;
      switch (status) {
        case 'high':
          statusLabel = 'Bahaya - Segera Periksa';
        case 'attention':
          statusLabel = 'Perlu Pemantauan';
        default:
          statusLabel = 'Normal';
      }
      final dateStr = s['screeningAt'] ?? '';
      String formattedDate;
      try {
        final date = DateTime.parse(dateStr.toString());
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        formattedDate =
            '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (_) {
        formattedDate = dateStr.toString();
      }
      return {
        'systolic': sys,
        'diastolic': dia,
        'status': status,
        'statusLabel': statusLabel,
        'date': formattedDate,
      };
    }).toList()
      ..sort((a, b) {
        if (a['date'] == '-' || a['date'] == '-') return 0;
        return -(a['date'] as String).compareTo(b['date'] as String);
      });
  }

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
    ResponsiveSize.init(context);

    if (_isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            _buildProfileSection(data),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            _buildVitalStatsRow(data),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            _buildBPHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data) {
    return Column(
      children: [
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
        Text(
          data['name'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall),
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
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                label: 'TENSI',
                value: '${data['systolic']}/${data['diastolic']}',
                status: 'Tinggi',
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'GULA',
                value: '${data['glucose']}',
                status: 'Normal',
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
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
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
                unit: '',
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: _buildVitalCard(
                label: 'ASAM URAT',
                value: '${data['uricAcid']}',
                status: 'Normal',
                borderColor: AppColors.primary,
                statusColor: AppColors.primary,
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
        Text(
          'Riwayat Screening',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingMedium),
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
          Text(
            record['date'],
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
