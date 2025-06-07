// lib/services/data_service.dart - Optimized service layer
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class DataService {
  // Optimized cache with better memory management
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, List<PageModel>> _pageCache = {};
  static final Map<int, List<Map<String, dynamic>>> _pageDataCache = {};
  static final Map<int, int> _pageSurahCache = {};
  static final Map<int, int> _surahPageCache = {};
  static final List<JuzModel> _juzCache = [];
  static final Map<int, String> _juzNameCache = {};

  static const int _maxCacheSize = 20; // Limit cache size
  static bool _isInitialized = false;

  // Initialize cache with optimized loading
  static Future<void> initializeCache() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _loadJuzData(),
        _loadAllSurahs(),
        _preloadCriticalPageMappings(),
      ]);
      _isInitialized = true;
      print('✅ Cache initialized successfully');
    } catch (e) {
      print('❌ Cache initialization failed: $e');
      rethrow;
    }
  }

  // Preload critical page-surah mappings for better performance
  static Future<void> _preloadCriticalPageMappings() async {
    try {
      final database = await DatabaseManager.mushafDatabase;

      // Get first word of every 20th page for quick surah lookup
      final pageNumbers = [1, 21, 41, 61, 81, 101, 121, 141, 161, 181, 201, 221, 241, 261, 281, 301, 321, 341, 361, 381, 401, 421, 441, 461, 481, 501, 521, 541, 561, 581, 601];

      for (int pageNum in pageNumbers) {
        final result = await database.query(
          'pages',
          where: 'page_number = ?',
          whereArgs: [pageNum],
          orderBy: 'line_number ASC',
          limit: 1,
        );

        if (result.isNotEmpty) {
          final firstWordId = MushafUtils.safeParseInt(result.first['first_word_id']);
          if (firstWordId > 0) {
            final surahId = await _getSurahFromWordId(firstWordId);
            _pageSurahCache[pageNum] = surahId;
          }
        }
      }
    } catch (e) {
      print('Error preloading page mappings: $e');
    }
  }

  // Optimized surah lookup from word ID
  static Future<int> _getSurahFromWordId(int wordId) async {
    try {
      final scriptDb = await DatabaseManager.scriptDatabase;
      final result = await scriptDb.query(
        'words',
        columns: ['surah'],
        where: 'id = ?',
        whereArgs: [wordId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return MushafUtils.safeParseInt(result.first['surah'], defaultValue: 1);
      }
    } catch (e) {
      print('Error getting surah from word ID $wordId: $e');
    }
    return 1;
  }

  // Optimized juz data loading
  static Future<void> _loadJuzData() async {
    try {
      final database = await DatabaseManager.juzDatabase;
      final result = await database.query('juz', orderBy: 'juz_number ASC');

      _juzCache.clear();
      _juzNameCache.clear();

      for (var row in result) {
        final juz = JuzModel.fromJson(row);
        _juzCache.add(juz);

        // Use traditional names for better performance
        _juzNameCache[juz.juzNumber] = MushafUtils.getTraditionalJuzName(juz.juzNumber);
      }
    } catch (e) {
      print('Error loading juz data: $e');
      // Fallback to traditional names
      for (int i = 1; i <= 30; i++) {
        _juzNameCache[i] = MushafUtils.getTraditionalJuzName(i);
      }
    }
  }

  // Optimized surah loading
  static Future<void> _loadAllSurahs() async {
    try {
      final database = await DatabaseManager.surahDatabase;
      final result = await database.query('chapters', orderBy: 'id ASC');

      _surahCache.clear();
      for (var row in result) {
        final surah = SurahModel.fromJson(row);
        _surahCache[surah.id] = surah;
      }
    } catch (e) {
      print('Error loading surahs: $e');
      rethrow;
    }
  }

  // Optimized surah retrieval
  static Future<SurahModel?> getSurahById(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return null;

    // Check cache first
    if (_surahCache.containsKey(surahId)) {
      return _surahCache[surahId];
    }

    // Load all surahs if cache is empty
    if (_surahCache.isEmpty) {
      await _loadAllSurahs();
      return _surahCache[surahId];
    }

    return null;
  }

  // Get all surahs from cache
  static Future<List<SurahModel>> getAllSurahs() async {
    if (_surahCache.isEmpty) {
      await _loadAllSurahs();
    }
    return _surahCache.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  // Optimized juz lookup
  static Future<int> getJuzForSurah(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return 1;
    return MushafUtils.getJuzFromSurah(surahId);
  }

  // Get juz name from cache
  static String getJuzName(int juzNumber) {
    return _juzNameCache[juzNumber] ?? MushafUtils.getTraditionalJuzName(juzNumber);
  }

  // Optimized page layout with caching
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return [];

    // Check cache first
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    try {
      final database = await DatabaseManager.mushafDatabase;
      final result = await database.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC',
      );

      final pageLayout = result.map((row) => PageModel.fromJson(row)).toList();

      // Cache with size limit
      _manageCacheSize(_pageCache, pageNumber, pageLayout);

      return pageLayout;
    } catch (e) {
      print('Error getting page layout for page $pageNumber: $e');
      return [];
    }
  }

  // Optimized words retrieval
  static Future<List<UthmaniModel>> getWordsForLine(PageModel line) async {
    if (line.firstWordId == null || line.lastWordId == null) return [];

    try {
      final database = await DatabaseManager.scriptDatabase;
      final result = await database.query(
        'words',
        where: 'id >= ? AND id <= ?',
        whereArgs: [line.firstWordId, line.lastWordId],
        orderBy: 'id ASC',
      );

      return result.map((row) => UthmaniModel.fromJson(row)).toList();
    } catch (e) {
      print('Error getting words for line: $e');
      return [];
    }
  }

  // Optimized complete page data with caching
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    // Check cache first
    if (_pageDataCache.containsKey(pageNumber)) {
      return _pageDataCache[pageNumber]!.first;
    }

    final pageLayout = await getPageLayout(pageNumber);
    final lines = <Map<String, dynamic>>[];

    // Process lines in batch for better performance
    final futures = pageLayout.map((line) async {
      final words = await getWordsForLine(line);
      return {
        'line': line,
        'words': words,
      };
    });

    final results = await Future.wait(futures);
    lines.addAll(results);

    // Get surah name efficiently
    final surahId = await getSurahForPage(pageNumber);
    final surah = await getSurahById(surahId);

    final pageData = {
      'pageNumber': pageNumber,
      'lines': lines,
      'surahName': surah?.nameArabic ?? 'القرآن الكريم',
      'juzNumber': MushafUtils.getJuzFromPage(pageNumber),
    };

    // Cache with size limit
    _manageCacheSize(_pageDataCache, pageNumber, [pageData]);

    return pageData;
  }

  // Optimized surah lookup for page with caching and fix for type casting
  static Future<int> getSurahForPage(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return 1;

    // Check cache first
    if (_pageSurahCache.containsKey(pageNumber)) {
      return _pageSurahCache[pageNumber]!;
    }

    // Check nearby cached pages
    for (int offset = 1; offset <= 10; offset++) {
      if (_pageSurahCache.containsKey(pageNumber - offset)) {
        final nearbyPage = pageNumber - offset;
        final surahId = _pageSurahCache[nearbyPage]!;

        // Check if this page is likely in the same surah
        final estimatedSurah = await _estimateSurahForPage(pageNumber, nearbyPage, surahId);
        if (estimatedSurah > 0) {
          _pageSurahCache[pageNumber] = estimatedSurah;
          return estimatedSurah;
        }
        break;
      }
    }

    try {
      final database = await DatabaseManager.mushafDatabase;
      final pageResult = await database.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC',
        limit: 1,
      );

      if (pageResult.isNotEmpty) {
        // Fix: Safe parsing of first_word_id
        final firstWordId = MushafUtils.safeParseInt(pageResult.first['first_word_id']);

        if (firstWordId > 0) {
          final surahId = await _getSurahFromWordId(firstWordId);
          _pageSurahCache[pageNumber] = surahId;
          return surahId;
        }
      }
    } catch (e) {
      print('Error getting surah for page $pageNumber: $e');
    }

    // Fallback
    const fallbackSurah = 1;
    _pageSurahCache[pageNumber] = fallbackSurah;
    return fallbackSurah;
  }

  // Estimate surah for page based on nearby page
  static Future<int> _estimateSurahForPage(int targetPage, int knownPage, int knownSurah) async {
    // Simple heuristic: if pages are close, likely same surah
    final pageDiff = (targetPage - knownPage).abs();
    if (pageDiff <= 5) {
      return knownSurah;
    }
    return 0; // Uncertain
  }

  // Optimized surah start page with caching
  static Future<int> getSurahStartPage(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return 1;

    // Check cache first
    if (_surahPageCache.containsKey(surahId)) {
      return _surahPageCache[surahId]!;
    }

    try {
      final scriptDb = await DatabaseManager.scriptDatabase;
      final wordResult = await scriptDb.query(
        'words',
        columns: ['id'],
        where: 'surah = ? AND ayah = 1 AND word = 1',
        whereArgs: [surahId],
        limit: 1,
      );

      if (wordResult.isNotEmpty) {
        final firstWordId = MushafUtils.safeParseInt(wordResult.first['id']);

        final mushafDb = await DatabaseManager.mushafDatabase;
        final pageResult = await mushafDb.query(
          'pages',
          columns: ['page_number'],
          where: 'first_word_id <= ? AND last_word_id >= ?',
          whereArgs: [firstWordId, firstWordId],
          limit: 1,
        );

        if (pageResult.isNotEmpty) {
          final startPage = MushafUtils.safeParseInt(pageResult.first['page_number'], defaultValue: 1);
          _surahPageCache[surahId] = startPage;
          return startPage;
        }
      }
    } catch (e) {
      print('Error getting start page for surah $surahId: $e');
    }

    // Fallback using approximation
    final startPage = MushafUtils.getApproximateSurahStartPage(surahId);
    _surahPageCache[surahId] = startPage;
    return startPage;
  }

  // Get all juz data from cache
  static Future<List<JuzModel>> getAllJuz() async {
    if (_juzCache.isEmpty) {
      await _loadJuzData();
    }
    return List.from(_juzCache);
  }

  // Generic cache size management
  static void _manageCacheSize<T>(Map<int, T> cache, int key, T value) {
    if (cache.length >= _maxCacheSize) {
      // Remove oldest entries (simple FIFO)
      final keysToRemove = cache.keys.take(cache.length - _maxCacheSize + 1);
      for (final keyToRemove in keysToRemove) {
        cache.remove(keyToRemove);
      }
    }
    cache[key] = value;
  }

  // Clear cache for memory management
  static void clearCache() {
    _surahCache.clear();
    _pageCache.clear();
    _pageDataCache.clear();
    _pageSurahCache.clear();
    _surahPageCache.clear();
    _juzCache.clear();
    _juzNameCache.clear();
    _isInitialized = false;
    print('Cache cleared');
  }

  // Get cache status for debugging
  static Map<String, int> getCacheStatus() {
    return {
      'surahs': _surahCache.length,
      'pages': _pageCache.length,
      'pageData': _pageDataCache.length,
      'pageSurah': _pageSurahCache.length,
      'surahPage': _surahPageCache.length,
      'juz': _juzCache.length,
      'juzNames': _juzNameCache.length,
    };
  }
}