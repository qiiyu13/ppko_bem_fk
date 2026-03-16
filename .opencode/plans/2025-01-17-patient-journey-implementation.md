# Patient Journey Web - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standalone Flutter Web application that displays animated patient health journeys when accessed via QR code URL with patient_id parameter.

**Architecture:** Separate Flutter Web project from the main Mediku app. Uses PageView with 4 animated chapters (Profile, Metrics, Timeline, Snapshot). Fetches patient data from static JSON files served via CDN/vercel public folder. Deploys to Vercel.

**Tech Stack:** Flutter Web, fl_chart, qr_flutter, go_router, http, url_strategy, Vercel hosting

---

## Prerequisites

- Flutter SDK installed (version ^3.10.7)
- Vercel CLI installed globally
- Git configured

---

## Task 1: Create New Flutter Project

**Files:**
- Create: `mediku-journey-web/` (project root)

**Step 1: Create Flutter project**

Run:
```bash
cd /home/qiu/Work/ppko_bem_fk
flutter create --platforms web mediku-journey-web
```

Expected: Project created with web/, lib/, test/ directories

**Step 2: Navigate to project**

Run:
```bash
cd mediku-journey-web
```

**Step 3: Verify web support**

Run:
```bash
flutter devices
```

Expected: Should list "Chrome (web)" device

**Step 4: Initial commit**

Run:
```bash
git init
git add .
git commit -m "feat: initial flutter web project"
```

---

## Task 2: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Update pubspec.yaml**

```yaml
name: mediku_journey_web
description: Patient Health Journey Visualization

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.10.7

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  fl_chart: ^0.70.0
  qr_flutter: ^4.1.0
  go_router: ^14.0.0
  http: ^1.2.0
  url_strategy: ^0.3.0
  flutter_svg: ^2.0.10
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

**Step 2: Get dependencies**

Run:
```bash
flutter pub get
```

Expected: Dependencies installed successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add dependencies for charts, routing, and http"
```

---

## Task 3: Create Data Models

**Files:**
- Create: `lib/models/patient.dart`
- Create: `lib/models/health_metric.dart`
- Create: `lib/models/timeline_event.dart`

**Step 1: Create Patient model**

```dart
// lib/models/patient.dart

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? bloodType;
  final String? avatarUrl;
  final String summary;
  final Map<String, HealthMetricData> metrics;
  final List<TimelineEvent> timeline;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.bloodType,
    this.avatarUrl,
    required this.summary,
    required this.metrics,
    required this.timeline,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      bloodType: json['bloodType'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      summary: json['summary'] as String,
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, HealthMetricData.fromJson(value)),
      ),
      timeline: (json['timeline'] as List)
          .map((e) => TimelineEvent.fromJson(e))
          .toList(),
    );
  }
}

class HealthMetricData {
  final String current;
  final String? unit;
  final List<MetricReading> history;

  HealthMetricData({
    required this.current,
    this.unit,
    required this.history,
  });

  factory HealthMetricData.fromJson(Map<String, dynamic> json) {
    return HealthMetricData(
      current: json['current'] as String,
      unit: json['unit'] as String?,
      history: (json['history'] as List)
          .map((e) => MetricReading.fromJson(e))
          .toList(),
    );
  }
}

class MetricReading {
  final DateTime date;
  final double value;
  final double? secondaryValue;

  MetricReading({
    required this.date,
    required this.value,
    this.secondaryValue,
  });

  factory MetricReading.fromJson(Map<String, dynamic> json) {
    return MetricReading(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      secondaryValue: json['secondaryValue'] != null
          ? (json['secondaryValue'] as num).toDouble()
          : null,
    );
  }
}

class TimelineEvent {
  final DateTime date;
  final String type;
  final String title;
  final String description;
  final String status;

  TimelineEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
    );
  }
}
```

**Step 2: Run analyzer**

Run:
```bash
flutter analyze lib/models/patient.dart
```

Expected: No errors

**Step 3: Commit**

```bash
git add lib/models/
git commit -m "feat: add patient data models"
```

---

## Task 4: Create Data Service

**Files:**
- Create: `lib/services/data_service.dart`

**Step 1: Create data service**

```dart
// lib/services/data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class DataService {
  static const String _baseUrl = 'patients';
  
  // For local development vs production
  static String get _cdnBaseUrl {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      // Will be served from same domain in production via vercel
      return '/$_baseUrl';
    }
    // Local development - adjust as needed
    return '/$_baseUrl';
  }

  static Future<Patient?> fetchPatient(String patientId) async {
    try {
      final url = '$_cdnBaseUrl/$patientId.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Patient.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient: $e');
    }
  }

  static Future<List<String>> listAvailablePatients() async {
    // This would ideally come from an index file
    // For now, return hardcoded demo patients
    return ['patient-001', 'patient-002', 'demo-patient'];
  }
}
```

**Step 2: Commit**

```bash
git add lib/services/
git commit -m "feat: add data service for fetching patient JSON"
```

---

## Task 5: Set Up Routing

**Files:**
- Create: `lib/routes/app_router.dart`
- Modify: `lib/main.dart`

**Step 1: Create router**

```dart
// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/journey_screen.dart';
import '../screens/not_found_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const NotFoundScreen(
          message: 'Silakan scan QR code untuk melihat perjalanan kesehatan pasien',
        ),
      ),
      GoRoute(
        path: '/journey',
        builder: (context, state) {
          final patientId = state.uri.queryParameters['patient_id'];
          if (patientId == null || patientId.isEmpty) {
            return const NotFoundScreen(
              message: 'ID Pasien tidak ditemukan',
            );
          }
          return JourneyScreen(patientId: patientId);
        },
      ),
    ],
    errorBuilder: (context, state) => NotFoundScreen(
      message: 'Halaman tidak ditemukan: ${state.uri.path}',
    ),
  );
}
```

**Step 2: Update main.dart**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'routes/app_router.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mediku Journey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      routerConfig: AppRouter.router,
    );
  }
}
```

**Step 3: Test router**

Run:
```bash
flutter run -d chrome
```

Expected: App opens in Chrome at `localhost:8080`

Navigate to: `http://localhost:8080/journey?patient_id=test`

Expected: JourneyScreen loads (will show loading/error state for now)

**Step 4: Commit**

```bash
git add lib/main.dart lib/routes/
git commit -m "feat: setup go_router with journey route"
```

---

## Task 6: Create Journey Screen Container

**Files:**
- Create: `lib/screens/journey_screen.dart`
- Create: `lib/screens/not_found_screen.dart`

**Step 1: Create journey screen**

```dart
// lib/screens/journey_screen.dart

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/data_service.dart';
import '../widgets/chapters/profile_chapter.dart';
import '../widgets/chapters/metrics_chapter.dart';
import '../widgets/chapters/timeline_chapter.dart';
import '../widgets/chapters/snapshot_chapter.dart';
import '../widgets/progress_indicator.dart';

class JourneyScreen extends StatefulWidget {
  final String patientId;

  const JourneyScreen({super.key, required this.patientId});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  Patient? _patient;
  bool _isLoading = true;
  String? _error;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final patient = await DataService.fetchPatient(widget.patientId);
      setState(() {
        _patient = patient;
        _isLoading = false;
        if (patient == null) {
          _error = 'Pasien tidak ditemukan';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat perjalanan kesehatan...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _patient == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Terjadi kesalahan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatient,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          JourneyProgressIndicator(
            currentPage: _currentPage,
            totalPages: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              children: [
                ProfileChapter(patient: _patient!),
                MetricsChapter(patient: _patient!),
                TimelineChapter(patient: _patient!),
                SnapshotChapter(patient: _patient!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
```

**Step 2: Create not found screen**

```dart
// lib/screens/not_found_screen.dart

import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String message;

  const NotFoundScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              const Text(
                'Demo tersedia untuk pasien:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'patient-001',
                  'patient-002',
                  'demo-patient',
                ].map((id) => ActionChip(
                  label: Text(id),
                  onPressed: () {
                    // Navigate to demo
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/screens/
git commit -m "feat: add journey screen with pageview and loading states"
```

---

## Task 7: Create Animation Utilities

**Files:**
- Create: `lib/widgets/animations/slide_in_card.dart`
- Create: `lib/widgets/animations/animated_line.dart`
- Create: `lib/widgets/progress_indicator.dart`

**Step 1: Create slide in card widget**

```dart
// lib/widgets/animations/slide_in_card.dart

import 'package:flutter/material.dart';

class SlideInCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final AxisDirection direction;
  final Curve curve;

  const SlideInCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.direction = AxisDirection.up,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    Offset beginOffset;
    switch (widget.direction) {
      case AxisDirection.up:
        beginOffset = const Offset(0, 1);
        break;
      case AxisDirection.down:
        beginOffset = const Offset(0, -1);
        break;
      case AxisDirection.left:
        beginOffset = const Offset(1, 0);
        break;
      case AxisDirection.right:
        beginOffset = const Offset(-1, 0);
        break;
    }

    _offsetAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Step 2: Create animated line for charts**

```dart
// lib/widgets/animations/animated_line.dart

import 'package:flutter/material.dart';

class AnimatedLine extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Duration duration;
  final Axis direction;

  const AnimatedLine({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.duration = const Duration(seconds: 2),
    this.direction = Axis.vertical,
  });

  @override
  State<AnimatedLine> createState() => _AnimatedLineState();
}

class _AnimatedLineState extends State<AnimatedLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (widget.direction == Axis.vertical) {
          return Container(
            width: widget.width,
            height: widget.height * _animation.value,
            color: widget.color,
          );
        } else {
          return Container(
            width: widget.width * _animation.value,
            height: widget.height,
            color: widget.color,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Step 3: Create progress indicator**

```dart
// lib/widgets/progress_indicator.dart

import 'package:flutter/material.dart';

class JourneyProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const JourneyProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index <= currentPage;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }
}
```

**Step 4: Commit**

```bash
git add lib/widgets/animations/ lib/widgets/progress_indicator.dart
git commit -m "feat: add animation utilities for slide and line animations"
```

---

## Task 8: Create Profile Chapter

**Files:**
- Create: `lib/widgets/chapters/profile_chapter.dart`

**Step 1: Create profile chapter**

```dart
// lib/widgets/chapters/profile_chapter.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class ProfileChapter extends StatelessWidget {
  final Patient patient;

  const ProfileChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideInCard(
            delay: const Duration(milliseconds: 0),
            child: _buildInfoCard(
              context,
              icon: Icons.person,
              label: 'Nama',
              value: patient.name,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 200),
            direction: AxisDirection.left,
            child: _buildInfoCard(
              context,
              icon: Icons.cake,
              label: 'Usia',
              value: '${patient.age} tahun',
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 400),
            direction: AxisDirection.right,
            child: _buildInfoCard(
              context,
              icon: Icons.bloodtype,
              label: 'Golongan Darah',
              value: patient.bloodType ?? '-',
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 600),
            child: _buildInfoCard(
              context,
              icon: patient.gender == 'Pria' ? Icons.male : Icons.female,
              label: 'Jenis Kelamin',
              value: patient.gender,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 32),
          SlideInCard(
            delay: const Duration(milliseconds: 800),
            child: Text(
              patient.summary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/chapters/profile_chapter.dart
git commit -m "feat: add profile chapter with staggered card animations"
```

---

## Task 9: Create Metrics Chapter

**Files:**
- Create: `lib/widgets/chapters/metrics_chapter.dart`

**Step 1: Create metrics chapter**

```dart
// lib/widgets/chapters/metrics_chapter.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class MetricsChapter extends StatelessWidget {
  final Patient patient;

  const MetricsChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Perkembangan Kesehatan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (patient.metrics.containsKey('bloodPressure'))
              SlideInCard(
                delay: const Duration(milliseconds: 0),
                child: _buildMetricCard(
                  context,
                  title: 'Tekanan Darah',
                  metric: patient.metrics['bloodPressure']!,
                  color: Colors.red,
                  icon: Icons.favorite,
                  isBloodPressure: true,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('cholesterol'))
              SlideInCard(
                delay: const Duration(milliseconds: 300),
                child: _buildMetricCard(
                  context,
                  title: 'Kolesterol',
                  metric: patient.metrics['cholesterol']!,
                  color: Colors.orange,
                  icon: Icons.water_drop,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('bloodSugar'))
              SlideInCard(
                delay: const Duration(milliseconds: 600),
                child: _buildMetricCard(
                  context,
                  title: 'Gula Darah',
                  metric: patient.metrics['bloodSugar']!,
                  color: Colors.green,
                  icon: Icons.bloodtype,
                ),
              ),
            const SizedBox(height: 16),
            if (patient.metrics.containsKey('uricAcid'))
              SlideInCard(
                delay: const Duration(milliseconds: 900),
                child: _buildMetricCard(
                  context,
                  title: 'Asam Urat',
                  metric: patient.metrics['uricAcid']!,
                  color: Colors.purple,
                  icon: Icons.science,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required HealthMetricData metric,
    required Color color,
    required IconData icon,
    bool isBloodPressure = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${metric.current} ${metric.unit ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _buildLineChart(metric, color, isBloodPressure),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    HealthMetricData metric,
    Color color,
    bool isBloodPressure,
  ) {
    final spots = metric.history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/chapters/metrics_chapter.dart
git commit -m "feat: add metrics chapter with animated fl_chart charts"
```

---

## Task 10: Create Timeline Chapter

**Files:**
- Create: `lib/widgets/chapters/timeline_chapter.dart`

**Step 1: Create timeline chapter**

```dart
// lib/widgets/chapters/timeline_chapter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';
import '../animations/animated_line.dart';

class TimelineChapter extends StatelessWidget {
  final Patient patient;

  const TimelineChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Perjalanan Medis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: patient.timeline.length,
              itemBuilder: (context, index) {
                final event = patient.timeline[index];
                final isLeft = index % 2 == 0;
                final delay = Duration(milliseconds: index * 300);

                return TimelineItem(
                  event: event,
                  isLeft: isLeft,
                  delay: delay,
                  isLast: index == patient.timeline.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLeft;
  final Duration delay;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.event,
    required this.isLeft,
    required this.delay,
    required this.isLast,
  });

  IconData get _icon {
    switch (event.type) {
      case 'appointment':
        return Icons.event;
      case 'lab':
        return Icons.science;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.info;
    }
  }

  Color get _color {
    switch (event.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          if (isLeft) ...[
            Expanded(
              child: SlideInCard(
                delay: delay,
                direction: AxisDirection.left,
                child: _buildEventCard(),
              ),
            ),
            _buildTimelineLine(),
            const Expanded(child: SizedBox()),
          ] else ...[
            const Expanded(child: SizedBox()),
            _buildTimelineLine(),
            Expanded(
              child: SlideInCard(
                delay: delay,
                direction: AxisDirection.right,
                child: _buildEventCard(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(event.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      width: 40,
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          if (!isLast)
            Expanded(
              child: AnimatedLine(
                width: 2,
                height: double.infinity,
                color: Colors.grey.shade300,
                direction: Axis.vertical,
              ),
            ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/chapters/timeline_chapter.dart
git commit -m "feat: add timeline chapter with alternating cards"
```

---

## Task 11: Create Snapshot Chapter

**Files:**
- Create: `lib/widgets/chapters/snapshot_chapter.dart`

**Step 1: Create snapshot chapter**

```dart
// lib/widgets/chapters/snapshot_chapter.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class SnapshotChapter extends StatelessWidget {
  final Patient patient;

  const SnapshotChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final currentUrl = Uri.base.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Status Kesehatan Saat Ini',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (patient.metrics.containsKey('bloodPressure'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 0),
                    direction: AxisDirection.left,
                    child: _buildMetricSnapshot(
                      'Tekanan Darah',
                      patient.metrics['bloodPressure']!.current,
                      'mmHg',
                      Colors.red,
                      Icons.favorite,
                    ),
                  ),
                if (patient.metrics.containsKey('cholesterol'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 100),
                    direction: AxisDirection.up,
                    child: _buildMetricSnapshot(
                      'Kolesterol',
                      patient.metrics['cholesterol']!.current,
                      'mg/dL',
                      Colors.orange,
                      Icons.water_drop,
                    ),
                  ),
                if (patient.metrics.containsKey('bloodSugar'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 200),
                    direction: AxisDirection.right,
                    child: _buildMetricSnapshot(
                      'Gula Darah',
                      patient.metrics['bloodSugar']!.current,
                      'mg/dL',
                      Colors.green,
                      Icons.bloodtype,
                    ),
                  ),
                if (patient.metrics.containsKey('uricAcid'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 300),
                    direction: AxisDirection.left,
                    child: _buildMetricSnapshot(
                      'Asam Urat',
                      patient.metrics['uricAcid']!.current,
                      'mg/dL',
                      Colors.purple,
                      Icons.science,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            SlideInCard(
              delay: const Duration(milliseconds: 500),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Bagikan Perjalanan Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: currentUrl,
                        version: QrVersions.auto,
                        size: 150,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan untuk melihat perjalanan kesehatan ${patient.name}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Copy to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link disalin ke clipboard'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Link'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Share functionality
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSnapshot(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/chapters/snapshot_chapter.dart
git commit -m "feat: add snapshot chapter with QR code sharing"
```

---

## Task 12: Create Demo Patient JSON

**Files:**
- Create: `public/patients/patient-001.json`
- Create: `public/patients/patient-002.json`

**Step 1: Create public directory and first patient**

```bash
mkdir -p public/patients
```

**Step 2: Create patient-001.json**

```json
{
  "id": "patient-001",
  "name": "Budi Santoso",
  "age": 45,
  "gender": "Pria",
  "bloodType": "O+",
  "avatarUrl": null,
  "summary": "Perjalanan kesehatan 6 bulan terakhir menunjukkan perbaikan signifikan",
  "metrics": {
    "bloodPressure": {
      "current": "120/80",
      "unit": "mmHg",
      "history": [
        {"date": "2024-07-01", "value": 135, "secondaryValue": 88},
        {"date": "2024-08-01", "value": 128, "secondaryValue": 85},
        {"date": "2024-09-01", "value": 125, "secondaryValue": 82},
        {"date": "2024-10-01", "value": 122, "secondaryValue": 80},
        {"date": "2024-11-01", "value": 120, "secondaryValue": 78},
        {"date": "2024-12-01", "value": 120, "secondaryValue": 80}
      ]
    },
    "cholesterol": {
      "current": "195",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 220},
        {"date": "2024-08-01", "value": 215},
        {"date": "2024-09-01", "value": 210},
        {"date": "2024-10-01", "value": 205},
        {"date": "2024-11-01", "value": 200},
        {"date": "2024-12-01", "value": 195}
      ]
    },
    "bloodSugar": {
      "current": "95",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 105},
        {"date": "2024-08-01", "value": 102},
        {"date": "2024-09-01", "value": 100},
        {"date": "2024-10-01", "value": 98},
        {"date": "2024-11-01", "value": 96},
        {"date": "2024-12-01", "value": 95}
      ]
    },
    "uricAcid": {
      "current": "5.8",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 6.8},
        {"date": "2024-08-01", "value": 6.5},
        {"date": "2024-09-01", "value": 6.2},
        {"date": "2024-10-01", "value": 6.0},
        {"date": "2024-11-01", "value": 5.9},
        {"date": "2024-12-01", "value": 5.8}
      ]
    }
  },
  "timeline": [
    {
      "date": "2024-07-15",
      "type": "appointment",
      "title": "Pemeriksaan Awal",
      "description": "Tekanan darah tinggi, diberikan rekomendasi diet",
      "status": "completed"
    },
    {
      "date": "2024-08-20",
      "type": "lab",
      "title": "Cek Lab Bulanan",
      "description": "Kolesterol menurun, perbaikan terlihat",
      "status": "completed"
    },
    {
      "date": "2024-09-25",
      "type": "appointment",
      "title": "Kontrol Rutin",
      "description": "Tekanan darah mulai normal, lanjutkan pola hidup sehat",
      "status": "completed"
    },
    {
      "date": "2024-11-10",
      "type": "lab",
      "title": "Cek Lab 3 Bulanan",
      "description": "Semua parameter dalam batas normal",
      "status": "completed"
    }
  ]
}
```

**Step 3: Create patient-002.json**

```json
{
  "id": "patient-002",
  "name": "Siti Aminah",
  "age": 52,
  "gender": "Wanita",
  "bloodType": "A+",
  "avatarUrl": null,
  "summary": "Pemantauan rutin kondisi diabetes dan tekanan darah",
  "metrics": {
    "bloodPressure": {
      "current": "118/76",
      "unit": "mmHg",
      "history": [
        {"date": "2024-07-01", "value": 145, "secondaryValue": 92},
        {"date": "2024-08-01", "value": 140, "secondaryValue": 88},
        {"date": "2024-09-01", "value": 132, "secondaryValue": 84},
        {"date": "2024-10-01", "value": 125, "secondaryValue": 80},
        {"date": "2024-11-01", "value": 120, "secondaryValue": 78},
        {"date": "2024-12-01", "value": 118, "secondaryValue": 76}
      ]
    },
    "cholesterol": {
      "current": "210",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 245},
        {"date": "2024-08-01", "value": 238},
        {"date": "2024-09-01", "value": 230},
        {"date": "2024-10-01", "value": 222},
        {"date": "2024-11-01", "value": 215},
        {"date": "2024-12-01", "value": 210}
      ]
    },
    "bloodSugar": {
      "current": "110",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 145},
        {"date": "2024-08-01", "value": 138},
        {"date": "2024-09-01", "value": 130},
        {"date": "2024-10-01", "value": 122},
        {"date": "2024-11-01", "value": 115},
        {"date": "2024-12-01", "value": 110}
      ]
    },
    "uricAcid": {
      "current": "4.2",
      "unit": "mg/dL",
      "history": [
        {"date": "2024-07-01", "value": 5.0},
        {"date": "2024-08-01", "value": 4.8},
        {"date": "2024-09-01", "value": 4.6},
        {"date": "2024-10-01", "value": 4.5},
        {"date": "2024-11-01", "value": 4.3},
        {"date": "2024-12-01", "value": 4.2}
      ]
    }
  },
  "timeline": [
    {
      "date": "2024-07-10",
      "type": "appointment",
      "title": "Konsultasi Diabetes",
      "description": "Gula darah tinggi, dimulai program diet ketat",
      "status": "completed"
    },
    {
      "date": "2024-08-15",
      "type": "medication",
      "title": "Pengaturan Obat",
      "description": "Dosis obat disesuaikan, respon baik",
      "status": "completed"
    },
    {
      "date": "2024-09-20",
      "type": "lab",
      "title": "Cek HbA1c",
      "description": "HbA1c turun dari 8.5% ke 7.2%",
      "status": "completed"
    },
    {
      "date": "2024-11-05",
      "type": "appointment",
      "title": "Evaluasi 4 Bulan",
      "description": "Kondisi stabil, gula darah terkontrol",
      "status": "completed"
    }
  ]
}
```

**Step 4: Commit**

```bash
git add public/
git commit -m "chore: add demo patient JSON files"
```

---

## Task 13: Configure Vercel Deployment

**Files:**
- Create: `vercel.json`
- Modify: `web/index.html` (if needed)

**Step 1: Create vercel.json**

```json
{
  "version": 2,
  "builds": [
    {
      "src": "web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "rewrites": [
    {
      "source": "/patients/(.*)",
      "destination": "/patients/$1"
    }
  ]
}
```

**Step 2: Copy public files to web directory**

Run:
```bash
cp -r public/patients web/
```

**Step 3: Update web/index.html title**

```html
<!-- In web/index.html, update title -->
<title>Mediku Journey</title>
```

**Step 4: Test build locally**

Run:
```bash
flutter build web --release
```

Expected: Build completes without errors in `build/web/`

**Step 5: Copy public data to build**

Run:
```bash
cp -r public/patients build/web/
```

**Step 6: Serve locally to test**

Run:
```bash
cd build/web
python3 -m http.server 8080
```

Navigate to: `http://localhost:8080/journey?patient_id=patient-001`

Expected: Journey animation displays correctly

**Step 7: Commit**

```bash
git add vercel.json web/
git commit -m "chore: add vercel config and web assets"
```

---

## Task 14: Deploy to Vercel

**Step 1: Install Vercel CLI (if not already)**

Run:
```bash
npm install -g vercel
```

**Step 2: Login to Vercel**

Run:
```bash
vercel login
```

**Step 3: Deploy**

Run:
```bash
vercel --prod
```

Follow prompts:
- Set up and deploy? Yes
- Which scope? [your account]
- Link to existing project? No
- Project name? mediku-journey-web
- Directory? ./

Expected: Deployment URL provided (e.g., `https://mediku-journey-web.vercel.app`)

**Step 4: Test deployed version**

Navigate to:
```
https://mediku-journey-web.vercel.app/journey?patient_id=patient-001
```

Expected: Journey animation works in production

**Step 5: Generate QR code for testing**

Use any QR generator with URL:
```
https://mediku-journey-web.vercel.app/journey?patient_id=patient-001
```

Scan with phone to verify it opens correctly.

---

## Task 15: Final Documentation

**Files:**
- Create: `README.md` (update existing)

**Step 1: Update README**

```markdown
# Mediku Journey Web

Patient Health Journey Visualization - A Flutter Web application that displays animated patient health journeys via QR code.

## Features

- **4 Animated Chapters**: Profile, Metrics Timeline, Medical Journey, Current Snapshot
- **QR Code Sharing**: Each journey can be shared via generated QR code
- **Responsive Design**: Works on mobile and desktop
- **Static Data**: Patient data served via JSON files

## Demo URLs

- Patient 001: https://mediku-journey-web.vercel.app/journey?patient_id=patient-001
- Patient 002: https://mediku-journey-web.vercel.app/journey?patient_id=patient-002

## Development

```bash
# Install dependencies
flutter pub get

# Run locally
flutter run -d chrome

# Build for production
flutter build web --release

# Copy patient data
cp -r public/patients build/web/

# Deploy
vercel --prod
```

## Adding New Patients

1. Create JSON file in `public/patients/{patient-id}.json`
2. Follow schema in existing patient files
3. Redeploy: `vercel --prod`

## Data Schema

See design document at `.opencode/plans/2025-01-17-patient-journey-design.md`
```

**Step 2: Final commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README"
```

---

## Testing Checklist

Before marking complete, verify:

- [ ] All 4 chapters display with animations
- [ ] Page transitions work smoothly
- [ ] Charts render and animate correctly
- [ ] Timeline displays alternating cards
- [ ] QR code generates and displays
- [ ] Copy link button works
- [ ] Error handling works (invalid patient ID)
- [ ] Responsive on mobile (use Chrome DevTools)
- [ ] Production deployment loads correctly
- [ ] QR code scan opens correct journey

---

## Next Steps / Enhancements

1. Add more patient demo data
2. Implement auto-advance with pause on user interaction
3. Add sound effects for assembly animations
4. Create admin tool to generate patient JSON
5. Add analytics tracking
6. Implement video export feature
7. Add PWA offline support

---

**Plan complete! Ready for implementation.**
