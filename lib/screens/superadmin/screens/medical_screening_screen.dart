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

  Map<String, dynamic>? _selectedFamily;
  List<Map<String, dynamic>> _familyProfiles = [];
  bool _isLoadingFamily = false;

  Map<String, dynamic>? _selectedProfile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _families = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPatient != null) {
      _selectedProfile = widget.initialPatient;
    } else {
      _fetchFamilies();
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

  Future<void> _fetchFamilies() async {
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
        _families = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _families = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectFamily(Map<String, dynamic> family) async {
    setState(() {
      _selectedFamily = family;
      _isLoadingFamily = true;
      _familyProfiles = [];
    });
    try {
      final response =
          await ApiService.get('/admin/patients/${family['id']}');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final profiles =
          (data['familyProfiles'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _familyProfiles = profiles;
        _selectedFamily = {
          ...family,
          'responsibleName': data['responsibleName'] ?? family['name'],
          'kkNumber': data['kkNumber'] ?? family['nik'],
        };
        _isLoadingFamily = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFamily = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat anggota keluarga')),
      );
    }
  }

  String _maskKk(String kk) {
    if (kk.length <= 4) return kk;
    return '${'•' * (kk.length - 4)}${kk.substring(kk.length - 4)}';
  }

  int? _ageFromBirthDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      final now = DateTime.now();
      var age = now.year - dt.year;
      if (now.month < dt.month ||
          (now.month == dt.month && now.day < dt.day)) {
        age--;
      }
      return age >= 0 ? age : null;
    } catch (_) {
      return null;
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
    if (_selectedProfile == null) return;

    final profileId =
        _selectedProfile!['profileId'] ?? _selectedProfile!['id'];
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

  String _stepTitle() {
    if (_selectedProfile != null) return 'Medical Screening';
    if (_selectedFamily != null) return 'Pilih Anggota Keluarga';
    return 'Pilih Keluarga';
  }

  void _onBackPressed() {
    if (_selectedProfile != null) {
      setState(() => _selectedProfile = null);
      return;
    }
    if (_selectedFamily != null) {
      setState(() {
        _selectedFamily = null;
        _familyProfiles = [];
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return PopScope(
      canPop: _selectedProfile == null && _selectedFamily == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _onBackPressed,
          ),
          title: Text(
            _stepTitle(),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: ResponsiveSize.fontXLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedProfile != null) return _buildMedicalForm();
    if (_selectedFamily != null) return _buildProfileSelection();
    return _buildFamilySelection();
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScanResult: (data) {
            setState(() {
              _selectedProfile = data;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFamilySelection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchFamilies(),
                  decoration: InputDecoration(
                    hintText: 'Cari No. KK atau Nama Kepala Keluarga',
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
              : _families.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.family_restroom,
                              size: 48, color: AppColors.textSecondary),
                          SizedBox(height: ResponsiveSize.spacingMedium),
                          Text(
                            'Tidak ada keluarga ditemukan',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveSize.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                      itemCount: _families.length,
                      itemBuilder: (context, index) {
                        return _buildFamilyCard(_families[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> family) {
    final name = (family['name'] ?? family['responsibleName'] ?? '-').toString();
    final kk = (family['nik'] ?? family['kkNumber'] ?? '').toString();
    final count = family['_count'] as Map<String, dynamic>? ?? {};
    final memberCount = count['familyProfiles'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectFamily(family),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.family_restroom,
                    color: AppColors.primary, size: 28),
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
                      'KK: ${_maskKk(kk)}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (memberCount > 0) ...[
                      SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                      Text(
                        '$memberCount anggota',
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
      ),
    );
  }

  Widget _buildProfileSelection() {
    final family = _selectedFamily!;
    final familyName =
        (family['responsibleName'] ?? family['name'] ?? '-').toString();
    final kk = (family['kkNumber'] ?? family['nik'] ?? '').toString();

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(ResponsiveSize.paddingMedium),
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
              Icon(Icons.family_restroom, color: AppColors.primary),
              SizedBox(width: ResponsiveSize.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      familyName,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'KK: ${_maskKk(kk)}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFamily = null;
                    _familyProfiles = [];
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
        Expanded(
          child: _isLoadingFamily
              ? const Center(child: CircularProgressIndicator())
              : _familyProfiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off,
                              size: 48, color: AppColors.textSecondary),
                          SizedBox(height: ResponsiveSize.spacingMedium),
                          Text(
                            'Belum ada anggota terdaftar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveSize.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSize.paddingMedium,
                      ),
                      itemCount: _familyProfiles.length,
                      itemBuilder: (context, index) {
                        return _buildProfileCard(_familyProfiles[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    final name = (profile['name'] as String?) ?? '-';
    final nik = (profile['nik'] as String?) ?? '';
    final nikTail = nik.length > 3 ? nik.substring(nik.length - 3) : nik;
    final gender = (profile['gender'] as String?) ?? '';
    final age = _ageFromBirthDate(profile['birthDate']);
    final initial = name.isNotEmpty && name != '-'
        ? name[0].toUpperCase()
        : '?';
    final subtitle = [
      if (nikTail.isNotEmpty) 'NIK …$nikTail',
      if (gender.isNotEmpty) gender,
      if (age != null) '$age th',
    ].join(' · ');

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedProfile = profile;
          });
        },
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: ResponsiveSize.spacingSmall * 0.4),
                      Text(
                        subtitle,
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
      ),
    );
  }

  Widget _buildMedicalForm() {
    final profile = _selectedProfile!;
    final profileName = (profile['name'] as String?) ?? '-';
    final profileNik = (profile['nik'] as String?) ?? '';
    final age = _ageFromBirthDate(profile['birthDate']);
    final gender = (profile['gender'] as String?) ?? '';
    final meta = [
      if (gender.isNotEmpty) gender,
      if (age != null) '$age th',
    ].join(' · ');

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingMedium + bottomInset,
      ),
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
                        profileName,
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (profileNik.isNotEmpty)
                        Text(
                          'NIK: $profileNik',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProfile = null;
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
