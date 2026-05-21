import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_size.dart';
import '../../utils/patient_utils.dart';
import '../../models/health_metric.dart';

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

  String get _overallRisk {
    final score = _overallIrdScore;
    if (score >= 1.0) {
      return 'high';
    } else if (score >= 0.75) {
      return 'attention';
    } else {
      return 'normal';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'critical':
      case 'bahaya':
        return AppColors.error;
      case 'attention':
      case 'warning':
      case 'waspada':
      case 'perlu pemantauan':
        return attentionOrange;
      case 'normal':
      case 'stabil':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'critical':
      case 'bahaya':
        return Icons.error_outline_rounded;
      case 'attention':
      case 'warning':
      case 'waspada':
      case 'perlu pemantauan':
        return Icons.warning_amber_rounded;
      case 'normal':
      case 'stabil':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  double get _overallIrdScore {
    final patientMap = _patientData ?? widget.patient;
    if (_screenings.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(_screenings);
      sorted.sort((a, b) {
        final aTime = a['screeningAt']?.toString() ?? '';
        final bTime = b['screeningAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
      final score = sorted.first['irdScore'];
      if (score != null) return (score as num).toDouble();
    }
    final rootScore = patientMap['irdScore'];
    if (rootScore != null) return (rootScore as num).toDouble();
    
    final latestIrd = patientMap['latestIrd'];
    if (latestIrd is Map) {
      final score = latestIrd['irdScore'];
      if (score != null) return (score as num).toDouble();
    }
    return 0.0;
  }

  Widget _buildIRDSection(String riskLevel, Color riskColor, String riskLabel) {
    final score = _overallIrdScore;
    
    // Medical explanation based on risk category
    final String explanation;
    final String subtitle;
    if (riskLevel.toLowerCase() == 'high') {
      explanation = 'Skor IRD berada di atas batas kritis (≥1.0), menunjukkan risiko tinggi diabetes melitus. Diperlukan konsultasi dokter spesialis segera, diet ketat rendah gula, dan pemantauan berkala.';
      subtitle = 'Risiko Tinggi Diabetes';
    } else if (riskLevel.toLowerCase() == 'attention') {
      explanation = 'Skor IRD berada di ambang batas waspada (0.75 - 1.0). Disarankan untuk membatasi karbohidrat sederhana/gula, rutin berolahraga, dan melakukan screening ulang dalam 1-3 bulan.';
      subtitle = 'Waspada / Perlu Pemantauan';
    } else {
      explanation = 'Skor IRD stabil di bawah batas normal (<0.75). Risiko diabetes melitus saat ini tergolong rendah. Pertahankan pola hidup sehat dan lakukan pemeriksaan berkala.';
      subtitle = 'Tingkat Risiko Normal';
    }

    // Fraction calculation for custom linear slider (0.0 to 1.5 bounds)
    final double fraction = score > 0 ? (score / 1.5).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.analytics_rounded, color: riskColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INDEX RISK DIABETES (IRD)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Big Score representation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: riskColor.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  score > 0 ? score.toStringAsFixed(2) : '0.00',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          
          // Explanatory medical note
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingLarge),

          // Custom medical indicator slider bar
          Column(
            children: [
              // Visual axis/ticks labels
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.00 (Rendah)', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('0.75 (Waspada)', style: TextStyle(fontSize: 9, color: AppColors.statusAmber, fontWeight: FontWeight.bold)),
                  Text('1.00 (Tinggi)', style: TextStyle(fontSize: 9, color: AppColors.statusRed, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              // Linear track with colored sections
              LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  final dotOffset = (trackWidth * fraction) - 8.0;
                  final clampedOffset = dotOffset.clamp(0.0, trackWidth - 16.0);

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Underlay Track with risk ranges colors
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.statusGreen,
                              AppColors.statusAmber,
                              AppColors.statusRed,
                            ],
                            stops: [0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                      // Pointer/dot indicating the exact current value
                      Positioned(
                        left: clampedOffset,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: riskColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
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
          scrolledUnderElevation: 0.0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _extendedData;
    final overallRiskLevel = _overallRisk;
    final overallRiskColor = PatientUtils.riskColor(overallRiskLevel);
    final overallRiskLabel = PatientUtils.riskLabel(overallRiskLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Premium Page Header
              const Text(
                'Detail Pasien',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Informasi lengkap profil dan riwayat kesehatan pasien',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileSection(data, overallRiskColor, overallRiskLabel),
              SizedBox(height: ResponsiveSize.spacingMedium),
              _buildIRDSection(overallRiskLevel, overallRiskColor, overallRiskLabel),
              SizedBox(height: ResponsiveSize.spacingXLarge),
              
              // Dashboard Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Parameter Pemeriksaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacingMedium),
              
              _buildVitalStatsGrid(data),
              SizedBox(height: ResponsiveSize.spacingXLarge * 1.5),

              // History Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Screening Kesehatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacingLarge),

              _buildBPHistorySection(),
              SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data, Color riskColor, String riskLabel) {
    final name = data['name'];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final nik = data['nik']?.toString() ?? '';
    final familyName = (_patientData ?? widget.patient)['familyName']?.toString() ?? 'Keluarga';

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Styled Avatar with elegant branding
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and overall status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      familyName,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Overall status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status IRD: $riskLabel',
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Demographics Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _demographicChip(Icons.cake_outlined, '${data['age']} Tahun'),
                const SizedBox(width: 8),
                _demographicChip(
                  data['gender'].toString().toLowerCase() == 'wanita'
                      ? Icons.female_rounded
                      : Icons.male_rounded,
                  data['gender'].toString(),
                ),
                const SizedBox(width: 8),
                _demographicChip(Icons.water_drop_outlined, 'Gol: ${(_patientData ?? widget.patient)['bloodType'] ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Copyable NIK Row
          if (nik.isNotEmpty) ...[
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: nik));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NIK disalin ke papan klip'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'NIK $nik',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.copy_all_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _demographicChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalStatsGrid(Map<String, dynamic> data) {
    final age = (data['age'] as num?)?.toInt() ?? 30;
    final genderStr = (data['gender'] as String?) ?? 'pria';

    // Real dynamic status checks using HealthMetricData utility:
    final bpStatus = HealthMetricData.getBloodPressureStatus(data['systolic'], data['diastolic'], age);
    final bpColor = HealthMetricData.getStatusColor(bpStatus);
    final bpLabel = HealthMetricData.getStatusLabel(bpStatus);

    final sugarStatus = HealthMetricData.getBloodSugarStatus(data['glucose'], age);
    final sugarColor = HealthMetricData.getStatusColor(sugarStatus);
    final sugarLabel = HealthMetricData.getStatusLabel(sugarStatus);

    final uricAcidStatus = HealthMetricData.getUricAcidStatus(data['uricAcid'], age, genderStr);
    final uricAcidColor = HealthMetricData.getStatusColor(uricAcidStatus);
    final uricAcidLabel = HealthMetricData.getStatusLabel(uricAcidStatus);

    final cholesterolStatus = HealthMetricData.getCholesterolStatus(data['cholesterol'], age);
    final cholesterolColor = HealthMetricData.getStatusColor(cholesterolStatus);
    final cholesterolLabel = HealthMetricData.getStatusLabel(cholesterolStatus);

    // Calculate dynamic fraction representation for range bars:
    final bpFraction = data['systolic'] > 0 ? (data['systolic'] / 180.0) : 0.0;
    final sugarFraction = data['glucose'] > 0 ? (data['glucose'] / 200.0) : 0.0;
    final uricAcidFraction = data['uricAcid'] > 0 ? (data['uricAcid'] / 10.0) : 0.0;
    final cholesterolFraction = data['cholesterol'] > 0 ? (data['cholesterol'] / 300.0) : 0.0;
    final bmiFraction = _bmi > 0 ? (_bmi / 40.0) : 0.0;

    // BMI Color logic:
    final bmiVal = _bmi;
    final bmiColor = bmiVal <= 0
        ? AppColors.textSecondary
        : (bmiVal < 18.5 || bmiVal >= 25)
            ? (bmiVal >= 30 ? AppColors.error : attentionOrange)
            : AppColors.success;
    final bmiLabel = _bmiCategory;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildRedesignedVitalCard(
          icon: Icons.favorite_rounded,
          label: 'TEKANAN DARAH',
          value: data['systolic'] > 0 && data['diastolic'] > 0
              ? '${data['systolic']}/${data['diastolic']}'
              : '-',
          unit: 'mmHg',
          status: data['systolic'] > 0 ? bpLabel : 'Tidak Ada',
          statusColor: data['systolic'] > 0 ? bpColor : AppColors.textSecondary,
          fraction: bpFraction,
        ),
        _buildRedesignedVitalCard(
          icon: Icons.opacity_rounded,
          label: 'GULA DARAH',
          value: data['glucose'] > 0 ? '${data['glucose'].toStringAsFixed(0)}' : '-',
          unit: 'mg/dL',
          status: data['glucose'] > 0 ? sugarLabel : 'Tidak Ada',
          statusColor: data['glucose'] > 0 ? sugarColor : AppColors.textSecondary,
          fraction: sugarFraction,
        ),
        _buildRedesignedVitalCard(
          icon: Icons.speed_rounded,
          label: 'KOLESTEROL',
          value: data['cholesterol'] > 0 ? '${data['cholesterol'].toStringAsFixed(0)}' : '-',
          unit: 'mg/dL',
          status: data['cholesterol'] > 0 ? cholesterolLabel : 'Tidak Ada',
          statusColor: data['cholesterol'] > 0 ? cholesterolColor : AppColors.textSecondary,
          fraction: cholesterolFraction,
        ),
        _buildRedesignedVitalCard(
          icon: Icons.science_outlined,
          label: 'ASAM URAT',
          value: data['uricAcid'] > 0 ? '${data['uricAcid'].toStringAsFixed(1)}' : '-',
          unit: 'mg/dL',
          status: data['uricAcid'] > 0 ? uricAcidLabel : 'Tidak Ada',
          statusColor: data['uricAcid'] > 0 ? uricAcidColor : AppColors.textSecondary,
          fraction: uricAcidFraction,
        ),
        _buildRedesignedVitalCard(
          icon: Icons.monitor_weight_outlined,
          label: 'BERAT / TINGGI',
          value: data['weight'] > 0 && data['height'] > 0
              ? '${data['weight'].toStringAsFixed(0)}/${data['height'].toStringAsFixed(0)}'
              : '-',
          unit: 'kg/cm',
          status: data['weight'] > 0 ? 'Tercatat' : 'Tidak Ada',
          statusColor: data['weight'] > 0 ? AppColors.primary : AppColors.textSecondary,
          fraction: 0.5,
        ),
        _buildRedesignedVitalCard(
          icon: Icons.analytics_outlined,
          label: 'INDEX MASSA TUBUH',
          value: _bmi > 0 ? _bmi.toStringAsFixed(1) : '-',
          unit: 'BMI',
          status: _bmi > 0 ? bmiLabel : 'Tidak Ada',
          statusColor: _bmi > 0 ? bmiColor : AppColors.textSecondary,
          fraction: bmiFraction,
        ),
      ],
    );
  }

  Widget _buildRedesignedVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required double fraction,
  }) {
    final statusBgColor = statusColor.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: statusColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (value != '-' && unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Custom Visual progress bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBPHistorySection() {
    if (_screenings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              'Belum ada riwayat screening kesehatan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort screenings descending (latest first)
    final sortedScreenings = List<Map<String, dynamic>>.from(_screenings);
    sortedScreenings.sort((a, b) {
      final aTime = a['screeningAt']?.toString() ?? '';
      final bTime = b['screeningAt']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    return Column(
      children: [
        for (var i = 0; i < sortedScreenings.length; i++)
          _buildTimelineHistoryItem(sortedScreenings[i], isLast: i == sortedScreenings.length - 1),
      ],
    );
  }

  Widget _buildTimelineHistoryItem(Map<String, dynamic> s, {required bool isLast}) {
    final dateStr = s['screeningAt'] ?? '';
    String formattedDate = '';
    try {
      final date = DateTime.parse(dateStr.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      formattedDate = dateStr.toString();
    }

    final sys = (s['systolic'] ?? 0) as num;
    final dia = (s['diastolic'] ?? 0) as num;
    final bloodSugar = s['bloodSugar'] != null ? (s['bloodSugar'] as num).toDouble() : 0.0;
    final cholesterol = s['cholesterol'] != null ? (s['cholesterol'] as num).toDouble() : 0.0;
    final uricAcid = s['uricAcid'] != null ? (s['uricAcid'] as num).toDouble() : 0.0;
    final weight = s['weight'] != null ? (s['weight'] as num).toDouble() : 0.0;
    final height = s['height'] != null ? (s['height'] as num).toDouble() : 0.0;
    final notes = s['notes']?.toString() ?? '';
    final screenerName = s['screener']?['responsibleName']?.toString() ?? 'Petugas';

    // Status evaluation for color dot based strictly on IRD score
    final score = s['irdScore'] != null ? (s['irdScore'] as num).toDouble() : 0.0;
    final String irdCat;
    if (score >= 1.0) {
      irdCat = 'high';
    } else if (score >= 0.75) {
      irdCat = 'attention';
    } else {
      irdCat = 'normal';
    }
    final dotColor = _getStatusColor(irdCat);
    final dotIcon = _getStatusIcon(irdCat);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side Timeline track and indicators
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(dotIcon, color: dotColor, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Timeline glassmorphic metric card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Oleh: $screenerName',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Screening Metrics Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (sys > 0 && dia > 0)
                        _buildTimelineMetricBadge('Tensi', '$sys/$dia mmHg', AppColors.primary),
                      if (bloodSugar > 0)
                        _buildTimelineMetricBadge('Gula', '${bloodSugar.toStringAsFixed(0)} mg/dL', attentionOrange),
                      if (cholesterol > 0)
                        _buildTimelineMetricBadge('Kolesterol', '${cholesterol.toStringAsFixed(0)} mg/dL', Colors.purple),
                      if (uricAcid > 0)
                        _buildTimelineMetricBadge('Asam Urat', '${uricAcid.toStringAsFixed(1)} mg/dL', Colors.pink),
                      if (weight > 0)
                        _buildTimelineMetricBadge('Berat', '${weight.toStringAsFixed(0)} kg', Colors.blueGrey),
                      if (height > 0)
                        _buildTimelineMetricBadge('Tinggi', '${height.toStringAsFixed(0)} cm', Colors.blueGrey),
                    ],
                  ),

                  // Screener notes if present
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
