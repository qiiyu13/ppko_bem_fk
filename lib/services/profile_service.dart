import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../exceptions/sync_conflict_exception.dart';
import '../models/family_profile.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'websocket_service.dart';

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

  /// True when the last network load failed (UI shows cached data or error).
  bool lastLoadFailed = false;

  Future<void> reload() => _loadProfiles();

  StreamSubscription<Map<String, dynamic>>? _dataUpdateSubscription;

  Future<void> initialize() async {
    try {
      await _loadProfiles();
    } catch (e) {
      final cached = await CacheService.getProfiles();
      _profiles = cached
          .map((row) => FamilyProfile.fromJson(row['data'] as String))
          .toList();
      _profilesController.add(List.unmodifiable(_profiles));
      if (_activeProfile == null && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        _activeProfileController.add(_activeProfile);
      }
    }

    _dataUpdateSubscription?.cancel();
    _dataUpdateSubscription = WebSocketService.instance.dataUpdateStream.listen(
      (event) {
        if (event['type'] == 'profiles') {
          _loadProfiles();
        }
      },
    );
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
      ApiService.cacheInterceptor.clearAll();
      WebSocketService.instance.disconnect();
    }
  }

  Future<void> logout() async {
    await setLoggedIn(false);
  }

  Future<void> _loadProfiles() async {
    try {
      final response = await ApiService.get('/profiles');
      final data = response.data['data'] as List;
      _profiles = data
          .map((json) => FamilyProfile.fromApi(json as Map<String, dynamic>))
          .toList();
      lastLoadFailed = false;
      _profilesController.add(List.unmodifiable(_profiles));

      for (final profile in _profiles) {
        await CacheService.saveProfile(profile.id, profile.toJson());
      }

      if (_activeProfile != null &&
          !_profiles.any((p) => p.id == _activeProfile!.id)) {
        _activeProfile = null;
      }
      if (_activeProfile == null && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        _activeProfileController.add(_activeProfile);
      }
    } catch (e) {
      lastLoadFailed = true;
      final cached = await CacheService.getProfiles();
      _profiles = cached
          .map((row) => FamilyProfile.fromJson(row['data'] as String))
          .toList();
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
    String? nik,
    required String name,
    required String gender,
    required DateTime birthDate,
    String? bloodType,
    String? address,
    String? phone,
    File? avatar,
    Map<String, dynamic>? healthVariables,
  }) async {
    final base = <String, dynamic>{
      'nik': ?nik,
      'name': name,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
      'bloodType': bloodType,
      'address': address,
      'phone': phone,
      ...?healthVariables,
    };
    FormData formData;
    if (avatar != null) {
      formData = FormData.fromMap({
        ...base,
        'avatar': await MultipartFile.fromFile(avatar.path),
      });
    } else {
      formData = FormData.fromMap(base);
    }

    try {
      final response = await ApiService.post('/profiles', data: formData);
      final profile = FamilyProfile.fromApi(
        response.data['data'] as Map<String, dynamic>,
      );
      _profiles.add(profile);
      _profilesController.add(List.unmodifiable(_profiles));
      if (_profiles.length == 1) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      await CacheService.saveProfile(profile.id, profile.toJson());
      return profile;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data is Map
            ? (e.response!.data['error']?['message'] ??
                  e.response!.data['message'])
            : null;
        throw Exception(
          msg ?? 'Gagal membuat profil (${e.response?.statusCode})',
        );
      }
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
        education: healthVariables?['education'] as String?,
        occupation: healthVariables?['occupation'] as String?,
        maritalStatus: healthVariables?['maritalStatus'] as String?,
        income: (healthVariables?['income'] as num?)?.toDouble(),
        familyDiseaseHistory:
            healthVariables?['familyDiseaseHistory'] as String?,
        smokingStatus: healthVariables?['smokingStatus'] as String?,
        physicalActivity: healthVariables?['physicalActivity'] as String?,
        fruitConsumption: healthVariables?['fruitConsumption'] as String?,
        vegetableConsumption:
            healthVariables?['vegetableConsumption'] as String?,
        sweetFoodConsumption:
            healthVariables?['sweetFoodConsumption'] as String?,
        sweetDrinkConsumption:
            healthVariables?['sweetDrinkConsumption'] as String?,
        fattyFoodConsumption:
            healthVariables?['fattyFoodConsumption'] as String?,
        fastFoodConsumption: healthVariables?['fastFoodConsumption'] as String?,
        sleepDuration: (healthVariables?['sleepDuration'] as num?)?.toDouble(),
        medicationRoutine: healthVariables?['medicationRoutine'] as String?,
      );
      await CacheService.queueSync('/profiles', 'POST', base);
      _profiles.add(profile);
      _profilesController.add(List.unmodifiable(_profiles));
      if (_profiles.length == 1) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      return profile;
    }
  }

  Future<void> updateProfile(FamilyProfile profile, {File? avatar}) async {
    try {
      FormData formData;
      final map = profile.toApiMap();
      map['updatedAt'] = profile.updatedAt.toIso8601String();
      if (avatar != null) {
        formData = FormData.fromMap({
          ...map,
          'avatar': await MultipartFile.fromFile(avatar.path),
        });
      } else {
        formData = FormData.fromMap(map);
      }
      final response = await ApiService.put(
        '/profiles/${profile.id}',
        data: formData,
      );
      final saved = FamilyProfile.fromApi(
        response.data['data'] as Map<String, dynamic>,
      );
      final index = _profiles.indexWhere((p) => p.id == saved.id);
      if (index != -1) {
        _profiles[index] = saved;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      if (_activeProfile?.id == saved.id) {
        _activeProfile = saved;
        _activeProfileController.add(_activeProfile);
      }
      await CacheService.saveProfile(saved.id, saved.toJson());
    } on SyncConflictException {
      rethrow;
    } catch (_) {
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      await CacheService.queueSync('/profiles/${profile.id}', 'PUT', {
        ...profile.toApiMap(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      });
    }
  }

  Future<void> deleteProfile(String id, DateTime updatedAt) async {
    try {
      await ApiService.delete(
        '/profiles/$id',
        data: {'updatedAt': updatedAt.toIso8601String()},
      );
    } on SyncConflictException {
      rethrow;
    } catch (_) {
      await CacheService.queueSync('/profiles/$id', 'DELETE', {
        'updatedAt': updatedAt.toIso8601String(),
      });
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
    _dataUpdateSubscription?.cancel();
    _activeProfileController.close();
    _profilesController.close();
  }
}
