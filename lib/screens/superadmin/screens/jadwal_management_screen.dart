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
      if (mounted) setState(() => _schedules = jadwal);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _appointmentToSchedule(Map<String, dynamic> a) {
    DateTime date = DateTime.now();
    final rawDate = a['date'];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? date;
    } else if (rawDate is DateTime) {
      date = rawDate;
    }

    String time = '';
    String village = '';
    final notes = a['notes'];
    if (notes != null) {
      try {
        final parsed = jsonDecode(notes as String) as Map<String, dynamic>;
        time = parsed['time'] ?? '';
        village = parsed['village'] ?? '';
      } catch (_) {}
    }

    return {
      'id': a['id'],
      'title': a['title'] ?? '',
      'date': date,
      'time': time,
      'location': a['location'] ?? '',
      'village': village,
      'patientsCount': 0,
      'highRiskCount': 0,
      'status': 'Scheduled',
      'updatedAt': a['updatedAt'],
      'notes': notes,
    };
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final id = schedule['id'].toString();
    final updatedAt = schedule['updatedAt'] != null
        ? DateTime.tryParse(schedule['updatedAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    await AppointmentService.deleteAppointment(id, updatedAt);
    await _loadSchedules();
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  icon: Icon(Icons.add, color: AppColors.textOnPrimary),
                  label: Text(
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
                  ? Center(
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
                            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
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
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final date = schedule['date'] as DateTime;
    final status = schedule['status'] as String;
    final highRiskCount = schedule['highRiskCount'] as int;

    Color statusColor;
    switch (status) {
      case 'Urgent':
        statusColor = highRiskRed;
        break;
      default:
        statusColor = AppColors.statusGreen;
    }

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
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
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            schedule['time'],
                            style: TextStyle(
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
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            schedule['location'],
                            style: TextStyle(
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
          SizedBox(height: ResponsiveSize.spacingMedium),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${schedule['patientsCount']} pasien',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (highRiskCount > 0) ...[
                const SizedBox(width: 12),
                Icon(Icons.warning_amber, size: 14, color: highRiskRed),
                const SizedBox(width: 4),
                Text(
                  '$highRiskCount high risk',
                  style: TextStyle(
                    color: highRiskRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primary, size: 20),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScheduleFormScreen(schedule: schedule),
                    ),
                  );
                  if (result == true) _loadSchedules();
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: highRiskRed, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Jadwal'),
                      content: const Text(
                        'Apakah Anda yakin ingin menghapus jadwal ini?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            await _deleteSchedule(schedule);
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Jadwal berhasil dihapus'),
                                backgroundColor: AppColors.statusGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: highRiskRed,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
