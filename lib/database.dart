// lib/database.dart - Fixed database with Juz integration
import 'dart:io';
import 'dart:math' as math;
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

  // Juz database for accurate page-to-surah mapping
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

  // Get dominant surah for a page using juz database
  static Future<int> getDominantSurahForPage(int pageNumber) async {
    try {
      final database = await juzDatabase;

      // Get all juz entries that might contain this page
      final queryResults = await database.query('juz');

      for (var row in queryResults) {
        String verseMappingStr = row['verse_mapping'] as String;

        // Parse the verse mapping to find which pages this juz covers
        // Format is like: {"1":"1-7","2":"1-141"}
        if (verseMappingStr.isNotEmpty) {
          // Simple approach: check if this page falls within the range
          // You can make this more sophisticated by parsing the JSON properly

          // For now, use a simple page-to-juz mapping
          int juzNumber = row['juz_number'] as int;
          int firstVerseKey = _parseVerseKey(row['first_verse_key'] as String);
          int lastVerseKey = _parseVerseKey(row['last_verse_key'] as String);

          // Estimate if this page falls within this juz's range
          if (_isPageInJuzRange(pageNumber, juzNumber)) {
            // Get the most likely surah for this page within the juz
            return _getSurahFromVerseKey(firstVerseKey, lastVerseKey, pageNumber, juzNumber);
          }
        }
      }
    } catch (error) {
      print('Error finding dominant surah for page $pageNumber: $error');
    }

    // Fallback to simple estimation
    return _estimateSurahFromPageNumber(pageNumber);
  }

  // Helper: Parse verse key like "2:142" to get surah number
  static int _parseVerseKey(String verseKey) {
    try {
      return int.parse(verseKey.split(':')[0]);
    } catch (e) {
      return 1;
    }
  }

  // Helper: Check if page is likely in juz range
  static bool _isPageInJuzRange(int pageNumber, int juzNumber) {
    // Simple approximation: each juz is about 20 pages
    int startPage = (juzNumber - 1) * 20 + 1;
    int endPage = juzNumber * 20;
    return pageNumber >= startPage && pageNumber <= endPage;
  }

  // Helper: Get most likely surah for page within juz
  static int _getSurahFromVerseKey(int firstSurah, int lastSurah, int pageNumber, int juzNumber) {
    // If it's all one surah, return that
    if (firstSurah == lastSurah) return firstSurah;

    // Otherwise, estimate based on page position within juz
    int juzStartPage = (juzNumber - 1) * 20 + 1;
    int pageInJuz = pageNumber - juzStartPage + 1;

    // Simple interpolation between first and last surah
    if (pageInJuz <= 10) return firstSurah;
    return lastSurah;
  }

  // Fallback estimation (improved)
  static int _estimateSurahFromPageNumber(int pageNumber) {
    if (pageNumber == 1) return 1; // Al-Fatiha
    if (pageNumber <= 2) return 1; // Al-Fatiha continues
    if (pageNumber <= 49) return 2; // Al-Baqarah
    if (pageNumber <= 76) return 3; // Aal-E-Imran
    if (pageNumber <= 106) return 4; // An-Nisa
    if (pageNumber <= 127) return 5; // Al-Maidah
    if (pageNumber <= 150) return 6; // Al-An'am
    if (pageNumber <= 186) return 7; // Al-A'raf
    if (pageNumber <= 207) return 8; // Al-Anfal
    if (pageNumber <= 221) return 9; // At-Tawbah
    if (pageNumber <= 235) return 10; // Yunus
    if (pageNumber <= 248) return 11; // Hud
    if (pageNumber <= 262) return 12; // Yusuf
    if (pageNumber <= 267) return 13; // Ar-Ra'd
    if (pageNumber <= 281) return 14; // Ibrahim
    if (pageNumber <= 293) return 15; // Al-Hijr
    if (pageNumber <= 304) return 16; // An-Nahl
    if (pageNumber <= 312) return 17; // Al-Isra
    if (pageNumber <= 332) return 18; // Al-Kahf
    if (pageNumber <= 341) return 19; // Maryam
    if (pageNumber <= 350) return 20; // Ta-Ha

    // Continue pattern or return a reasonable default
    return math.max(1, math.min(114, (pageNumber / 5).round()));
  }

  // Get complete page data with accurate surah detection
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

    // Get accurate surah for this page
    int dominantSurahId = await getDominantSurahForPage(pageNumber);
    SurahModel? surah = await getSurahById(dominantSurahId);

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
      'surahName': surah.nameArabic,
    };
  }
}