import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../constants/app_colors.dart';
import '../../utils/asset_helper.dart';
import '../../utils/responsive_size.dart';
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
      final profileId = ProfileService.instance.activeProfile?.id;
      if (profileId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Tidak ada profil aktif';
        });
        return;
      }

      final response = await ApiService.get(
        '/screenings',
        queryParameters: {'profileId': profileId},
      );

      final data = response.data['data'] as List? ?? [];
      setState(() {
        _screeningData = data.map((json) {
          final map = json as Map<String, dynamic>;
          return BPScreeningData(
            date: DateTime.parse(map['screeningAt'] as String),
            systolic: (map['systolic'] as num).toInt(),
            diastolic: (map['diastolic'] as num).toInt(),
            weight: (map['weight'] as num? ?? 0).toDouble(),
            height: (map['height'] as num? ?? 0).toDouble(),
            bloodSugar: (map['bloodSugar'] as num? ?? 0).toDouble(),
            uricAcid: (map['uricAcid'] as num? ?? 0).toDouble(),
            cholesterol: (map['cholesterol'] as num? ?? 0).toDouble(),
            gender: widget.gender,
          );
        }).toList();
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Saya',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return ErrorStateWidget(message: _error!, onRetry: _loadScreenings);
            }

            if (_screeningData.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada data screening',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
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
                      // Expandable Screening Cards
                      ..._screeningData.reversed.take(_kRecentReportsLimit).map((data) {
                        return _buildExpandableScreeningCard(
                          data: data,
                          isInitiallyExpanded: false,
                        );
                      }),

                    ],
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
  final double bloodSugar;
  final double uricAcid;
  final double cholesterol;
  final String gender;

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

  double get ird {
    final auDenominator = gender.toLowerCase() == 'pria' ? 7.0 : 6.0;
    final gdsComponent = 0.3 * (bloodSugar / 200);
    final bpComponent = 0.2 * ((systolic / 140 + diastolic / 90) / 2);
    final kolComponent = 0.2 * (cholesterol / 240);
    final auComponent = 0.15 * (uricAcid / auDenominator);
    final bmiComponent = 0.15 * (bmi / 25);
    return gdsComponent +
        bpComponent +
        kolComponent +
        auComponent +
        bmiComponent;
  }

  String get irdCategory {
    if (ird < 0.75) return 'normal';
    if (ird <= 1.0) return 'attention';
    return 'high';
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

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getIRDStatusColor(String category) {
    switch (category) {
      case 'normal':
        return AppColors.success;
      case 'attention':
        return const Color(0xFFFF9800);
      case 'high':
        return const Color(0xFFEF5350);
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              top: Radius.circular(ResponsiveSize.cardBorderRadius),
              bottom: _isExpanded
                  ? Radius.zero
                  : Radius.circular(ResponsiveSize.cardBorderRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              child: Row(
                children: [
                  // Document icon
                  SvgPicture.asset(
                    AssetHelper.getSvgPath('document_recolored_final_2.svg'),
                    width: ResponsiveSize.iconMedium * 1.2,
                    height: ResponsiveSize.iconMedium * 1.2,
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: Text(
                      _formatDate(widget.data.date),
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
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
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(ResponsiveSize.cardBorderRadius),
                ),
                border: const Border(top: BorderSide(color: AppColors.surface)),
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
                          iconColor: const Color(0xFFEF5350),
                          label: 'Tekanan Darah',
                          value: '${widget.data.systolic}/${widget.data.diastolic}',
                          unit: 'mmHg',
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall),
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: const Color(0xFF42A5F5),
                          label: 'Berat Badan',
                          value: widget.data.weight.toStringAsFixed(1),
                          unit: 'kg',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.paddingSmall),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.height,
                          iconColor: const Color(0xFFAB47BC),
                          label: 'Tinggi Badan',
                          value: widget.data.height.toStringAsFixed(0),
                          unit: 'cm',
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall),
                      Expanded(
                        child: _buildVitalChip(
                          icon: Icons.calculate_outlined,
                          iconColor: const Color(0xFFFFA726),
                          label: 'BMI',
                          value: widget.data.bmi.toStringAsFixed(1),
                          unit: widget.data.bmiCategory,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Lab results
                  Text(
                    'Hasil Lab',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  _buildLabRow('Gula Darah', '${widget.data.bloodSugar.toStringAsFixed(0)} mg/dL', _labColor(widget.data.bloodSugar, normal: 100, borderline: 126)),
                  _buildLabRow('Asam Urat', '${widget.data.uricAcid.toStringAsFixed(1)} mg/dL', _labColor(widget.data.uricAcid, normal: 6, borderline: 7)),
                  _buildLabRow('Kolesterol', '${widget.data.cholesterol.toStringAsFixed(0)} mg/dL', _labColor(widget.data.cholesterol, normal: 200, borderline: 240)),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // IRD progress bar
                  _buildIRDBar(),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  const Divider(color: AppColors.surface),
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  // Action button
                  _buildActionButton(
                    label: 'Unduh Laporan',
                    icon: Icons.download_outlined,
                    onTap: () { _downloadReport(); },
                    bgColor: AppColors.primary,
                    fgColor: AppColors.background,
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
          borderRadius: BorderRadius.circular(ResponsiveSize.buttonBorderRadius),
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
      padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _labColor(double value, {required double normal, required double borderline}) {
    if (value < normal) return AppColors.success;
    if (value < borderline) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
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
              style: TextStyle(fontSize: ResponsiveSize.fontSmall, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: ResponsiveSize.fontSmall, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
              style: TextStyle(fontSize: ResponsiveSize.fontSmall, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              '${widget.data.ird.toStringAsFixed(2)} · ${widget.data.irdCategory}',
              style: TextStyle(fontSize: ResponsiveSize.fontSmall, fontWeight: FontWeight.w600, color: irdColor),
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
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final doc = await _generatePdf();
        return doc.save();
      },
      name: 'Laporan_Screening_${_formatDate(widget.data.date)}.pdf',
    );
  }

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      ),
    );
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

    final auNormal = d.gender.toLowerCase() == 'pria' ? 7.0 : 6.0;

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
                  pw.Text(
                    'Tanggal Screening: ${_formatDate(d.date)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Dicetak: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'DATA VITAL',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
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
                pw.TableRow(children: [_pdfCell('Tekanan Darah'), _pdfCell('${d.systolic}/${d.diastolic}'), _pdfCell('mmHg')]),
                pw.TableRow(children: [_pdfCell('Berat Badan'), _pdfCell(d.weight.toStringAsFixed(1)), _pdfCell('kg')]),
                pw.TableRow(children: [_pdfCell('Tinggi Badan'), _pdfCell(d.height.toStringAsFixed(0)), _pdfCell('cm')]),
                pw.TableRow(children: [_pdfCell('BMI'), _pdfCell(d.bmi.toStringAsFixed(1)), _pdfCell(d.bmiCategory)]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'HASIL LABORATORIUM',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
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
                pw.TableRow(children: [
                  _pdfCell('Gula Darah'),
                  _pdfCell('${d.bloodSugar.toStringAsFixed(0)} mg/dL'),
                  _pdfCell('< 100 mg/dL'),
                  _pdfColorCell(_labStatusText(d.bloodSugar, 100, 126), _pdfLabColor(d.bloodSugar, 100, 126)),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Asam Urat'),
                  _pdfCell('${d.uricAcid.toStringAsFixed(1)} mg/dL'),
                  _pdfCell('< ${auNormal.toStringAsFixed(0)} mg/dL'),
                  _pdfColorCell(_labStatusText(d.uricAcid, auNormal, auNormal + 1), _pdfLabColor(d.uricAcid, auNormal, auNormal + 1)),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Kolesterol'),
                  _pdfCell('${d.cholesterol.toStringAsFixed(0)} mg/dL'),
                  _pdfCell('< 200 mg/dL'),
                  _pdfColorCell(_labStatusText(d.cholesterol, 200, 240), _pdfLabColor(d.cholesterol, 200, 240)),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'INDEX RISIKO DIABETES (IRD)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      pw.Text('Nilai IRD', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                      pw.Text(
                        d.ird.toStringAsFixed(2),
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Kategori Risiko', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                      pw.Text(
                        d.irdCategory,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: irdColor),
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
        style: pw.TextStyle(fontSize: 10, color: color, fontWeight: pw.FontWeight.bold),
      ),
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

// Touchable Card Widget with press animation
class TouchableCard extends StatefulWidget {
  final Widget child;

  const TouchableCard({super.key, required this.child});

  @override
  State<TouchableCard> createState() => _TouchableCardState();
}

class _TouchableCardState extends State<TouchableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {},
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.cardBorderRadius,
                ),
                border: Border.all(color: AppColors.surface, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Touchable Suggestion Card
class TouchableSuggestionCard extends StatefulWidget {
  final IconData? icon;
  final String? iconAsset;
  final bool isSvg;
  final String title;
  final String subtitle;
  final Color iconColor;

  const TouchableSuggestionCard({
    super.key,
    this.icon,
    this.iconAsset,
    this.isSvg = false,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  }) : assert(
         icon != null || iconAsset != null,
         'Must provide either icon or iconAsset',
       );

  @override
  State<TouchableSuggestionCard> createState() =>
      _TouchableSuggestionCardState();
}

class _TouchableSuggestionCardState extends State<TouchableSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  Widget _buildIcon() {
    if (widget.iconAsset != null) {
      if (widget.isSvg) {
        return SvgPicture.asset(
          AssetHelper.getSvgPath(
            widget.iconAsset!
                .replaceFirst('assets/svg/', '')
                .replaceFirst('assets/images/', ''),
          ),
          width: ResponsiveSize.iconMedium,
          height: ResponsiveSize.iconMedium,
          colorFilter: ColorFilter.mode(widget.iconColor, BlendMode.srcIn),
        );
      } else {
        return Image.asset(
          widget.iconAsset!,
          width: ResponsiveSize.iconMedium,
          height: ResponsiveSize.iconMedium,
          color: widget.iconColor,
        );
      }
    }
    return Icon(
      widget.icon,
      color: widget.iconColor,
      size: ResponsiveSize.iconMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {},
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.cardBorderRadius,
                ),
                border: Border.all(color: AppColors.surface, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _buildIcon(),
            ),
            SizedBox(height: ResponsiveSize.spacingSmall),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Touchable Button Widget
class TouchableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isFilled;

  const TouchableButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.isFilled,
  });

  @override
  State<TouchableButton> createState() => _TouchableButtonState();
}

class _TouchableButtonState extends State<TouchableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: widget.isFilled
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.buttonBorderRadius,
                ),
                border: Border.all(
                  color: widget.isFilled
                      ? AppColors.primary
                      : AppColors.surface,
                  width: 1,
                ),
                boxShadow: widget.isFilled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
