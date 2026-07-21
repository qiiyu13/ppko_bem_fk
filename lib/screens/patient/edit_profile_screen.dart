import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/family_profile.dart';
import '../../services/profile_service.dart';
import '../../utils/avatar_picker.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/health_variables_section.dart';
import '../../widgets/profile_form_field.dart';

class EditProfileScreen extends StatefulWidget {
  final FamilyProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nikController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  late String _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;
  String? _birthDateError;
  File? _avatarFile;
  bool _isLoading = false;
  bool _healthDirty = false;
  late final HealthVariableValues _healthValues;

  static const List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  Future<void> _pickImage() async {
    final cropped = await AvatarPicker.pickAndCrop();
    if (cropped != null) {
      setState(() => _avatarFile = cropped);
    }
  }

  @override
  void initState() {
    super.initState();
    _nikController = TextEditingController(text: widget.profile.nik ?? '');
    _nameController = TextEditingController(text: widget.profile.name);
    _addressController = TextEditingController(
      text: widget.profile.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    final g = widget.profile.gender.toLowerCase();
    _selectedGender = g == 'wanita' ? 'Wanita' : 'Pria';
    _selectedBloodType = widget.profile.bloodType;
    _selectedBirthDate = widget.profile.birthDate;
    _healthValues = HealthVariableValues(profile: widget.profile);
  }

  bool get _isDirty =>
      _nameController.text != widget.profile.name ||
      _addressController.text != (widget.profile.address ?? '') ||
      _phoneController.text != (widget.profile.phone ?? '') ||
      _selectedGender !=
          (widget.profile.gender.toLowerCase() == 'wanita'
              ? 'Wanita'
              : 'Pria') ||
      _selectedBloodType != widget.profile.bloodType ||
      _selectedBirthDate != widget.profile.birthDate ||
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
          'Perubahan profil belum disimpan dan akan hilang jika keluar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Mengedit'),
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
          title: const Text('Edit Profil'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Pribadi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ubah data profil ${widget.profile.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
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
                            imageUrl: widget.profile.avatarUrl,
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

                // NIK (read-only)
                ProfileFormField(
                  controller: _nikController,
                  label: 'NIK *',
                  hint: 'Masukkan 16 digit NIK',
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIK wajib diisi';
                    }
                    if (value.length != 16) return 'NIK harus 16 digit';
                    return null;
                  },
                ),

                // Name
                ProfileFormField(
                  controller: _nameController,
                  label: 'Nama Lengkap *',
                  hint: 'Masukkan nama lengkap',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),

                // Gender
                const ProfileFieldLabel('Jenis Kelamin'),
                Row(
                  children: [
                    Expanded(child: _buildGenderOption('Pria', Icons.male)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGenderOption('Wanita', Icons.female)),
                  ],
                ),
                const SizedBox(height: 20),

                // Birth Date
                const ProfileFieldLabel('Tanggal Lahir *'),
                InkWell(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _birthDateError != null
                            ? AppColors.statusRed
                            : AppColors.surface,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedBirthDate != null
                              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                              : 'Pilih tanggal lahir',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedBirthDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_birthDateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _birthDateError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.statusRed,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Blood Type
                const ProfileFieldLabel('Golongan Darah (Opsional)'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bloodTypes.map((type) {
                    final isSelected = _selectedBloodType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedBloodType = selected ? type : null;
                        });
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
                const SizedBox(height: 20),

                // Address
                ProfileFormField(
                  controller: _addressController,
                  label: 'Alamat (Opsional)',
                  hint: 'Masukkan alamat lengkap',
                  maxLines: 3,
                ),

                // Phone
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

                // Submit Button
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
                            'Simpan Perubahan',
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
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () => setState(() => _selectedGender = gender),
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

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
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
      final updatedProfile = widget.profile.copyWith(
        name: _nameController.text,
        gender: _selectedGender.toLowerCase(),
        birthDate: _selectedBirthDate!,
        bloodType: _selectedBloodType,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        education: _healthValues.education,
        occupation: _healthValues.occupation,
        maritalStatus: _healthValues.maritalStatus,
        income: _healthValues.income,
        familyDiseaseHistory: _healthValues.familyDiseaseHistory,
        smokingStatus: _healthValues.smokingStatus,
        physicalActivity: _healthValues.physicalActivity,
        fruitConsumption: _healthValues.fruitConsumption,
        vegetableConsumption: _healthValues.vegetableConsumption,
        sweetFoodConsumption: _healthValues.sweetFoodConsumption,
        sweetDrinkConsumption: _healthValues.sweetDrinkConsumption,
        fattyFoodConsumption: _healthValues.fattyFoodConsumption,
        fastFoodConsumption: _healthValues.fastFoodConsumption,
        sleepDuration: _healthValues.sleepDuration,
        medicationRoutine: _healthValues.medicationRoutine,
      );

      await ProfileService.instance.updateProfile(
        updatedProfile,
        avatar: _avatarFile,
      );

      if (mounted) {
        showAppSnackBar(context, 'Profil berhasil diperbarui', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Gagal menyimpan perubahan. Periksa koneksi Anda.',
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
