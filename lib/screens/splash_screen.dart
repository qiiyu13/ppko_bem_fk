import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/asset_helper.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'welcome_screen.dart';
import 'patient/patient_main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'superadmin/superadmin_main_screen.dart';

const _commonSvgs = [
  'doodle-01.svg',
  'document-icon.svg',
  'document_recolored_final_2.svg',
  'doctor_modified.svg',
];

Future<void> _precacheSvgs() async {
  for (final name in _commonSvgs) {
    final loader = SvgAssetLoader(AssetHelper.getSvgPath(name));
    await svg.cache
        .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _precacheSvgs();
    Future.delayed(const Duration(milliseconds: 1200), _navigate);
  }

  Future<void> _navigate() async {
    final userData = await AuthService.getMe();

    await _fadeController.forward();
    if (!mounted) return;

    if (userData != null) {
      await ProfileService.instance.initialize();
      if (!mounted) return;
      final role = userData['role'] ?? 'PATIENT';
      Widget destination;
      if (role == 'ADMIN') {
        destination = const AdminMainScreen();
      } else if (role == 'SUPERADMIN') {
        destination = const SuperadminMainScreen();
      } else {
        destination = const PatientMainScreen();
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(opacity: _fadeAnimation.value, child: child);
        },
        child: Center(
          child: SvgPicture.asset(
            'assets/icon/logo-only.svg',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
