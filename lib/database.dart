// lib/database.dart - Simple database with Juz integration
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static Database? _scriptDatabase;
  static Database? _mushafDatabase;
  static Database? _surahDatabase;
  static Database? _juzDatabase;

  // Initialize databases at startup
  static Future<void> initializeDatabases() async {
    await Future.wait([
      scriptDatabase,
      mushafDatabase,
      surahDatabase,
      juzDatabase,
    ]);
  }

  // Script database for Quranic text
  static Future<Database> get scriptDatabase async {
    if (_scriptDatabase != null) return _scriptDatabase!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, "script.db");

    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load("assets/script/uthmani.db");
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    _scriptDatabase = await openDatabase(databasePath, readOnly: true);
    return _scriptDatabase!;
  }

  // Mushaf database for page layout
  static Future<Database> get mushafDatabase async {
    if (_mushafDatabase != null) return _mushafDatabase!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, "mushaf.db");

    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load("assets/mushaf/qpc.db");
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    _mushafDatabase = await openDatabase(databasePath, readOnly: true);
    return _mushafDatabase!;
  }

  // Surah database for surah names
  static Future<Database> get surahDatabase async {
    if (_surahDatabase != null) return _surahDatabase!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, "surah.db");

    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load("assets/meta/surah.sqlite");
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    _surahDatabase = await openDatabase(databasePath, readOnly: true);
    return _surahDatabase!;
  }

  // Juz database
  static Future<Database> get juzDatabase async {
    if (_juzDatabase != null) return _juzDatabase!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, "juz.db");

    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load("assets/meta/juz.sqlite");
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    _juzDatabase = await openDatabase(databasePath, readOnly: true);
    return _juzDatabase!;
  }

  // Get surah info
  static Future<SurahModel?> getSurahById(int surahId) async {
    try {
      final database = await surahDatabase;
      final queryResults = await database.query(
        'chapters',
        where: 'id = ?',
        whereArgs: [surahId],
        limit: 1,
      );

      if (queryResults.isNotEmpty) {
        return SurahModel.fromJson(queryResults.first);
      }
    } catch (error) {
      print('Error retrieving surah $surahId: $error');
    }
    return null;
  }

  // Get page layout
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
    final database = await mushafDatabase;
    final queryResults = await database.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    return queryResults.map((row) => PageModel.fromJson(row)).toList();
  }

  // Simple surah detection using juz
  static Future<int> getSurahForPage(int pageNumber) async {
    try {
      final database = await juzDatabase;

      // Simple: each juz is roughly 20 pages
      int juzNumber = ((pageNumber - 1) ~/ 20) + 1;
      if (juzNumber > 30) juzNumber = 30;

      final queryResults = await database.query(
        'juz',
        where: 'juz_number = ?',
        whereArgs: [juzNumber],
        limit: 1,
      );

      if (queryResults.isNotEmpty) {
        String firstVerseKey = queryResults.first['first_verse_key'] as String;
        return int.parse(firstVerseKey.split(':')[0]);
      }
    } catch (error) {
      print('Error: $error');
    }

    return 1; // Default: Al-Fatiha
  }

  // Get complete page data
  static Future<Map<String, dynamic>> getCompletePageData(
    int pageNumber,
  ) async {
    final pageLayout = await getPageLayout(pageNumber);

    // Collect word IDs for this page
    List<int> wordIds = [];
    for (PageModel line in pageLayout) {
      if (line.firstWordId != null && line.lastWordId != null) {
        for (int id = line.firstWordId!; id <= line.lastWordId!; id++) {
          wordIds.add(id);
        }
      }
    }

    // Get words from database
    Map<int, UthmaniModel> wordsById = {};
    if (wordIds.isNotEmpty) {
      final database = await scriptDatabase;
      final placeholders = wordIds.map((_) => '?').join(',');
      final wordResults = await database.query(
        'words',
        where: 'id IN ($placeholders)',
        whereArgs: wordIds,
        orderBy: 'id ASC',
      );

      for (var row in wordResults) {
        final word = UthmaniModel.fromJson(row);
        wordsById[word.id] = word;
      }
    }

    // Organize words into lines
    List<Map<String, dynamic>> lines = [];
    for (PageModel line in pageLayout) {
      List<UthmaniModel> lineWords = [];
      if (line.firstWordId != null && line.lastWordId != null) {
        for (int id = line.firstWordId!; id <= line.lastWordId!; id++) {
          if (wordsById.containsKey(id)) {
            lineWords.add(wordsById[id]!);
          }
        }
      }
      lines.add({
        'line': line,
        'words': lineWords,
      });
    }

    // Get surah for this page
    int surahId = await getSurahForPage(pageNumber);
    SurahModel? surah = await getSurahById(surahId);

    return {
      'pageNumber': pageNumber,
      'lines': lines,
      'surahName': surah?.nameArabic ?? 'القرآن الكريم',
    };
  }
}
