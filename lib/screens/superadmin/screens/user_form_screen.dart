import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/region_service.dart';
import '../../../utils/responsive_size.dart';

class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? admin;

  const UserFormScreen({super.key, this.admin});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isActive = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _triedSubmit = false;
  String? _selectedVillageId;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoadingVillages = true;

  @override
  void initState() {
    super.initState();
    _loadVillages();
    final a = widget.admin;
    if (a != null) {
      _nameController.text = (a['responsibleName'] ?? a['name'] ?? '') as String;
      _usernameController.text = (a['username'] ?? '') as String? ?? '';
      _positionController.text = (a['position'] ?? '') as String? ?? '';
      _phoneController.text = (a['phone'] ?? '') as String? ?? '';
      _isActive = a['isActive'] == true;
      _selectedVillageId = a['regionId'] as String?;
    }
  }

  Future<void> _loadVillages() async {
    try {
      final villages = await RegionService.getVillages();
      setState(() {
        _villages = villages;
        _isLoadingVillages = false;
      });
    } catch (e) {
      setState(() => _isLoadingVillages = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _triedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wilayah monitoring wajib dipilih'),
        backgroundColor: AppColors.statusRed,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    final isEdit = widget.admin != null;
    try {
      if (isEdit) {
        await AdminService.updateUser(
          widget.admin!['id'] as String,
          username: _usernameController.text.trim(),
          responsibleName: _nameController.text.trim(),
          position: _positionController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          isActive: _isActive,
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
          regionId: _selectedVillageId,
          updatedAt: DateTime.parse(widget.admin!['updatedAt'] as String),
        );
      } else {
        await AdminService.createUser(
          username: _usernameController.text.trim(),
          responsibleName: _nameController.text.trim(),
          password: _passwordController.text,
          position: _positionController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          isActive: _isActive,
          role: 'ADMIN',
          regionId: _selectedVillageId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? 'Admin diperbarui' : 'Admin ditambahkan'),
        backgroundColor: AppColors.statusGreen,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit
            ? 'Gagal menyimpan perubahan. Periksa koneksi lalu coba lagi.'
            : 'Gagal menambah admin. Pastikan username belum dipakai, lalu coba lagi.'),
        backgroundColor: AppColors.statusRed,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final isEdit = widget.admin != null;

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
          isEdit ? 'Edit Admin' : 'Tambah Admin',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  label: 'Nama',
                  hint: 'Nama lengkap',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: 'Username',
                  hint: 'Username untuk login',
                  controller: _usernameController,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Username wajib diisi';
                    if (t.length < 3) return 'Minimal 3 karakter';
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: 'Jabatan',
                  hint: 'Contoh: Dokter Umum',
                  controller: _positionController,
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: 'Nomor Telepon',
                  hint: 'Contoh: 081234567890',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: isEdit ? 'Password (kosongkan jika tidak diubah)' : 'Password',
                  hint: 'Minimal 6 karakter',
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (isEdit && (v == null || v.isEmpty)) return null;
                    if (v == null || v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _villageDropdown(),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _statusToggle(),
                SizedBox(height: ResponsiveSize.spacingXLarge * 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.paddingMedium),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Admin',
                            style: TextStyle(fontSize: ResponsiveSize.fontLarge, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        SizedBox(height: ResponsiveSize.spacingSmall),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingMedium,
              vertical: ResponsiveSize.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status',
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        SizedBox(height: ResponsiveSize.spacingSmall),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.paddingMedium,
            vertical: ResponsiveSize.paddingSmall,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(_isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      color: _isActive ? AppColors.statusGreen : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _villageDropdown() {
    final selectedVillage = _selectedVillageId != null
        ? _villages.firstWhere(
            (v) => v['id'] == _selectedVillageId,
            orElse: () => {'name': ''},
          )['name'] as String
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wilayah Monitoring (Desa / Kelurahan)',
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        SizedBox(height: ResponsiveSize.spacingSmall),
        _isLoadingVillages
            ? const SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
              )
            : InkWell(
                onTap: () => _showSearchablePicker(
                  title: 'Pilih Desa / Kelurahan',
                  options: _villages.map((v) => v['name'] as String).toList(),
                  onSelected: (selectedName) {
                    final village = _villages.firstWhere(
                      (v) => v['name'] == selectedName,
                    );
                    setState(() {
                      _selectedVillageId = village['id'] as String;
                    });
                  },
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.paddingMedium,
                    vertical: ResponsiveSize.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _triedSubmit && _selectedVillageId == null
                          ? AppColors.statusRed.withValues(alpha: 0.5)
                          : AppColors.surface,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedVillage ?? 'Pilih desa/kelurahan',
                          style: TextStyle(
                            color: selectedVillage != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
        if (_triedSubmit && _selectedVillageId == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'Wilayah monitoring wajib dipilih',
              style: TextStyle(
                color: AppColors.statusRed,
                fontSize: ResponsiveSize.fontSmall,
              ),
            ),
          ),
      ],
    );
  }

  void _showSearchablePicker({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final searchController = TextEditingController();
    final filteredOptions = List<String>.from(options);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setModalState(() {
                        filteredOptions.clear();
                        filteredOptions.addAll(
                          options.where((opt) =>
                              opt.toLowerCase().contains(query.toLowerCase())),
                        );
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: filteredOptions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Tidak ada hasil',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredOptions.length,
                          itemBuilder: (ctx, i) {
                            return InkWell(
                              onTap: () {
                                onSelected(filteredOptions[i]);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Text(
                                  filteredOptions[i],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
              ],
            );
          },
        );
      },
    ).then((_) => searchController.dispose());
  }
}
