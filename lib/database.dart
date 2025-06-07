// lib/database.dart - Optimized database with caching and performance improvements
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

  // Cache for frequently accessed data
  static Map<int, SurahModel> _surahCache = {};
  static Map<int, List<PageModel>> _pageCache = {};
  static Map<int, int> _surahPageCache = {};
  static List<JuzModel> _juzList = [];
  static bool _cacheInitialized = false;

  // Initialize databases and cache
  static Future<void> initializeDatabases() async {
    try {
      await Future.wait([
        scriptDatabase,
        mushafDatabase,
        surahDatabase,
        juzDatabase,
      ]);

      // Initialize cache for better performance
      await _initializeCache();
      print('✅ Databases and cache initialized');
    } catch (e) {
      print('❌ Database initialization failed: $e');
      throw e;
    }
  }

  // Initialize cache with frequently used data
  static Future<void> _initializeCache() async {
    if (_cacheInitialized) return;

    try {
      // Cache all surahs
      await _cacheSurahs();

      // Cache juz data
      await _cacheJuzData();

      // Cache surah-to-page mapping
      await _cacheSurahPageMapping();

      _cacheInitialized = true;
    } catch (e) {
      print('Cache initialization error: $e');
    }
  }

  static Future<void> _cacheSurahs() async {
    final database = await surahDatabase;
    final queryResults = await database.query('chapters', orderBy: 'id ASC');

    for (var row in queryResults) {
      final surah = SurahModel.fromJson(row);
      _surahCache[surah.id] = surah;
    }
  }

  static Future<void> _cacheJuzData() async {
    final database = await juzDatabase;
    final queryResults = await database.query('juz', orderBy: 'juz_number ASC');

    _juzList = queryResults.map((row) => JuzModel.fromJson(row)).toList();
  }

  static Future<void> _cacheSurahPageMapping() async {
    // This creates a mapping of surah to starting page
    // Using the juz data and approximate calculations
    for (int surahId = 1; surahId <= 114; surahId++) {
      _surahPageCache[surahId] = await _calculateSurahStartPage(surahId);
    }
  }

  static Future<int> _calculateSurahStartPage(int surahId) async {
    try {
      // Try to get from mushaf database first
      final mushafDb = await mushafDatabase;
      final scriptDb = await scriptDatabase;

      // Get the first word of this surah
      final wordQuery = await scriptDb.query(
        'words',
        where: 'surah = ? AND ayah = 1 AND word = 1',
        whereArgs: [surahId],
        limit: 1,
      );

      if (wordQuery.isNotEmpty) {
        final firstWordId = wordQuery.first['id'] as int;

        // Find which page contains this word
        final pageQuery = await mushafDb.query(
          'pages',
          where: 'first_word_id <= ? AND last_word_id >= ?',
          whereArgs: [firstWordId, firstWordId],
          limit: 1,
        );

        if (pageQuery.isNotEmpty) {
          return pageQuery.first['page_number'] as int;
        }
      }
    } catch (e) {
      print('Error calculating start page for surah $surahId: $e');
    }

    // Fallback to estimated page numbers
    return _getEstimatedStartPage(surahId);
  }

  static int _getEstimatedStartPage(int surahId) {
    // Rough estimates based on common Mushaf layouts
    const Map<int, int> estimatedPages = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
      11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
      21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
      31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
      41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
      61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
      71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
      81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
      91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599, 100: 599,
      101: 600, 102: 600, 103: 601, 104: 601, 105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603,
      111: 603, 112: 604, 113: 604, 114: 604,
    };

    return estimatedPages[surahId] ?? 1;
  }

  // Database getters with singleton pattern
  static Future<Database> get scriptDatabase async {
    if (_scriptDatabase != null) return _scriptDatabase!;
    _scriptDatabase = await _initializeDatabase("script.db", "assets/script/uthmani.db");
    return _scriptDatabase!;
  }

  static Future<Database> get mushafDatabase async {
    if (_mushafDatabase != null) return _mushafDatabase!;
    _mushafDatabase = await _initializeDatabase("mushaf.db", "assets/mushaf/qpc.db");
    return _mushafDatabase!;
  }

  static Future<Database> get surahDatabase async {
    if (_surahDatabase != null) return _surahDatabase!;
    _surahDatabase = await _initializeDatabase("surah.db", "assets/meta/surah.sqlite");
    return _surahDatabase!;
  }

  static Future<Database> get juzDatabase async {
    if (_juzDatabase != null) return _juzDatabase!;
    _juzDatabase = await _initializeDatabase("juz.db", "assets/meta/juz.sqlite");
    return _juzDatabase!;
  }

  // Generic database initialization
  static Future<Database> _initializeDatabase(String dbName, String assetPath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, dbName);

    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load(assetPath);
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    return await openDatabase(databasePath, readOnly: true);
  }

  // Optimized data retrieval methods

  // Get surah info with caching
  static Future<SurahModel?> getSurahById(int surahId) async {
    // Return from cache if available
    if (_surahCache.containsKey(surahId)) {
      return _surahCache[surahId];
    }

    try {
      final database = await surahDatabase;
      final queryResults = await database.query(
        'chapters',
        where: 'id = ?',
        whereArgs: [surahId],
        limit: 1,
      );

      if (queryResults.isNotEmpty) {
        final surah = SurahModel.fromJson(queryResults.first);
        _surahCache[surahId] = surah; // Cache the result
        return surah;
      }
    } catch (error) {
      print('Error retrieving surah $surahId: $error');
    }
    return null;
  }

  // Get all surahs (cached)
  static Future<List<SurahModel>> getAllSurahs() async {
    if (_surahCache.isEmpty) {
      await _cacheSurahs();
    }
    return _surahCache.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  // Get page layout with caching
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
    // Return from cache if available
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final database = await mushafDatabase;
    final queryResults = await database.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    final pageLayout = queryResults.map((row) => PageModel.fromJson(row)).toList();

    // Cache the result (but limit cache size)
    if (_pageCache.length < 50) { // Keep last 50 pages in cache
      _pageCache[pageNumber] = pageLayout;
    }

    return pageLayout;
  }

  // Get juz for surah (cached)
  static Future<int> getJuzForSurah(int surahId) async {
    if (_juzList.isEmpty) {
      await _cacheJuzData();
    }

    try {
      for (var juz in _juzList) {
        final firstVerse = juz.firstVerseKey.split(':');
        final lastVerse = juz.lastVerseKey.split(':');

        if (firstVerse.length >= 2 && lastVerse.length >= 2) {
          final firstSurah = int.tryParse(firstVerse[0]) ?? 0;
          final lastSurah = int.tryParse(lastVerse[0]) ?? 0;

          if (surahId >= firstSurah && surahId <= lastSurah) {
            return juz.juzNumber;
          }
        }
      }
    } catch (e) {
      print('Error getting juz for surah $surahId: $e');
    }

    // Fallback calculation
    return ((surahId - 1) ~/ 4) + 1;
  }

  // Get surah start page (cached)
  static Future<int> getSurahStartPage(int surahId) async {
    if (_surahPageCache.containsKey(surahId)) {
      return _surahPageCache[surahId]!;
    }

    // If not cached, calculate and cache
    final startPage = await _calculateSurahStartPage(surahId);
    _surahPageCache[surahId] = startPage;
    return startPage;
  }

  // Get complete page data with optimized queries
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    final pageLayout = await getPageLayout(pageNumber);

    // Collect word IDs for this page
    Set<int> wordIds = {};
    for (PageModel line in pageLayout) {
      if (line.firstWordId != null && line.lastWordId != null) {
        for (int id = line.firstWordId!; id <= line.lastWordId!; id++) {
          wordIds.add(id);
        }
      }
    }

    // Get words from database in one query
    Map<int, UthmaniModel> wordsById = {};
    if (wordIds.isNotEmpty) {
      final database = await scriptDatabase;
      final placeholders = wordIds.map((_) => '?').join(',');
      final wordResults = await database.query(
        'words',
        where: 'id IN ($placeholders)',
        whereArgs: wordIds.toList(),
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

  // Simple surah detection using cached data
  static Future<int> getSurahForPage(int pageNumber) async {
    // Use cached surah-page mapping to find which surah this page belongs to
    for (var entry in _surahPageCache.entries) {
      final surahId = entry.key;
      final startPage = entry.value;

      // Find the next surah's start page
      int? nextStartPage;
      for (int nextSurahId = surahId + 1; nextSurahId <= 114; nextSurahId++) {
        if (_surahPageCache.containsKey(nextSurahId)) {
          nextStartPage = _surahPageCache[nextSurahId];
          break;
        }
      }

      // Check if current page falls within this surah's range
      if (pageNumber >= startPage &&
          (nextStartPage == null || pageNumber < nextStartPage)) {
        return surahId;
      }
    }

    return 1; // Default: Al-Fatiha
  }

  // Get all juz data (cached)
  static Future<List<JuzModel>> getAllJuz() async {
    if (_juzList.isEmpty) {
      await _cacheJuzData();
    }
    return List.from(_juzList);
  }

  // Clear cache (useful for memory management)
  static void clearCache() {
    _pageCache.clear();
    _surahCache.clear();
    _surahPageCache.clear();
    _juzList.clear();
    _cacheInitialized = false;
  }
}

// New JuzModel class
class JuzModel {
  final int juzNumber;
  final String firstVerseKey;
  final String lastVerseKey;
  final int versesCount;

  const JuzModel({
    required this.juzNumber,
    required this.firstVerseKey,
    required this.lastVerseKey,
    required this.versesCount,
  });

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      juzNumber: json['juz_number'] as int? ?? 0,
      firstVerseKey: json['first_verse_key'] as String? ?? '',
      lastVerseKey: json['last_verse_key'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
    );
  }
}