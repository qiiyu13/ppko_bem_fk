import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/asset_helper.dart';
import 'welcome_screen.dart';

const _commonSvgs = [
  'doodle-01.svg',
  'document-icon.svg',
  'document_recolored_final_2.svg',
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

    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _precacheSvgs();
    // Min display time so logo is visible; navigates as soon as min hits.
    Future.delayed(const Duration(milliseconds: 1200), _navigateToWelcome);
  }

  void _navigateToWelcome() async {
    // Start fade out animation
    await _fadeController.forward();

    if (mounted) {
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
            AssetHelper.getSvgPath('Group_2.svg'),
            width: 240,
            height: 67,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
