import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import 'schedule_form_screen.dart';

class JadwalManagementScreen extends StatefulWidget {
  const JadwalManagementScreen({super.key});

  @override
  State<JadwalManagementScreen> createState() => _JadwalManagementScreenState();
}

class _JadwalManagementScreenState extends State<JadwalManagementScreen> {
  static const Color highRiskRed = Color(0xFFEF5350);

  final List<Map<String, dynamic>> _schedules = [
    {
      'id': 1,
      'title': 'Screening Massal - Sukamaju',
      'date': DateTime(2023, 10, 15),
      'time': '08:00 - 12:00',
      'location': 'Balai Desa Sukamaju',
      'village': 'Sukamaju',
      'patientsCount': 45,
      'highRiskCount': 8,
      'status': 'Scheduled',
    },
    {
      'id': 2,
      'title': 'Follow-up High Risk - Cibadak',
      'date': DateTime(2023, 10, 18),
      'time': '09:00 - 11:00',
      'location': 'Puskesmas Kecamatan',
      'village': 'Cibadak',
      'patientsCount': 12,
      'highRiskCount': 12,
      'status': 'Urgent',
    },
    {
      'id': 3,
      'title': 'Screening Massal - Mekarwangi',
      'date': DateTime(2023, 10, 22),
      'time': '08:00 - 14:00',
      'location': 'Posyandu Mekarwangi',
      'village': 'Mekarwangi',
      'patientsCount': 62,
      'highRiskCount': 5,
      'status': 'Scheduled',
    },
  ];

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleFormScreen(),
                      ),
                    );
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
              child: ListView.builder(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return _buildScheduleCard(schedule);
                },
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
                      _getMonthName(date.month).toUpperCase(),
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
                          padding: EdgeInsets.symmetric(
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
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          schedule['time'],
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
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
              SizedBox(width: 4),
              Text(
                '${schedule['patientsCount']} pasien',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (highRiskCount > 0) ...[
                SizedBox(width: 12),
                Icon(Icons.warning_amber, size: 14, color: highRiskRed),
                SizedBox(width: 4),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScheduleFormScreen(schedule: schedule),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: highRiskRed, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Hapus Jadwal'),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus jadwal ini?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Jadwal berhasil dihapus'),
                                backgroundColor: AppColors.statusGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: highRiskRed,
                          ),
                          child: Text('Hapus'),
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
