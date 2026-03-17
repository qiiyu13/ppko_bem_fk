import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

/// Database operation wrapper that handles both mobile (real SQLite) and web (mock)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  // Mock data storage for web
  final List<Map<String, dynamic>> _mockProfiles = [];
  final Map<String, String> _mockAppState = {};
  final _uuid = const Uuid();

  DatabaseHelper._init();

  bool get isWeb => kIsWeb;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Initialize mock data for web
      await _initMockData();
    } else {
      // Initialize FFI for desktop platforms
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    _initialized = true;
  }

  Future<void> _initMockData() async {
    // Create mock profiles for web demo
    _mockProfiles.addAll([
      {
        'id': _uuid.v4(),
        'nik': '12131415',
        'name': 'Budi Santoso',
        'gender': 'Pria',
        'birth_date': DateTime(1980, 5, 15).toIso8601String(),
        'blood_type': 'O+',
        'address': 'Jl. Mawar No. 123, Jakarta',
        'phone': '08123456789',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'nik': '21222324',
        'name': 'Siti Aminah',
        'gender': 'Wanita',
        'birth_date': DateTime(1982, 8, 20).toIso8601String(),
        'blood_type': 'A+',
        'address': '',
        'phone': '',
        'created_at': DateTime.now().toIso8601String(),
      },
    ]);
    _mockAppState['active_profile_id'] = _mockProfiles.first['id'];
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Database not supported on web. Use query/insert/update/delete methods instead.',
      );
    }
    if (_database != null) return _database!;
    await _ensureInitialized();
    _database = await _initDB('mediku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    await _ensureInitialized();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
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

  // Cross-platform query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? orderBy,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    await _ensureInitialized();

    if (kIsWeb) {
      if (table == 'family_profiles') {
        return List<Map<String, dynamic>>.from(_mockProfiles);
      } else if (table == 'app_state') {
        if (where != null && whereArgs != null && where.contains('key = ?')) {
          final key = whereArgs.first as String;
          final value = _mockAppState[key];
          if (value != null) {
            return [
              {'key': key, 'value': value},
            ];
          }
        }
        return [];
      }
      return [];
    } else {
      final db = await database;
      return await db.query(
        table,
        orderBy: orderBy,
        where: where,
        whereArgs: whereArgs,
      );
    }
  }

  // Cross-platform insert method
  Future<int> insert(String table, Map<String, dynamic> values) async {
    await _ensureInitialized();

    if (kIsWeb) {
      if (table == 'family_profiles') {
        _mockProfiles.add(values);
        return 1;
      } else if (table == 'app_state') {
        _mockAppState[values['key']] = values['value'];
        return 1;
      }
      return 0;
    } else {
      final db = await database;
      return await db.insert(table, values);
    }
  }

  // Cross-platform update method
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    await _ensureInitialized();

    if (kIsWeb) {
      if (table == 'family_profiles' && whereArgs != null) {
        final id = whereArgs.first as String;
        final index = _mockProfiles.indexWhere((p) => p['id'] == id);
        if (index != -1) {
          _mockProfiles[index] = {..._mockProfiles[index], ...values};
          return 1;
        }
      }
      return 0;
    } else {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    }
  }

  // Cross-platform delete method
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    await _ensureInitialized();

    if (kIsWeb) {
      if (table == 'family_profiles' && whereArgs != null) {
        final id = whereArgs.first as String;
        _mockProfiles.removeWhere((p) => p['id'] == id);
        return 1;
      } else if ((table == 'health_metrics' || table == 'appointments') &&
          whereArgs != null) {
        // For web demo, health metrics and appointments are not stored
        return 1;
      }
      return 0;
    } else {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    }
  }

  Future close() async {
    if (!kIsWeb) {
      final db = await database;
      db.close();
    }
  }
}
