// lib/enhanced_database.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/enhanced_models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class EnhancedDatabase {
  static Database? _script;
  static Database? _mushaf;
  static Database? _surah;
  static List<JuzModel>? _juzData;

  // Cache for metadata
  static final Map<int, PageMetadata> _metadataCache = {};
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, Map<String, dynamic>> _pageCache = {};
  static const int _maxCacheSize = 15;
  static final List<int> _cacheOrder = [];

  // Initialize all databases
  static Future<void> initializeDatabases() async {
    await Future.wait([
      script,
      mushaf,
      surahDb,
      _loadJuzData(),
    ]);
  }

  static Future<Database> get script async {
    if (_script != null) return _script!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "script.db");

    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/script/uthmani.db");
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _script = await openDatabase(path, readOnly: true);
    return _script!;
  }

  static Future<Database> get mushaf async {
    if (_mushaf != null) return _mushaf!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "mushaf.db");

    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/mushaf/qpc.db");
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _mushaf = await openDatabase(path, readOnly: true);
    return _mushaf!;
  }

  static Future<Database> get surahDb async {
    if (_surah != null) return _surah!;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "surah.db");

    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/meta/surah.sqlite");
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _surah = await openDatabase(path, readOnly: true);
    return _surah!;
  }

  static Future<void> _loadJuzData() async {
    if (_juzData != null) return;

    try {
      String jsonString = await rootBundle.loadString('assets/meta/juz.json');
      List<dynamic> jsonList = json.decode(jsonString);
      _juzData = jsonList.map((json) => JuzModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading juz data: $e');
      _juzData = [];
    }
  }

  static Future<SurahModel?> getSurah(int surahId) async {
    if (_surahCache.containsKey(surahId)) {
      return _surahCache[surahId];
    }

    try {
      final db = await surahDb;
      final List<Map<String, dynamic>> maps = await db.query(
        'surahs',
        where: 'id = ?',
        whereArgs: [surahId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final surah = SurahModel.fromJson(maps.first);
        _surahCache[surahId] = surah;
        return surah;
      }
    } catch (e) {
      print('Error getting surah $surahId: $e');
    }

    return null;
  }

  static Future<List<SurahModel>> getAllSurahs() async {
    try {
      final db = await surahDb;
      final List<Map<String, dynamic>> maps = await db.query(
        'surahs',
        orderBy: 'id ASC',
      );
      return maps.map((map) => SurahModel.fromJson(map)).toList();
    } catch (e) {
      print('Error getting all surahs: $e');
      return [];
    }
  }

  static int _getJuzForPage(int pageNumber) {
    if (_juzData == null || _juzData!.isEmpty) return 1;

    // More accurate Juz mapping based on standard Mushaf
    // These are approximate ranges for each Juz in a 604-page Mushaf
    final juzRanges = [
      21,   // Juz 1: pages 1-21
      41,   // Juz 2: pages 22-41
      62,   // Juz 3: pages 42-62
      82,   // Juz 4: pages 63-82
      102,  // Juz 5: pages 83-102
      121,  // Juz 6: pages 103-121
      141,  // Juz 7: pages 122-141
      161,  // Juz 8: pages 142-161
      181,  // Juz 9: pages 162-181
      201,  // Juz 10: pages 182-201
      221,  // Juz 11: pages 202-221
      241,  // Juz 12: pages 222-241
      261,  // Juz 13: pages 242-261
      281,  // Juz 14: pages 262-281
      301,  // Juz 15: pages 282-301
      321,  // Juz 16: pages 302-321
      341,  // Juz 17: pages 322-341
      361,  // Juz 18: pages 342-361
      381,  // Juz 19: pages 362-381
      401,  // Juz 20: pages 382-401
      421,  // Juz 21: pages 402-421
      441,  // Juz 22: pages 422-441
      461,  // Juz 23: pages 442-461
      481,  // Juz 24: pages 462-481
      501,  // Juz 25: pages 482-501
      521,  // Juz 26: pages 502-521
      541,  // Juz 27: pages 522-541
      561,  // Juz 28: pages 542-561
      581,  // Juz 29: pages 562-581
      604,  // Juz 30: pages 582-604
    ];

    for (int i = 0; i < juzRanges.length; i++) {
      if (pageNumber <= juzRanges[i]) {
        return i + 1;
      }
    }

    return 30; // Default to last Juz
  }

  static bool _isRightPage(int pageNumber) {
    // In traditional mushaf binding:
    // - Right pages (recto): odd page numbers (1, 3, 5, ...)
    // - Left pages (verso): even page numbers (2, 4, 6, ...)
    return pageNumber % 2 == 1;
  }

  static Future<PageMetadata> getPageMetadata(int pageNumber) async {
    if (_metadataCache.containsKey(pageNumber)) {
      return _metadataCache[pageNumber]!;
    }

    await initializeDatabases();

    // Get page lines to find surahs
    final pageLayout = await getPage(pageNumber);
    final Set<int> surahNumbers = {};

    // First, check page lines for surah numbers
    for (PageModel line in pageLayout) {
      if (line.surahNumber != null && line.surahNumber! > 0) {
        surahNumbers.add(line.surahNumber!);
      }
    }

    // If no surah numbers found in page lines, get from words
    if (surahNumbers.isEmpty) {
      try {
        final db = await script;

        // Get all word IDs for this page
        List<int> allWordIds = [];
        for (PageModel line in pageLayout) {
          if (line.firstWordId != null && line.lastWordId != null) {
            for (int i = line.firstWordId!; i <= line.lastWordId!; i++) {
              allWordIds.add(i);
            }
          }
        }

        if (allWordIds.isNotEmpty) {
          final String placeholders = allWordIds.map((_) => '?').join(',');
          final List<Map<String, dynamic>> wordMaps = await db.query(
            'words',
            columns: ['DISTINCT surah'],
            where: 'id IN ($placeholders)',
            whereArgs: allWordIds,
          );

          for (var wordMap in wordMaps) {
            final surah = wordMap['surah'] as int?;
            if (surah != null && surah > 0) {
              surahNumbers.add(surah);
            }
          }
        }
      } catch (e) {
        print('Error getting surah numbers for page $pageNumber: $e');
      }
    }

    // Fallback: estimate surah based on page number if still empty
    if (surahNumbers.isEmpty) {
      int estimatedSurah = _estimateSurahFromPage(pageNumber);
      surahNumbers.add(estimatedSurah);
    }

    // Get surah models
    final List<SurahModel> surahs = [];
    for (int surahId in surahNumbers.toList()..sort()) {
      final surah = await getSurah(surahId);
      if (surah != null) {
        surahs.add(surah);
      }
    }

    // Use the first surah as primary, or create default
    final primarySurah = surahs.isNotEmpty
        ? surahs.first
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

    final metadata = PageMetadata(
      pageNumber: pageNumber,
      juzNumber: _getJuzForPage(pageNumber),
      primarySurah: primarySurah,
      allSurahs: surahs,
      isRightPage: _isRightPage(pageNumber),
      isLeftPage: !_isRightPage(pageNumber),
    );

    _metadataCache[pageNumber] = metadata;
    return metadata;
  }

  // Estimate surah based on page number (rough approximation)
  static int _estimateSurahFromPage(int pageNumber) {
    if (pageNumber <= 2) return 1;   // Al-Fatiha
    if (pageNumber <= 49) return 2;  // Al-Baqarah
    if (pageNumber <= 76) return 3;  // Aal-E-Imran
    if (pageNumber <= 106) return 4; // An-Nisa
    if (pageNumber <= 127) return 5; // Al-Maidah
    if (pageNumber <= 150) return 6; // Al-An'am
    if (pageNumber <= 176) return 7; // Al-A'raf
    if (pageNumber <= 187) return 8; // Al-Anfal
    if (pageNumber <= 207) return 9; // At-Tawbah
    // Add more mappings as needed
    return 1; // Default fallback
  }

  static Future<List<PageModel>> getPage(int pageNumber) async {
    final db = await mushaf;
    final List<Map<String, dynamic>> maps = await db.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    return maps.map((map) => PageModel.fromJson(map)).toList();
  }

  // Enhanced cache management
  static void _updateCacheOrder(int pageNumber) {
    _cacheOrder.remove(pageNumber);
    _cacheOrder.add(pageNumber);

    while (_cacheOrder.length > _maxCacheSize) {
      final oldestPage = _cacheOrder.removeAt(0);
      _pageCache.remove(oldestPage);
    }
  }

  static Future<Map<String, dynamic>> getCompletePage(int pageNumber) async {
    // Check cache first
    if (_pageCache.containsKey(pageNumber)) {
      _updateCacheOrder(pageNumber);
      return _pageCache[pageNumber]!;
    }

    final pageLayout = await getPage(pageNumber);

    // Get all word IDs needed for this page
    List<int> allWordIds = [];
    for (PageModel line in pageLayout) {
      if (line.firstWordId != null && line.lastWordId != null) {
        for (int i = line.firstWordId!; i <= line.lastWordId!; i++) {
          allWordIds.add(i);
        }
      }
    }

    // Single query to get all words for the page
    Map<int, UthmaniModel> wordsMap = {};
    if (allWordIds.isNotEmpty) {
      final db = await script;
      final String placeholders = allWordIds.map((_) => '?').join(',');
      final List<Map<String, dynamic>> wordMaps = await db.query(
        'words',
        where: 'id IN ($placeholders)',
        whereArgs: allWordIds,
        orderBy: 'id ASC',
      );

      for (var wordMap in wordMaps) {
        final word = UthmaniModel.fromJson(wordMap);
        wordsMap[word.id] = word;
      }
    }

    // Build page lines
    List<Map<String, dynamic>> pageLines = [];
    for (PageModel line in pageLayout) {
      if (line.firstWordId != null && line.lastWordId != null) {
        List<UthmaniModel> lineWords = [];
        for (int i = line.firstWordId!; i <= line.lastWordId!; i++) {
          if (wordsMap.containsKey(i)) {
            lineWords.add(wordsMap[i]!);
          }
        }
        pageLines.add({
          'line': line,
          'words': lineWords,
        });
      } else {
        pageLines.add({
          'line': line,
          'words': <UthmaniModel>[],
        });
      }
    }

    // Get metadata for this page
    final metadata = await getPageMetadata(pageNumber);

    final result = {
      'pageNumber': pageNumber,
      'lines': pageLines,
      'metadata': metadata,
    };

    // Cache the result
    _pageCache[pageNumber] = result;
    _updateCacheOrder(pageNumber);

    return result;
  }

  // Utility methods
  static void clearCache() {
    _metadataCache.clear();
    _surahCache.clear();
    _pageCache.clear();
    _cacheOrder.clear();
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'metadataCached': _metadataCache.keys.toList()..sort(),
      'pagesCached': _pageCache.keys.toList()..sort(),
      'surahsCached': _surahCache.keys.toList()..sort(),
      'cacheSize': _pageCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }

  // Preload pages around current page for smoother navigation
  static Future<void> preloadPagesAround(int centerPage, {int range = 2}) async {
    final List<int> pagesToPreload = [];

    for (int i = -range; i <= range; i++) {
      final pageNum = centerPage + i;
      if (pageNum >= 1 && pageNum <= 604 && !_pageCache.containsKey(pageNum)) {
        pagesToPreload.add(pageNum);
      }
    }

    // Load in background
    for (int pageNum in pagesToPreload) {
      getCompletePage(pageNum).catchError((e) {
        print('Error preloading page $pageNum: $e');
      });
    }
  }
}