import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'api_service.dart';

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
    return results ?? [];
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
        await ApiService.request(
          item['method'] as String,
          item['endpoint'] as String,
        );
        await _db?.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
      } catch (_) {
        break;
      }
    }
  }
}
