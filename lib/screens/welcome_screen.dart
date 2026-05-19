import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/app_colors.dart';
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
  final TextEditingController _kkController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _logoTapCount = 0;
  Timer? _tapResetTimer;

  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
  }

  void _onLogoTap() {
    _logoTapCount++;

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _logoTapCount = 0;
        });
      }
    });

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _tapResetTimer?.cancel();
      _showAdminLoginDialog();
    }
  }

  void _showAdminLoginDialog() {
    final adminKkController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final textScaler = MediaQuery.textScalerOf(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Akses Admin',
          style: TextStyle(
            fontSize: 22 * textScaler.scale(1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan KK dan Password:',
              style: TextStyle(fontSize: 16 * textScaler.scale(1.0)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminKkController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 18 * textScaler.scale(1.0)),
              decoration: InputDecoration(
                hintText: 'Nomor KK',
                hintStyle: TextStyle(
                  fontSize: 16 * textScaler.scale(1.0),
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
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
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminPasswordController,
              obscureText: true,
              style: TextStyle(fontSize: 18 * textScaler.scale(1.0)),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                  fontSize: 16 * textScaler.scale(1.0),
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
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
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                fontSize: 16 * textScaler.scale(1.0),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final kk = adminKkController.text.trim();
              final password = adminPasswordController.text;
              if (kk.isEmpty || password.isEmpty) return;

              Navigator.pop(context);

              try {
                final data = await AuthService.login(
                  kkNumber: kk,
                  password: password,
                );
                if (!mounted) return;
                final user = data['user'];
                final role = user['role'];

                if (role == 'ADMIN') {
                  _navigateToAdminDashboard();
                } else if (role == 'SUPERADMIN') {
                  _navigateToSuperadminDashboard();
                } else {
                  _showErrorDialog('Akun ini bukan admin');
                }
              } catch (e) {
                if (!mounted) return;
                _showErrorDialog('Login gagal. Periksa kembali KK dan password Anda.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Masuk sebagai Admin',
              style: TextStyle(fontSize: 16 * textScaler.scale(1.0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _showErrorDialog(String message) {
    final textScaler = MediaQuery.textScalerOf(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: TextStyle(fontSize: 20 * textScaler.scale(1.0)),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16 * textScaler.scale(1.0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 16 * textScaler.scale(1.0),
                color: AppColors.primary,
              ),
            ),
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
    _kkController.dispose();
    _passwordController.dispose();
    _tapResetTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Widget _buildLoadingForm() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildWelcomeBackForm(bool isShortScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang kembali,',
              style: TextStyle(
                fontSize: isShortScreen ? 14 : 16,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: isShortScreen ? 4 : 6),
            Text(
              _userName,
              style: TextStyle(
                fontSize: isShortScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        SizedBox(height: isShortScreen ? 24 : 32),

        SizedBox(
          width: double.infinity,
          height: isShortScreen ? 44 : 52,
          child: ElevatedButton(
            onPressed: () {
              if (_userRole == 'ADMIN') {
                _navigateToAdminDashboard();
              } else if (_userRole == 'SUPERADMIN') {
                _navigateToSuperadminDashboard();
              } else {
                _navigateToPatientDashboard();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LANJUTKAN',
                  style: TextStyle(
                    fontSize: isShortScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: isShortScreen ? 6 : 8),
                Icon(Icons.arrow_forward, size: isShortScreen ? 16 : 18),
              ],
            ),
          ),
        ),

        SizedBox(height: isShortScreen ? 16 : 24),

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
            child: Text(
              'Bukan Anda? Masuk dengan akun lain',
              style: TextStyle(
                fontSize: isShortScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: AppColors.statusRed,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'v1.0 © 2024 MEDIKU',
            style: TextStyle(
              fontSize: isShortScreen ? 10 : 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isShortScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang di MEDIKU',
              style: TextStyle(
                fontSize: isShortScreen ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isShortScreen ? 4 : 6),
            Text(
              'Masukkan KK dan Password',
              style: TextStyle(
                fontSize: isShortScreen ? 12 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        SizedBox(height: isShortScreen ? 16 : 24),

        TextField(
          controller: _kkController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: isShortScreen ? 16 : 17,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: 3201...',
            hintStyle: TextStyle(
              fontSize: isShortScreen ? 14 : 15,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: AppColors.primary,
              size: isShortScreen ? 20 : 22,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isShortScreen ? 12 : 14,
            ),
          ),
        ),

        SizedBox(height: isShortScreen ? 12 : 16),

        TextField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(
            fontSize: isShortScreen ? 16 : 17,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(
              fontSize: isShortScreen ? 14 : 15,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: AppColors.primary,
              size: isShortScreen ? 20 : 22,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isShortScreen ? 12 : 14,
            ),
          ),
        ),

        SizedBox(height: isShortScreen ? 8 : 12),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lupa password?',
              style: TextStyle(
                fontSize: isShortScreen ? 12 : 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        SizedBox(height: isShortScreen ? 8 : 12),

        SizedBox(
          width: double.infinity,
          height: isShortScreen ? 44 : 48,
          child: ElevatedButton(
            onPressed: () async {
              final kk = _kkController.text.trim();
              final password = _passwordController.text;
              if (kk.isEmpty) {
                _showErrorDialog('KK tidak boleh kosong');
                return;
              }
              if (password.isEmpty) {
                _showErrorDialog('Password tidak boleh kosong');
                return;
              }
              try {
                final data = await AuthService.login(
                  kkNumber: kk,
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
                  _showErrorDialog('Login gagal. Periksa kembali KK dan password Anda.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MASUK',
                  style: TextStyle(
                    fontSize: isShortScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: isShortScreen ? 6 : 8),
                Icon(Icons.arrow_forward, size: isShortScreen ? 16 : 18),
              ],
            ),
          ),
        ),

        SizedBox(height: isShortScreen ? 12 : 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum punya akun?',
              style: TextStyle(
                fontSize: isShortScreen ? 12 : 14,
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
              child: Text(
                'Daftar',
                style: TextStyle(
                  fontSize: isShortScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'v1.0 © 2024 MEDIKU',
            style: TextStyle(
              fontSize: isShortScreen ? 10 : 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isShortScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          left: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: -10,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.statusGreen.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 40,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 130,
                          right: -30,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySurface.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: 80,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 50,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.statusGreen.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 60,
                          left: -40,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.statusGreen.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: 60,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            child: Image.asset(
                              AssetHelper.getIllustrationPath('welcome-illustration.webp'),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: isSmallScreen ? 16 : 24,
                          child: GestureDetector(
                            onTap: _onLogoTap,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 16.0 : 24.0,
                        right: isSmallScreen ? 16.0 : 24.0,
                        top: isShortScreen ? 12.0 : 16.0,
                        bottom: 16.0,
                      ),
                      child: _isLoading
                          ? _buildLoadingForm()
                          : _isLoggedIn
                          ? _buildWelcomeBackForm(isShortScreen)
                          : _buildLoginForm(isShortScreen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
