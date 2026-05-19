import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';
import '../screens/rw_list_screen.dart';
import '../screens/user_form_screen.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;
  Map<String, dynamic>? _regionStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _loadStats();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await AdminService.getUsers(role: 'ADMIN');
      setState(() {
        _admins = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await RegionService.getStats();
      setState(() {
        _regionStats = stats;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Manajemen Pengguna',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Tim Medis'),
            Tab(text: 'Wilayah'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTimMedisTab(), _buildWilayahTab()],
      ),
    );
  }

  Widget _buildTimMedisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
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
                    builder: (context) => const UserFormScreen(),
                  ),
                ).then((_) => _loadUsers());
              },
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: const Text(
                'Tambah Admin',
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
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: AppColors.primary,
            child: _admins.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Belum ada admin',
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
                    itemCount: _admins.length,
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      return _buildAdminCard(admin);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    final isActive = admin['isActive'] == true;
    final name = admin['responsibleName'] ?? admin['name'] ?? 'Unknown';
    final role = admin['role'] ?? 'ADMIN';
    final id = admin['id'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
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
                      role,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.paddingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.statusGreen.withValues(alpha: 0.1)
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.statusGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveSize.paddingSmall),
                        Text(
                          'ID: ${id.length > 8 ? id.substring(0, 8) : id}...',
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
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFormScreen(admin: admin),
                        ),
                      ).then((_) => _loadUsers());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.textSecondary),
                    onPressed: () => _deleteAdmin(admin),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final name = admin['responsibleName'] ?? admin['name'] ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Admin'),
        content: Text('Apakah Anda yakin ingin menghapus $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteUser(
          admin['id'] as String,
          DateTime.parse(admin['updatedAt'] as String),
        );
        _showSnackBar('Admin berhasil dihapus');
        _loadUsers();
      } catch (e) {
        _showSnackBar('Gagal menghapus admin');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildWilayahTab() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RwListScreen()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingMedium,
              vertical: ResponsiveSize.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                    size: ResponsiveSize.iconMedium,
                  ),
                ),
                SizedBox(width: ResponsiveSize.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kelola RW/RT',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _regionStats == null
                            ? 'Memuat...'
                            : '${_regionStats!['rwCount']} RW • ${_regionStats!['rtCount']} RT • ${_regionStats!['profileCount']} Penduduk',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
