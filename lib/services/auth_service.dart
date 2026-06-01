import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'token_service.dart';
import 'websocket_service.dart';

class AuthService {
  static final ValueNotifier<int> avatarRevision = ValueNotifier<int>(0);

  static Future<Map<String, dynamic>> register({
    required String kkNumber,
    required String responsibleName,
    required String password,
    String? phone,
    String? villageId,
    int? rwNumber,
    int? rtNumber,
  }) async {
    final response = await ApiService.post('/auth/register', data: {
      'kkNumber': kkNumber,
      'responsibleName': responsibleName,
      'password': password,
      'phone': phone,
      if (villageId != null) 'villageId': villageId,
      if (rwNumber != null) 'rwNumber': rwNumber,
      if (rtNumber != null) 'rtNumber': rtNumber,
    });

    final data = response.data['data'];
    await TokenService.setToken(data['token']);
    await TokenService.setKKNumber(kkNumber);
    await TokenService.setResponsibleName(responsibleName);
    // Registration always creates a patient account.
    await TokenService.setRole(data['user']?['role'] ?? 'PATIENT');
    // Don't seed _cachedMe from the register response — it lacks the full
    // /auth/me fields (avatarPath, region, ...). Let getMe() fetch them.

    WebSocketService.instance.connect();

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });

    final data = response.data['data'];
    final user = data['user'] as Map<String, dynamic>;
    await TokenService.setToken(data['token']);
    await TokenService.setKKNumber(identifier);
    await TokenService.setResponsibleName(user['responsibleName']);
    await TokenService.setRole(user['role'] ?? 'PATIENT');

    // NOTE: do NOT seed _cachedMe with this login `user` — it is a thin object
    // ({id,kkNumber,username,responsibleName,role}) missing avatarPath/phone/
    // region/etc. that /auth/me returns. Seeding it makes the account render
    // blank until app restart. Let the first getMe() fetch the full record.

    WebSocketService.instance.connect();

    return data;
  }

  static Map<String, dynamic>? _cachedMe;

  static String? userAvatarUrl(Map<String, dynamic>? user) {
    final path = user?['avatarPath'] as String?;
    if (path == null || path.isEmpty) return null;
    return '${Env.serverBaseUrl}$path';
  }

  static Future<Map<String, dynamic>?> getMe({bool force = false}) async {
    if (!force && _cachedMe != null) return _cachedMe;
    try {
      final response = await ApiService.get('/auth/me');
      _cachedMe = response.data['data'] as Map<String, dynamic>?;
      final role = _cachedMe?['role'];
      if (role is String) {
        // Keep cached role fresh so the next relaunch routes without a network call.
        await TokenService.setRole(role);
      }
      return _cachedMe;
    } catch (e) {
      return _cachedMe;
    }
  }

  static Future<String> updatePicture(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });
    final response = await ApiService.dio.put('/auth/me/picture', data: formData);
    final data = response.data?['data'] as Map<String, dynamic>?;
    final avatarPath = data?['avatarPath'] as String?;
    if (avatarPath == null) {
      throw Exception('Gagal upload foto: respons server tidak valid');
    }
    _cachedMe?['avatarPath'] = avatarPath;
    avatarRevision.value++;
    return avatarPath;
  }

  static Future<bool> isLoggedIn() async {
    final token = await TokenService.getToken();
    if (token == null) return false;
    final user = await getMe();
    return user != null;
  }

  static Future<void> logout() async {
    // Server logout is best-effort and must NOT block the UI. Capture the token
    // and fire the request unawaited so the user leaves instantly even if the
    // network is slow or offline.
    final token = await TokenService.getToken();
    if (token != null) {
      unawaited(_fireServerLogout(token));
    }
    WebSocketService.instance.disconnect();
    _cachedMe = null;
    await NotificationService.clearCache();
    await TokenService.clearAll();
  }

  static Future<void> _fireServerLogout(String token) async {
    try {
      await ApiService.dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // Token is cleared locally regardless; ignore network failures.
    }
  }

  static Future<bool> forgotPassword({
    required String kkNumber,
    required String phone,
  }) async {
    try {
      await ApiService.post('/auth/forgot-password', data: {
        'kkNumber': kkNumber,
        'phone': phone,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword({
    required String kkNumber,
    required String firebaseToken,
    required String newPassword,
  }) async {
    try {
      await ApiService.post('/auth/reset-password', data: {
        'kkNumber': kkNumber,
        'firebaseToken': firebaseToken,
        'newPassword': newPassword,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
