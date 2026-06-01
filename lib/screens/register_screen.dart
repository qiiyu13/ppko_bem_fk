import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'patient/patient_main_screen.dart';
import '../services/auth_service.dart';
import '../services/region_service.dart';
import 'package:mediku/utils/page_transitions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _kkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _kkLength = 0;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingVillages = true;

  List<Map<String, dynamic>> _villages = [];
  String? _selectedVillageId;
  int? _selectedRwNumber;
  int? _selectedRtNumber;

  static final List<int> _numbers = List.generate(20, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _loadVillages();
    _kkController.addListener(() {
      setState(() => _kkLength = _kkController.text.length);
    });
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
    _kkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final kkNumber = _kkController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (_villages.isEmpty) {
      _showErrorDialog('Pendaftaran belum tersedia. Hubungi admin.');
      return;
    }

    if (kkNumber.isEmpty || name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showErrorDialog('Semua kolom harus diisi');
      return;
    }

    if (_selectedVillageId == null) {
      _showErrorDialog('Pilih desa/kelurahan Anda terlebih dahulu');
      return;
    }

    if (kkNumber.length < 16) {
      _showErrorDialog('Nomor KK harus 16 digit');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        kkNumber: kkNumber,
        responsibleName: name,
        password: password,
        phone: phone,
        villageId: _selectedVillageId,
        rwNumber: _selectedRwNumber,
        rtNumber: _selectedRtNumber,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        ParallaxPageRoute(page: const PatientMainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Akun Keluarga',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Satu akun untuk seluruh anggota keluarga Anda.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // KK Input
              _buildInputLabel('Nomor Kartu Keluarga (KK)'),
              const SizedBox(height: 4),
              const Text(
                'Masukkan 16 digit angka sesuai Kartu Keluarga Anda',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kkController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildInputDecoration(
                  hint: 'Contoh: 3201234567890001',
                  icon: Icons.badge_outlined,
                ).copyWith(
                  counterText: '$_kkLength/16',
                  counterStyle: TextStyle(
                    fontSize: 12,
                    color: _kkLength == 16
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: _kkLength == 16
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name Input
              _buildInputLabel('Nama Penanggung Jawab'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildInputDecoration(
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 20),

              // Phone Input
              _buildInputLabel('Nomor Handphone'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildInputDecoration(
                  hint: 'Contoh: 08123456789',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 20),

              // Village Selection
              _buildInputLabel('Desa / Kelurahan'),
              const SizedBox(height: 8),
              _isLoadingVillages
                  ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ))
                  : _villages.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.statusAmber, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pendaftaran belum tersedia. Hubungi admin.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildPickerField(
                          icon: Icons.location_city_outlined,
                          hint: 'Pilih desa/kelurahan',
                          selectedLabel: _selectedVillageId != null
                              ? _villages.firstWhere(
                                  (v) => v['id'] == _selectedVillageId,
                                  orElse: () => {'name': ''},
                                )['name'] as String
                              : null,
                          onTap: () => _showSearchablePicker(
                            title: 'Pilih Desa / Kelurahan',
                            options: _villages.map((v) => v['name'] as String).toList(),
                            onSelected: (selectedName) {
                              final village = _villages.firstWhere(
                                (v) => v['name'] == selectedName,
                              );
                              setState(() {
                                _selectedVillageId = village['id'] as String;
                                _selectedRwNumber = null;
                                _selectedRtNumber = null;
                              });
                            },
                          ),
                        ),

              if (_selectedVillageId != null) ...[
                const SizedBox(height: 20),
                // RW Selection
                _buildInputLabel('RW (opsional)'),
                const SizedBox(height: 8),
                _buildPickerField(
                  icon: Icons.account_tree_outlined,
                  hint: 'Pilih RW Anda',
                  selectedLabel: _selectedRwNumber != null
                      ? 'RW ${_selectedRwNumber.toString().padLeft(2, '0')}'
                      : null,
                  onTap: () => _showSearchablePicker(
                    title: 'Pilih RW',
                    options: _numbers.map((n) => 'RW ${n.toString().padLeft(2, '0')}').toList(),
                    onSelected: (selected) {
                      final match = RegExp(r'RW (\d+)').firstMatch(selected);
                      if (match != null) {
                        setState(() {
                          _selectedRwNumber = int.parse(match.group(1)!);
                          _selectedRtNumber = null;
                        });
                      }
                    },
                  ),
                ),
              ],

              if (_selectedRwNumber != null) ...[
                const SizedBox(height: 20),
                _buildInputLabel('RT'),
                const SizedBox(height: 8),
                _buildPickerField(
                  icon: Icons.location_on_outlined,
                  hint: 'Pilih RT Anda',
                  selectedLabel: _selectedRtNumber != null
                      ? 'RT ${_selectedRtNumber.toString().padLeft(2, '0')}'
                      : null,
                  onTap: () => _showSearchablePicker(
                    title: 'Pilih RT',
                    options: _numbers.map((n) => 'RT ${n.toString().padLeft(2, '0')}').toList(),
                    onSelected: (selected) {
                      final match = RegExp(r'RT (\d+)').firstMatch(selected);
                      if (match != null) {
                        setState(() {
                          _selectedRtNumber = int.parse(match.group(1)!);
                        });
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Password/PIN Input
              _buildInputLabel('Kata Sandi / PIN'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildInputDecoration(
                  hint: 'Masukkan kata sandi',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isLoadingVillages || _villages.isEmpty) ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Text(
                          'DAFTAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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

  Widget _buildPickerField({
    required IconData icon,
    required String hint,
    required String? selectedLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                selectedLabel ?? hint,
                style: TextStyle(
                  color: selectedLabel != null ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 22,
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
