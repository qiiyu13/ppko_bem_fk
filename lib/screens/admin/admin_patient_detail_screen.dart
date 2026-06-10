import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediku/widgets/app_avatar.dart';
import '../../config/env.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_size.dart';
import '../../utils/patient_utils.dart';
import '../../models/health_metric.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final bool preloaded;
  final bool readOnly;

  const AdminPatientDetailScreen({
    super.key,
    required this.patient,
    this.preloaded = false,
    this.readOnly = false,
  });

  @override
  State<AdminPatientDetailScreen> createState() =>
      _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen> {
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
      if (!mounted) return;
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

  Future<void> _refresh() => _fetchPatientDetail();

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

  String get _overallRisk => PatientUtils.irdCategoryFromScore(_overallIrdScore);

  IconData _getStatusIcon(String category) {
    switch (category) {
      case 'high':
        return Icons.error_outline_rounded;
      case 'attention':
        return Icons.warning_amber_rounded;
      case 'normal':
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
    
    final String subtitle;
    if (riskLevel.toLowerCase() == 'high') {
      subtitle = 'Risiko Tinggi Diabetes';
    } else if (riskLevel.toLowerCase() == 'attention') {
      subtitle = 'Waspada / Perlu Pemantauan';
    } else {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INDEX RISK DIABETES (IRD)',
                      style: TextStyle(
                        fontSize: 11,
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
              const SizedBox(width: 8),
              Text(
                score > 0 ? score.toStringAsFixed(2) : '0.00',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingLarge),

          // Custom medical indicator slider bar
          Column(
            children: [
              // Visual axis/ticks labels - Top Row (Rendah & Tinggi)
              const SizedBox(
                height: 14,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment(-1.0, 0.0),
                      child: Text('0.00 (Rendah)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                    Align(
                      alignment: Alignment(0.334, 0.0), // 1.00 / 1.5 = 66.7% width (alignment 0.334)
                      child: Text('1.00 (Tinggi)', style: TextStyle(fontSize: 10, color: AppColors.statusRed, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
                      // Underlay Track with risk ranges colors aligned to thresholds
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.statusGreen,
                              AppColors.statusGreen,
                              AppColors.statusAmber,
                              AppColors.statusAmber,
                              AppColors.statusRed,
                              AppColors.statusRed,
                            ],
                            stops: [0.0, 0.50, 0.50, 0.6667, 0.6667, 1.0],
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
              const SizedBox(height: 6),
              // Visual axis/ticks labels - Bottom Row (Waspada)
              const SizedBox(
                height: 14,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment(0.0, 0.0), // 0.75 / 1.5 = 50% width (alignment 0.0)
                      child: Text('0.75 (Waspada)', style: TextStyle(fontSize: 10, color: AppColors.statusAmber, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    'Riwayat Skrining Kesehatan',
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
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data, Color riskColor, String riskLabel) {
    final name = data['name'];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarPath = (_patientData ?? widget.patient)['avatarPath'] as String?;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? '${Env.serverBaseUrl}$avatarPath'
        : null;
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
              AppAvatar(
                imageUrl: avatarUrl,
                size: 66,
                backgroundColor: AppColors.primarySurface,
                borderColor: AppColors.primary.withValues(alpha: 0.15),
                borderWidth: 2,
                fallback: Text(
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
                  _isFemale(data['gender'].toString())
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

  bool _isFemale(String gender) {
    final g = gender.toLowerCase().trim();
    return g == 'wanita' || g == 'perempuan' || g == 'p' || g == 'female';
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
    final age = (data['age'] as num?)?.toInt() ?? 0;
    final hasAge = age > 0;
    final genderStr = (data['gender'] as String?) ?? '';

    // Statuses depend on age-based reference ranges — never assume an age.
    String? statusLabelFor(MetricStatus status) =>
        HealthMetricData.getStatusLabel(status);

    String? bpLabel;
    Color bpColor = AppColors.textSecondary;
    if (data['systolic'] > 0 && data['diastolic'] > 0) {
      if (hasAge) {
        final s = HealthMetricData.getBloodPressureStatus(
            data['systolic'], data['diastolic'], age);
        bpLabel = statusLabelFor(s);
        bpColor = HealthMetricData.getStatusColor(s);
      } else {
        bpLabel = 'Perlu data usia';
      }
    }

    String? sugarLabel;
    Color sugarColor = AppColors.textSecondary;
    if (data['glucose'] > 0) {
      if (hasAge) {
        final s = HealthMetricData.getBloodSugarStatus(data['glucose'], age);
        sugarLabel = statusLabelFor(s);
        sugarColor = HealthMetricData.getStatusColor(s);
      } else {
        sugarLabel = 'Perlu data usia';
      }
    }

    String? cholesterolLabel;
    Color cholesterolColor = AppColors.textSecondary;
    if (data['cholesterol'] > 0) {
      if (hasAge) {
        final s =
            HealthMetricData.getCholesterolStatus(data['cholesterol'], age);
        cholesterolLabel = statusLabelFor(s);
        cholesterolColor = HealthMetricData.getStatusColor(s);
      } else {
        cholesterolLabel = 'Perlu data usia';
      }
    }

    String? uricAcidLabel;
    Color uricAcidColor = AppColors.textSecondary;
    if (data['uricAcid'] > 0) {
      if (hasAge) {
        final s = HealthMetricData.getUricAcidStatus(
            data['uricAcid'], age, genderStr);
        uricAcidLabel = statusLabelFor(s);
        uricAcidColor = HealthMetricData.getStatusColor(s);
      } else {
        uricAcidLabel = 'Perlu data usia';
      }
    }

    // BMI thresholds are age-independent for adults.
    final bmiVal = _bmi;
    String? bmiLabel;
    Color bmiColor = AppColors.textSecondary;
    if (bmiVal > 0) {
      if (bmiVal < 18.5) {
        bmiLabel = 'Kurang';
        bmiColor = AppColors.statusAmber;
      } else if (bmiVal < 25) {
        bmiLabel = 'Normal';
        bmiColor = AppColors.statusGreen;
      } else if (bmiVal < 30) {
        bmiLabel = 'Berlebih';
        bmiColor = AppColors.statusAmber;
      } else {
        bmiLabel = 'Obesitas';
        bmiColor = AppColors.statusRed;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildRedesignedVitalCard(
          label: 'TEKANAN DARAH',
          value: data['systolic'] > 0 && data['diastolic'] > 0
              ? '${data['systolic']}/${data['diastolic']}'
              : '-',
          unit: 'mmHg',
          statusLabel: bpLabel,
          statusColor: bpColor,
        ),
        _buildRedesignedVitalCard(
          label: 'GULA DARAH',
          value: data['glucose'] > 0 ? data['glucose'].toStringAsFixed(0) : '-',
          unit: 'mg/dL',
          statusLabel: sugarLabel,
          statusColor: sugarColor,
        ),
        _buildRedesignedVitalCard(
          label: 'KOLESTEROL',
          value: data['cholesterol'] > 0
              ? data['cholesterol'].toStringAsFixed(0)
              : '-',
          unit: 'mg/dL',
          statusLabel: cholesterolLabel,
          statusColor: cholesterolColor,
        ),
        _buildRedesignedVitalCard(
          label: 'ASAM URAT',
          value:
              data['uricAcid'] > 0 ? data['uricAcid'].toStringAsFixed(1) : '-',
          unit: 'mg/dL',
          statusLabel: uricAcidLabel,
          statusColor: uricAcidColor,
        ),
        _buildRedesignedVitalCard(
          label: 'BERAT / TINGGI',
          value: data['weight'] > 0 && data['height'] > 0
              ? '${data['weight'].toStringAsFixed(0)}/${data['height'].toStringAsFixed(0)}'
              : '-',
          unit: 'kg/cm',
        ),
        _buildRedesignedVitalCard(
          label: 'INDEX MASSA TUBUH',
          value: bmiVal > 0 ? bmiVal.toStringAsFixed(1) : '-',
          unit: 'BMI',
          statusLabel: bmiLabel,
          statusColor: bmiColor,
        ),
      ],
    );
  }

  Widget _buildRedesignedVitalCard({
    required String label,
    required String value,
    required String unit,
    String? statusLabel,
    Color statusColor = AppColors.textSecondary,
  }) {
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
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
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          if (statusLabel != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 7),
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
    final irdCat = PatientUtils.irdCategoryFromScore(score);
    final dotColor = PatientUtils.riskColor(irdCat);
    final dotIcon = _getStatusIcon(irdCat);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side Timeline track and indicators (Sleek Compact Width)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(dotIcon, color: dotColor, size: 12),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Timeline compact metric card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Oleh: $screenerName',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Screening Metrics Grid (Two Columns: 3 Left, 3 Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHistoryMetricItem('Tensi', sys > 0 && dia > 0 ? '$sys/$dia mmHg' : '-'),
                            const SizedBox(height: 8),
                            _buildHistoryMetricItem('Gula Darah', bloodSugar > 0 ? '${bloodSugar.toStringAsFixed(0)} mg/dL' : '-'),
                            const SizedBox(height: 8),
                            _buildHistoryMetricItem('Kolesterol', cholesterol > 0 ? '${cholesterol.toStringAsFixed(0)} mg/dL' : '-'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHistoryMetricItem('Asam Urat', uricAcid > 0 ? '${uricAcid.toStringAsFixed(1)} mg/dL' : '-'),
                            const SizedBox(height: 8),
                            _buildHistoryMetricItem('Berat', weight > 0 ? '${weight.toStringAsFixed(0)} kg' : '-'),
                            const SizedBox(height: 8),
                            _buildHistoryMetricItem('Tinggi', height > 0 ? '${height.toStringAsFixed(0)} cm' : '-'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Screener notes if present
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 12, color: AppColors.textSecondary),
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

  Widget _buildHistoryMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: value == '-'
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
