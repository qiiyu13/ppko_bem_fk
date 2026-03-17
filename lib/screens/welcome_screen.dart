import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../utils/asset_helper.dart';
import 'patient/patient_main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'superadmin/superadmin_main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nikController = TextEditingController();
  int _logoTapCount = 0;
  Timer? _tapResetTimer;

  // Hardcoded NIK for patient login
  static const String VALID_PATIENT_NIK = '12131415';

  // Admin passcodes
  static const String ADMIN_PASSCODE = 'ADMIN123';
  static const String SUPERADMIN_PASSCODE = 'SUPER456';

  @override
  void initState() {
    super.initState();
    // Lock to portrait only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _onLogoTap() {
    _logoTapCount++;

    // Reset counter after 2 seconds if no more taps
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _logoTapCount = 0;
        });
      }
    });

    // Show passcode dialog after 5 taps
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _tapResetTimer?.cancel();
      _showPasscodeDialog();
    }
  }

  void _showPasscodeDialog() {
    final TextEditingController passcodeController = TextEditingController();
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
              'Masukkan kode akses:',
              style: TextStyle(fontSize: 16 * textScaler.scale(1.0)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passcodeController,
              obscureText: true,
              keyboardType: TextInputType.text,
              style: TextStyle(fontSize: 18 * textScaler.scale(1.0)),
              decoration: InputDecoration(
                hintText: 'Kode akses',
                hintStyle: TextStyle(
                  fontSize: 16 * textScaler.scale(1.0),
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
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
            onPressed: () {
              final passcode = passcodeController.text.toUpperCase().trim();
              Navigator.pop(context);

              if (passcode == ADMIN_PASSCODE) {
                _navigateToAdminDashboard();
              } else if (passcode == SUPERADMIN_PASSCODE) {
                _navigateToSuperadminDashboard();
              } else {
                _showErrorDialog('Kode akses salah');
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
              'Masuk',
              style: TextStyle(fontSize: 16 * textScaler.scale(1.0)),
            ),
          ),
        ],
      ),
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

  void _navigateToPatientDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PatientMainScreen()),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminMainScreen()),
    );
  }

  void _navigateToSuperadminDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SuperadminMainScreen()),
    );
  }

  @override
  void dispose() {
    _nikController.dispose();
    _tapResetTimer?.cancel();
    // Reset orientation when screen is disposed (if needed for other screens)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: screenHeight - MediaQuery.of(context).padding.top,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top section - Doctor SVG with admin access
                SizedBox(
                  height: screenHeight * 0.50,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          AssetHelper.getSvgPath('doctor_modified.svg'),
                          height: screenHeight * 0.45,
                          fit: BoxFit.contain,
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
                              color: AppColors.primarySurface.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
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

                // Login form card
                Expanded(
                  child: Container(
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title section
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
                                'Masukkan NIK untuk melanjutkan',
                                style: TextStyle(
                                  fontSize: isShortScreen ? 12 : 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isShortScreen ? 16 : 24),

                          // Form section
                          TextField(
                            controller: _nikController,
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
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isShortScreen ? 12 : 14,
                              ),
                            ),
                          ),

                          SizedBox(height: isShortScreen ? 16 : 24),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            height: isShortScreen ? 44 : 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final inputNik = _nikController.text.trim();
                                if (inputNik.isEmpty) {
                                  _showErrorDialog('NIK tidak boleh kosong');
                                } else if (inputNik == VALID_PATIENT_NIK) {
                                  _navigateToPatientDashboard();
                                } else {
                                  _showErrorDialog(
                                    'NIK tidak valid. Gunakan: 12131415',
                                  );
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
                                  Icon(
                                    Icons.arrow_forward,
                                    size: isShortScreen ? 16 : 18,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Footer
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
