# Multi-Profile Family Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement multi-profile support allowing unlimited family members per device with isolated health data

**Architecture:** Device-only SQLite storage with ProfileService singleton managing active profile state. Home Tab gets dropdown switcher, Profile Tab becomes family management center.

**Tech Stack:** Flutter, sqflite (SQLite), uuid

---

## Prerequisites

**Check pubspec.yaml dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  uuid: ^4.2.0
```

**Install dependencies:**
```bash
flutter pub add sqflite path uuid
```

---

## Task 1: Create Database Helper

**Files:**
- Create: `lib/services/database_helper.dart`

**Step 1: Write the database helper**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mediku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Family profiles table
    await db.execute('''
      CREATE TABLE family_profiles (
        id TEXT PRIMARY KEY,
        nik TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        blood_type TEXT,
        address TEXT,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Track active profile
    await db.execute('''
      CREATE TABLE app_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Health metrics per profile
    await db.execute('''
      CREATE TABLE health_metrics (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        metric_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES family_profiles(id)
      )
    ''');

    // Appointments per profile
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        FOREIGN KEY (profile_id) REFERENCES family_profiles(id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
```

**Step 2: Verify file created**

Check: `lib/services/database_helper.dart` exists with correct content

**Step 3: Commit**

```bash
git add lib/services/database_helper.dart
git commit -m "feat: add database helper with schema for multi-profile support"
```

---

## Task 2: Create FamilyProfile Model

**Files:**
- Create: `lib/models/family_profile.dart`

**Step 1: Write the model**

```dart
import 'dart:convert';

class FamilyProfile {
  final String id;
  final String nik;
  final String name;
  final String gender;
  final DateTime birthDate;
  final String? bloodType;
  final String? address;
  final String? phone;
  final DateTime createdAt;

  FamilyProfile({
    required this.id,
    required this.nik,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.bloodType,
    this.address,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
      'blood_type': bloodType,
      'address': address,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FamilyProfile.fromMap(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      nik: map['nik'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      bloodType: map['blood_type'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory FamilyProfile.fromJson(String source) =>
      FamilyProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get formattedNik {
    if (nik.length != 16) return nik;
    return '${nik.substring(0, 6)} **** **** ${nik.substring(12)}';
  }

  FamilyProfile copyWith({
    String? id,
    String? nik,
    String? name,
    String? gender,
    DateTime? birthDate,
    String? bloodType,
    String? address,
    String? phone,
    DateTime? createdAt,
  }) {
    return FamilyProfile(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**Step 2: Verify file created**

Check: `lib/models/family_profile.dart` exists

**Step 3: Commit**

```bash
git add lib/models/family_profile.dart
git commit -m "feat: add FamilyProfile model"
```

---

## Task 3: Create ProfileService

**Files:**
- Create: `lib/services/profile_service.dart`

**Step 1: Write the service**

```dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/family_profile.dart';
import 'database_helper.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  final _uuid = const Uuid();
  FamilyProfile? _activeProfile;
  List<FamilyProfile> _profiles = [];

  final _activeProfileController = StreamController<FamilyProfile?>.broadcast();
  Stream<FamilyProfile?> get activeProfileStream => _activeProfileController.stream;

  final _profilesController = StreamController<List<FamilyProfile>>.broadcast();
  Stream<List<FamilyProfile>> get profilesStream => _profilesController.stream;

  FamilyProfile? get activeProfile => _activeProfile;
  List<FamilyProfile> get profiles => List.unmodifiable(_profiles);

  Future<void> initialize() async {
    await _loadProfiles();
    await _loadActiveProfile();
  }

  Future<void> _loadProfiles() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('family_profiles', orderBy: 'created_at DESC');
    _profiles = maps.map((map) => FamilyProfile.fromMap(map)).toList();
    _profilesController.add(_profiles);
  }

  Future<void> _loadActiveProfile() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'app_state',
      where: 'key = ?',
      whereArgs: ['active_profile_id'],
    );

    if (result.isNotEmpty) {
      final activeId = result.first['value'] as String;
      _activeProfile = _profiles.firstWhere(
        (p) => p.id == activeId,
        orElse: () => _profiles.isNotEmpty ? _profiles.first : null!,
      );
    } else if (_profiles.isNotEmpty) {
      _activeProfile = _profiles.first;
      await _saveActiveProfileId(_activeProfile!.id);
    }

    _activeProfileController.add(_activeProfile);
  }

  Future<void> _saveActiveProfileId(String profileId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'app_state',
      {'key': 'active_profile_id', 'value': profileId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setActiveProfile(String profileId) async {
    final profile = _profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );

    _activeProfile = profile;
    await _saveActiveProfileId(profileId);
    _activeProfileController.add(_activeProfile);
  }

  Future<FamilyProfile> createProfile({
    required String nik,
    required String name,
    required String gender,
    required DateTime birthDate,
    String? bloodType,
    String? address,
    String? phone,
  }) async {
    final profile = FamilyProfile(
      id: _uuid.v4(),
      nik: nik,
      name: name,
      gender: gender,
      birthDate: birthDate,
      bloodType: bloodType,
      address: address,
      phone: phone,
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('family_profiles', profile.toMap());

    await _loadProfiles();

    // If this is the first profile, set it as active
    if (_profiles.length == 1) {
      await setActiveProfile(profile.id);
    }

    return profile;
  }

  Future<void> updateProfile(FamilyProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'family_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );

    await _loadProfiles();

    // Update active profile if it was changed
    if (_activeProfile?.id == profile.id) {
      _activeProfile = profile;
      _activeProfileController.add(_activeProfile);
    }
  }

  Future<void> deleteProfile(String profileId) async {
    final db = await DatabaseHelper.instance.database;
    
    // Delete related data first
    await db.delete('health_metrics', where: 'profile_id = ?', whereArgs: [profileId]);
    await db.delete('appointments', where: 'profile_id = ?', whereArgs: [profileId]);
    await db.delete('family_profiles', where: 'id = ?', whereArgs: [profileId]);

    await _loadProfiles();

    // If we deleted the active profile, switch to another one
    if (_activeProfile?.id == profileId) {
      if (_profiles.isNotEmpty) {
        await setActiveProfile(_profiles.first.id);
      } else {
        _activeProfile = null;
        _activeProfileController.add(null);
      }
    }
  }

  Future<bool> hasProfiles() async {
    if (_profiles.isEmpty) {
      await _loadProfiles();
    }
    return _profiles.isNotEmpty;
  }

  Future<void> createDefaultProfile() async {
    // Create a default profile from the current hardcoded data
    await createProfile(
      nik: '3375011234567890',
      name: 'Pak Budi Santoso',
      gender: 'Pria',
      birthDate: DateTime(1959, 1, 1), // Age 65
      bloodType: 'O+',
      address: 'Desa Ngemplak, Kecamatan Simokerto',
      phone: '081234567890',
    );
  }

  void dispose() {
    _activeProfileController.close();
    _profilesController.close();
  }
}
```

**Step 2: Verify file created**

Check: `lib/services/profile_service.dart` exists

**Step 3: Commit**

```bash
git add lib/services/profile_service.dart
git commit -m "feat: add ProfileService for managing family profiles"
```

---

## Task 4: Initialize Database on App Startup

**Files:**
- Modify: `lib/main.dart` (entire file)

**Step 1: Update main.dart to initialize ProfileService**

Find the existing main.dart and modify it:

```dart
import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize profile service
  await ProfileService.instance.initialize();
  
  // If no profiles exist, create default profile
  if (!await ProfileService.instance.hasProfiles()) {
    await ProfileService.instance.createDefaultProfile();
  }
  
  runApp(const MedikuApp());
}

class MedikuApp extends StatelessWidget {
  const MedikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mediku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
```

**Step 2: Verify app still runs**

```bash
flutter run
```

Expected: App launches without errors

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize ProfileService on app startup with default profile"
```

---

## Task 5: Create Profile Selector Widget

**Files:**
- Create: `lib/widgets/profile_selector.dart`

**Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/family_profile.dart';
import '../services/profile_service.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        
        if (activeProfile == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _showProfileSwitcher(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surface, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeProfile.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ProfileSwitcherSheet(),
    );
  }
}

class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Pilih Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Profile list
            StreamBuilder<List<FamilyProfile>>(
              stream: ProfileService.instance.profilesStream,
              initialData: ProfileService.instance.profiles,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? [];
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _ProfileListTile(profile: profile);
                  },
                );
              },
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to add profile screen (will be created later)
                    _showAddProfileDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Anggota Keluarga'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    // For now, just show a snackbar - actual dialog in next task
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur tambah profil akan segera hadir')),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final FamilyProfile profile;

  const _ProfileListTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        final isActive = activeProfile?.id == profile.id;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          title: Text(
            profile.name,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            profile.formattedNik,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
          onTap: () async {
            await ProfileService.instance.setActiveProfile(profile.id);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
```

**Step 2: Verify file created**

Check: `lib/widgets/profile_selector.dart` exists

**Step 3: Commit**

```bash
git add lib/widgets/profile_selector.dart
git commit -m "feat: add ProfileSelector widget with bottom sheet"
```

---

## Task 6: Update Home Tab with Profile Selector

**Files:**
- Modify: `lib/screens/patient/tabs/home_tab.dart` (greeting section)

**Step 1: Import ProfileSelector**

Add import at top:
```dart
import '../../../widgets/profile_selector.dart';
```

**Step 2: Replace greeting section with profile selector**

Find the greeting section (around line 118-145) and replace:

**OLD:**
```dart
// Greeting Section
Container(
  margin: EdgeInsets.symmetric(
    horizontal: math.max(ResponsiveSize.paddingMedium, 16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _getGreeting(),
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: math.min(ResponsiveSize.fontMedium, 16),
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '$userName!',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: math.min(ResponsiveSize.fontXXLarge, 28),
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    ],
  ),
),
```

**NEW:**
```dart
// Greeting Section with Profile Selector
Container(
  margin: EdgeInsets.symmetric(
    horizontal: math.max(ResponsiveSize.paddingMedium, 16),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: math.min(ResponsiveSize.fontMedium, 16),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          StreamBuilder<FamilyProfile?>(
            stream: ProfileService.instance.activeProfileStream,
            initialData: ProfileService.instance.activeProfile,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final displayName = profile?.name.split(' ').first ?? userName;
              return Text(
                '$displayName!',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: math.min(ResponsiveSize.fontXXLarge, 28),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      const ProfileSelector(),
    ],
  ),
),
```

**Step 3: Add imports needed**

```dart
import '../../../services/profile_service.dart';
import '../../../models/family_profile.dart';
```

**Step 4: Update metrics to use dynamic user data**

Find the metrics section (around line 95) and make it use active profile:

**OLD:**
```dart
// Mock user data - in real app, this comes from user profile
const userAge = 45;
const userGender = 'Pria';
const userName = 'Pak Budi';

final metrics = HealthMetricData.getMockMetrics(
  age: userAge,
  gender: userGender,
);
```

**NEW:**
```dart
// Use active profile data
StreamBuilder<FamilyProfile?>(
  stream: ProfileService.instance.activeProfileStream,
  initialData: ProfileService.instance.activeProfile,
  builder: (context, snapshot) {
    final profile = snapshot.data;
    final userAge = profile?.age ?? 45;
    final userGender = profile?.gender ?? 'Pria';
    final userName = profile?.name.split(' ').first ?? 'Pak Budi';

    final metrics = HealthMetricData.getMockMetrics(
      age: userAge,
      gender: userGender,
    );
    
    // Rest of the build method continues here...
```

**Note:** This requires restructuring the build method to use StreamBuilder at the top level. The complete modified file would be:

```dart
// ... imports ...

class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  // Mock appointment data
  final Map<String, dynamic> _nextAppointment = {
    'title': 'Medical Screening',
    'date': DateTime.now().add(const Duration(days: 5)),
    'location': 'Balai Desa Sukamaju',
  };

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  int _getDaysUntilAppointment() {
    final appointmentDate = _nextAppointment['date'] as DateTime;
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);
    return difference.inDays;
  }

  bool _shouldShowAppointmentBanner() {
    return _getDaysUntilAppointment() <= 7 && _getDaysUntilAppointment() >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final userAge = profile?.age ?? 45;
        final userGender = profile?.gender ?? 'Pria';
        final userName = profile?.name.split(' ').first ?? 'Pak Budi';

        final metrics = HealthMetricData.getMockMetrics(
          age: userAge,
          gender: userGender,
        );

        final daysUntilAppointment = _getDaysUntilAppointment();
        final showAppointmentBanner = _shouldShowAppointmentBanner();

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 16),

                      // Greeting Section with Profile Selector
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: math.max(ResponsiveSize.paddingMedium, 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: math.min(ResponsiveSize.fontMedium, 16),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$userName!',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: math.min(ResponsiveSize.fontXXLarge, 28),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const ProfileSelector(),
                          ],
                        ),
                      ),

                      // ... rest of the widget tree continues ...
```

**Step 5: Test the app**

```bash
flutter run
```

Expected:
- Home tab shows "Pak Budi!" greeting
- Profile selector button visible in header
- Tapping selector shows bottom sheet with profiles
- Can see "Pak Budi Santoso" in the list

**Step 6: Commit**

```bash
git add lib/screens/patient/tabs/home_tab.dart
git commit -m "feat: add ProfileSelector to Home Tab header"
```

---

## Task 7: Redesign Profile Tab for Family Management

**Files:**
- Modify: `lib/screens/patient/tabs/profil_tab.dart` (entire file)

**Step 1: Replace entire profil_tab.dart**

```dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/family_profile.dart';
import '../../../services/profile_service.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final spacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<FamilyProfile>>(
          stream: ProfileService.instance.profilesStream,
          initialData: ProfileService.instance.profiles,
          builder: (context, snapshot) {
            final profiles = snapshot.data ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: spacing),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anggota Keluarga',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profiles.length} anggota terdaftar',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profiles.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing * 2),

                    // Active Profile Card
                    StreamBuilder<FamilyProfile?>(
                      stream: ProfileService.instance.activeProfileStream,
                      initialData: ProfileService.instance.activeProfile,
                      builder: (context, snapshot) {
                        final activeProfile = snapshot.data;
                        if (activeProfile == null) return const SizedBox.shrink();

                        return _buildActiveProfileCard(
                          activeProfile,
                          screenWidth,
                          padding,
                          spacing,
                          context,
                        );
                      },
                    ),

                    SizedBox(height: spacing * 2),

                    // Family Members List
                    Text(
                      'Semua Anggota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: spacing),

                    // List of all profiles
                    ...profiles.map((profile) => _buildProfileListItem(
                      profile,
                      screenWidth,
                      padding,
                      spacing,
                      context,
                    )),

                    SizedBox(height: spacing * 2),

                    // Add Family Member Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddProfileDialog(context),
                        icon: Icon(
                          Icons.person_add,
                          size: 20,
                          color: AppColors.textOnPrimary,
                        ),
                        label: Text(
                          'Tambah Anggota Keluarga',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    SizedBox(height: spacing),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveProfileCard(
    FamilyProfile profile,
    double screenWidth,
    double padding,
    double spacing,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PROFIL AKTIF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          SizedBox(height: spacing),
          Container(
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.person,
              size: screenWidth * 0.07,
              color: AppColors.textOnPrimary,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NIK: ${profile.formattedNik}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip('${profile.age} Tahun', Icons.cake),
              const SizedBox(width: 8),
              _buildInfoChip(profile.gender, profile.gender == 'Pria' ? Icons.male : Icons.female),
              if (profile.bloodType != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(profile.bloodType!, Icons.water_drop),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileListItem(
    FamilyProfile profile,
    double screenWidth,
    double padding,
    double spacing,
    BuildContext context,
  ) {
    return StreamBuilder<FamilyProfile?>(
      stream: ProfileService.instance.activeProfileStream,
      initialData: ProfileService.instance.activeProfile,
      builder: (context, snapshot) {
        final activeProfile = snapshot.data;
        final isActive = activeProfile?.id == profile.id;

        return Container(
          margin: EdgeInsets.only(bottom: spacing),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showProfileOptions(context, profile, isActive),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(padding * 0.75),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 2)
                      : Border.all(color: AppColors.surface, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: padding * 0.75),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'AKTIF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.formattedNik,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.age} tahun • ${profile.gender}${profile.bloodType != null ? ' • ${profile.bloodType}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileOptions(BuildContext context, FamilyProfile profile, bool isActive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.switch_account, color: AppColors.primary),
                title: Text(
                  isActive ? 'Profil Aktif' : 'Pilih Profil Ini',
                  style: TextStyle(color: isActive ? AppColors.primary : AppColors.textPrimary),
                ),
                trailing: isActive ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () async {
                  if (!isActive) {
                    await ProfileService.instance.setActiveProfile(profile.id);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.textSecondary),
                title: const Text('Edit Profil'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(context, profile);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text('Hapus Profil', style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, profile);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Anggota Keluarga'),
        content: const Text('Fitur ini akan segera hadir. Untuk saat ini, gunakan data default yang sudah tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, FamilyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: const Text('Fitur edit profil akan segera hadir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FamilyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Profil'),
        content: Text('Apakah Anda yakin ingin menghapus profil ${profile.name}? Semua data terkait akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await ProfileService.instance.deleteProfile(profile.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil ${profile.name} telah dihapus')),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Test the app**

```bash
flutter run
```

Expected:
- Profile tab shows "Anggota Keluarga" header
- Active profile displayed prominently with badge
- List of all family members below
- Tap any profile to see options
- Can switch profile or delete (edit coming later)

**Step 3: Commit**

```bash
git add lib/screens/patient/tabs/profil_tab.dart
git commit -m "feat: redesign Profile Tab for family management"
```

---

## Task 8: Create Add Profile Screen

**Files:**
- Create: `lib/screens/patient/add_profile_screen.dart`
- Modify: `lib/widgets/profile_selector.dart` (update navigation)

**Step 1: Create AddProfileScreen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/profile_service.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedGender = 'Pria';
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Anggota',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan data anggota keluarga',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // NIK
              _buildTextField(
                controller: _nikController,
                label: 'NIK',
                hint: 'Masukkan 16 digit NIK',
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIK wajib diisi';
                  }
                  if (value.length != 16) {
                    return 'NIK harus 16 digit';
                  }
                  return null;
                },
              ),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),

              // Gender
              _buildLabel('Jenis Kelamin'),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption('Pria', Icons.male),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption('Wanita', Icons.female),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Birth Date
              _buildLabel('Tanggal Lahir'),
              InkWell(
                onTap: _selectBirthDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Pilih tanggal lahir',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedBirthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Blood Type
              _buildLabel('Golongan Darah'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodTypes.map((type) {
                  final isSelected = _selectedBloodType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBloodType = selected ? type : null;
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Alamat',
                hint: 'Masukkan alamat lengkap',
                maxLines: 3,
              ),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Nomor Telepon',
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines ?? 1,
          validator: validator,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ProfileService.instance.createProfile(
        nik: _nikController.text,
        name: _nameController.text,
        gender: _selectedGender,
        birthDate: _selectedBirthDate!,
        bloodType: _selectedBloodType,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

**Step 2: Update ProfileSelector navigation**

In `lib/widgets/profile_selector.dart`, find `_showAddProfileDialog` method and replace:

**OLD:**
```dart
void _showAddProfileDialog(BuildContext context) {
  // For now, just show a snackbar - actual dialog in next task
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fitur tambah profil akan segera hadir')),
  );
}
```

**NEW:**
```dart
void _showAddProfileDialog(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AddProfileScreen()),
  );
}
```

Also add import at top:
```dart
import '../screens/patient/add_profile_screen.dart';
```

**Step 3: Test the app**

```bash
flutter run
```

Expected:
- Can navigate to Add Profile screen from both Home Tab selector and Profile Tab
- Form validation works
- Can add new family member
- New profile appears in list immediately

**Step 4: Commit**

```bash
git add lib/screens/patient/add_profile_screen.dart lib/widgets/profile_selector.dart
git commit -m "feat: add AddProfileScreen for creating new family members"
```

---

## Task 9: Create Edit Profile Screen

**Files:**
- Create: `lib/screens/patient/edit_profile_screen.dart`
- Modify: `lib/screens/patient/tabs/profil_tab.dart` (update navigation)

**Step 1: Create EditProfileScreen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/family_profile.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final FamilyProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nikController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  
  late String _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _nikController = TextEditingController(text: widget.profile.nik);
    _nameController = TextEditingController(text: widget.profile.name);
    _addressController = TextEditingController(text: widget.profile.address ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _selectedGender = widget.profile.gender;
    _selectedBloodType = widget.profile.bloodType;
    _selectedBirthDate = widget.profile.birthDate;
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ubah data profil ${widget.profile.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // NIK (read-only)
              _buildTextField(
                controller: _nikController,
                label: 'NIK',
                hint: 'Masukkan 16 digit NIK',
                keyboardType: TextInputType.number,
                maxLength: 16,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIK wajib diisi';
                  }
                  if (value.length != 16) {
                    return 'NIK harus 16 digit';
                  }
                  return null;
                },
              ),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),

              // Gender
              _buildLabel('Jenis Kelamin'),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption('Pria', Icons.male),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption('Wanita', Icons.female),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Birth Date
              _buildLabel('Tanggal Lahir'),
              InkWell(
                onTap: _selectBirthDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Pilih tanggal lahir',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedBirthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Blood Type
              _buildLabel('Golongan Darah'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodTypes.map((type) {
                  final isSelected = _selectedBloodType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBloodType = selected ? type : null;
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Alamat',
                hint: 'Masukkan alamat lengkap',
                maxLines: 3,
              ),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Nomor Telepon',
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines ?? 1,
          readOnly: readOnly,
          validator: validator,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? AppColors.surface : AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        name: _nameController.text,
        gender: _selectedGender,
        birthDate: _selectedBirthDate!,
        bloodType: _selectedBloodType,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      await ProfileService.instance.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

**Step 2: Update profil_tab.dart navigation**

In `lib/screens/patient/tabs/profil_tab.dart`, find `_showEditProfileDialog` and replace:

**OLD:**
```dart
void _showEditProfileDialog(BuildContext context, FamilyProfile profile) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Profil'),
      content: const Text('Fitur edit profil akan segera hadir.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

**NEW:**
```dart
void _showEditProfileDialog(BuildContext context, FamilyProfile profile) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditProfileScreen(profile: profile),
    ),
  );
}
```

Add import at top:
```dart
import '../edit_profile_screen.dart';
```

**Step 3: Test the app**

```bash
flutter run
```

Expected:
- Can navigate to Edit Profile screen
- All existing data pre-filled
- Can modify any field (except NIK)
- Changes saved and reflected immediately

**Step 4: Commit**

```bash
git add lib/screens/patient/edit_profile_screen.dart lib/screens/patient/tabs/profil_tab.dart
git commit -m "feat: add EditProfileScreen for modifying family member data"
```

---

## Task 10: Final Testing and Verification

**Step 1: Full app test**

Run the app and verify:

1. ✅ App launches without errors
2. ✅ Home Tab shows profile selector in header
3. ✅ Tapping selector shows all family profiles
4. ✅ Can switch between profiles
5. ✅ Home Tab updates to show selected profile's name
6. ✅ Profile Tab shows active profile prominently
7. ✅ Profile Tab lists all family members
8. ✅ Can add new family member
9. ✅ Can edit existing profile
10. ✅ Can delete profile with confirmation
11. ✅ Data persists after app restart
12. ✅ Each profile has isolated data (metrics use correct age/gender)

**Step 2: Verify database persistence**

Close and reopen app - profiles should still be there.

**Step 3: Run Flutter analyze**

```bash
flutter analyze
```

Expected: No critical errors

**Step 4: Final commit**

```bash
git add .
git commit -m "feat: complete multi-profile family support implementation"
```

---

## Summary

The multi-profile feature is now complete with:

- ✅ SQLite database for local storage
- ✅ ProfileService singleton for state management
- ✅ Profile selector in Home Tab header
- ✅ Family management in Profile Tab
- ✅ Add/Edit/Delete profile functionality
- ✅ Data isolation per profile
- ✅ Full offline support
- ✅ Clean architecture ready for future backend integration

**Next Steps (Phase 2):**
- Add profile photos/avatars
- Implement per-profile health metric history in database
- Add biometric authentication per profile
- Backend sync with device registration
