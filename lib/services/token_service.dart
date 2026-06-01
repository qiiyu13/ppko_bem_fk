import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _kkKey = 'kk_number';
  static const _responsibleNameKey = 'responsible_name';
  static const _roleKey = 'user_role';

  // In-memory caches. Secure-storage reads hit the platform keychain/keystore
  // and are slow (notably on Android); the request interceptor reads the token
  // on every call, so cache it after the first read.
  static String? _cachedToken;
  static bool _tokenLoaded = false;
  static String? _cachedRole;
  static bool _roleLoaded = false;

  static Future<void> setToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    _tokenLoaded = true;
    return _cachedToken;
  }

  static Future<void> setKKNumber(String kk) async =>
      await _storage.write(key: _kkKey, value: kk);

  static Future<String?> getKKNumber() async =>
      await _storage.read(key: _kkKey);

  static Future<void> setResponsibleName(String name) async =>
      await _storage.write(key: _responsibleNameKey, value: name);

  static Future<String?> getResponsibleName() async =>
      await _storage.read(key: _responsibleNameKey);

  // Cached role enables optimistic, network-free routing on relaunch.
  static Future<void> setRole(String role) async {
    _cachedRole = role;
    _roleLoaded = true;
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    if (_roleLoaded) return _cachedRole;
    _cachedRole = await _storage.read(key: _roleKey);
    _roleLoaded = true;
    return _cachedRole;
  }

  static Future<void> clearAll() async {
    _cachedToken = null;
    _tokenLoaded = true; // known-empty; avoids a redundant storage read
    _cachedRole = null;
    _roleLoaded = true;
    await _storage.deleteAll();
  }
}
