import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../constants/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/screening_service.dart';
import '../../../utils/responsive_size.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    final me = await AuthService.getMe();
    final role = (me?['role'] ?? '').toString();
    _isSuperadmin = role == 'SUPERADMIN';
    _screenerName = me?['responsibleName']?.toString();
    if (_isSuperadmin) {
      _admins = await AdminService.getUsers(role: 'ADMIN');
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
    setState(() => _fetching = true);
    final data = await ScreeningService.getScreeningReport(
      screenedBy: _isSuperadmin ? _selectedAdminId : null,
      from: _fromBound,
      to: _toBound,
    );
    if (!mounted) return;
    setState(() {
      _results = data;
      _fetching = false;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

  // ---- CSV export ----
  String _buildCsv() {
    final buf = StringBuffer();
    buf.writeln(
        'Tanggal,Nama,NIK,JK,Sistolik,Diastolik,GulaDarah,AsamUrat,Kolesterol,BeratBadan,TinggiBadan,IRDScore,Kategori,Petugas');
    String esc(String s) => s.replaceAll(',', ' ');
    for (final r in _results) {
      buf.writeln([
        _rowDate(r),
        esc(_patientName(r)),
        _patientNik(r),
        esc((r['profile']?['gender'] ?? '-').toString()),
        _int(r['systolic']),
        _int(r['diastolic']),
        _num(r['bloodSugar']),
        _num(r['uricAcid']),
        _num(r['cholesterol']),
        _num(r['weight']),
        _num(r['height']),
        _num(r['irdScore'], decimals: 2),
        _category(r),
        esc(_screenerOf(r)),
      ].join(','));
    }
    return buf.toString();
  }

  Future<void> _exportCsv() async {
    if (_results.isEmpty) {
      _toast('Belum ada data untuk diexport');
      return;
    }
    final csv = _buildCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV'),
        content: SingleChildScrollView(
          child: SelectableText(
            csv,
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
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => (await _generatePdf()).save(),
      name:
          'Laporan_Skrining_${DateFormat('yyyyMMdd').format(_from)}_${DateFormat('yyyyMMdd').format(_to)}.pdf',
    );
  }

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      ),
    );
    final primaryColor = PdfColor.fromHex('144425');
    final greyColor = PdfColor.fromHex('6B7280');
    final lightGrey = PdfColor.fromHex('F3F4F6');
    final borderColor = PdfColor.fromHex('E5E7EB');

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    final header = ['Tgl', 'Nama', 'NIK', 'TD', 'GDS', 'AU', 'Kol', 'BB', 'TB', 'IRD', 'Kategori'];

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: lightGrey),
        children: header.map((h) => cell(h, bold: true)).toList(),
      ),
      for (final r in _results)
        pw.TableRow(children: [
          cell(_rowDate(r)),
          cell(_patientName(r)),
          cell(_patientNik(r)),
          cell('${_int(r['systolic'])}/${_int(r['diastolic'])}'),
          cell(_num(r['bloodSugar'])),
          cell(_num(r['uricAcid'])),
          cell(_num(r['cholesterol'])),
          cell(_num(r['weight'])),
          cell(_num(r['height'])),
          cell(_num(r['irdScore'], decimals: 2)),
          cell(_category(r)),
        ]),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN SKRINING KESEHATAN',
                    style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Petugas: ${_selectedScopeLabel()}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                pw.Text(
                    'Periode: ${_dateFmt.format(_from)} – ${_dateFmt.format(_to)}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                pw.Text('Total: ${_results.length} skrining',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            children: rows,
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: borderColor),
          pw.Text(
            'PPKO BEM FK — Laporan dibuat otomatis pada ${_dateFmt.format(DateTime.now())}.',
            style: pw.TextStyle(fontSize: 8, color: greyColor),
          ),
        ],
      ),
    );
    return doc;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Skrining'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
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
            DropdownButtonFormField<String?>(
              initialValue: _selectedAdminId,
              decoration: const InputDecoration(
                labelText: 'Petugas',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Semua Petugas')),
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
          ],
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

  Widget _buildList() {
    if (_fetching) return const Center(child: CircularProgressIndicator());
    if (_results.isEmpty) {
      return const Center(child: Text('Tidak ada data pada rentang ini'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _results[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(_patientName(r)),
            subtitle: Text(
                '${_rowDate(r)} • TD ${_int(r['systolic'])}/${_int(r['diastolic'])} • IRD ${_num(r['irdScore'], decimals: 2)}'
                '${_isSuperadmin ? '\nPetugas: ${_screenerOf(r)}' : ''}'),
            isThreeLine: _isSuperadmin,
            trailing: Text(_category(r),
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
                icon: const Icon(Icons.table_chart),
                label: const Text('Export CSV'),
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
