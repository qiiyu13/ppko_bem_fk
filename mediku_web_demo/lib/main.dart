import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import from main Mediku app
import 'package:mediku/constants/app_theme.dart';
import 'package:mediku/screens/patient/patient_main_screen.dart';
import 'package:mediku/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web database
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize profile service
  await ProfileService.instance.initialize();

  // Create demo profile if doesn't exist
  if (!await ProfileService.instance.hasProfiles()) {
    await ProfileService.instance.createDefaultProfile();
  }

  runApp(
    DevicePreview(enabled: true, builder: (context) => const WebDemoApp()),
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
      // Skip splash and welcome, go directly to patient dashboard
      home: const PatientMainScreen(),
      builder: DevicePreview.appBuilder,
    );
  }
}
