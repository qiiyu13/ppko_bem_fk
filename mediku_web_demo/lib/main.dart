import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

// Import from main Mediku app
import 'package:mediku/constants/app_theme.dart';
import 'package:mediku/screens/patient/patient_main_screen.dart';
import 'package:mediku/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize profile service (automatically uses mock data on web)
  await ProfileService.instance.initialize();

  // If no profiles exist, create default profile
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
      home: const PatientMainScreen(),
      builder: DevicePreview.appBuilder,
    );
  }
}
