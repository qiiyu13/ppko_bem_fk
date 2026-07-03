import 'dart:convert';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class CacheService {
  static Database? _db;

  // Persistent store for GET responses so cold start and bad-network requests
  // can render from disk instead of hanging on the network.
  static const _httpCacheTableSql = '''
    CREATE TABLE IF NOT EXISTS http_cache (
      key TEXT PRIMARY KEY,
      body TEXT NOT NULL,
      status INTEGER NOT NULL,
      expires_at TEXT NOT NULL
    )
  ''';

  static Future<void> init() async {
    // sqflite has no web implementation. Leaving _db null is safe: every
    // method below is a null-aware no-op, so the web build runs cache-less
    // and always hits the network.
    if (kIsWeb) return;

    if (Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _db = await openDatabase(
      join(await getDatabasesPath(), 'mediku_cache.db'),
      version: 3,
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
          CREATE TABLE pending_sync (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE articles (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE appointments (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            data TEXT NOT NULL,
            synced INTEGER DEFAULT 1,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(_httpCacheTableSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(_httpCacheTableSql);
        }
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS articles (
              id TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS appointments (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              data TEXT NOT NULL,
              synced INTEGER DEFAULT 1,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<void> saveProfile(String id, String data) async {
    await _db?.insert('profiles', {
      'id': id,
      'data': data,
      'synced': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final results = await _db?.query('profiles', orderBy: 'updated_at DESC');
    return results?.map((row) {
      final String dataStr = row['data'] as String;
      return jsonDecode(dataStr) as Map<String, dynamic>;
    }).toList() ?? [];
  }

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> saveArticles(List<Map<String, dynamic>> articles) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final article in articles) {
      batch.insert('articles', {
        'id': article['id'],
        'data': jsonEncode(article),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getArticles() async {
    final results = await _db?.query('articles', orderBy: 'updated_at DESC');
    return results?.map((row) {
      final String dataStr = row['data'] as String;
      return jsonDecode(dataStr) as Map<String, dynamic>;
    }).toList() ?? [];
  }

  static Future<void> saveAppointment(String id, Map<String, dynamic> data) async {
    await _db?.insert('appointments', {
      'id': id,
      'user_id': data['userId'] ?? '',
      'data': jsonEncode(data),
      'synced': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAppointments() async {
    final results = await _db?.query('appointments', orderBy: 'updated_at DESC');
    return results?.map((row) {
      final String dataStr = row['data'] as String;
      return jsonDecode(dataStr) as Map<String, dynamic>;
    }).toList() ?? [];
  }

  static Future<void> queueSync(String endpoint, String method, Map<String, dynamic> data) async {
    await _db?.insert('pending_sync', {
      'endpoint': endpoint,
      'method': method,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> processSyncQueue() async {
    if (!await isOnline()) return 0;

    final pending = await _db?.query('pending_sync', orderBy: 'created_at ASC');
    if (pending == null || pending.isEmpty) return 0;

    int synced = 0;
    for (final item in pending) {
      try {
        final String dataStr = item['data'] as String? ?? '{}';
        final Map<String, dynamic> data = jsonDecode(dataStr);
        await ApiService.request(
          item['method'] as String,
          item['endpoint'] as String,
          data: data.isNotEmpty ? data : null,
        );
        await _db?.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
        synced++;
      } catch (e) {
        final statusCode = e is DioException ? e.response?.statusCode : null;
        if (statusCode == 409) {
          // Conflict - server has newer data, drop this sync item (server wins)
          await _db?.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
        } else if (statusCode == 404) {
          // Resource deleted on server, drop this sync item
          await _db?.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
        } else if (statusCode == 401) {
          // Auth expired, stop syncing - user needs to re-login
          break;
        }
        // Other errors: keep item in queue for next sync attempt
      }
    }
    return synced;
  }

  static Future<int> getPendingSyncCount() async {
    final result = await _db?.rawQuery('SELECT COUNT(*) as count FROM pending_sync');
    return (result?.first['count'] as int?) ?? 0;
  }

  static Future<void> saveHttpCache(
      String key, String body, int status, DateTime expiresAt) async {
    await _db?.insert('http_cache', {
      'key': key,
      'body': body,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns {body, status, expiresAt} for a cached GET, or null if absent.
  static Future<Map<String, dynamic>?> getHttpCache(String key) async {
    final rows = await _db?.query('http_cache',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows == null || rows.isEmpty) return null;
    final row = rows.first;
    return {
      'body': row['body'] as String,
      'status': row['status'] as int,
      'expiresAt': DateTime.parse(row['expires_at'] as String),
    };
  }

  /// Drops every persisted GET whose key starts with [prefix] (e.g. '/profiles'),
  /// so a write is never followed by a stale offline read.
  static Future<void> invalidateHttpCache(String prefix) async {
    await _db?.delete('http_cache', where: 'key LIKE ?', whereArgs: ['$prefix%']);
  }

  static Future<void> clearAll() async {
    await _db?.delete('profiles');
    await _db?.delete('articles');
    await _db?.delete('appointments');
    await _db?.delete('pending_sync');
    await _db?.delete('http_cache');
  }
}
