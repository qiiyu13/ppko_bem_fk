import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _initialized = true;
  }

  Future<Database> get database async {
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
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
