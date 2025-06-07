// lib/database.dart - Simplified database for basic Mushaf display
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

  // Initialize databases at startup
  static Future<void> initializeDatabases() async {
    await Future.wait([
      scriptDatabase,
      mushafDatabase,
      surahDatabase,
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

  // Get surah info - fixed to use 'chapters' table name
  static Future<SurahModel?> getSurahById(int surahId) async {
    try {
      final database = await surahDatabase;
      final queryResults = await database.query(
        'chapters', // Changed from 'surahs' to 'chapters'
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

  // Estimate surah from page number (simple fallback)
  static int _estimateSurahFromPageNumber(int pageNumber) {
    if (pageNumber == 1) return 1; // Al-Fatiha
    if (pageNumber <= 49) return 2; // Al-Baqarah
    if (pageNumber <= 76) return 3; // Aal-E-Imran
    if (pageNumber <= 106) return 4; // An-Nisa
    if (pageNumber <= 127) return 5; // Al-Maidah
    if (pageNumber <= 150) return 6; // Al-An'am
    // Add more as needed, or just return a default
    return 2; // Default to Al-Baqarah
  }

  // Get complete page data with simplified metadata
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
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

    // Find surah for this page (simplified approach)
    int estimatedSurah = _estimateSurahFromPageNumber(pageNumber);
    SurahModel? surah = await getSurahById(estimatedSurah);

    // Create fallback surah if none found
    surah ??= const SurahModel(
      id: 1,
      name: 1,
      nameSimple: 'Al-Fatiha',
      nameArabic: 'الفاتحة',
      revelationOrder: 1,
      revelationPlace: 'Meccan',
      versesCount: 7,
      bismillahPre: 1,
    );

    return {
      'pageNumber': pageNumber,
      'lines': lines,
      'surahName': surah.nameArabic, // Only Arabic name
    };
  }
}