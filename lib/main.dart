import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'services/platform_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap image cache so large herbal photos don't pin RAM.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
  if (PlatformUtil.firebaseAvailable) {
    await Firebase.initializeApp();
  }

  ApiService.setupInterceptors();
  await CacheService.init();

  runApp(
    kDebugMode
        ? DevicePreview(enabled: true, builder: (context) => const MyApp())
        : const MyApp(),
  );

  // Non-critical services start after first frame so UI isn't blocked.
  ConnectivityService.instance.initialize();
  NotificationService.instance.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDIKU',
      debugShowCheckedModeBanner: false,
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
