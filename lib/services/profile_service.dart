import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/family_profile.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  FamilyProfile? _activeProfile;
  List<FamilyProfile> _profiles = [];

  final _activeProfileController = StreamController<FamilyProfile?>.broadcast();
  Stream<FamilyProfile?> get activeProfileStream =>
      _activeProfileController.stream;

  final _profilesController = StreamController<List<FamilyProfile>>.broadcast();
  Stream<List<FamilyProfile>> get profilesStream => _profilesController.stream;

  FamilyProfile? get activeProfile => _activeProfile;
  List<FamilyProfile> get profiles => List.unmodifiable(_profiles);

  Future<void> initialize() async {
    try {
      await _loadProfiles();
    } catch (e) {
      final cached = await CacheService.getProfiles();
      _profiles = cached.map((row) => FamilyProfile.fromJson(row['data'] as String)).toList();
      _profilesController.add(List.unmodifiable(_profiles));
      if (_activeProfile == null && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        _activeProfileController.add(_activeProfile);
      }
    }
  }

  Future<bool> isLoggedIn() async {
    return AuthService.isLoggedIn();
  }

  Future<void> setLoggedIn(bool value) async {
    if (!value) {
      await AuthService.logout();
      _profiles = [];
      _activeProfile = null;
      _profilesController.add(List.unmodifiable(_profiles));
      _activeProfileController.add(null);
      await CacheService.clearAll();
    }
  }

  Future<void> logout() async {
    await setLoggedIn(false);
  }

  Future<void> _loadProfiles() async {
    try {
      final response = await ApiService.get('/profiles');
      final data = response.data['data'] as List;
      _profiles = data.map((json) => FamilyProfile.fromMap(json as Map<String, dynamic>)).toList();
      _profilesController.add(List.unmodifiable(_profiles));

      for (final profile in _profiles) {
        await CacheService.saveProfile(profile.id, profile.toJson());
      }

      if (_activeProfile == null && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        _activeProfileController.add(_activeProfile);
      }
    } catch (e) {
      final cached = await CacheService.getProfiles();
      _profiles = cached.map((row) => FamilyProfile.fromJson(row['data'] as String)).toList();
      _profilesController.add(List.unmodifiable(_profiles));
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    final profile = _profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );
    _activeProfile = profile;
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
    final data = {
      'nik': nik,
      'name': name,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
      'bloodType': bloodType,
      'address': address,
      'phone': phone,
    };

    try {
      final response = await ApiService.post('/profiles', data: data);
      final profile = FamilyProfile.fromMap(response.data['data'] as Map<String, dynamic>);
      _profiles.add(profile);
      _profilesController.add(List.unmodifiable(_profiles));
      if (_profiles.length == 1) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      await CacheService.saveProfile(profile.id, profile.toJson());
      return profile;
    } catch (e) {
      final tempId = const Uuid().v4();
      final profile = FamilyProfile(
        id: tempId,
        nik: nik,
        name: name,
        gender: gender,
        birthDate: birthDate,
        bloodType: bloodType,
        address: address,
        phone: phone,
      );
      await CacheService.queueSync('/profiles', 'POST', data);
      _profiles.add(profile);
      _profilesController.add(List.unmodifiable(_profiles));
      if (_profiles.length == 1) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      return profile;
    }
  }

  Future<void> updateProfile(FamilyProfile profile) async {
    try {
      await ApiService.put('/profiles/${profile.id}', data: profile.toMap());
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      if (_activeProfile?.id == profile.id) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      await CacheService.saveProfile(profile.id, profile.toJson());
    } catch (e) {
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      await CacheService.queueSync('/profiles/${profile.id}', 'PUT', profile.toMap());
    }
  }

  Future<void> deleteProfile(String id) async {
    try {
      await ApiService.delete('/profiles/$id');
    } catch (e) {
      await CacheService.queueSync('/profiles/$id', 'DELETE', {});
    }
    _profiles.removeWhere((p) => p.id == id);
    _profilesController.add(List.unmodifiable(_profiles));
    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      _activeProfileController.add(_activeProfile);
    }
  }

  Future<bool> hasProfiles() async {
    if (_profiles.isEmpty) {
      await _loadProfiles();
    }
    return _profiles.isNotEmpty;
  }

  void dispose() {
    _activeProfileController.close();
    _profilesController.close();
  }
}
