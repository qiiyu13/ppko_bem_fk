import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mediku/utils/page_transitions.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _heroVisible = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _heroVisible = true);
    });
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

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      ParallaxPageRoute(page: const ForgotPasswordScreen()),
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

  Future<void> _navigateByRole(String role) async {
    await ProfileService.instance.initialize();
    if (!mounted) return;
    Widget destination;
    if (role == 'ADMIN') {
      destination = const AdminMainScreen();
    } else if (role == 'SUPERADMIN') {
      destination = const SuperadminMainScreen();
    } else {
      destination = const PatientMainScreen();
    }
    Navigator.of(context).pushReplacement(
      ParallaxPageRoute(page: destination),
    );
  }

  Widget _buildHero() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _heroVisible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        offset: _heroVisible ? Offset.zero : const Offset(0, 0.04),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MEDIKU',
                style: AppTheme.screenTitle.copyWith(
                  fontSize: 44,
                  letterSpacing: 3.0,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                'Kesehatan keluarga di satu tempat',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _heroVisible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.fastOutSlowIn,
        offset: _heroVisible ? Offset.zero : const Offset(0, 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
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
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
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
                    _showErrorDialog(
                      'Nomor KK atau Username tidak boleh kosong',
                    );
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
                      await _navigateByRole(role);
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
                      ParallaxPageRoute(
                        page: const RegisterScreen(),
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
            const SizedBox(height: AppTheme.spaceSmall),
            Center(
              child: Text('v1.0 © 2026 MEDIKU', style: AppTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(child: _buildHero()),
                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                    Transform.translate(
                      offset: const Offset(0, 20),
                      child: Image.asset(
                        AssetHelper.getIllustrationPath(
                          'welcome-illustration.webp',
                        ),
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusCard * 2),
                topRight: Radius.circular(AppTheme.radiusCard * 2),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceXLarge,
                AppTheme.spaceXLarge,
                AppTheme.spaceXLarge,
                AppTheme.spaceXLarge,
              ),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }
}
