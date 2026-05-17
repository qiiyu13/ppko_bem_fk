import 'dart:convert';
import 'package:flutter/material.dart';
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
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _villageController = TextEditingController();
  final _dateDisplayController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    if (s != null) {
      _titleController.text = s['title'] ?? '';
      _locationController.text = s['location'] ?? '';

      final rawDate = s['date'];
      if (rawDate is DateTime) {
        _selectedDate = rawDate;
      } else if (rawDate is String) {
        _selectedDate = DateTime.tryParse(rawDate);
      }
      if (_selectedDate != null) {
        _dateDisplayController.text = _formatDate(_selectedDate!);
      }

      final notes = s['notes'];
      if (notes != null) {
        try {
          final parsed = jsonDecode(notes as String) as Map<String, dynamic>;
          _timeController.text = parsed['time'] ?? '';
          _villageController.text = parsed['village'] ?? '';
        } catch (_) {}
      }
      _timeController.text = _timeController.text.isNotEmpty
          ? _timeController.text
          : (s['time'] ?? '');
      _villageController.text = _villageController.text.isNotEmpty
          ? _villageController.text
          : (s['village'] ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _villageController.dispose();
    _dateDisplayController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final time = _timeController.text.trim();
    final village = _villageController.text.trim();

    if (title.isEmpty || _selectedDate == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, tanggal, dan lokasi wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notes = jsonEncode({'time': time, 'village': village});
      final isEdit = widget.schedule != null;

      if (isEdit) {
        final id = widget.schedule!['id'].toString();
        final updatedAt = widget.schedule!['updatedAt'] != null
            ? DateTime.tryParse(widget.schedule!['updatedAt'].toString()) ??
                DateTime.now()
            : DateTime.now();
        await AppointmentService.updateAppointment(
          id,
          title: title,
          date: _selectedDate,
          location: location,
          notes: notes,
          type: 'JADWAL',
          updatedAt: updatedAt,
        );
      } else {
        await AppointmentService.createAppointment(
          title: title,
          date: _selectedDate!,
          location: location,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Judul Kegiatan',
                hint: 'Contoh: Screening Massal RW 01',
                controller: _titleController,
              ),

              SizedBox(height: ResponsiveSize.spacingLarge),

              _buildTextField(
                label: 'Tanggal',
                hint: 'Pilih Tanggal',
                controller: _dateDisplayController,
                readOnly: true,
                suffixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                onTap: _pickDate,
              ),

              SizedBox(height: ResponsiveSize.spacingLarge),

              _buildTextField(
                label: 'Waktu',
                hint: 'Contoh: 08:00 - 12:00',
                controller: _timeController,
              ),

              SizedBox(height: ResponsiveSize.spacingLarge),

              _buildTextField(
                label: 'Lokasi',
                hint: 'Contoh: Balai Desa Sukamaju',
                controller: _locationController,
              ),

              SizedBox(height: ResponsiveSize.spacingLarge),

              _buildTextField(
                label: 'Desa',
                hint: 'Contoh: Sukamaju',
                controller: _villageController,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
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
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.surface),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
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
