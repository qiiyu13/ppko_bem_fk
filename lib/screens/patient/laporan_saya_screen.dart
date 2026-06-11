import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../utils/asset_helper.dart';
import '../../utils/date_utils.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';

const int _kRecentReportsLimit = 5;

class LaporanSayaScreen extends StatefulWidget {
  final String gender;

  const LaporanSayaScreen({super.key, required this.gender});

  @override
  State<LaporanSayaScreen> createState() => _LaporanSayaScreenState();
}

class _LaporanSayaScreenState extends State<LaporanSayaScreen> {
  List<BPScreeningData> _screeningData = [];
  bool _isLoading = true;
  bool _showAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  Future<void> _loadScreenings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = ProfileService.instance.activeProfile;
      final profileId = profile?.id;
      if (profileId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Tidak ada profil aktif';
        });
        return;
      }

      // The endpoint is paginated (default page size 20) — walk every page so
      // "Tampilkan Semua" really shows the whole history.
      final raw = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final response = await ApiService.get(
          '/screenings',
          queryParameters: {'profileId': profileId, 'page': page, 'limit': 100},
        );
        final batch =
            (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
        raw.addAll(batch);
        final total =
            ((response.data['meta'] as Map<String, dynamic>?)?['total'] as num?)
                ?.toInt();
        if (batch.isEmpty || total == null || raw.length >= total) break;
        page++;
      }

      setState(() {
        _screeningData =
            raw.map((map) {
                return BPScreeningData(
                  // Stored as UTC; display in the device's zone.
                  date: DateTime.parse(map['screeningAt'] as String).toLocal(),
                  systolic: (map['systolic'] as num).toInt(),
                  diastolic: (map['diastolic'] as num).toInt(),
                  weight: (map['weight'] as num? ?? 0).toDouble(),
                  height: (map['height'] as num? ?? 0).toDouble(),
                  bloodSugar: (map['bloodSugar'] as num?)?.toDouble(),
                  uricAcid: (map['uricAcid'] as num?)?.toDouble(),
                  cholesterol: (map['cholesterol'] as num?)?.toDouble(),
                  gender: widget.gender,
                  storedIrdScore: (map['irdScore'] as num?)?.toDouble(),
                  storedIrdCategory: map['irdCategory'] as String?,
                  patientName: profile?.name,
                  patientNik: profile?.nik,
                );
              }).toList()
              // Newest first — never trust API ordering.
              ..sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data screening. Periksa koneksi Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Laporan Saya'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return ErrorStateWidget(
                message: _error!,
                onRetry: _loadScreenings,
              );
            }

            if (_screeningData.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.inbox_outlined,
                title: 'Belum ada data screening',
                subtitle: 'Hasil screening kesehatan Anda\nakan muncul di sini',
              );
            }

            final visible = _showAll
                ? _screeningData
                : _screeningData.take(_kRecentReportsLimit).toList();
            final hasMore = _screeningData.length > _kRecentReportsLimit;

            return RefreshIndicator(
              onRefresh: _loadScreenings,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screening History Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: AppColors.primary,
                                  size: ResponsiveSize.iconMedium,
                                ),
                                SizedBox(width: ResponsiveSize.paddingSmall),
                                Text(
                                  'Riwayat Screening',
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.fontLarge,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_screeningData.length} screening',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveSize.spacingMedium),
                        // Expandable Screening Cards (newest first)
                        ...visible.map((data) {
                          return _buildExpandableScreeningCard(
                            data: data,
                            isInitiallyExpanded: false,
                          );
                        }),
                        if (hasMore)
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() => _showAll = !_showAll);
                              },
                              icon: Icon(
                                _showAll
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                _showAll
                                    ? 'Tampilkan Lebih Sedikit'
                                    : 'Tampilkan Semua (${_screeningData.length})',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandableScreeningCard({
    required BPScreeningData data,
    bool isInitiallyExpanded = false,
  }) {
    return ExpandableScreeningCardWidget(
      data: data,
      isInitiallyExpanded: isInitiallyExpanded,
    );
  }
}

// Data model for screening
class BPScreeningData {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final double weight;
  final double height;
  // Labs are nullable: a skipped test must show as "-", not as 0.
  final double? bloodSugar;
  final double? uricAcid;
  final double? cholesterol;
  final String gender;
  // Score/category as the backend computed them at screening time. Preferred
  // over the local recomputation so patient and admin views never disagree
  // (rounding, or the profile's gender being edited later).
  final double? storedIrdScore;
  final String? storedIrdCategory;
  final String? patientName;
  final String? patientNik;

  BPScreeningData({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.weight,
    required this.height,
    required this.bloodSugar,
    required this.uricAcid,
    required this.cholesterol,
    required this.gender,
    this.storedIrdScore,
    this.storedIrdCategory,
    this.patientName,
    this.patientNik,
  });

  double get bmi {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  /// Accepts both app convention ('Pria'/'Wanita') and API convention
  /// ('male'/'female') so the uric-acid denominator is never wrong.
  bool get isMale {
    final g = gender.toLowerCase();
    return g == 'pria' || g == 'male' || g == 'laki-laki';
  }

  /// Stored backend value when available; local fallback only for rows that
  /// predate the backend storing scores.
  double get ird => storedIrdScore ?? _computedIrd;

  double get _computedIrd {
    final auDenominator = isMale ? 7.0 : 6.0;
    final gdsComponent = 0.3 * ((bloodSugar ?? 0) / 200);
    final bpComponent = 0.2 * ((systolic / 140 + diastolic / 90) / 2);
    final kolComponent = 0.2 * ((cholesterol ?? 0) / 240);
    final auComponent = 0.15 * ((uricAcid ?? 0) / auDenominator);
    final bmiComponent = 0.15 * (bmi / 25);
    return gdsComponent +
        bpComponent +
        kolComponent +
        auComponent +
        bmiComponent;
  }

  String get irdCategory {
    final stored = storedIrdCategory;
    if (stored != null && stored.isNotEmpty) return stored;
    if (ird < 0.75) return 'normal';
    if (ird <= 1.0) return 'attention';
    return 'high';
  }

  String get irdCategoryLabel {
    switch (irdCategory) {
      case 'normal':
        return 'Normal';
      case 'attention':
        return 'Perhatian';
      default:
        return 'Tinggi';
    }
  }
}

// Expandable Screening Card Widget
class ExpandableScreeningCardWidget extends StatefulWidget {
  final BPScreeningData data;
  final bool isInitiallyExpanded;

  const ExpandableScreeningCardWidget({
    super.key,
    required this.data,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableScreeningCardWidget> createState() =>
      _ExpandableScreeningCardWidgetState();
}

class _ExpandableScreeningCardWidgetState
    extends State<ExpandableScreeningCardWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  String _formatDate(DateTime date) => IndonesianDate.format(date);

  Color _getIRDStatusColor(String category) {
    switch (category) {
      case 'normal':
        return AppColors.statusGreen;
      case 'attention':
        return AppColors.statusAmber;
      case 'high':
        return AppColors.statusRed;
      default:
        return AppColors.statusGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: AppTheme.cardShadowLight,
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppTheme.radiusCard),
              bottom: _isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppTheme.radiusCard),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Document icon
                  SvgPicture.asset(
                    AssetHelper.getSvgPath('document_recolored_final_2.svg'),
                    width: ResponsiveSize.iconMedium * 1.1,
                    height: ResponsiveSize.iconMedium * 1.1,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(widget.data.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: ResponsiveSize.iconMedium,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - detailed report
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusCard),
                ),
                border: Border(top: BorderSide(color: AppColors.surface)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vital chips 2x2 grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.favorite,
                          iconColor: AppColors.statusRed,
                          label: 'Tekanan Darah',
                          value:
                              '${widget.data.systolic}/${widget.data.diastolic}',
                          unit: 'mmHg',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: AppColors.primaryLight,
                          label: 'Berat Badan',
                          value: widget.data.weight.toStringAsFixed(1),
                          unit: 'kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.height,
                          iconColor: AppColors.primary,
                          label: 'Tinggi Badan',
                          value: widget.data.height.toStringAsFixed(0),
                          unit: 'cm',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.calculate_outlined,
                          iconColor: AppColors.statusAmber,
                          label: 'BMI',
                          value: widget.data.bmi.toStringAsFixed(1),
                          unit: widget.data.bmiCategory,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Lab results
                  const Text(
                    'Hasil Lab',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildNullableLabRow(
                    'Gula Darah',
                    widget.data.bloodSugar,
                    decimals: 0,
                    normal: 100,
                    borderline: 126,
                  ),
                  _buildNullableLabRow(
                    'Asam Urat',
                    widget.data.uricAcid,
                    decimals: 1,
                    normal: 6,
                    borderline: 7,
                  ),
                  _buildNullableLabRow(
                    'Kolesterol',
                    widget.data.cholesterol,
                    decimals: 0,
                    normal: 200,
                    borderline: 240,
                  ),
                  const SizedBox(height: 10),
                  // IRD progress bar
                  _buildIRDBar(),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.surface),
                  const SizedBox(height: 6),
                  // Action button
                  _buildActionButton(
                    label: 'Unduh Laporan',
                    icon: Icons.download_outlined,
                    onTap: () {
                      _downloadReport();
                    },
                    bgColor: AppColors.primary,
                    fgColor: AppColors.textOnPrimary,
                    borderColor: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ResponsiveSize.paddingMedium),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            ResponsiveSize.buttonBorderRadius,
          ),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: ResponsiveSize.iconSmall),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 14),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _labColor(
    double value, {
    required double normal,
    required double borderline,
  }) {
    if (value < normal) return AppColors.statusGreen;
    if (value < borderline) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  /// Skipped lab (null) renders as a neutral "-" instead of a green 0.
  Widget _buildNullableLabRow(
    String label,
    double? value, {
    required int decimals,
    required double normal,
    required double borderline,
  }) {
    if (value == null) {
      return _buildLabRow(label, '-', AppColors.textSecondary);
    }
    return _buildLabRow(
      label,
      '${value.toStringAsFixed(decimals)} mg/dL',
      _labColor(value, normal: normal, borderline: borderline),
    );
  }

  Widget _buildLabRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIRDBar() {
    final irdColor = _getIRDStatusColor(widget.data.irdCategory);
    final progress = (widget.data.ird).clamp(0.0, 1.5) / 1.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IRD (Index Risiko Diabetes)',
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${widget.data.ird.toStringAsFixed(2)} · ${widget.data.irdCategoryLabel}',
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                fontWeight: FontWeight.w600,
                color: irdColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(irdColor),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadReport() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final doc = await _generatePdf();
          return doc.save();
        },
        name: 'Laporan_Screening_${_formatDate(widget.data.date)}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat PDF. Coba lagi.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  /// Noto Sans comes from the network; offline we fall back to the built-in
  /// Helvetica (fine for Indonesian text) instead of failing the export.
  Future<pw.ThemeData?> _pdfTheme() async {
    try {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document(theme: await _pdfTheme());
    final d = widget.data;

    final primaryColor = PdfColor.fromHex('144425');
    final greyColor = PdfColor.fromHex('6B7280');
    final lightGrey = PdfColor.fromHex('F3F4F6');
    final borderColor = PdfColor.fromHex('E5E7EB');

    PdfColor irdColor;
    PdfColor irdLightColor;
    switch (d.irdCategory) {
      case 'normal':
        irdColor = PdfColor.fromHex('4CAF50');
        irdLightColor = PdfColor.fromHex('E8F5E9');
        break;
      case 'attention':
        irdColor = PdfColor.fromHex('FFA726');
        irdLightColor = PdfColor.fromHex('FFF8E1');
        break;
      default:
        irdColor = PdfColor.fromHex('EF5350');
        irdLightColor = PdfColor.fromHex('FFEBEE');
    }

    final auNormal = d.isMale ? 7.0 : 6.0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN SCREENING KESEHATAN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  if (d.patientName != null)
                    pw.Text(
                      'Nama: ${d.patientName}'
                      '${d.patientNik != null ? '  ·  NIK: ${d.patientNik}' : ''}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  pw.Text(
                    'Tanggal Screening: ${_formatDate(d.date)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Dicetak: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'DATA VITAL',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrey),
                  children: [
                    _pdfCell('Parameter', bold: true),
                    _pdfCell('Nilai', bold: true),
                    _pdfCell('Satuan', bold: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Tekanan Darah'),
                    _pdfCell('${d.systolic}/${d.diastolic}'),
                    _pdfCell('mmHg'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Berat Badan'),
                    _pdfCell(d.weight.toStringAsFixed(1)),
                    _pdfCell('kg'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Tinggi Badan'),
                    _pdfCell(d.height.toStringAsFixed(0)),
                    _pdfCell('cm'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('BMI'),
                    _pdfCell(d.bmi.toStringAsFixed(1)),
                    _pdfCell(d.bmiCategory),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'HASIL LABORATORIUM',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrey),
                  children: [
                    _pdfCell('Pemeriksaan', bold: true),
                    _pdfCell('Hasil', bold: true),
                    _pdfCell('Normal', bold: true),
                    _pdfCell('Status', bold: true),
                  ],
                ),
                _pdfLabRow('Gula Darah', d.bloodSugar, 0, '< 100 mg/dL', 100, 126),
                _pdfLabRow(
                  'Asam Urat',
                  d.uricAcid,
                  1,
                  '< ${auNormal.toStringAsFixed(0)} mg/dL',
                  auNormal,
                  auNormal + 1,
                ),
                _pdfLabRow('Kolesterol', d.cholesterol, 0, '< 200 mg/dL', 200, 240),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'INDEX RISIKO DIABETES (IRD)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: irdLightColor,
                border: pw.Border(
                  left: pw.BorderSide(color: irdColor, width: 4),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Nilai IRD',
                        style: pw.TextStyle(fontSize: 9, color: greyColor),
                      ),
                      pw.Text(
                        d.ird.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Kategori Risiko',
                        style: pw.TextStyle(fontSize: 9, color: greyColor),
                      ),
                      pw.Text(
                        d.irdCategoryLabel,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: irdColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: borderColor),
            pw.Text(
              'PPKO BEM FK — Laporan ini dibuat secara otomatis oleh sistem.',
              style: pw.TextStyle(fontSize: 8, color: greyColor),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfColorCell(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Skipped lab (null) renders as "-" instead of a green "Normal" 0.
  pw.TableRow _pdfLabRow(
    String name,
    double? value,
    int decimals,
    String normalText,
    double normal,
    double borderline,
  ) {
    if (value == null) {
      return pw.TableRow(
        children: [
          _pdfCell(name),
          _pdfCell('-'),
          _pdfCell(normalText),
          _pdfColorCell('-', PdfColor.fromHex('6B7280')),
        ],
      );
    }
    return pw.TableRow(
      children: [
        _pdfCell(name),
        _pdfCell('${value.toStringAsFixed(decimals)} mg/dL'),
        _pdfCell(normalText),
        _pdfColorCell(
          _labStatusText(value, normal, borderline),
          _pdfLabColor(value, normal, borderline),
        ),
      ],
    );
  }

  String _labStatusText(double value, double normal, double borderline) {
    if (value < normal) return 'Normal';
    if (value < borderline) return 'Batas';
    return 'Tinggi';
  }

  PdfColor _pdfLabColor(double value, double normal, double borderline) {
    if (value < normal) return PdfColor.fromHex('4CAF50');
    if (value < borderline) return PdfColor.fromHex('FFA726');
    return PdfColor.fromHex('EF5350');
  }
}
