import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class ResidentListScreen extends StatelessWidget {
  final String rwNumber;
  final String rtNumber;
  final Map<String, dynamic> rtData;

  ResidentListScreen({
    super.key,
    required this.rwNumber,
    required this.rtNumber,
    required this.rtData,
  });

  final List<Map<String, dynamic>> _residents = [
    {
      'name': 'Budi Santoso',
      'nik': '320123199812220001',
      'age': 45,
      'lastScreening': '15 Okt 2023',
      'status': 'Normal',
    },
    {
      'name': 'Sari Wulandari',
      'nik': '320123199908880004',
      'age': 38,
      'lastScreening': '10 Okt 2023',
      'status': 'Attention',
    },
    {
      'name': 'Ahmad Dahlan',
      'nik': '320123199217770002',
      'age': 52,
      'lastScreening': '28 Sep 2023',
      'status': 'High Risk',
    },
    {
      'name': 'Siti Aminah',
      'nik': '3201231995221990002',
      'age': 41,
      'lastScreening': '05 Okt 2023',
      'status': 'Normal',
    },
    {
      'name': 'Yanto Basna',
      'nik': '320123197722110005',
      'age': 58,
      'lastScreening': '12 Okt 2023',
      'status': 'Normal',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'High Risk':
        return const Color(0xFFEF5350);
      case 'Attention':
        return const Color(0xFFFF9800);
      case 'Normal':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

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
          'RW $rwNumber RT $rtNumber',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              // TODO: Add resident
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              color: AppColors.background,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'RT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RT $rtNumber',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Ketua: ${rtData['ketua']}',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rtData['houseCount']} Rumah',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${rtData['residentCount']} Penduduk',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontMedium,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              color: AppColors.background,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari penduduk...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface.withValues(alpha: 0.3),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.paddingMedium,
                    vertical: ResponsiveSize.paddingSmall,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                itemCount: _residents.length,
                itemBuilder: (context, index) {
                  final resident = _residents[index];
                  return _buildResidentCard(resident);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    final statusColor = _getStatusColor(resident['status']);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
          SizedBox(width: ResponsiveSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident['name'],
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                Text(
                  'NIK: ${resident['nik']}',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                Row(
                  children: [
                    Icon(Icons.cake, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      '${resident['age']} tahun',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Screening: ${resident['lastScreening']}',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              resident['status'],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
