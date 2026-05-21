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
    if (!_formKey.currentState!.validate()) return;
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
        content: Text('Gagal: $e'),
        backgroundColor: Colors.red,
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
            hintStyle: const TextStyle(color: AppColors.surface),
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
            : DropdownButtonFormField<String>(
                initialValue: _selectedVillageId,
                decoration: InputDecoration(
                  hintText: 'Pilih desa/kelurahan',
                  hintStyle: const TextStyle(color: AppColors.surface),
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
                items: _villages.map((v) => DropdownMenuItem(
                  value: v['id'] as String,
                  child: Text(v['name'] as String),
                )).toList(),
                onChanged: (val) => setState(() => _selectedVillageId = val),
                validator: (v) => v == null ? 'Wilayah monitoring wajib dipilih' : null,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
      ],
    );
  }
}
