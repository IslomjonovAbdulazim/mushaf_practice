// lib/database.dart - Combined and optimized database functionality
// This consolidates simple_database.dart and enhanced_database.dart into one comprehensive file

import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  // Static database instances - using lazy initialization for better performance
  static Database? _scriptDatabase;
  static Database? _mushafDatabase;
  static Database? _surahDatabase;
  static List<JuzModel>? _juzData;

  // Caching system for improved performance and reduced database queries
  static final Map<int, PageMetadata> _metadataCache = {};
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, Map<String, dynamic>> _pageDataCache = {};

  // Cache management constants
  static const int _maxCacheSize = 15; // Keep 15 pages in memory at once
  static final List<int> _cacheAccessOrder = []; // Track access order for LRU eviction

  // Initialize all databases at app startup for better user experience
  static Future<void> initializeDatabases() async {
    await Future.wait([
      scriptDatabase,
      mushafDatabase,
      surahDatabase,
      _loadJuzData(),
    ]);
    print('All databases initialized successfully');
  }

  // Get the script database (contains Quranic text with Uthmani script)
  static Future<Database> get scriptDatabase async {
    if (_scriptDatabase != null) return _scriptDatabase!;

    // Get the app's documents directory for storing databases
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String databasePath = join(documentsDirectory.path, "script.db");

    // Copy database from assets if it doesn't exist locally
    if (!await File(databasePath).exists()) {
      ByteData assetData = await rootBundle.load("assets/script/uthmani.db");
      List<int> bytes = assetData.buffer.asUint8List();
      await File(databasePath).writeAsBytes(bytes);
    }

    _scriptDatabase = await openDatabase(databasePath, readOnly: true);
    return _scriptDatabase!;
  }

  // Get the mushaf database (contains page layout and formatting information)
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

  // Get the surah database (contains surah metadata like names and revelation info)
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

  // Load Juz data from JSON file (contains information about Quran divisions)
  static Future<void> _loadJuzData() async {
    if (_juzData != null) return;

    try {
      String jsonContent = await rootBundle.loadString('assets/meta/juz.json');
      List<dynamic> jsonList = json.decode(jsonContent);
      _juzData = jsonList.map((json) => JuzModel.fromJson(json)).toList();
    } catch (error) {
      print('Error loading juz data: $error');
      _juzData = []; // Initialize as empty list to prevent null errors
    }
  }

  // Calculate which Juz (section) a page belongs to based on traditional Mushaf divisions
  static int _calculateJuzForPage(int pageNumber) {
    // These page ranges are based on the standard 604-page Mushaf layout
    // Each Juz traditionally contains about 20 pages, but the actual ranges vary
    final juzStartingPages = [
      1,    // Juz 1: Al-Fatiha and beginning of Al-Baqarah
      22,   // Juz 2: Al-Baqarah (continuing)
      42,   // Juz 3: Al-Baqarah (continuing)
      62,   // Juz 4: Al-Baqarah and Aal-E-Imran
      82,   // Juz 5: Aal-E-Imran (continuing)
      102,  // Juz 6: Aal-E-Imran and An-Nisa
      121,  // Juz 7: An-Nisa (continuing)
      142,  // Juz 8: An-Nisa and Al-Maidah
      162,  // Juz 9: Al-Maidah and Al-An'am
      182,  // Juz 10: Al-An'am and Al-A'raf
      201,  // Juz 11: Al-A'raf and Al-Anfal
      222,  // Juz 12: Al-Anfal and At-Tawbah
      242,  // Juz 13: At-Tawbah and Yunus
      262,  // Juz 14: Yunus, Hud, and Yusuf
      282,  // Juz 15: Yusuf, Ar-Ra'd, and Ibrahim
      302,  // Juz 16: Ibrahim, Al-Hijr, and An-Nahl
      322,  // Juz 17: An-Nahl and Al-Isra
      342,  // Juz 18: Al-Isra and Al-Kahf
      362,  // Juz 19: Al-Kahf and Maryam
      382,  // Juz 20: Maryam, Ta-Ha, and Al-Anbiya
      402,  // Juz 21: Al-Anbiya and Al-Hajj
      422,  // Juz 22: Al-Hajj, Al-Mu'minun, and An-Nur
      442,  // Juz 23: An-Nur and Al-Furqan
      462,  // Juz 24: Al-Furqan, Ash-Shu'ara, and An-Naml
      482,  // Juz 25: An-Naml and Al-Qasas
      502,  // Juz 26: Al-Qasas and Al-Ankabut
      522,  // Juz 27: Al-Ankabut, Ar-Rum, and Luqman
      542,  // Juz 28: Luqman, As-Sajdah, and Al-Ahzab
      562,  // Juz 29: Al-Ahzab, Saba, and Fatir
      582,  // Juz 30: Fatir to An-Nas (end of Quran)
    ];

    // Find which Juz this page belongs to by checking the starting pages
    for (int juzIndex = juzStartingPages.length - 1; juzIndex >= 0; juzIndex--) {
      if (pageNumber >= juzStartingPages[juzIndex]) {
        return juzIndex + 1; // Return 1-based Juz number
      }
    }

    return 1; // Default to first Juz if calculation fails
  }

  // Determine if a page is on the right side (odd pages) or left side (even pages)
  static bool _isRightSidePage(int pageNumber) {
    // In traditional book binding, odd-numbered pages appear on the right
    return pageNumber % 2 == 1;
  }

  // Retrieve surah information by ID, with caching for performance
  static Future<SurahModel?> getSurahById(int surahId) async {
    // Check cache first to avoid unnecessary database queries
    if (_surahCache.containsKey(surahId)) {
      return _surahCache[surahId];
    }

    try {
      final database = await surahDatabase;
      final queryResults = await database.query(
        'surahs',
        where: 'id = ?',
        whereArgs: [surahId],
        limit: 1,
      );

      if (queryResults.isNotEmpty) {
        final surahModel = SurahModel.fromJson(queryResults.first);
        _surahCache[surahId] = surahModel; // Cache for future use
        return surahModel;
      }
    } catch (error) {
      print('Error retrieving surah $surahId: $error');
    }

    return null; // Return null if surah not found or error occurred
  }

  // Get all surahs for reference or navigation purposes
  static Future<List<SurahModel>> getAllSurahs() async {
    try {
      final database = await surahDatabase;
      final queryResults = await database.query(
        'surahs',
        orderBy: 'id ASC', // Order by surah number
      );
      return queryResults.map((row) => SurahModel.fromJson(row)).toList();
    } catch (error) {
      print('Error retrieving all surahs: $error');
      return []; // Return empty list on error
    }
  }

  // Estimate which surah a page likely contains based on page number
  // This is used as a fallback when database queries don't provide surah information
  static int _estimateSurahFromPageNumber(int pageNumber) {
    // Approximate page ranges for major surahs in a 604-page Mushaf
    final surahPageEstimates = [
      (1, 1),     // Al-Fatiha: page 1 only
      (2, 49),    // Al-Baqarah: pages 2-49 (longest surah)
      (50, 76),   // Aal-E-Imran: pages 50-76
      (77, 106),  // An-Nisa: pages 77-106
      (107, 127), // Al-Maidah: pages 107-127
      (128, 150), // Al-An'am: pages 128-150
      (151, 176), // Al-A'raf: pages 151-176
      (177, 187), // Al-Anfal: pages 177-187
      (188, 207), // At-Tawbah: pages 188-207
      (208, 221), // Yunus: pages 208-221
      // Additional mappings can be added here for more precision
    ];

    // Search through the estimates to find which surah this page likely contains
    for (int surahIndex = 0; surahIndex < surahPageEstimates.length; surahIndex++) {
      final (startPage, endPage) = surahPageEstimates[surahIndex];
      if (pageNumber >= startPage && pageNumber <= endPage) {
        return surahIndex + 1; // Return 1-based surah number
      }
    }

    // For pages beyond our detailed mapping, use rough calculation
    if (pageNumber > 207) {
      // Estimate based on the fact that later surahs are generally shorter
      return ((pageNumber - 207) / 8).ceil() + 9;
    }

    return 1; // Default to Al-Fatiha if estimation fails
  }

  // Create comprehensive metadata for a page including surah and Juz information
  static Future<PageMetadata> generatePageMetadata(int pageNumber) async {
    await initializeDatabases(); // Ensure all databases are ready

    // Get the page layout information
    final pageLayout = await getPageLayout(pageNumber);
    final Set<int> surahNumbers = {};

    // Collect all word IDs that appear on this page
    List<int> allWordIds = [];
    for (PageModel lineLayout in pageLayout) {
      if (lineLayout.firstWordId != null && lineLayout.lastWordId != null) {
        // Add all word IDs in the range for this line
        for (int wordId = lineLayout.firstWordId!; wordId <= lineLayout.lastWordId!; wordId++) {
          allWordIds.add(wordId);
        }
      }
    }

    // Query the database to find which surahs these words belong to
    if (allWordIds.isNotEmpty) {
      try {
        final database = await scriptDatabase;
        final placeholders = allWordIds.map((_) => '?').join(',');
        final wordQueryResults = await database.query(
          'words',
          columns: ['DISTINCT surah'], // Only get unique surah numbers
          where: 'id IN ($placeholders)',
          whereArgs: allWordIds,
        );

        // Extract surah numbers from query results
        for (var wordRow in wordQueryResults) {
          final surahNumber = wordRow['surah'] as int?;
          if (surahNumber != null && surahNumber > 0) {
            surahNumbers.add(surahNumber);
          }
        }
      } catch (error) {
        print('Error finding surah numbers for page $pageNumber: $error');
      }
    }

    // Use estimation as fallback if no surahs found from word data
    if (surahNumbers.isEmpty) {
      int estimatedSurahNumber = _estimateSurahFromPageNumber(pageNumber);
      surahNumbers.add(estimatedSurahNumber);
    }

    // Retrieve full surah information for all surahs found on this page
    final List<SurahModel> pagesSurahs = [];
    for (int surahId in surahNumbers.toList()..sort()) {
      final surahModel = await getSurahById(surahId);
      if (surahModel != null) {
        pagesSurahs.add(surahModel);
      }
    }

    // Create a default surah if none were found (should rarely happen)
    final primarySurah = pagesSurahs.isNotEmpty
        ? pagesSurahs.first
        : SurahModel(
      id: 1,
      name: 1,
      nameSimple: 'Al-Fatiha',
      nameArabic: 'الفاتحة',
      revelationOrder: 1,
      revelationPlace: 'Meccan',
      versesCount: 7,
      bismillahPre: 1,
    );

    // Assemble the complete metadata for this page
    return PageMetadata(
      pageNumber: pageNumber,
      juzNumber: _calculateJuzForPage(pageNumber),
      primarySurah: primarySurah,
      allSurahs: pagesSurahs,
      isRightPage: _isRightSidePage(pageNumber),
      isLeftPage: !_isRightSidePage(pageNumber),
    );
  }

  // Get the layout information for a specific page (lines, centering, etc.)
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
    final database = await mushafDatabase;
    final queryResults = await database.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC', // Ensure lines are in correct order
    );
    return queryResults.map((row) => PageModel.fromJson(row)).toList();
  }

  // Manage cache access order for LRU (Least Recently Used) eviction
  static void _updateCacheAccessOrder(int pageNumber) {
    _cacheAccessOrder.remove(pageNumber); // Remove if already in list
    _cacheAccessOrder.add(pageNumber);    // Add to end (most recently used)

    // Remove oldest entries if cache exceeds maximum size
    while (_cacheAccessOrder.length > _maxCacheSize) {
      final oldestPage = _cacheAccessOrder.removeAt(0);
      _pageDataCache.remove(oldestPage);
    }
  }

  // Get complete page data including layout, words, and metadata
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    // Always fetch fresh metadata to ensure dynamic updates when navigating
    final pageLayout = await getPageLayout(pageNumber);

    // Collect all word IDs needed for this page
    List<int> requiredWordIds = [];
    for (PageModel lineLayout in pageLayout) {
      if (lineLayout.firstWordId != null && lineLayout.lastWordId != null) {
        for (int wordId = lineLayout.firstWordId!; wordId <= lineLayout.lastWordId!; wordId++) {
          requiredWordIds.add(wordId);
        }
      }
    }

    // Fetch all words for this page in a single efficient query
    Map<int, UthmaniModel> wordsById = {};
    if (requiredWordIds.isNotEmpty) {
      final database = await scriptDatabase;
      final placeholders = requiredWordIds.map((_) => '?').join(',');
      final wordQueryResults = await database.query(
        'words',
        where: 'id IN ($placeholders)',
        whereArgs: requiredWordIds,
        orderBy: 'id ASC',
      );

      // Create a lookup map for O(1) word access by ID
      for (var wordRow in wordQueryResults) {
        final wordModel = UthmaniModel.fromJson(wordRow);
        wordsById[wordModel.id] = wordModel;
      }
    }

    // Organize words into lines according to the page layout
    List<Map<String, dynamic>> organizedLines = [];
    for (PageModel lineLayout in pageLayout) {
      if (lineLayout.firstWordId != null && lineLayout.lastWordId != null) {
        List<UthmaniModel> wordsInLine = [];
        // Collect words for this specific line
        for (int wordId = lineLayout.firstWordId!; wordId <= lineLayout.lastWordId!; wordId++) {
          if (wordsById.containsKey(wordId)) {
            wordsInLine.add(wordsById[wordId]!);
          }
        }
        organizedLines.add({
          'line': lineLayout,
          'words': wordsInLine,
        });
      } else {
        // Handle lines without words (like spacing or decorative elements)
        organizedLines.add({
          'line': lineLayout,
          'words': <UthmaniModel>[],
        });
      }
    }

    // Generate fresh metadata for dynamic updates
    final pageMetadata = await generatePageMetadata(pageNumber);

    // Assemble the complete page data structure
    return {
      'pageNumber': pageNumber,
      'lines': organizedLines,
      'metadata': pageMetadata,
    };
  }

  // Preload pages around the current page for smoother navigation experience
  static Future<void> preloadSurroundingPages(int centerPage, {int range = 2}) async {
    final List<int> pagesToPreload = [];

    // Determine which pages to preload within the valid range
    for (int offset = -range; offset <= range; offset++) {
      final targetPage = centerPage + offset;
      if (targetPage >= 1 && targetPage <= 604 && !_pageDataCache.containsKey(targetPage)) {
        pagesToPreload.add(targetPage);
      }
    }

    // Load pages in background without blocking the UI
    for (int pageNumber in pagesToPreload) {
      getCompletePageData(pageNumber).catchError((error) {
        print('Error preloading page $pageNumber: $error');
      });
    }
  }

  // Utility methods for cache management and maintenance

  // Clear all cached data to free memory
  static void clearAllCaches() {
    _metadataCache.clear();
    _surahCache.clear();
    _pageDataCache.clear();
    _cacheAccessOrder.clear();
  }

  // Get statistics about current cache usage for debugging
  static Map<String, dynamic> getCacheStatistics() {
    return {
      'metadataCachedPages': _metadataCache.keys.toList()..sort(),
      'pageDataCachedPages': _pageDataCache.keys.toList()..sort(),
      'surahsCached': _surahCache.keys.toList()..sort(),
      'currentCacheSize': _pageDataCache.length,
      'maximumCacheSize': _maxCacheSize,
      'accessOrder': List.from(_cacheAccessOrder),
    };
  }

  // Legacy methods for backward compatibility with existing code

  // Get all word data (primarily for initial development and testing)
  static Future<List<UthmaniModel>> getAllWords() async {
    final database = await scriptDatabase;
    final queryResults = await database.query('words');
    return queryResults.map((row) => UthmaniModel.fromJson(row)).toList();
  }

  // Get words for a specific range (used in original implementation)
  static Future<List<UthmaniModel>> getWordsInRange(int firstWordId, int lastWordId) async {
    final database = await scriptDatabase;
    final queryResults = await database.query(
      'words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [firstWordId, lastWordId],
      orderBy: 'id ASC',
    );
    return queryResults.map((row) => UthmaniModel.fromJson(row)).toList();
  }
}