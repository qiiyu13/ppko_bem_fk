import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../services/appointment_service.dart';
import '../../../utils/responsive_size.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _dateDisplayController = TextEditingController();
  final _timeDisplayController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _originalDate;
  bool _isLoading = false;

  static final _mapsUrlPattern = RegExp(
    r'^https?://(www\.)?(google\.[a-z.]+/maps|maps\.app\.goo\.gl|goo\.gl/maps)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    if (s != null) {
      _titleController.text = s['title'] ?? '';
      _locationController.text = s['location'] ?? '';

      final rawDate = s['date'];
      if (rawDate is DateTime) {
        _selectedDate = rawDate.toLocal();
      } else if (rawDate is String) {
        _selectedDate = DateTime.tryParse(rawDate)?.toLocal();
      }
      _originalDate = _selectedDate;
      if (_selectedDate != null) {
        _dateDisplayController.text = _formatDate(_selectedDate!);
      }

      final notes = s['notes'];
      if (notes is String && notes.isNotEmpty) {
        try {
          final parsed = jsonDecode(notes) as Map<String, dynamic>;
          final time = parsed['time'] as String? ?? '';
          _parseTimeRange(time);
          _mapsUrlController.text = parsed['mapsUrl'] as String? ?? '';
        } catch (e) {
          debugPrint('schedule notes parse failed: $e');
        }
      }
    }
  }

  void _parseTimeRange(String range) {
    final parts = range.split('-').map((e) => e.trim()).toList();
    if (parts.length != 2) return;
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start != null && end != null) {
      _startTime = start;
      _endTime = end;
      _timeDisplayController.text = _formatTimeRange(start, end);
    }
  }

  TimeOfDay? _parseTime(String value) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeRange(TimeOfDay start, TimeOfDay end) =>
      '${_formatTime(start)} - ${_formatTime(end)}';

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _mapsUrlController.dispose();
    _dateDisplayController.dispose();
    _timeDisplayController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final floor = _originalDate != null && _originalDate!.isBefore(today)
        ? _originalDate!
        : today;
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: _selectedDate != null && _selectedDate!.isAfter(floor)
          ? _selectedDate!
          : floor,
      firstDate: floor,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateDisplayController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickTimeRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Pilih waktu mulai',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute),
      helpText: 'Pilih waktu selesai',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (end == null) return;

    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _startTime = start;
      _endTime = end;
      _timeDisplayController.text = _formatTimeRange(start, end);
    });
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse('https://www.google.com/maps');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final time = _startTime != null && _endTime != null
          ? _formatTimeRange(_startTime!, _endTime!)
          : '';
      final mapsUrl = _mapsUrlController.text.trim();
      final notes = jsonEncode({
        'time': time,
        if (mapsUrl.isNotEmpty) 'mapsUrl': mapsUrl,
      });
      final isEdit = widget.schedule != null;

      if (isEdit) {
        final id = widget.schedule!['id'].toString();
        final updatedAt = widget.schedule!['updatedAt'] != null
            ? DateTime.tryParse(widget.schedule!['updatedAt'].toString()) ??
                DateTime.now()
            : DateTime.now();
        await AppointmentService.updateAppointment(
          id,
          title: _titleController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          notes: notes,
          type: 'JADWAL',
          updatedAt: updatedAt,
        );
      } else {
        await AppointmentService.createAppointment(
          title: _titleController.text.trim(),
          date: _selectedDate!,
          location: _locationController.text.trim(),
          notes: notes,
          type: 'JADWAL',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Jadwal berhasil diperbarui!'
              : 'Jadwal berhasil ditambahkan!'),
          backgroundColor: AppColors.statusGreen,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final isEdit = widget.schedule != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: ResponsiveSize.fontXLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Judul Kegiatan',
                    hint: 'Contoh: Screening Massal RW 01',
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: ResponsiveSize.spacingLarge),
                  _buildTextField(
                    label: 'Tanggal',
                    hint: 'Pilih Tanggal',
                    controller: _dateDisplayController,
                    readOnly: true,
                    suffixIcon:
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: _pickDate,
                    validator: (_) =>
                        _selectedDate == null ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: ResponsiveSize.spacingLarge),
                  _buildTextField(
                    label: 'Waktu',
                    hint: 'Pilih rentang waktu',
                    controller: _timeDisplayController,
                    readOnly: true,
                    suffixIcon:
                        const Icon(Icons.access_time, color: AppColors.primary),
                    onTap: _pickTimeRange,
                  ),
                  SizedBox(height: ResponsiveSize.spacingLarge),
                  _buildTextField(
                    label: 'Lokasi',
                    hint: 'Contoh: Balai Desa Sukamaju',
                    controller: _locationController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: ResponsiveSize.spacingLarge),
                  _buildTextField(
                    label: 'Link Google Maps (opsional)',
                    hint: 'Tempel link dari Google Maps',
                    controller: _mapsUrlController,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return _mapsUrlPattern.hasMatch(value)
                          ? null
                          : 'Link Google Maps tidak valid';
                    },
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  TextButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    label: const Text(
                      'Buka Google Maps untuk salin link',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingXLarge * 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.paddingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontLarge,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.fontMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingMedium,
              vertical: ResponsiveSize.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }
}
