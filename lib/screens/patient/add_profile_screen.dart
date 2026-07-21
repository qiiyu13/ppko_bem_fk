import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/profile_service.dart';
import '../../utils/avatar_picker.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/health_variables_section.dart';
import '../../widgets/profile_form_field.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedGender = 'Pria';
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;
  String? _birthDateError;
  File? _avatarFile;
  bool _isLoading = false;
  bool _healthDirty = false;
  final _healthValues = HealthVariableValues();

  Future<void> _pickImage() async {
    final cropped = await AvatarPicker.pickAndCrop();
    if (cropped != null) {
      setState(() => _avatarFile = cropped);
    }
  }

  bool get _isDirty =>
      _nikController.text.isNotEmpty ||
      _nameController.text.isNotEmpty ||
      _addressController.text.isNotEmpty ||
      _phoneController.text.isNotEmpty ||
      _selectedBirthDate != null ||
      _selectedBloodType != null ||
      _avatarFile != null ||
      _healthDirty;

  Future<void> _confirmDiscard() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text(
          'Data profil belum disimpan dan akan hilang jika keluar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Mengisi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Buang',
              style: TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _healthValues.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _confirmDiscard,
          ),
          title: const Text('Tambah Anggota'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const ClampingScrollPhysics(),
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Masukkan data anggota keluarga',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                          imageUrl: null,
                          fallback: Icon(
                            _selectedGender == 'Wanita'
                                ? Icons.female
                                : Icons.male,
                            size: 40,
                            color: AppColors.textOnPrimary,
                          ),
                          size: 90,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderColor: AppColors.primary,
                          borderWidth: 2,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _avatarFile != null ? 'Ganti Foto' : 'Tambah Foto',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ProfileFormField(
                controller: _nikController,
                label: 'NIK *',
                hint: 'Masukkan 16 digit NIK',
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'NIK wajib diisi';
                  if (value.length != 16) return 'NIK harus 16 digit';
                  return null;
                },
              ),

              ProfileFormField(
                controller: _nameController,
                label: 'Nama Lengkap *',
                hint: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nama wajib diisi';
                  return null;
                },
              ),

              _GenderSelector(
                selectedGender: _selectedGender,
                onGenderSelected: (gender) {
                  setState(() => _selectedGender = gender);
                },
              ),
              const SizedBox(height: 20),

              _BirthDateField(
                selectedDate: _selectedBirthDate,
                onTap: _selectBirthDate,
                errorText: _birthDateError,
              ),
              const SizedBox(height: 20),

              _BloodTypeSelector(
                selectedBloodType: _selectedBloodType,
                onBloodTypeSelected: (type) {
                  setState(() => _selectedBloodType = type);
                },
              ),
              const SizedBox(height: 20),

              ProfileFormField(
                controller: _addressController,
                label: 'Alamat (Opsional)',
                hint: 'Masukkan alamat lengkap',
                maxLines: 3,
              ),

              ProfileFormField(
                controller: _phoneController,
                label: 'Nomor Telepon (Opsional)',
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),

              HealthVariablesSection(
                values: _healthValues,
                onChanged: () => setState(() => _healthDirty = true),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateError = null;
      });
    }
  }

  Future<void> _submitForm() async {
    final valid = _formKey.currentState!.validate();
    if (_selectedBirthDate == null) {
      setState(() => _birthDateError = 'Tanggal lahir wajib diisi');
      return;
    }
    if (!valid) return;

    setState(() => _isLoading = true);

    try {
      await ProfileService.instance.createProfile(
        nik: _nikController.text,
        name: _nameController.text,
        gender: _selectedGender.toLowerCase(),
        birthDate: _selectedBirthDate!,
        bloodType: _selectedBloodType,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        avatar: _avatarFile,
        healthVariables: _healthValues.toApiMap(),
      );

      if (mounted) {
        showAppSnackBar(context, 'Profil berhasil ditambahkan', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Gagal menyimpan profil. Periksa koneksi Anda.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _GenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderSelected;

  const _GenderSelector({
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Jenis Kelamin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                gender: 'Pria',
                icon: Icons.male,
                isSelected: selectedGender == 'Pria',
                onTap: () => onGenderSelected('Pria'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                gender: 'Wanita',
                icon: Icons.female,
                isSelected: selectedGender == 'Wanita',
                onTap: () => onGenderSelected('Wanita'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String gender;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.gender,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthDateField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final String? errorText;

  const _BirthDateField({
    required this.selectedDate,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Tanggal Lahir *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? AppColors.statusRed
                    : AppColors.surface,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Pilih tanggal lahir',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: AppColors.statusRed),
            ),
          ),
      ],
    );
  }
}

class _BloodTypeSelector extends StatelessWidget {
  final String? selectedBloodType;
  final ValueChanged<String?> onBloodTypeSelected;

  const _BloodTypeSelector({
    required this.selectedBloodType,
    required this.onBloodTypeSelected,
  });

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Golongan Darah (Opsional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bloodTypes.map((type) {
            final isSelected = selectedBloodType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                onBloodTypeSelected(selected ? type : null);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
