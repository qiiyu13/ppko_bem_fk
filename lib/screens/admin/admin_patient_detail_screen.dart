import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_size.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final bool preloaded;

  const AdminPatientDetailScreen({
    super.key,
    required this.patient,
    this.preloaded = false,
  });

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
    if (widget.preloaded) {
      final List<dynamic> screenings = widget.patient['screenings'] ?? [];
      _patientData = widget.patient;
      _screenings = screenings.cast<Map<String, dynamic>>();
      _isLoading = false;
    } else {
      _fetchPatientDetail();
    }
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data pasien')),
      );
    }
  }

  Map<String, dynamic> get _extendedData {
    final patientMap = _patientData ?? widget.patient;

    // Find the latest screening if available
    Map<String, dynamic>? latestScreening;
    if (_screenings.isNotEmpty) {
      final sortedScreenings = List<Map<String, dynamic>>.from(_screenings);
      sortedScreenings.sort((a, b) {
        final aTime = a['screeningAt']?.toString() ?? '';
        final bTime = b['screeningAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
      latestScreening = sortedScreenings.first;
    }

    // Helper to get latest from generic metrics list if needed
    double? getLatestMetricValue(String type, {bool isSecondary = false}) {
      final metricsList = patientMap['metrics'];
      if (metricsList is List) {
        final matching = metricsList.where((m) => m is Map && m['type'] == type).toList();
        if (matching.isNotEmpty) {
          final sortedMatching = List<dynamic>.from(matching);
          sortedMatching.sort((a, b) {
            final aTime = a['recordedAt']?.toString() ?? '';
            final bTime = b['recordedAt']?.toString() ?? '';
            return bTime.compareTo(aTime);
          });
          final latest = sortedMatching.first as Map;
          final val = isSecondary ? latest['secondaryValue'] : latest['value'];
          return (val as num?)?.toDouble();
        }
      }
      return null;
    }

    // Extract values with robust fallbacks:
    // 1. Latest Screening
    // 2. Metrics List
    // 3. Root attributes
    // 4. Default to 0
    final systolic = latestScreening?['systolic'] ??
                     getLatestMetricValue('blood_pressure') ??
                     patientMap['systolic'] ?? 0;

    final diastolic = latestScreening?['diastolic'] ??
                      getLatestMetricValue('blood_pressure', isSecondary: true) ??
                      patientMap['diastolic'] ?? 0;

    final glucose = latestScreening?['bloodSugar'] ??
                    getLatestMetricValue('blood_sugar') ??
                    patientMap['glucose'] ??
                    patientMap['bloodSugar'] ?? 0;

    final weight = latestScreening?['weight'] ??
                   patientMap['weight'] ??
                   getLatestMetricValue('weight') ?? 0;

    final height = latestScreening?['height'] ??
                   patientMap['height'] ??
                   getLatestMetricValue('height') ?? 0;

    final uricAcid = latestScreening?['uricAcid'] ??
                     getLatestMetricValue('uric_acid') ??
                     patientMap['uricAcid'] ?? 0;

    final cholesterol = latestScreening?['cholesterol'] ??
                        getLatestMetricValue('cholesterol') ??
                        patientMap['cholesterol'] ?? 0;

    return {
      'name': patientMap['name'] ?? '',
      'nik': patientMap['nik'] ?? '',
      'age': patientMap['age'] ?? 0,
      'gender': patientMap['gender'] ?? '',
      'systolic': (systolic as num).toInt(),
      'diastolic': (diastolic as num).toInt(),
      'glucose': (glucose as num).toDouble(),
      'weight': (weight as num).toDouble(),
      'height': (height as num).toDouble(),
      'uricAcid': (uricAcid as num).toDouble(),
      'cholesterol': (cholesterol as num).toDouble(),
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

    final list = _screenings.map((s) {
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
        'rawDate': dateStr.toString(),
      };
    }).toList();

    list.sort((a, b) {
      final aDate = a['rawDate'] as String;
      final bDate = b['rawDate'] as String;
      return bDate.compareTo(aDate); // Descending order (latest first)
    });

    return list;
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
                color: AppColors.surface.withValues(alpha: 0.5),
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
            const Icon(
              Icons.badge_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${data['age']} Tahun • ${data['gender']}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (unit != null && unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
        const Text(
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
              color: statusColor.withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
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
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
