import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Turn this off before going to production!
      builder: (context) => const MyApp(),
    ),
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
      builder: DevicePreview.appBuilder,
    );
  }
}
