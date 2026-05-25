import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../utils/avatar_picker.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/app_avatar.dart';

class AdminProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminProfileEditScreen({super.key, required this.user});

  @override
  State<AdminProfileEditScreen> createState() => _AdminProfileEditScreenState();
}

class _AdminProfileEditScreenState extends State<AdminProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  File? _avatarFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final cropped = await AvatarPicker.pickAndCrop();
    if (cropped != null) {
      setState(() => _avatarFile = cropped);
    }
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController.text = (u['responsibleName'] ?? '') as String;
    _positionController.text = (u['position'] ?? '') as String? ?? '';
    _phoneController.text = (u['phone'] ?? '') as String? ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await AdminService.updateUser(
        widget.user['id'] as String,
        responsibleName: _nameController.text.trim(),
        position: _positionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        updatedAt: widget.user['updatedAt'] != null
            ? DateTime.parse(widget.user['updatedAt'] as String)
            : DateTime.now(),
      );
      if (_avatarFile != null) {
        await AuthService.updatePicture(_avatarFile!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil diperbarui'),
        backgroundColor: AppColors.statusGreen,
      ));
      AuthService.getMe(force: true);
      Navigator.pop(context, true);
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
          'Edit Profil',
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
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: _avatarFile != null
                        ? ClipOval(
                            child: Image.file(
                              _avatarFile!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          )
                        : AppAvatar(
                            imageUrl: AuthService.userAvatarUrl(widget.user),
                            size: 90,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            borderColor: AppColors.primary,
                            borderWidth: 2,
                            fallback: const Icon(Icons.local_hospital, size: 40, color: AppColors.primary),
                          ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, size: 18, color: AppColors.primary),
                    label: Text(
                      _avatarFile != null ? 'Ganti Foto' : 'Tambah Foto',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: 'Nama',
                  hint: 'Nama lengkap',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                SizedBox(height: ResponsiveSize.spacingLarge),
                _field(
                  label: 'Jabatan',
                  hint: 'Contoh: Bidan Desa',
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
                  label: 'Password (isi hanya jika ingin mengganti)',
                  hint: 'Minimal 6 karakter',
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
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
                            'Simpan Perubahan',
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
}
