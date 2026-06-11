import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart' show navigatorKey;
import '../utils/asset_helper.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/token_service.dart';
import '../services/websocket_service.dart';
import 'welcome_screen.dart';
import 'patient/patient_main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'superadmin/superadmin_main_screen.dart';

// Minimum time the brand splash stays visible. Auth resolution runs CONCURRENTLY
// with this window, so a warm relaunch is gated only by branding, not network.
const _minSplash = Duration(milliseconds: 600);

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    unawaited(_precacheSvgs());
    unawaited(_boot());
  }

  Future<void> _boot() async {
    final minSplash = Future<void>.delayed(_minSplash);
    final token = await TokenService.getToken();

    // No token: skip the pointless /auth/me round-trip and go straight to welcome.
    if (token == null) {
      await minSplash;
      await _exit(const WelcomeScreen());
      return;
    }

    // Start the network identity refresh immediately so it overlaps the splash.
    final mePromise = AuthService.getMe();
    final cachedRole = await TokenService.getRole();

    if (cachedRole != null) {
      // Optimistic route: show the last-known home without blocking on the
      // network, then re-validate the session in the background.
      await _goHome(cachedRole);
      unawaited(_revalidate(mePromise));
      return;
    }

    // No cached role (legacy install): must wait for the network to learn which
    // home to show, but still honor the minimum splash duration.
    final results = await Future.wait([mePromise, minSplash]);
    final me = results.first as Map<String, dynamic>?;
    if (me == null) {
      await _exit(const WelcomeScreen());
    } else {
      await _goHome(me['role'] ?? 'PATIENT');
    }
  }

  // Re-check the session after an optimistic route. The request interceptor
  // clears the token when a refresh fails, so a missing token here means the
  // session is truly invalid (vs. merely offline, where the token survives).
  Future<void> _revalidate(Future<Map<String, dynamic>?> mePromise) async {
    await mePromise;
    final token = await TokenService.getToken();
    if (token != null) return; // still authenticated, or just offline — stay put.

    await AuthService.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _goHome(String role) async {
    // Warm start skips the login flow, which is the only other place the
    // websocket gets connected — without this, a relaunched session has no
    // live updates at all until the user logs out and back in.
    WebSocketService.instance.ensureConnected();
    // Preload profiles cached-first in the background; the home screen renders
    // from cache and refreshes itself, so navigation never waits on /profiles.
    unawaited(ProfileService.instance.initialize());
    await _exit(_homeFor(role));
  }

  Widget _homeFor(String role) {
    switch (role) {
      case 'ADMIN':
        return const AdminMainScreen();
      case 'SUPERADMIN':
        return const SuperadminMainScreen();
      default:
        return const PatientMainScreen();
    }
  }

  Future<void> _exit(Widget destination) async {
    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
