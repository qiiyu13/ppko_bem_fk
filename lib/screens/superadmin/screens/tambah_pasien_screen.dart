import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class TambahPasienScreen extends StatefulWidget {
  const TambahPasienScreen({super.key});

  @override
  State<TambahPasienScreen> createState() => _TambahPasienScreenState();
}

class _TambahPasienScreenState extends State<TambahPasienScreen> {
  static const Color blueAccent = Color(0xFF2196F3);
  static const Color pinkAccent = Color(0xFFE91E63);

  int _currentStep = 1;
  String _selectedGender = '';
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Pasien',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: ResponsiveSize.fontMedium,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _currentStep == 1
            ? _buildStep1Identity()
            : _currentStep == 2
            ? _buildSuccessNotification()
            : _buildStep3Medical(),
      ),
    );
  }

  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),

          SizedBox(height: ResponsiveSize.spacingXLarge),

          Text(
            'Identitas Dasar',
            style: TextStyle(
              fontSize: ResponsiveSize.fontXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingXLarge),

          _buildTextField(
            label: 'Nomor Induk Kependudukan (NIK)',
            hint: 'Masukkan 16 digit NIK',
            controller: _nikController,
            keyboardType: TextInputType.number,
            suffixIcon: IconButton(
              icon: Icon(Icons.camera_alt, color: AppColors.primary),
              onPressed: () {
                // TODO: OCR scan NIK
              },
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingSmall),
          Text(
            'Pastikan NIK sesuai dengan KTP pasien.',
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingLarge),

          _buildTextField(
            label: 'Nama Lengkap',
            hint: 'Nama sesuai KTP',
            controller: _nameController,
            suffixIcon: IconButton(
              icon: Icon(Icons.mic, color: blueAccent),
              onPressed: () {
                // TODO: Voice input
              },
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingLarge),

          _buildTextField(
            label: 'Tanggal Lahir',
            hint: 'Pilih Tanggal',
            readOnly: true,
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            onTap: () {
              // TODO: Show date picker
            },
          ),

          SizedBox(height: ResponsiveSize.spacingLarge),

          Text(
            'Jenis Kelamin',
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),

          Row(
            children: [
              Expanded(
                child: _buildGenderCard('Laki-laki', Icons.male, blueAccent),
              ),
              SizedBox(width: ResponsiveSize.paddingMedium),
              Expanded(
                child: _buildGenderCard('Perempuan', Icons.female, pinkAccent),
              ),
            ],
          ),

          SizedBox(height: ResponsiveSize.spacingXLarge * 2),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueAccent,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveSize.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LANJUT',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessNotification() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.statusGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.statusGreen,
                size: 60,
              ),
            ),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            Text(
              'Pasien Berhasil Terdaftar!',
              style: TextStyle(
                fontSize: ResponsiveSize.fontXXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveSize.spacingMedium),
            Text(
              'Lanjutkan untuk menambahkan data medical screening',
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveSize.spacingXLarge * 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 3;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveSize.paddingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lanjut ke Medical Screening',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveSize.spacingMedium),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Selesai (Lewati Medical)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveSize.fontMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Medical() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),

          SizedBox(height: ResponsiveSize.spacingXLarge),

          Text(
            'Data Medical Screening',
            style: TextStyle(
              fontSize: ResponsiveSize.fontXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),
          Text(
            'Pasien: ${_nameController.text}',
            style: TextStyle(
              fontSize: ResponsiveSize.fontMedium,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingXLarge),

          _buildFormSection('Tekanan Darah'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Sistolik',
                  hint: 'mmHg',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Text(
                '/',
                style: TextStyle(fontSize: 24, color: AppColors.textSecondary),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Expanded(
                child: _buildTextField(
                  label: 'Diastolik',
                  hint: 'mmHg',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),

          _buildFormSection('Berat & Tinggi Badan'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Berat Badan',
                  hint: 'kg',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Expanded(
                child: _buildTextField(
                  label: 'Tinggi Badan',
                  hint: 'cm',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),

          _buildFormSection('Hasil Laboratorium'),
          _buildTextField(
            label: 'Gula Darah',
            hint: 'mg/dL',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          _buildTextField(
            label: 'Asam Urat',
            hint: 'mg/dL',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          _buildTextField(
            label: 'Kolesterol',
            hint: 'mg/dL',
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: ResponsiveSize.spacingXLarge * 2),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pasien dan data screening berhasil disimpan!',
                    ),
                    backgroundColor: AppColors.statusGreen,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveSize.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Simpan Data',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 1 ? blueAccent : AppColors.surface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 2
                  ? AppColors.statusGreen
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 3 ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard(String gender, IconData icon, Color color) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.surface,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: ResponsiveSize.iconLarge),
            SizedBox(height: ResponsiveSize.spacingSmall),
            Text(
              gender,
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveSize.spacingSmall),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveSize.fontMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.fontMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.surface),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
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
