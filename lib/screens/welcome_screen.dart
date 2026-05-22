import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../screens/patient/patient_main_screen.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/superadmin/superadmin_main_screen.dart';
import '../screens/register_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/asset_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _illustrationVisible = false;
  String _userName = '';
  String _userRole = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userData = await AuthService.getMe();
    if (userData != null && mounted) {
      setState(() {
        _isLoggedIn = true;
        _userName = userData['responsibleName'] ?? 'Pengguna';
        _userRole = userData['role'] ?? 'PATIENT';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
    if (mounted) setState(() => _illustrationVisible = true);
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPatientDashboard() async {
    await ProfileService.instance.initialize();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PatientMainScreen()),
    );
  }

  Future<void> _navigateToAdminDashboard() async {
    await ProfileService.instance.initialize();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminMainScreen()),
    );
  }

  Future<void> _navigateToSuperadminDashboard() async {
    await ProfileService.instance.initialize();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SuperadminMainScreen()),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 140,
      child: SvgPicture.asset(
        AssetHelper.getSvgPath(
          'sammy-line-doctor-prescribing-medicine-during-clinical-consultation.svg',
        ),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBrandingHeader() {
    return Column(
      children: [
        _buildIllustration(),
        const SizedBox(height: AppTheme.spaceLarge),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AssetHelper.getIconPath('leaf_icon.png'),
              width: 20,
              height: 20,
              color: AppColors.primary,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              'MEDIKU',
              style: AppTheme.screenTitle.copyWith(
                fontSize: 26,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          'Kesehatan keluarga di satu tempat',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.text,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Nomor KK atau Username',
            hintStyle: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 16,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Lupa password?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              final identifier = _identifierController.text.trim();
              final password = _passwordController.text;
              if (identifier.isEmpty) {
                _showErrorDialog('Nomor KK atau Username tidak boleh kosong');
                return;
              }
              if (password.isEmpty) {
                _showErrorDialog('Password tidak boleh kosong');
                return;
              }
              try {
                final data = await AuthService.login(
                  identifier: identifier,
                  password: password,
                );
                if (mounted) {
                  final role = data['user']?['role'] ?? 'PATIENT';
                  if (role == 'ADMIN') {
                    await _navigateToAdminDashboard();
                  } else if (role == 'SUPERADMIN') {
                    await _navigateToSuperadminDashboard();
                  } else {
                    await _navigateToPatientDashboard();
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showErrorDialog(
                    'Login gagal. Periksa kembali KK/Username dan password Anda.',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text(
              'MASUK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Belum punya akun?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Daftar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeBackContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            onPressed: () {
              setState(() => _isLoggedIn = false);
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        const Text(
          'Selamat datang kembali,',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          _userName,
          style: AppTheme.screenTitle.copyWith(
            fontSize: 28,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXXLarge),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_userRole == 'ADMIN') {
                _navigateToAdminDashboard();
              } else if (_userRole == 'SUPERADMIN') {
                _navigateToSuperadminDashboard();
              } else {
                _navigateToPatientDashboard();
              }
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(
              'LANJUTKAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXLarge),
        Center(
          child: TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await AuthService.logout();
              await _checkLoginStatus();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Bukan Anda? Masuk dengan akun lain',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.statusRed,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _isLoggedIn
              ? Column(
                  key: const ValueKey('welcome'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandingHeader(),
                    _buildWelcomeBackContent(),
                    const SizedBox(height: AppTheme.spaceXLarge),
                    Center(
                      child: Text(
                        'v1.0 © 2026 MEDIKU',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('login'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandingHeader(),
                    const SizedBox(height: AppTheme.spaceXLarge),
                    _buildLoginForm(),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Center(
                      child: Text(
                        'v1.0 © 2026 MEDIKU',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXLarge,
              vertical: AppTheme.spaceMedium,
            ),
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              offset: _illustrationVisible ? Offset.zero : const Offset(0, 0.05),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _illustrationVisible ? 1.0 : 0.0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceXLarge,
                    AppTheme.spaceXXLarge,
                    AppTheme.spaceXLarge,
                    AppTheme.spaceXLarge,
                  ),
                  child: _buildCardContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
