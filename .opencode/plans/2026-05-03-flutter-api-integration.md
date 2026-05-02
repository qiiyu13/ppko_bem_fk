# Flutter-Backend API Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Connect the Flutter frontend to the Express.js backend API, replacing local SQLite with REST API calls, implementing auto-login via JWT, offline support with sync queue, QR code-based patient check-in, and password-only admin access.

**Architecture:** Three-phase approach. Phase 1 builds auth connection (register/login/auto-login/logout + forgot password). Phase 2 adds offline cache + QR codes. Phase 3 connects all remaining screens to API endpoints and removes demo logic.

**Tech Stack:** Flutter (Dart), Dio HTTP client, Secure Storage, SQLite (cache), QR generation/scanning, Express.js backend (already built)

---

## Phase 1: Auth Integration

Goal: Replace mock login with real API auth. Register, login, auto-login with JWT, forgot password.

### Task A1: Add Flutter dependencies

**Files:**
- Modify: `pubspec.yaml`

```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.1
  intl: ^0.18.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.0
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3
```

Install with `flutter pub get`. Verify no errors.

### Task A2: Create API Service (Dio)

**Files:**
- Create: `lib/services/api_service.dart`

```dart
import 'package:dio/dio.dart';
import 'token_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static void setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await TokenService.clearAll();
          // Navigate to login — handled by observing auth state
        }
        handler.next(error);
      },
    ));
  }

  static Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  static Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  static Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  static Future<Response> delete(String path) =>
      dio.delete(path);
}
```

### Task A3: Create Token Service (Secure Storage)

**Files:**
- Create: `lib/services/token_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _kkKey = 'kk_number';
  static const _responsibleNameKey = 'responsible_name';

  static Future<void> setToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: _tokenKey);

  static Future<void> setKKNumber(String kk) async =>
      await _storage.write(key: _kkKey, value: kk);

  static Future<String?> getKKNumber() async =>
      await _storage.read(key: _kkKey);

  static Future<void> setResponsibleName(String name) async =>
      await _storage.write(key: _responsibleNameKey, value: name);

  static Future<String?> getResponsibleName() async =>
      await _storage.read(key: _responsibleNameKey);

  static Future<void> clearAll() async =>
      await _storage.deleteAll();
}
```

### Task A4: Create Auth Service

**Files:**
- Create: `lib/services/auth_service.dart`

```dart
import 'api_service.dart';
import 'token_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String kkNumber,
    required String responsibleName,
    required String password,
    String? phone,
  }) async {
    final response = await ApiService.post('/auth/register', data: {
      'kkNumber': kkNumber,
      'responsibleName': responsibleName,
      'password': password,
      'phone': phone,
    });

    final data = response.data['data'];
    await TokenService.setToken(data['token']);
    await TokenService.setKKNumber(kkNumber);
    await TokenService.setResponsibleName(responsibleName);

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String kkNumber,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', data: {
      'kkNumber': kkNumber,
      'password': password,
    });

    final data = response.data['data'];
    final user = data['user'];
    await TokenService.setToken(data['token']);
    await TokenService.setKKNumber(kkNumber);
    await TokenService.setResponsibleName(user['responsibleName']);

    return data;
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await ApiService.get('/auth/me');
      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await TokenService.getToken();
    if (token == null) return false;
    final user = await getMe();
    return user != null;
  }

  static Future<void> logout() async {
    await TokenService.clearAll();
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
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      await ApiService.post('/auth/reset-password', data: {
        'kkNumber': kkNumber,
        'resetCode': resetCode,
        'newPassword': newPassword,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### Task A5: Create Cache Service (Base for offline support)

**Files:**
- Create: `lib/services/cache_service.dart`

Implement skeleton with tables: `profiles`, `metrics`, `appointments`, `articles`, `pending_sync`.
Full implementation in Phase 2 — for Phase 1, just create the database and tables.

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CacheService {
  static Database? _db;

  static Future<void> init() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'mediku_cache.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            synced INTEGER DEFAULT 1,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE metrics (
            id TEXT PRIMARY KEY,
            profile_id TEXT NOT NULL,
            data TEXT NOT NULL,
            synced INTEGER DEFAULT 1,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_sync (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> saveProfile(String id, Map<String, dynamic> data) async {
    await _db?.insert('profiles', {
      'id': id,
      'data': data.toString(),
      'synced': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final results = await _db?.query('profiles', orderBy: 'updated_at DESC');
    return results?.map((r) => r).toList() ?? [];
  }

  static Future<void> queueSync(String endpoint, String method, Map<String, dynamic> data) async {
    await _db?.insert('pending_sync', {
      'endpoint': endpoint,
      'method': method,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> processSyncQueue() async {
    final pending = await _db?.query('pending_sync', orderBy: 'created_at ASC');
    if (pending == null || pending.isEmpty) return;

    for (final item in pending) {
      try {
        // Parse stored data string back to JSON
        final data = item['data'] as String;
        await ApiService.request(
          item['method'] as String,
          item['endpoint'] as String,
          data: data is Map ? data : null,
        );
        await _db?.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
      } catch (_) {
        break; // Stop queue — retry next time
      }
    }
  }
}
```

> Note: `ApiService.request(String method, ...)` needs to be added to `api_service.dart`.

### Task A6: Add Forgot Password Backend Endpoint

**Files:**
- Modify: `backend/src/modules/auth/auth.routes.js`
- Modify: `backend/src/modules/auth/auth.controller.js`
- Modify: `backend/src/modules/auth/auth.service.js`

**Add to auth.routes.js:**
```js
router.post('/forgot-password', [
  body('kkNumber').isString().matches(/^\d{16}$/),
  body('phone').isString().notEmpty(),
  validate,
], controller.forgotPassword);

router.post('/reset-password', [
  body('kkNumber').isString().matches(/^\d{16}$/),
  body('resetCode').isString().isLength({ min: 6, max: 6 }),
  body('newPassword').isString().isLength({ min: 6 }),
  validate,
], controller.resetPassword);
```

**Add to auth.service.js:**
```js
// Add ResetCode model to schema.prisma
// Use a simple in-memory map or DB table

const resetCodes = new Map(); // kkNumber -> { code, expiresAt }

const forgotPassword = async ({ kkNumber, phone }) => {
  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('KK number not found'), { statusCode: 404 });
  if (user.phone !== phone) throw Object.assign(new Error('Phone number does not match'), { statusCode: 400 });

  const code = String(Math.floor(100000 + Math.random() * 900000)); // 6-digit code
  resetCodes.set(kkNumber, { code, expiresAt: Date.now() + 15 * 60 * 1000 });

  console.log(`\n🔐 Reset code for ${kkNumber}: ${code}\n`); // Mock SMS
  return { message: 'Reset code sent via SMS (mock)' };
};

const resetPassword = async ({ kkNumber, resetCode, newPassword }) => {
  const stored = resetCodes.get(kkNumber);
  if (!stored) throw Object.assign(new Error('No reset code requested'), { statusCode: 400 });
  if (stored.code !== resetCode) throw Object.assign(new Error('Invalid reset code'), { statusCode: 400 });
  if (Date.now() > stored.expiresAt) throw Object.assign(new Error('Reset code expired'), { statusCode: 400 });

  const hashedPassword = await hashPassword(newPassword);
  await prisma.user.update({
    where: { kkNumber },
    data: { password: hashedPassword },
  });

  resetCodes.delete(kkNumber);
  return { message: 'Password reset successful' };
};
```

**Add to auth.controller.js:**
```js
const forgotPassword = async (req, res, next) => {
  try {
    const result = await authService.forgotPassword(req.body);
    return success(res, result);
  } catch (err) {
    if (err.statusCode === 404) return error(res, err.message, 404, 'NOT_FOUND');
    if (err.statusCode === 400) return error(res, err.message, 400, 'VALIDATION_ERROR');
    next(err);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const result = await authService.resetPassword(req.body);
    return success(res, result);
  } catch (err) {
    if (err.statusCode === 400) return error(res, err.message, 400, 'VALIDATION_ERROR');
    next(err);
  }
};

module.exports = { register, login, getMe, forgotPassword, resetPassword };
```

**Note:** For production, the reset code should be stored in a database table. For now, in-memory is fine since this is mock.

### Task A7: Rewrite WelcomeScreen

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

Replace hardcoded credentials with real API calls:
- On init: check `AuthService.isLoggedIn()` → auto-navigate to home
- If not logged in: show login form (KK + password)
- Remove hardcoded `VALID_PATIENT_NIK`
- Remove hardcoded `ADMIN_PASSCODE` / `SUPERADMIN_PASSCODE`
- Admin access: keep tap-heart-5-times → show admin login (same form, KK + password)
- Add "Forgot password" link → navigation to reset password screen
- Add "Register" link → navigation to register screen

### Task A8: Rewrite RegisterScreen

**Files:**
- Modify: `lib/screens/register_screen.dart`

Replace local-only registration with API call:
- Collect: `kkNumber`, `responsibleName`, `password`, `phone`
- POST /auth/register
- On success: store JWT, navigate to create profile prompt
- On error: show error message

### Task A9: Update main.dart

**Files:**
- Modify: `lib/main.dart`

Initialize services before running app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setupInterceptors();
  await CacheService.init();
  runApp(DevicePreview(enabled: true, builder: (_) => MedikuApp()));
}
```

### Task A10: Run backend forgot password migration

**Files:**
- Modify: `backend/prisma/schema.prisma`

**Changes:** Add ResetCode model to schema (for production). For Phase 1, in-memory is fine.

### Phase 1 Deliverables
- ✅ User can register with KK + password via API
- ✅ User can login with KK + password via API
- ✅ Auto-login with stored JWT on app open
- ✅ User stays logged in until explicit logout
- ✅ Admin login via tap-heart + KK + password
- ✅ Forgot password flow (mock SMS)
- ✅ Logout clears all stored data

### Phase 1 Verification
1. Register new account → verify token stored → auto-navigate to home
2. Close app, reopen → verify auto-login works
3. Logout → verify redirect to login
4. Login with new device → KK + password → verify JWT returned
5. Forgot password → enter KK + phone → see mock code in console → reset password → login with new password

---

## Phase 2: Offline Support + QR Codes

*(detailed in separate document)*

### Task P1: Full Cache Service Implementation
### Task P2: QR Code Generation on Profile
### Task P3: QR Scanner for Admin
### Task P4: Background Sync Queue
### Task P5: Offline Indicators

---

## Phase 3: Connect All Remaining Screens

*(detailed in separate document)*

### Task R1: Connect Profile Screens (CRUD via API)
### Task R2: Connect Health Metrics Screens
### Task R3: Connect Admin Dashboard
### Task R4: Connect Articles
### Task R5: Connect Medical Screenings
### Task R6: Remove All Demo/Hardcoded Logic
### Task R7: Error Handling & Edge Cases
### Task R8: Manual E2E Testing
