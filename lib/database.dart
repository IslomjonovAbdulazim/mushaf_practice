// lib/database.dart - Clean database manager with proper structure
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static Database? _scriptDatabase;
  static Database? _mushafDatabase;
  static Database? _surahDatabase;
  static Database? _juzDatabase;

  // Initialize all databases
  static Future<void> initializeDatabases() async {
    try {
      await Future.wait([
        _getScriptDatabase(),
        _getMushafDatabase(),
        _getSurahDatabase(),
        _getJuzDatabase(),
      ]);
      print('✅ All databases initialized successfully');
    } catch (e) {
      print('❌ Database initialization failed: $e');
      throw e;
    }
  }

  // Script database (Uthmani text)
  static Future<Database> _getScriptDatabase() async {
    if (_scriptDatabase != null) return _scriptDatabase!;
    _scriptDatabase = await _initializeDatabase(
        "script.db",
        "assets/script/uthmani.db"
    );
    return _scriptDatabase!;
  }

  // Mushaf database (page layout)
  static Future<Database> _getMushafDatabase() async {
    if (_mushafDatabase != null) return _mushafDatabase!;
    _mushafDatabase = await _initializeDatabase(
        "mushaf.db",
        "assets/mushaf/qpc.db"
    );
    return _mushafDatabase!;
  }

  // Surah database (chapter information)
  static Future<Database> _getSurahDatabase() async {
    if (_surahDatabase != null) return _surahDatabase!;
    _surahDatabase = await _initializeDatabase(
        "surah.db",
        "assets/meta/surah.sqlite"
    );
    return _surahDatabase!;
  }

  // Juz database (part information)
  static Future<Database> _getJuzDatabase() async {
    if (_juzDatabase != null) return _juzDatabase!;
    _juzDatabase = await _initializeDatabase(
        "juz.db",
        "assets/meta/juz.sqlite"
    );
    return _juzDatabase!;
  }

  // Generic database initialization
  static Future<Database> _initializeDatabase(String dbName, String assetPath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = join(documentsDirectory.path, dbName);

    if (!await File(databasePath).exists()) {
      final assetData = await rootBundle.load(assetPath);
      final bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    return await openDatabase(databasePath, readOnly: true);
  }

  // Public getters for databases
  static Future<Database> get scriptDatabase => _getScriptDatabase();
  static Future<Database> get mushafDatabase => _getMushafDatabase();
  static Future<Database> get surahDatabase => _getSurahDatabase();
  static Future<Database> get juzDatabase => _getJuzDatabase();

  // Close all databases
  static Future<void> closeDatabases() async {
    await _scriptDatabase?.close();
    await _mushafDatabase?.close();
    await _surahDatabase?.close();
    await _juzDatabase?.close();

    _scriptDatabase = null;
    _mushafDatabase = null;
    _surahDatabase = null;
    _juzDatabase = null;
  }
}