import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';
import 'rw_list_screen.dart';

class VillageListScreen extends StatefulWidget {
  const VillageListScreen({super.key});

  @override
  State<VillageListScreen> createState() => _VillageListScreenState();
}

class _VillageListScreenState extends State<VillageListScreen> {
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVillages();
  }

  Future<void> _loadVillages() async {
    try {
      final villages = await RegionService.getVillages();
      setState(() {
        _villages = villages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addVillage() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Desa/Kelurahan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama desa/kelurahan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tambah', style: TextStyle(color: AppColors.textOnPrimary)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await RegionService.createRegion(
          type: 'VILLAGE',
          name: controller.text.trim(),
        );
        _loadVillages();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambah desa'), backgroundColor: Colors.red),
        );
      }
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
          'Daftar Desa/Kelurahan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVillage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadVillages,
                color: AppColors.primary,
                child: _villages.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada desa/kelurahan.\nTambah untuk mengaktifkan pendaftaran pasien.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                        itemCount: _villages.length,
                        itemBuilder: (context, index) =>
                            _buildVillageCard(_villages[index]),
                      ),
              ),
      ),
    );
  }

  Widget _buildVillageCard(Map<String, dynamic> village) {
    final count = village['_count'] as Map<String, dynamic>? ?? {};
    final rwCount = count['children'] as int? ?? 0;

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
              builder: (context) => RwListScreen(
                villageId: village['id'] as String,
                villageName: village['name'] as String,
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_city, color: AppColors.primary, size: 28),
              ),
              SizedBox(width: ResponsiveSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      village['name'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Text(
                      '$rwCount RW',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
