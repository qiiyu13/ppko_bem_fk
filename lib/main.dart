import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'services/platform_util.dart';
import 'services/websocket_service.dart';

// Global navigator key: lets background tasks (e.g. token re-validation after an
// optimistic relaunch route) redirect without holding a screen's BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap image cache so large herbal photos don't pin RAM.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  ApiService.setupInterceptors();
  // Dead session (failed token refresh): kick to login instead of leaving the
  // user on a screen where every request silently fails until relaunch.
  ApiService.onSessionExpired = () {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Sesi berakhir, silakan masuk kembali.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  };
  await CacheService.init();

  runApp(
    kDebugMode
        ? DevicePreview(enabled: true, builder: (context) => const MyApp())
        : const MyApp(),
  );

  // Firebase + non-critical services start after the first frame so the splash
  // paints immediately and auth resolution isn't blocked by SDK init.
  _initBackgroundServices();
}

Future<void> _initBackgroundServices() async {
  if (PlatformUtil.firebaseAvailable) {
    await Firebase.initializeApp();
  }
  ConnectivityService.instance.initialize();
  NotificationService.instance.initialize();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The OS tears the socket down while the app is backgrounded, and the
  // reconnect loop gives up after a bounded number of attempts. Re-establish
  // on every foreground so live updates survive backgrounding. No-ops when
  // already connected or not logged in.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WebSocketService.instance.ensureConnected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDIKU',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      builder: kDebugMode ? DevicePreview.appBuilder : null,
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English fallback
      ],
    );
  }
}
