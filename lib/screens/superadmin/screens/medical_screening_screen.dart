import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../utils/responsive_size.dart';
import '../../admin/qr_scanner_screen.dart';

class MedicalScreeningScreen extends StatefulWidget {
  final Map<String, dynamic>? initialPatient;

  const MedicalScreeningScreen({super.key, this.initialPatient});

  @override
  State<MedicalScreeningScreen> createState() => _MedicalScreeningScreenState();
}

class _MedicalScreeningScreenState extends State<MedicalScreeningScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _uricAcidController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _selectedPatient;
  bool _isLoading = false;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPatient != null) {
      _selectedPatient = widget.initialPatient;
    } else {
      _fetchPatients();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bloodSugarController.dispose();
    _uricAcidController.dispose();
    _cholesterolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      final response = await ApiService.get(
        '/admin/patients',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'] ?? [];
      setState(() {
        _patients = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _patients = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateScreeningFields() {
    final fields = <String, TextEditingController>{
      'Sistolik': _systolicController,
      'Diastolik': _diastolicController,
      'Gula Darah': _bloodSugarController,
      'Kolesterol': _cholesterolController,
      'Asam Urat': _uricAcidController,
      'Tinggi Badan': _heightController,
    };
    for (final entry in fields.entries) {
      if (entry.value.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.key} wajib diisi')),
        );
        return false;
      }
      if (int.tryParse(entry.value.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.key} harus berupa angka')),
        );
        return false;
      }
    }
    if (_weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat Badan wajib diisi')),
      );
      return false;
    }
    if (double.tryParse(_weightController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat Badan harus berupa angka')),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitScreening() async {
    if (_selectedPatient == null) return;

    final profileId = _selectedPatient!['profileId'] ?? _selectedPatient!['id'];
    if (profileId == null) return;

    if (!_validateScreeningFields()) return;

    final body = {
      'profileId': profileId,
      'systolic': int.parse(_systolicController.text.trim()),
      'diastolic': int.parse(_diastolicController.text.trim()),
      'bloodSugar': int.parse(_bloodSugarController.text.trim()),
      'cholesterol': int.parse(_cholesterolController.text.trim()),
      'uricAcid': int.parse(_uricAcidController.text.trim()),
      'height': int.parse(_heightController.text.trim()),
      'weight': double.parse(_weightController.text.trim()),
      'notes': _notesController.text,
      'screeningAt': DateTime.now().toIso8601String(),
    };

    try {
      await ApiService.post('/screenings', data: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data screening berhasil disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
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

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScanResult: (data) {
            setState(() {
              _selectedPatient = data;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchPatients(),
                  decoration: InputDecoration(
                    hintText: 'Cari pasien (NIK atau Nama)...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
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
              SizedBox(width: ResponsiveSize.paddingSmall),
              IconButton(
                onPressed: _openQrScanner,
                icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                tooltip: 'Scan QR Pasien',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
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
                  if (patient['village'] != null) ...[
                    SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                    Text(
                      'Desa: ${patient['village']}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                  controller: _systolicController,
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
                  controller: _diastolicController,
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
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Expanded(
                child: _buildTextField(
                  label: 'Tinggi Badan',
                  hint: 'cm',
                  controller: _heightController,
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
            controller: _bloodSugarController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          _buildTextField(
            label: 'Asam Urat',
            hint: 'mg/dL',
            controller: _uricAcidController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          _buildTextField(
            label: 'Kolesterol',
            hint: 'mg/dL',
            controller: _cholesterolController,
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: ResponsiveSize.spacingMedium),

          _buildFormSection('Catatan'),
          _buildTextField(
            label: 'Catatan',
            hint: 'Opsional',
            controller: _notesController,
          ),

          SizedBox(height: ResponsiveSize.spacingXLarge * 2),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitScreening,
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
    required TextEditingController controller,
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
          controller: controller,
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
