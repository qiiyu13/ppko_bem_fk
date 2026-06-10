import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../utils/responsive_size.dart';
import '../../admin/qr_scanner_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

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

  final FocusNode _systolicFocus = FocusNode();
  final FocusNode _diastolicFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _bloodSugarFocus = FocusNode();
  final FocusNode _uricAcidFocus = FocusNode();
  final FocusNode _cholesterolFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _selectedFamily;
  List<Map<String, dynamic>> _familyProfiles = [];
  bool _isLoadingFamily = false;

  Map<String, dynamic>? _selectedProfile;
  bool _isLoading = false;
  bool _isSubmitting = false;
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
    _systolicFocus.dispose();
    _diastolicFocus.dispose();
    _weightFocus.dispose();
    _heightFocus.dispose();
    _bloodSugarFocus.dispose();
    _uricAcidFocus.dispose();
    _cholesterolFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  bool get _isFormDirty {
    return [
      _systolicController,
      _diastolicController,
      _weightController,
      _heightController,
      _bloodSugarController,
      _uricAcidController,
      _cholesterolController,
      _notesController,
    ].any((c) => c.text.trim().isNotEmpty);
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang data?'),
        content: const Text(
          'Data yang sudah diisi akan hilang. Yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return result ?? false;
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

  String? _validateInt(String? v, String label) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$label wajib diisi';
    if (int.tryParse(t) == null) return 'Harus berupa angka';
    return null;
  }

  String? _validateDouble(String? v, String label) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$label wajib diisi';
    if (_parseDecimal(t) == null) return 'Harus berupa angka';
    return null;
  }

  /// Parse a decimal accepting either comma or dot as separator (id_ID locale).
  double? _parseDecimal(String? s) =>
      double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  Future<void> _submitScreening() async {
    if (_selectedProfile == null || _isSubmitting) return;

    final profileId =
        _selectedProfile!['profileId'] ?? _selectedProfile!['id'];
    if (profileId == null) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      _focusFirstInvalid();
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      'profileId': profileId,
      'systolic': int.parse(_systolicController.text.trim()),
      'diastolic': int.parse(_diastolicController.text.trim()),
      'bloodSugar': _parseDecimal(_bloodSugarController.text),
      'cholesterol': _parseDecimal(_cholesterolController.text),
      'uricAcid': _parseDecimal(_uricAcidController.text),
      'height': _parseDecimal(_heightController.text),
      'weight': _parseDecimal(_weightController.text),
      'notes': _notesController.text,
      'screeningAt': DateTime.now().toIso8601String(),
    };

    try {
      await ApiService.post('/screenings', data: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data screening berhasil disimpan!'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal menyimpan data screening. Periksa koneksi lalu coba lagi.'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    }
  }

  void _focusFirstInvalid() {
    final order = <(TextEditingController, FocusNode)>[
      (_systolicController, _systolicFocus),
      (_diastolicController, _diastolicFocus),
      (_weightController, _weightFocus),
      (_heightController, _heightFocus),
      (_bloodSugarController, _bloodSugarFocus),
      (_uricAcidController, _uricAcidFocus),
      (_cholesterolController, _cholesterolFocus),
    ];
    for (final (c, f) in order) {
      final t = c.text.trim();
      if (t.isEmpty || double.tryParse(t) == null) {
        f.requestFocus();
        return;
      }
    }
  }

  String _stepTitle() {
    if (_selectedProfile != null) return 'Medical Screening';
    if (_selectedFamily != null) return 'Pilih Anggota Keluarga';
    return 'Pilih Keluarga';
  }

  Future<void> _onBackPressed() async {
    if (_selectedProfile != null) {
      if (_isFormDirty) {
        final ok = await _confirmDiscard();
        if (!ok) return;
      }
      setState(() {
        _selectedProfile = null;
        _clearFormFields();
      });
      return;
    }
    if (_selectedFamily != null) {
      setState(() {
        _selectedFamily = null;
        _familyProfiles = [];
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _clearFormFields() {
    _systolicController.clear();
    _diastolicController.clear();
    _weightController.clear();
    _heightController.clear();
    _bloodSugarController.clear();
    _uricAcidController.clear();
    _cholesterolController.clear();
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final canPopNow = _selectedProfile == null &&
        _selectedFamily == null;

    return PopScope(
      canPop: canPopNow && !_isFormDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
      ParallaxPageRoute(
        page: QrScannerScreen(
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
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textSecondary),
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
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSize.paddingSmall),
              IconButton(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
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
                          const Icon(Icons.family_restroom,
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
                child: const Icon(Icons.family_restroom,
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
              const Icon(Icons.family_restroom, color: AppColors.primary),
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
                child: const Text(
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
                          const Icon(Icons.group_off,
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
                  style: const TextStyle(
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

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
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
                      const Icon(Icons.person, color: AppColors.primary),
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
                        onPressed: () async {
                          if (_isFormDirty) {
                            final ok = await _confirmDiscard();
                            if (!ok) return;
                          }
                          setState(() {
                            _selectedProfile = null;
                            _clearFormFields();
                          });
                        },
                        child: const Text(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildIntField(
                        label: 'Sistolik',
                        hint: '90–180',
                        suffix: 'mmHg',
                        controller: _systolicController,
                        focusNode: _systolicFocus,
                        nextFocus: _diastolicFocus,
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall),
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall),
                    Expanded(
                      child: _buildIntField(
                        label: 'Diastolik',
                        hint: '60–110',
                        suffix: 'mmHg',
                        controller: _diastolicController,
                        focusNode: _diastolicFocus,
                        nextFocus: _weightFocus,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildFormSection('Berat & Tinggi Badan'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDoubleField(
                        label: 'Berat Badan',
                        hint: 'mis. 65',
                        suffix: 'kg',
                        controller: _weightController,
                        focusNode: _weightFocus,
                        nextFocus: _heightFocus,
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.paddingSmall),
                    Expanded(
                      child: _buildDoubleField(
                        label: 'Tinggi Badan',
                        hint: 'mis. 165',
                        suffix: 'cm',
                        controller: _heightController,
                        focusNode: _heightFocus,
                        nextFocus: _bloodSugarFocus,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildFormSection('Hasil Laboratorium'),
                _buildDoubleField(
                  label: 'Gula Darah',
                  hint: 'mis. 110',
                  suffix: 'mg/dL',
                  controller: _bloodSugarController,
                  focusNode: _bloodSugarFocus,
                  nextFocus: _uricAcidFocus,
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildDoubleField(
                  label: 'Asam Urat',
                  hint: 'mis. 6',
                  suffix: 'mg/dL',
                  controller: _uricAcidController,
                  focusNode: _uricAcidFocus,
                  nextFocus: _cholesterolFocus,
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildDoubleField(
                  label: 'Kolesterol',
                  hint: 'mis. 180',
                  suffix: 'mg/dL',
                  controller: _cholesterolController,
                  focusNode: _cholesterolFocus,
                  nextFocus: _notesFocus,
                ),
                SizedBox(height: ResponsiveSize.spacingMedium),
                _buildFormSection('Catatan'),
                _buildNotesField(),
                SizedBox(height: ResponsiveSize.spacingMedium),
              ],
            ),
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingSmall,
        ResponsiveSize.paddingMedium,
        ResponsiveSize.paddingSmall,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitScreening,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.background,
                      ),
                    ),
                  )
                : Text(
                    'Simpan Data',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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

  Widget _buildIntField({
    required String label,
    required String hint,
    required String suffix,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
  }) {
    return _buildField(
      label: label,
      hint: hint,
      suffix: suffix,
      controller: controller,
      focusNode: focusNode,
      nextFocus: nextFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => _validateInt(v, label),
    );
  }

  Widget _buildDoubleField({
    required String label,
    required String hint,
    required String suffix,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
  }) {
    return _buildField(
      label: label,
      hint: hint,
      suffix: suffix,
      controller: controller,
      focusNode: focusNode,
      nextFocus: nextFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
      ],
      validator: (v) => _validateDouble(v, label),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan',
          style: TextStyle(
            fontSize: ResponsiveSize.fontMedium,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
        TextFormField(
          controller: _notesController,
          focusNode: _notesFocus,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Opsional',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
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
              vertical: ResponsiveSize.paddingSmall * 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required String suffix,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required String? Function(String?) validator,
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
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              focusNode.unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppColors.textSecondary),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.statusRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.statusRed, width: 1.5),
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
