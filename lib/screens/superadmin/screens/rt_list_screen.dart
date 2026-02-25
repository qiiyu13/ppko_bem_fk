import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import 'resident_list_screen.dart';

class RtListScreen extends StatelessWidget {
  final String rwNumber;
  final Map<String, dynamic> rwData;

  const RtListScreen({super.key, required this.rwNumber, required this.rwData});

  List<Map<String, dynamic>> get _rts {
    if (rwNumber == '01') {
      return [
        {
          'number': '001',
          'houseCount': 25,
          'residentCount': 30,
          'ketua': 'Pak Amin',
        },
        {
          'number': '002',
          'houseCount': 30,
          'residentCount': 35,
          'ketua': 'Ibu Rina',
        },
        {
          'number': '003',
          'houseCount': 20,
          'residentCount': 15,
          'ketua': 'Pak Dodi',
        },
      ];
    } else if (rwNumber == '02') {
      return [
        {
          'number': '001',
          'houseCount': 35,
          'residentCount': 40,
          'ketua': 'Pak Joko',
        },
        {
          'number': '002',
          'houseCount': 25,
          'residentCount': 20,
          'ketua': 'Ibu Ani',
        },
      ];
    } else {
      return [
        {
          'number': '001',
          'houseCount': 20,
          'residentCount': 25,
          'ketua': 'Pak Surya',
        },
        {
          'number': '002',
          'houseCount': 25,
          'residentCount': 20,
          'ketua': 'Ibu Mina',
        },
        {
          'number': '003',
          'houseCount': 15,
          'residentCount': 10,
          'ketua': 'Pak Budi',
        },
      ];
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
          'RW $rwNumber - Daftar RT',
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
              // TODO: Add RT
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
                        'RW',
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
                          'RW $rwNumber',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Ketua: ${rwData['ketua']}',
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
                        '${rwData['rtCount']} RT',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontMedium,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${rwData['residentCount']} Penduduk',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                itemCount: _rts.length,
                itemBuilder: (context, index) {
                  final rt = _rts[index];
                  return _buildRtCard(context, rt);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRtCard(BuildContext context, Map<String, dynamic> rt) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResidentListScreen(
                rwNumber: rwNumber,
                rtNumber: rt['number'],
                rtData: rt,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'RT',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        rt['number'],
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RT ${rt['number']} - ${rt['ketua']}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.home,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${rt['houseCount']} Rumah',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontMedium,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${rt['residentCount']} Penduduk',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontMedium,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: ResponsiveSize.iconSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
