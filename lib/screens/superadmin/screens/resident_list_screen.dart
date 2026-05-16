import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';

class ResidentListScreen extends StatefulWidget {
  final String rwNumber;
  final String rtNumber;
  final String? rtId;

  const ResidentListScreen({
    super.key,
    required this.rwNumber,
    required this.rtNumber,
    this.rtId,
  });

  @override
  State<ResidentListScreen> createState() => _ResidentListScreenState();
}

class _ResidentListScreenState extends State<ResidentListScreen> {
  List<Map<String, dynamic>> _residents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      final residents = await RegionService.getResidents(regionId: widget.rtId);
      setState(() {
        _residents = residents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Penduduk RT ${widget.rtNumber}',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadResidents,
                color: AppColors.primary,
                child: _residents.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada penduduk',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                        itemCount: _residents.length,
                        itemBuilder: (context, index) {
                          final resident = _residents[index];
                          return _buildResidentCard(resident);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    final name = resident['name'] ?? 'Unknown';
    final nik = resident['nik'] ?? '';
    final birthDate = resident['birthDate'] != null
        ? DateTime.parse(resident['birthDate'])
        : null;
    final age = birthDate != null
        ? DateTime.now().year - birthDate.year
        : 0;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
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
                    name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Text(
                    'NIK: $nik',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (age > 0)
                    Text(
                      '$age tahun',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
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
