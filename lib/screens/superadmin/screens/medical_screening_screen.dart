import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class MedicalScreeningScreen extends StatefulWidget {
  const MedicalScreeningScreen({super.key});

  @override
  State<MedicalScreeningScreen> createState() => _MedicalScreeningScreenState();
}

class _MedicalScreeningScreenState extends State<MedicalScreeningScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedPatient;

  final List<Map<String, dynamic>> _patients = [
    {
      'name': 'Budi Santoso',
      'nik': '320123199812220001',
      'village': 'Sukamaju',
      'lastScreening': '2023-10-15',
    },
    {
      'name': 'Sari Wulandari',
      'nik': '320123199908880004',
      'village': 'Cibadak',
      'lastScreening': '2023-10-10',
    },
    {
      'name': 'Ahmad Dahlan',
      'nik': '320123199217770002',
      'village': 'Sukamaju',
      'lastScreening': '2023-09-28',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
          'Medical Screening',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedPatient == null
            ? _buildPatientSelection()
            : _buildMedicalForm(),
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pasien (NIK atau Nama)...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
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
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return _buildPatientCard(patient);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPatient = patient;
          });
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: AppColors.primary, size: 28),
            ),
            SizedBox(width: ResponsiveSize.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'],
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Text(
                    'NIK: ${patient['nik']}',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                  Text(
                    'Desa: ${patient['village']}',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: ResponsiveSize.iconSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                SizedBox(width: ResponsiveSize.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!['name'],
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'NIK: ${_selectedPatient!['nik']}',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPatient = null;
                    });
                  },
                  child: Text(
                    'Ganti',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

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
                    content: Text('Data screening berhasil disimpan!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
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
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.fontMedium,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.surface),
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
              vertical: ResponsiveSize.paddingSmall * 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
