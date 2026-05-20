import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'patient/patient_main_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _kkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  int? _selectedRwNumber;
  int? _selectedRtNumber;

  static final List<int> _numbers = List.generate(100, (i) => i + 1);

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

    if (kkNumber.isEmpty || name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showErrorDialog('Semua kolom harus diisi');
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
        rwNumber: _selectedRwNumber,
        rtNumber: _selectedRtNumber,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PatientMainScreen()),
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
                  hint: 'Masukkan 16 digit KK',
                  icon: Icons.badge_outlined,
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

              // RW Selection
              _buildInputLabel('RW (opsional)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedRwNumber,
                decoration: _buildInputDecoration(
                  hint: 'Pilih RW Anda',
                  icon: Icons.location_city_outlined,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Tidak dipilih')),
                  ..._numbers.map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('RW ${n.toString().padLeft(2, '0')}'),
                      )),
                ],
                onChanged: (val) => setState(() {
                  _selectedRwNumber = val;
                  _selectedRtNumber = null;
                }),
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),

              if (_selectedRwNumber != null) ...[
                const SizedBox(height: 20),
                _buildInputLabel('RT'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedRtNumber,
                  decoration: _buildInputDecoration(
                    hint: 'Pilih RT Anda',
                    icon: Icons.location_on_outlined,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Tidak dipilih')),
                    ..._numbers.map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('RT ${n.toString().padLeft(2, '0')}'),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedRtNumber = val),
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
                  onPressed: _isLoading ? null : _handleRegister,
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
