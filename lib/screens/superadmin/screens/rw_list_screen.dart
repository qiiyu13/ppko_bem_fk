import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';
import 'rt_list_screen.dart';

class RwListScreen extends StatefulWidget {
  const RwListScreen({super.key});

  @override
  State<RwListScreen> createState() => _RwListScreenState();
}

class _RwListScreenState extends State<RwListScreen> {
  List<Map<String, dynamic>> _rws = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await RegionService.getRegions();
      // Filter only RW-level regions (regions with type 'RW' and no parent)
      final rwList = regions.where((r) => r['type'] == 'RW').toList();
      setState(() {
        _rws = rwList;
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar RW',
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
                onRefresh: _loadRegions,
                color: AppColors.primary,
                child: _rws.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada RW',
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
                        itemCount: _rws.length,
                        itemBuilder: (context, index) {
                          final rw = _rws[index];
                          return _buildRwCard(context, rw);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildRwCard(BuildContext context, Map<String, dynamic> rw) {
    final children = rw['children'] as List<dynamic>? ?? [];
    final count = rw['_count'] as Map<String, dynamic>? ?? {};
    final userCount = count['users'] as int? ?? 0;

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
          final children = (rw['children'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RtListScreen(
                rwId: rw['id'] as String,
                rwName: rw['name'] as String? ?? 'RW',
                rtData: children,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    rw['name']?.toString() ?? 'RW',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: ResponsiveSize.fontLarge,
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
                      rw['name']?.toString() ?? 'RW',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Text(
                      '${children.length} RT • $userCount KK',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
