import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/otp_service.dart';
import '../services/platform_util.dart';
import '../widgets/app_snackbar.dart';

enum ForgotPasswordStep { phone, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _step = ForgotPasswordStep.phone;
  final _kkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _kkController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _sendOTP() async {
    if (!PlatformUtil.firebaseAvailable) {
      setState(() => _error = 'Fitur OTP tidak tersedia di platform ini');
      return;
    }

    final kk = _kkController.text.trim();
    final phone = _phoneController.text.trim();
    if (kk.length != 16) {
      setState(() => _error = 'Nomor KK harus 16 digit');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Nomor telepon wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.forgotPassword(kkNumber: kk, phone: phone);
    } catch (_) {
      // Proceed with OTP even if API call fails (Firebase handles delivery)
    }

    await OtpService.sendOTP(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _step = ForgotPasswordStep.otp;
          _isLoading = false;
          _error = null;
        });
        _startResendCooldown();
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      },
      onAutoVerify: () {
        setState(() {
          _isLoading = false;
        });
        _verifyAndProceed();
      },
    );
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCooldown--;
      });
      return _resendCooldown > 0;
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  void _verifyOTP() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await OtpService.verifyOTP(code);
      if (token != null) {
        _verifyAndProceed(token: token);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memverifikasi kode OTP';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Kode OTP tidak valid';
      });
    }
  }

  void _verifyAndProceed({String? token}) async {
    if (token == null) {
      if (_verificationId == null) {
        setState(() => _error = 'Verifikasi gagal. Silakan coba lagi.');
        return;
      }
      final finalToken = await OtpService.verifyOTP(
        _otpControllers.map((c) => c.text).join(),
      );
      if (finalToken == null) {
        setState(() => _error = 'Verifikasi gagal. Silakan coba lagi.');
        return;
      }
      token = finalToken;
    }

    setState(() => _step = ForgotPasswordStep.newPassword);
    _isLoading = false;
  }

  void _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final firebaseToken = await _getFirebaseToken();
    if (firebaseToken == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token verifikasi tidak ditemukan. Mulai ulang proses.';
      });
      return;
    }

    final success = await AuthService.resetPassword(
      kkNumber: _kkController.text.trim(),
      firebaseToken: firebaseToken,
      newPassword: password,
    );

    if (success && mounted) {
      showAppSnackBar(context, 'Password berhasil direset', success: true);
      Navigator.pop(context);
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal mereset password. Coba lagi.';
      });
    }
  }

  Future<String?> _getFirebaseToken() async {
    final user = await OtpService.verifyOTP(
      _otpControllers.map((c) => c.text).join(),
    );
    return user;
  }

  @override
  Widget build(BuildContext context) {
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
          _step == ForgotPasswordStep.phone
              ? 'Lupa Password'
              : _step == ForgotPasswordStep.otp
              ? 'Verifikasi OTP'
              : 'Password Baru',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step == ForgotPasswordStep.phone) _buildPhoneStep(),
              if (_step == ForgotPasswordStep.otp) _buildOTPStep(),
              if (_step == ForgotPasswordStep.newPassword)
                _buildNewPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan nomor KK dan nomor telepon\nyang terdaftar',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _kkController,
          keyboardType: TextInputType.number,
          maxLength: 16,
          decoration: _inputDecoration(
            'Nomor KK',
            'Masukkan 16 digit nomor KK',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('Nomor Telepon', 'Contoh: 08123456789'),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorWidget(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: _buttonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Kirim OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masukkan kode OTP yang dikirim ke\n${_phoneController.text}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 48,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                onChanged: (value) => _onOtpChanged(index, value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorWidget(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: _buttonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resendCooldown > 0 ? null : _sendOTP,
            child: Text(
              _resendCooldown > 0
                  ? 'Kirim ulang dalam $_resendCooldown detik'
                  : 'Kirim ulang OTP',
              style: TextStyle(
                color: _resendCooldown > 0
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buat password baru untuk akun Anda',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputDecoration('Password Baru', 'Minimal 6 karakter'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: _inputDecoration(
            'Konfirmasi Password',
            'Ulangi password baru',
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorWidget(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: _buttonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.statusRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
