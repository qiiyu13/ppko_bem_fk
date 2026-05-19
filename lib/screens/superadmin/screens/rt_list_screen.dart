import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';
import 'family_accounts_screen.dart';

class RtListScreen extends StatefulWidget {
  final String rwId;
  final String rwName;
  final List<Map<String, dynamic>>? rtData;

  const RtListScreen({
    super.key,
    required this.rwId,
    required this.rwName,
    this.rtData,
  });

  @override
  State<RtListScreen> createState() => _RtListScreenState();
}

class _RtListScreenState extends State<RtListScreen> {
  List<Map<String, dynamic>> _rts = [];

  @override
  void initState() {
    super.initState();
    _rts = widget.rtData ?? [];
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
          'Daftar RT - ${widget.rwName}',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _rts.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada RT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                itemCount: _rts.length,
                itemBuilder: (context, index) {
                  final rt = _rts[index];
                  return _buildRtCard(context, rt);
                },
              ),
      ),
    );
  }

  Widget _buildRtCard(BuildContext context, Map<String, dynamic> rt) {
    final count = rt['_count'] as Map<String, dynamic>? ?? {};
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FamilyAccountsScreen(
                rtId: rt['id'] as String,
                rtName: rt['name']?.toString() ?? 'RT',
                rwName: widget.rwName,
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
                  color: AppColors.primarySurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    rt['name']?.toString() ?? 'RT',
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
                      rt['name']?.toString() ?? 'RT',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Text(
                      '$userCount Keluarga',
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
