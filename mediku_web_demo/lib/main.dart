import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:device_frame/device_frame.dart';

// Import from main Mediku app
import 'package:mediku/constants/app_theme.dart';
import 'package:mediku/screens/patient/patient_main_screen.dart';
import 'package:mediku/services/api_service.dart';
import 'package:mediku/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service and cache
  ApiService.setupInterceptors();
  await CacheService.init();

  runApp(
    DevicePreview(
      enabled: true,
      defaultDevice: Devices.android.samsungGalaxyS25,
      builder: (context) => const WebDemoApp(),
    ),
  );
}

class WebDemoApp extends StatelessWidget {
  const WebDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDIKU Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PatientMainScreen(),
      builder: DevicePreview.appBuilder,
    );
  }
}
