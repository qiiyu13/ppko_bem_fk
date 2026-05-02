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
