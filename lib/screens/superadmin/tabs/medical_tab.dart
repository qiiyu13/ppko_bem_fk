import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/feature_flags.dart';
import '../../../services/admin_service.dart';
import '../../../services/region_service.dart';
import '../../../services/screening_service.dart';
import '../../../utils/responsive_size.dart';
import '../../../utils/page_transitions.dart';
import '../screens/screening_report_screen.dart';

class MedicalTab extends StatefulWidget {
  const MedicalTab({super.key});

  @override
  State<MedicalTab> createState() => _MedicalTabState();
}

class _MedicalTabState extends State<MedicalTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _villageBreakdown = [];
  List<Map<String, dynamic>> _admins = [];
  int _totalScreenings = 0;
  int _highRiskCount = 0;
  int _attentionCount = 0;
  int _normalCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        RegionService.getStats(),
        ScreeningService.getStats(),
        if (FeatureFlags.superadminAdminThroughput)
          AdminService.getUsers(role: 'ADMIN')
        else
          Future.value(<Map<String, dynamic>>[]),
        if (FeatureFlags.superadminAdminThroughput)
          AdminService.getThroughput()
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final regionStats = results[0] as Map<String, dynamic>;
      final screeningStats = results[1] as Map<String, dynamic>;
      final adminsRaw = (results[2] as List).cast<Map<String, dynamic>>();
      final throughput = (results[3] as List).cast<Map<String, dynamic>>();

      final throughputById = {
        for (final t in throughput) t['userId']?.toString() ?? '': t,
      };
      final admins = adminsRaw.map((a) {
        final id = a['id']?.toString() ?? '';
        final t = throughputById[id];
        if (t == null) return a;
        return {
          ...a,
          'screeningsLast7d': t['screeningsLast7d'] ?? a['screeningsLast7d'],
          'patientCount': t['patientCount'] ?? a['patientCount'],
        };
      }).toList();

      final villages = (regionStats['villages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final cats = screeningStats['categories'] as Map<String, dynamic>? ?? {};

      setState(() {
        _villageBreakdown = villages;
        _admins = admins;
        _totalScreenings = (screeningStats['total'] as num?)?.toInt() ?? 0;
        _highRiskCount = (cats['high'] as num?)?.toInt() ?? 0;
        _attentionCount = (cats['attention'] as num?)?.toInt() ?? 0;
        _normalCount = (cats['normal'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat laporan')),
      );
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
        scrolledUnderElevation: 0,
        title: Text(
          'Laporan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Laporan Skrining',
            icon: const Icon(Icons.assignment_outlined, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              ParallaxPageRoute(page: const ScreeningReportScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                children: [
                  _summaryCard(),
                  SizedBox(height: ResponsiveSize.spacingXLarge),
                  _sectionTitle('Distribusi Risiko'),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  _riskDistributionBar(),
                  SizedBox(height: ResponsiveSize.spacingXLarge),
                  _sectionTitle('Breakdown per Desa'),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  _buildVillageBreakdown(),
                  SizedBox(height: ResponsiveSize.spacingXLarge),
                  _sectionTitle('Throughput Admin'),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  _buildAdminThroughput(),
                  SizedBox(height: ResponsiveSize.spacingXLarge * 2),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveSize.fontXLarge,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Screening Tercatat',
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,##0', 'id_ID').format(_totalScreenings),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          Row(
            children: [
              _legend('High', _highRiskCount, AppColors.statusRed),
              const SizedBox(width: 16),
              _legend('Attention', _attentionCount, AppColors.statusAmber),
              const SizedBox(width: 16),
              _legend('Normal', _normalCount, AppColors.statusGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _riskDistributionBar() {
    final total = _highRiskCount + _attentionCount + _normalCount;
    if (total == 0) {
      return _emptyCard(Icons.bar_chart, 'Belum ada data screening');
    }
    final highPct = _highRiskCount / total;
    final attnPct = _attentionCount / total;
    final normPct = _normalCount / total;

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: (highPct * 10000).round(),
                    child: Container(color: AppColors.statusRed),
                  ),
                  Expanded(
                    flex: (attnPct * 10000).round(),
                    child: Container(color: AppColors.statusAmber),
                  ),
                  Expanded(
                    flex: (normPct * 10000).round(),
                    child: Container(color: AppColors.statusGreen),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(highPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.statusRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(attnPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.statusAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(normPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.statusGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVillageBreakdown() {
    if (!FeatureFlags.superadminPerVillageStats || _villageBreakdown.isEmpty) {
      return _emptyCard(
        Icons.location_city_outlined,
        _villageBreakdown.isEmpty
            ? 'Belum ada data per desa'
            : 'Fitur belum tersedia',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _villageHeader(),
            Container(height: 1, color: AppColors.divider),
            for (var i = 0; i < _villageBreakdown.length; i++) ...[
              _villageRow(_villageBreakdown[i]),
              if (i != _villageBreakdown.length - 1)
                Container(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _villageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Desa',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _colHeader('Total'),
          _colHeader('High', AppColors.statusRed),
          _colHeader('Attn', AppColors.statusAmber),
          _colHeader('Norm', AppColors.statusGreen),
        ],
      ),
    );
  }

  Widget _colHeader(String label, [Color? color]) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _villageRow(Map<String, dynamic> v) {
    final name = v['name']?.toString() ?? '-';
    final total = (v['profileCount'] as num?)?.toInt() ?? 0;
    final high = (v['high'] as num?)?.toInt() ?? 0;
    final attn = (v['attention'] as num?)?.toInt() ?? 0;
    final norm = (v['normal'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _cell('$total'),
          _cell('$high', AppColors.statusRed),
          _cell('$attn', AppColors.statusAmber),
          _cell('$norm', AppColors.statusGreen),
        ],
      ),
    );
  }

  Widget _cell(String value, [Color? color]) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: ResponsiveSize.fontSmall,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAdminThroughput() {
    if (!FeatureFlags.superadminAdminThroughput || _admins.isEmpty) {
      return _emptyCard(
        Icons.people_outline,
        _admins.isEmpty ? 'Belum ada admin terdaftar' : 'Fitur belum tersedia',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            for (var i = 0; i < _admins.length; i++) ...[
              _adminRow(_admins[i]),
              if (i != _admins.length - 1)
                Container(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _adminRow(Map<String, dynamic> admin) {
    final name = admin['responsibleName']?.toString() ??
        admin['name']?.toString() ??
        'Admin';
    final region = admin['region'] as Map<String, dynamic>?;
    final villageName = region?['name']?.toString() ?? 'Belum ditugaskan';
    final last7 = (admin['screeningsLast7d'] as num?)?.toInt();
    final patientCount = (admin['patientCount'] as num?)?.toInt();
    final isActive = admin['isActive'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  villageName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _miniMetric('7h', last7),
          const SizedBox(width: 12),
          _miniMetric('KK', patientCount),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, int? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value?.toString() ?? '—',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _emptyCard(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          SizedBox(height: ResponsiveSize.spacingSmall),
          Text(
            message,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
