import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/appointment_service.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/responsive_size.dart';
import 'schedule_form_screen.dart';

class JadwalManagementScreen extends StatefulWidget {
  const JadwalManagementScreen({super.key});

  @override
  State<JadwalManagementScreen> createState() => _JadwalManagementScreenState();
}

class _JadwalManagementScreenState extends State<JadwalManagementScreen> {
  static const Color highRiskRed = Color(0xFFEF5350);

  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final all = await AppointmentService.getAppointments();
      final jadwal = all
          .where((a) => a['type'] == 'JADWAL')
          .map(_appointmentToSchedule)
          .toList();
      jadwal.sort((a, b) {
        final da = a['date'] as DateTime;
        final db = b['date'] as DateTime;
        return da.compareTo(db);
      });
      if (mounted) {
        setState(() {
          _schedules = jadwal;
          final validIds = jadwal.map((s) => s['id'].toString()).toSet();
          _selectedIds.removeWhere((id) => !validIds.contains(id));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _appointmentToSchedule(Map<String, dynamic> a) {
    DateTime date = DateTime.now();
    final rawDate = a['date'];
    if (rawDate is String) {
      date = (DateTime.tryParse(rawDate) ?? date).toLocal();
    } else if (rawDate is DateTime) {
      date = rawDate.toLocal();
    }

    String time = '';
    final notes = a['notes'];
    if (notes is String && notes.isNotEmpty) {
      try {
        final parsed = jsonDecode(notes) as Map<String, dynamic>;
        time = parsed['time'] ?? '';
      } catch (_) {}
    }

    return {
      'id': a['id'],
      'title': a['title'] ?? '',
      'date': date,
      'time': time,
      'location': a['location'] ?? '',
      'status': 'Scheduled',
      'updatedAt': a['updatedAt'],
      'notes': notes,
    };
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus ${ids.length} jadwal terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: highRiskRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    int failed = 0;
    for (final id in ids) {
      final schedule = _schedules.firstWhere(
        (s) => s['id'].toString() == id,
        orElse: () => const {},
      );
      if (schedule.isEmpty) continue;
      final updatedAt = schedule['updatedAt'] != null
          ? DateTime.tryParse(schedule['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now();
      try {
        await AppointmentService.deleteAppointment(id, updatedAt);
      } catch (_) {
        failed++;
      }
    }
    _selectedIds.clear();
    await _loadSchedules();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed == 0
            ? 'Jadwal berhasil dihapus'
            : '$failed jadwal gagal dihapus'),
        backgroundColor:
            failed == 0 ? AppColors.statusGreen : highRiskRed,
      ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _openEdit(Map<String, dynamic> schedule) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(schedule: schedule),
      ),
    );
    if (result == true) _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _selectionMode ? _selectionAppBar() : _defaultAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              if (!_selectionMode)
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                  color: AppColors.background,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleFormScreen(),
                          ),
                        );
                        if (result == true) _loadSchedules();
                      },
                      icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
                      label: const Text(
                        'Tambah Jadwal',
                        style: TextStyle(color: AppColors.textOnPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.paddingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _schedules.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada jadwal',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: ResponsiveSize.fontMedium,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSchedules,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding:
                                  EdgeInsets.all(ResponsiveSize.paddingMedium),
                              itemCount: _schedules.length,
                              itemBuilder: (context, index) {
                                return _buildScheduleCard(_schedules[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _defaultAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Kelola Jadwal',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: ResponsiveSize.fontXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  AppBar _selectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedIds.length} dipilih',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: ResponsiveSize.fontXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: highRiskRed),
          tooltip: 'Hapus terpilih',
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final date = schedule['date'] as DateTime;
    final status = schedule['status'] as String;
    final id = schedule['id'].toString();
    final selected = _selectedIds.contains(id);

    Color statusColor;
    switch (status) {
      case 'Urgent':
        statusColor = highRiskRed;
        break;
      default:
        statusColor = AppColors.statusGreen;
    }

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          _toggleSelect(id);
        } else {
          _openEdit(schedule);
        }
      },
      onLongPress: () => _toggleSelect(id),
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surface,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              SizedBox(width: ResponsiveSize.spacingSmall),
            ],
            Container(
              width: 60,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    IndonesianDate.shortMonth(date.month).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.day.toString(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveSize.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule['title'],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: ResponsiveSize.fontLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  if ((schedule['time'] as String).isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          schedule['time'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          schedule['location'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
