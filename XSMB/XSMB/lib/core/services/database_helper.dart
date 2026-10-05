import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Non-destructive migration: preserve existing scraped results
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lottery_results (
        draw_date TEXT PRIMARY KEY,
        db TEXT NOT NULL,
        g1 TEXT NOT NULL,
        g2 TEXT NOT NULL,
        g3 TEXT NOT NULL,
        g4 TEXT NOT NULL,
        g5 TEXT NOT NULL,
        g6 TEXT NOT NULL,
        g7 TEXT NOT NULL,
        is_live INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stats_cache (
        cache_key TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_draw_date ON lottery_results (draw_date DESC)');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table for Lottery Results Cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lottery_results (
        draw_date TEXT PRIMARY KEY,
        db TEXT NOT NULL,
        g1 TEXT NOT NULL,
        g2 TEXT NOT NULL,
        g3 TEXT NOT NULL,
        g4 TEXT NOT NULL,
        g5 TEXT NOT NULL,
        g6 TEXT NOT NULL,
        g7 TEXT NOT NULL,
        is_live INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Table for Analysis and Stats JSON Cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stats_cache (
        cache_key TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Index for fast range queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_draw_date ON lottery_results (draw_date DESC)');

    // 4. Seed data from CSV
    await _seedDatabaseFromCSV(db);
  }

  Future<void> _seedDatabaseFromCSV(Database db) async {
    try {
      final csvString = await rootBundle.loadString('assets/db/xsmb_history.csv');
      final rows = const CsvToListConverter().convert(csvString, eol: '\n');
      
      Batch batch = db.batch();
      // Skip header (i=1)
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 28) continue;
        
        String rawDate = row[0].toString();
        if (rawDate.isEmpty) continue;
        
        // Keep date format as yyyy-MM-dd (from CSV)
        String drawDate = rawDate;

        String special = row[1].toString();
        String p1 = row[2].toString();
        String p2 = '${row[3]},${row[4]}';
        String p3 = '${row[5]},${row[6]},${row[7]},${row[8]},${row[9]},${row[10]}';
        String p4 = '${row[11]},${row[12]},${row[13]},${row[14]}';
        String p5 = '${row[15]},${row[16]},${row[17]},${row[18]},${row[19]},${row[20]}';
        String p6 = '${row[21]},${row[22]},${row[23]}';
        String p7 = '${row[24]},${row[25]},${row[26]},${row[27]}';
        
        // Clean empty parts
        p2 = p2.split(',').where((e) => e.trim().isNotEmpty).join(',');
        p3 = p3.split(',').where((e) => e.trim().isNotEmpty).join(',');
        p4 = p4.split(',').where((e) => e.trim().isNotEmpty).join(',');
        p5 = p5.split(',').where((e) => e.trim().isNotEmpty).join(',');
        p6 = p6.split(',').where((e) => e.trim().isNotEmpty).join(',');
        p7 = p7.split(',').where((e) => e.trim().isNotEmpty).join(',');

        batch.insert(
          'lottery_results',
          {
            'draw_date': drawDate,
            'db': special,
            'g1': p1,
            'g2': p2,
            'g3': p3,
            'g4': p4,
            'g5': p5,
            'g6': p6,
            'g7': p7,
            'is_live': 0,
            'created_at': DateTime.now().toUtc().toIso8601String()
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Failed to seed or file not found
      print("DatabaseHelper _seedDatabaseFromCSV Error: $e");
    }
  }

  // Insert or Update a lottery result
  Future<void> insertResult(Map<String, dynamic> result) async {
    try {
      final db = await database;
      await db.insert(
        'lottery_results',
        result,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Insert result skipped: $e");
    }
  }

  // Get result by date
  Future<Map<String, dynamic>?> getResultByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lottery_results',
      where: 'draw_date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Get results within a specific date range (efficient SQL WHERE query)
  Future<List<Map<String, dynamic>>> getResultsByDateRange(String fromDate, String toDate) async {
    try {
      final db = await database;
      return await db.query(
        'lottery_results',
        where: 'draw_date >= ? AND draw_date <= ?',
        whereArgs: [fromDate, toDate],
        orderBy: 'draw_date DESC',
      );
    } catch (e) {
      print("Get results by date range error: $e");
      return [];
    }
  }

  // Get latest results limit
  Future<List<Map<String, dynamic>>> getResultsHistory({int limit = 50, int offset = 0}) async {
    try {
      final db = await database;
      return await db.query(
        'lottery_results',
        orderBy: 'draw_date DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print("Get results history skipped: $e");
      return [];
    }
  }

  // Get generic stats JSON cache
  Future<String?> getStatsCache(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stats_cache',
      columns: ['json_data'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['json_data'] as String;
    }
    return null;
  }

  // Insert or Update generic stats JSON cache
  Future<void> saveStatsCache(String key, String jsonData) async {
    final db = await database;
    await db.insert(
      'stats_cache',
      {
        'cache_key': key,
        'json_data': jsonData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Clear caches
  Future<void> clearAllCaches() async {
    final db = await database;
    await db.delete('lottery_results');
    await db.delete('stats_cache');
  }
}
