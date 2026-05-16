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
  if (PlatformUtil.firebaseAvailable) {
    await Firebase.initializeApp();
  }

  // Initialize API service with interceptors
  ApiService.setupInterceptors();

  // Initialize local cache for offline support
  await CacheService.init();

  // Initialize connectivity monitoring and auto-sync
  await ConnectivityService.instance.initialize();

  // Initialize notification service (loads local cache, registers FCM if available)
  await NotificationService.instance.initialize();

  runApp(
    kDebugMode
        ? DevicePreview(enabled: true, builder: (context) => const MyApp())
        : const MyApp(),
  );
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
