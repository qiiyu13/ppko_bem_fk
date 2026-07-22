import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/screening_options.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/screening_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';

/// Report screen for admins/superadmins to extract the screenings they recorded,
/// filtered by date range. Admins see only their own; superadmins can pick an
/// admin or view all. Exportable as CSV (clipboard) or PDF.
class ScreeningReportScreen extends StatefulWidget {
  const ScreeningReportScreen({super.key});

  @override
  State<ScreeningReportScreen> createState() => _ScreeningReportScreenState();
}

class _ScreeningReportScreenState extends State<ScreeningReportScreen> {
  final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  bool _loading = true;
  bool _isSuperadmin = false;
  String? _screenerName; // shown in the report header
  List<Map<String, dynamic>> _admins = [];
  String? _selectedAdminId; // null = all (superadmin only)

  late DateTime _from;
  late DateTime _to;

  List<Map<String, dynamic>> _results = [];
  bool _fetching = false;
  bool _fetchFailed = false;
  bool _truncated = false; // backend hit its row cap; the set is incomplete

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    try {
      final me = await AuthService.getMe();
      final role = (me?['role'] ?? '').toString();
      _isSuperadmin = role == 'SUPERADMIN';
      _screenerName = me?['responsibleName']?.toString();
      if (_isSuperadmin) {
        _admins = await AdminService.getUsers(role: 'ADMIN');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fetchFailed = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await _fetch();
  }

  // Inclusive day bounds: start of [_from] .. end of [_to].
  DateTime get _fromBound => DateTime(_from.year, _from.month, _from.day);
  DateTime get _toBound =>
      DateTime(_to.year, _to.month, _to.day, 23, 59, 59, 999);

  Future<void> _fetch() async {
    setState(() {
      _fetching = true;
      _fetchFailed = false;
    });
    try {
      final report = await ScreeningService.getScreeningReport(
        screenedBy: _isSuperadmin ? _selectedAdminId : null,
        from: _fromBound,
        to: _toBound,
      );
      if (!mounted) return;
      setState(() {
        _results = report.rows;
        _truncated = report.truncated;
        _fetching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fetching = false;
        _fetchFailed = true;
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
    await _fetch();
  }

  String _selectedScopeLabel() {
    if (!_isSuperadmin) return _screenerName ?? 'Saya';
    if (_selectedAdminId == null) return 'Semua Petugas';
    final a = _admins.firstWhere(
      (e) => e['id']?.toString() == _selectedAdminId,
      orElse: () => const {},
    );
    return a['responsibleName']?.toString() ?? 'Petugas';
  }

  // ---- helpers to read a row safely ----
  String _num(dynamic v, {int decimals = 1}) {
    if (v == null) return '-';
    final n = (v as num).toDouble();
    return n.toStringAsFixed(decimals);
  }

  String _int(dynamic v) => v == null ? '-' : (v as num).toInt().toString();

  /// BMI = kg / m². Null when height/weight missing so exports show '-'.
  double? _bmi(Map<String, dynamic> r) {
    final w = (r['weight'] as num?)?.toDouble();
    final h = (r['height'] as num?)?.toDouble();
    if (w == null || h == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  String _rowDate(Map<String, dynamic> r) {
    final raw = r['screeningAt'];
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    return dt == null ? '-' : _dateFmt.format(dt);
  }

  String _patientName(Map<String, dynamic> r) =>
      (r['profile']?['name'] ?? '-').toString();
  String _patientNik(Map<String, dynamic> r) =>
      (r['profile']?['nik'] ?? '-').toString();
  String _screenerOf(Map<String, dynamic> r) =>
      (r['screener']?['responsibleName'] ?? '-').toString();
  String _category(Map<String, dynamic> r) =>
      (r['irdCategory'] ?? '-').toString();

  /// One vocabulary everywhere (list, CSV, PDF, patient app, notification)
  /// instead of leaking the raw English enum values.
  String _categoryLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'attention':
        return 'Waspada';
      case 'high':
        return 'Tinggi';
      default:
        return raw;
    }
  }

  // ---- CSV export ----
  // Semicolon delimiter + comma decimals: what Excel/Sheets with the id_ID
  // locale actually splits into columns. Fields are RFC 4180-quoted so names
  // containing the delimiter, quotes, or newlines can't break rows.
  String _buildCsv() {
    String esc(String s) {
      if (s.contains(';') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    String csvNum(dynamic v, {int decimals = 1}) => v == null
        ? '-'
        : (v as num).toDouble().toStringAsFixed(decimals).replaceAll('.', ',');

    final buf = StringBuffer();
    buf.writeln(
        'Tanggal;Nama;NIK;JK;Sistolik(mmHg);Diastolik(mmHg);GulaDarah(mg/dl);AsamUrat(mg/dl);Kolesterol(mg/dl);BeratBadan(kg);TinggiBadan(cm);BMI(kg/m2);IRDScore;Kategori;Petugas');
    for (final r in _results) {
      buf.writeln([
        _rowDate(r),
        esc(_patientName(r)),
        esc(_patientNik(r)),
        esc((r['profile']?['gender'] ?? '-').toString()),
        _int(r['systolic']),
        _int(r['diastolic']),
        csvNum(r['bloodSugar']),
        csvNum(r['uricAcid']),
        csvNum(r['cholesterol']),
        csvNum(r['weight']),
        csvNum(r['height']),
        csvNum(_bmi(r)),
        csvNum(r['irdScore'], decimals: 2),
        _categoryLabel(_category(r)),
        esc(_screenerOf(r)),
      ].join(';'));
    }
    return buf.toString();
  }

  static const _csvPreviewLines = 30;

  Future<void> _exportCsv() async {
    if (_results.isEmpty) {
      _toast('Belum ada data untuk diexport');
      return;
    }
    final csv = _buildCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    // Preview only the first rows — rendering thousands of lines in one
    // SelectableText freezes the dialog. The clipboard holds the full CSV.
    final lines = csv.trimRight().split('\n');
    final hidden = lines.length - 1 - _csvPreviewLines; // minus header
    final preview = hidden > 0
        ? '${lines.take(_csvPreviewLines + 1).join('\n')}\n… $hidden baris lagi (CSV lengkap sudah tersalin)'
        : csv;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salin CSV'),
        content: SingleChildScrollView(
          child: SelectableText(
            preview,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    _toast('CSV disalin ke clipboard');
  }

  // ---- PDF export ----
  Future<void> _exportPdf() async {
    if (_results.isEmpty) {
      _toast('Belum ada data untuk diexport');
      return;
    }
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => (await _generatePdf()).save(),
        name:
            'Laporan_Skrining_${DateFormat('yyyyMMdd').format(_from)}_${DateFormat('yyyyMMdd').format(_to)}.pdf',
      );
    } catch (_) {
      _toast('Gagal membuat PDF. Coba lagi.', error: true);
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

  /// Latest screening per profile — one page per person, so someone screened
  /// twice in the range appears once (their most recent row).
  List<Map<String, dynamic>> _latestPerPerson() {
    final byProfile = <String, Map<String, dynamic>>{};
    for (final r in _results) {
      final pid = (r['profileId'] ?? r['profile']?['nik'] ?? '').toString();
      final at = DateTime.tryParse(r['screeningAt']?.toString() ?? '');
      final prev = byProfile[pid];
      final prevAt =
          prev == null ? null : DateTime.tryParse(prev['screeningAt']?.toString() ?? '');
      if (prev == null ||
          (at != null && (prevAt == null || at.isAfter(prevAt)))) {
        byProfile[pid] = r;
      }
    }
    final list = byProfile.values.toList();
    list.sort((a, b) => _patientName(a).compareTo(_patientName(b)));
    return list;
  }

  int? _profileAge(Map<String, dynamic> r) {
    final raw = r['profile']?['birthDate'];
    final dt = raw == null ? null : DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    final now = DateTime.now();
    var age = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  String _bmiCategoryLabel(double? bmi) {
    if (bmi == null) return '-';
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  String _incomeText(dynamic v) {
    if (v == null) return '-';
    return 'Rp ${NumberFormat('#,###', 'id_ID').format((v as num).toDouble())}';
  }

  /// (label, value) rows for the perilaku snapshot of one screening row.
  List<(String, String)> _behaviorRows(Map<String, dynamic> r) {
    final rows = <(String, String)>[];
    void add(String key, String title, List<OptionItem> opts) {
      final v = r[key];
      if (v is String) rows.add((title, ScreeningOptions.labelFor(opts, v)));
    }

    add('smokingStatus', 'Merokok', ScreeningOptions.smokingStatus);
    add('physicalActivity', 'Aktivitas fisik', ScreeningOptions.physicalActivity);
    add('fruitConsumption', 'Konsumsi buah', ScreeningOptions.fruitConsumption);
    add('vegetableConsumption', 'Konsumsi sayur', ScreeningOptions.vegetableConsumption);
    add('sweetFoodConsumption', 'Makanan manis', ScreeningOptions.sweetFoodConsumption);
    add('sweetDrinkConsumption', 'Minuman manis', ScreeningOptions.sweetDrinkConsumption);
    add('fattyFoodConsumption', 'Makanan berlemak', ScreeningOptions.fattyFoodConsumption);
    add('fastFoodConsumption', 'Makanan cepat saji', ScreeningOptions.fastFoodConsumption);
    final sd = r['sleepDuration'];
    if (sd is num) rows.add(('Durasi tidur', '${sd % 1 == 0 ? sd.toInt() : sd} jam'));
    add('medicationRoutine', 'Rutin minum obat', ScreeningOptions.medicationRoutine);
    return rows;
  }

  // ---- black & white per-person PDF ----
  static final _pdfGrey = PdfColor.fromHex('6B7280');
  static final _pdfLightGrey = PdfColor.fromHex('F3F4F6');
  static final _pdfBorder = PdfColor.fromHex('D1D5DB');

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document(theme: await _pdfTheme());
    final persons = _latestPerPerson();

    var nNormal = 0, nAttention = 0, nHigh = 0;
    for (final r in persons) {
      switch (_category(r).toLowerCase()) {
        case 'high':
          nHigh++;
        case 'attention':
          nAttention++;
        case 'normal':
          nNormal++;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PPKO BEM FK — dibuat otomatis ${_dateFmt.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: _pdfGrey),
              ),
              pw.Text('Hal. ${ctx.pageNumber}/${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: _pdfGrey)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          _pdfCover(persons.length, nNormal, nAttention, nHigh),
          for (var i = 0; i < persons.length; i++) ...[
            pw.NewPage(),
            _pdfPersonPage(persons[i]),
          ],
        ],
      ),
    );
    return doc;
  }

  pw.Widget _pdfCover(int total, int nNormal, int nAttention, int nHigh) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LAPORAN SKRINING KESEHATAN',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('PPKO BEM FK', style: pw.TextStyle(fontSize: 10, color: _pdfGrey)),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 1, color: PdfColors.black),
        pw.SizedBox(height: 16),
        _pdfKvTable([
          ('Petugas', _selectedScopeLabel()),
          ('Periode', '${_dateFmt.format(_from)} – ${_dateFmt.format(_to)}'),
          ('Total Orang', '$total orang'),
          if (_truncated)
            ('Catatan', 'Data terpotong — melebihi batas ekspor, persempit rentang tanggal'),
        ]),
        pw.SizedBox(height: 28),
        _pdfSectionTitle('RINGKASAN KATEGORI RISIKO'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _pdfStatBox('Normal', nNormal),
          pw.SizedBox(width: 8),
          _pdfStatBox('Waspada', nAttention),
          pw.SizedBox(width: 8),
          _pdfStatBox('Tinggi', nHigh),
        ]),
      ],
    );
  }

  pw.Widget _pdfStatBox(String label, int count) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(children: [
          pw.Text('$count',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
        ]),
      ),
    );
  }

  pw.Widget _pdfPersonPage(Map<String, dynamic> r) {
    final profile = r['profile'] as Map<String, dynamic>? ?? {};
    final age = _profileAge(r);
    final bmi = _bmi(r);
    final waist = (r['waistCircumference'] as num?)?.toDouble();
    final hip = (r['hipCircumference'] as num?)?.toDouble();
    final ratio = (waist != null && hip != null && hip > 0) ? waist / hip : null;
    final behaviorRows = _behaviorRows(r);

    final identitas = <(String, String)>[
      ('Jenis Kelamin', (profile['gender'] ?? '-').toString()),
      if (age != null) ('Usia', '$age tahun'),
      ('Pendidikan', ScreeningOptions.labelFor(ScreeningOptions.education, profile['education'] as String?)),
      ('Pekerjaan', ScreeningOptions.labelFor(ScreeningOptions.occupation, profile['occupation'] as String?)),
      ('Status Perkawinan', ScreeningOptions.labelFor(ScreeningOptions.maritalStatus, profile['maritalStatus'] as String?)),
      ('Pendapatan', _incomeText(profile['income'])),
      ('Riwayat Keluarga (DM/HT/Stroke/Jantung)', ScreeningOptions.labelFor(ScreeningOptions.familyDiseaseHistory, profile['familyDiseaseHistory'] as String?)),
    ];

    final antropometri = <(String, String)>[
      ('Berat Badan', '${_num(r['weight'])} kg'),
      ('Tinggi Badan', '${_num(r['height'])} cm'),
      ('IMT', '${_num(bmi)} (${_bmiCategoryLabel(bmi)})'),
      ('Lingkar Pinggang', waist == null ? '-' : '${waist.toStringAsFixed(1)} cm'),
      ('Lingkar Perut', _num(r['abdominalCircumference']) == '-' ? '-' : '${_num(r['abdominalCircumference'])} cm'),
      ('Lingkar Panggul', hip == null ? '-' : '${hip.toStringAsFixed(1)} cm'),
      ('Rasio Pinggang-Panggul', ratio == null ? '-' : ratio.toStringAsFixed(2)),
    ];

    final klinis = <(String, String)>[
      ('Tekanan Darah', '${_int(r['systolic'])}/${_int(r['diastolic'])} mmHg'),
      ('Denyut Nadi', r['pulse'] == null ? '-' : '${_int(r['pulse'])} x/menit'),
      ('Gula Darah', _num(r['bloodSugar']) == '-' ? '-' : '${_num(r['bloodSugar'])} mg/dL'),
      ('Kolesterol', _num(r['cholesterol']) == '-' ? '-' : '${_num(r['cholesterol'])} mg/dL'),
      ('Asam Urat', _num(r['uricAcid']) == '-' ? '-' : '${_num(r['uricAcid'])} mg/dL'),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Identity header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(_patientName(r).toUpperCase(),
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('NIK: ${_patientNik(r)}',
                      style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(_rowDate(r),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Petugas: ${_screenerOf(r)}',
                    style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.black),
        pw.SizedBox(height: 12),
        _pdfSectionTitle('IDENTITAS & DEMOGRAFI'),
        _pdfKvTable(identitas),
        pw.SizedBox(height: 12),
        _pdfSectionTitle('ANTROPOMETRI'),
        _pdfKvTable(antropometri),
        pw.SizedBox(height: 12),
        _pdfSectionTitle('HASIL KLINIS'),
        _pdfKvTable(klinis),
        if (behaviorRows.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _pdfSectionTitle('PERILAKU & GAYA HIDUP'),
          _pdfKvTable(behaviorRows),
        ],
        pw.SizedBox(height: 16),
        // Result box — category as bold text only; no color in B/W print
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1.2),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SKOR IRD', style: pw.TextStyle(fontSize: 8, color: _pdfGrey)),
                  pw.Text(_num(r['irdScore'], decimals: 2),
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('KATEGORI RISIKO', style: pw.TextStyle(fontSize: 8, color: _pdfGrey)),
                  pw.Text(
                    _categoryLabel(_category(r)).toUpperCase(),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  /// Two-column label/value table — the workhorse of the per-person page.
  pw.Widget _pdfKvTable(List<(String, String)> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
      children: [
        for (final (label, value) in rows)
          pw.TableRow(children: [
            pw.Container(
              color: _pdfLightGrey,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(value,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ]),
      ],
    );
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppSnackBar(context, msg, error: error);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Laporan Skrining',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                if (_truncated) _buildTruncatedBanner(),
                const Divider(height: 1),
                Expanded(child: _buildList()),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildExportBar(),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateButton('Dari', _from, () => _pickDate(isFrom: true)),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Expanded(
                child: _dateButton('Sampai', _to, () => _pickDate(isFrom: false)),
              ),
            ],
          ),
          if (_isSuperadmin) ...[
            SizedBox(height: ResponsiveSize.spacingSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Petugas',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedAdminId,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      hint: Text(
                        'Pilih Petugas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: ResponsiveSize.fontMedium,
                        ),
                      ),
                      dropdownColor: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Petugas', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ..._admins.map((a) => DropdownMenuItem<String?>(
                          value: a['id']?.toString(),
                          child: Text(a['responsibleName']?.toString() ?? '-'),
                        )),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedAdminId = v);
                        _fetch();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTruncatedBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: ResponsiveSize.paddingMedium),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.statusAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.statusAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data melebihi batas ekspor — hanya ${_results.length} skrining ditampilkan. Persempit rentang tanggal.',
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime value, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(_dateFmt.format(value),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Color _categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('high') || c.contains('tinggi')) return AppColors.statusRed;
    if (c.contains('atten') || c.contains('waspada') || c.contains('perhati')) {
      return AppColors.statusAmber;
    }
    if (c.contains('normal')) return AppColors.statusGreen;
    return AppColors.textSecondary;
  }

  Widget _buildList() {
    if (_fetching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_fetchFailed) {
      return ErrorStateWidget(
        message: 'Gagal memuat laporan.\nPeriksa koneksi lalu coba lagi.',
        onRetry: () {
          if (_screenerName == null) {
            setState(() => _loading = true);
            _init();
          } else {
            _fetch();
          }
        },
      );
    }
    if (_results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'Tidak ada data pada rentang ini',
        subtitle: 'Ubah tanggal atau petugas untuk melihat hasil lain.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _results[i];
        final category = _categoryLabel(_category(r));
        final categoryColor = _categoryColor(category);
        return Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientName(r),
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_rowDate(r)} • TD ${_int(r['systolic'])}/${_int(r['diastolic'])} • IRD ${_num(r['irdScore'], decimals: 2)}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_isSuperadmin) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Petugas: ${_screenerOf(r)}',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Salin CSV'),
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingSmall),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
