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
      try {
        _activeProfile = _profiles.firstWhere((p) => p.id == activeId);
      } catch (e) {
        // Profile not found, use first available
        if (_profiles.isNotEmpty) {
          _activeProfile = _profiles.first;
        }
      }
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
