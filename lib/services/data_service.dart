// lib/services/data_service.dart - Heavy performance optimizations
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class DataService {
  // Aggressive caching with larger cache sizes
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, List<PageModel>> _pageCache = {};
  static final Map<int, Map<String, dynamic>> _pageDataCache = {};
  static final Map<int, int> _pageSurahCache = {};
  static final Map<int, int> _surahPageCache = {};
  static final List<JuzModel> _juzCache = [];
  static final Map<int, String> _juzNameCache = {};

  // Preloaded page ranges for instant access
  static final Map<String, List<Map<String, dynamic>>> _surahPagesCache = {};
  static final Map<int, String> _pageSurahNameCache = {}; // Quick surah name lookup

  static const int _maxCacheSize = 100; // Increased cache size
  static const int _preloadRange = 10; // Preload pages around current page
  static bool _isInitialized = false;

  // Initialize cache with heavy preloading
  static Future<void> initializeCache() async {
    if (_isInitialized) return;

    print('🚀 Starting heavy cache initialization...');
    final stopwatch = Stopwatch()..start();

    try {
      await Future.wait([
        _loadJuzData(),
        _loadAllSurahs(),
        _preloadAllPageSurahMappings(), // Preload ALL page-surah mappings
        _preloadCriticalPages(), // Preload first pages of each surah
      ]);

      _isInitialized = true;
      stopwatch.stop();
      print('✅ Heavy cache initialized in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('❌ Cache initialization failed: $e');
      rethrow;
    }
  }

  // Preload ALL page-surah mappings for instant lookup
  static Future<void> _preloadAllPageSurahMappings() async {
    try {
      print('📚 Preloading all page-surah mappings...');

      // Load surah start pages for quick calculation
      for (int surahId = 1; surahId <= 114; surahId++) {
        final startPage = MushafUtils.getApproximateSurahStartPage(surahId);
        _surahPageCache[surahId] = startPage;

        // Also cache reverse mapping for quick lookup
        int endPage = startPage + 8; // Approximate surah length
        if (surahId < 114) {
          endPage = MushafUtils.getApproximateSurahStartPage(surahId + 1) - 1;
        } else {
          endPage = 604; // Last page
        }

        // Cache page-to-surah mapping for this range
        for (int page = startPage; page <= endPage && page <= 604; page++) {
          _pageSurahCache[page] = surahId;
          // Also cache surah name for instant display
          final surah = _surahCache[surahId];
          if (surah != null) {
            _pageSurahNameCache[page] = surah.nameArabic;
          }
        }
      }

      print('✅ All page-surah mappings preloaded');
    } catch (e) {
      print('❌ Error preloading page mappings: $e');
    }
  }

  // Preload critical pages (first page of each surah)
  static Future<void> _preloadCriticalPages() async {
    try {
      print('🔥 Preloading critical pages...');

      final criticalPages = [1, 2, 22, 42, 62, 82, 102, 122, 142, 162, 182, 202, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];

      for (int pageNum in criticalPages) {
        await _preloadPageData(pageNum);
      }

      print('✅ Critical pages preloaded');
    } catch (e) {
      print('❌ Error preloading critical pages: $e');
    }
  }

  // Preload page data in background
  static Future<void> _preloadPageData(int pageNumber) async {
    if (_pageDataCache.containsKey(pageNumber)) return;

    try {
      final pageLayout = await _getPageLayoutFast(pageNumber);
      final lines = <Map<String, dynamic>>[];

      // Process lines efficiently
      for (var line in pageLayout) {
        final words = await getWordsForLine(line);
        lines.add({
          'line': line,
          'words': words,
        });
      }

      // Get surah info quickly
      final surahId = _pageSurahCache[pageNumber] ?? 1;
      final surahName = _pageSurahNameCache[pageNumber] ?? 'Holy Quran';

      final pageData = {
        'pageNumber': pageNumber,
        'lines': lines,
        'surahName': surahName,
        'juzNumber': MushafUtils.getJuzFromPage(pageNumber),
      };

      _pageDataCache[pageNumber] = pageData;
    } catch (e) {
      print('Error preloading page $pageNumber: $e');
    }
  }

  // Fast page layout retrieval
  static Future<List<PageModel>> _getPageLayoutFast(int pageNumber) async {
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
      _pageCache[pageNumber] = pageLayout;
      return pageLayout;
    } catch (e) {
      print('Error getting page layout for page $pageNumber: $e');
      return [];
    }
  }

  // Ultra-fast surah name lookup
  static String getSurahNameForPage(int pageNumber) {
    // Try cache first
    if (_pageSurahNameCache.containsKey(pageNumber)) {
      return _pageSurahNameCache[pageNumber]!;
    }

    // Fallback calculation
    final surahId = _pageSurahCache[pageNumber] ?? 1;
    final surah = _surahCache[surahId];
    final name = surah?.nameArabic ?? 'Holy Quran';

    // Cache for next time
    _pageSurahNameCache[pageNumber] = name;
    return name;
  }

  // Preload pages around current page for smooth navigation
  static Future<void> preloadAroundPage(int currentPage) async {
    final pagesToPreload = <int>[];

    // Preload pages before and after current page
    for (int i = -_preloadRange; i <= _preloadRange; i++) {
      final pageNum = currentPage + i;
      if (pageNum >= 1 && pageNum <= 604 && !_pageDataCache.containsKey(pageNum)) {
        pagesToPreload.add(pageNum);
      }
    }

    // Preload in background without waiting
    Future.microtask(() async {
      for (int pageNum in pagesToPreload) {
        await _preloadPageData(pageNum);
      }
    });
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
        _juzNameCache[juz.juzNumber] = MushafUtils.getTraditionalJuzName(juz.juzNumber);
      }
    } catch (e) {
      print('Error loading juz data: $e');
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

  // Super fast surah retrieval
  static Future<SurahModel?> getSurahById(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return null;
    return _surahCache[surahId];
  }

  // Get all surahs from cache
  static Future<List<SurahModel>> getAllSurahs() async {
    if (_surahCache.isEmpty) {
      await _loadAllSurahs();
    }
    return _surahCache.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  // Fast juz lookup
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
    return await _getPageLayoutFast(pageNumber);
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

  // ULTRA-FAST complete page data with aggressive caching
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    // Check cache first - instant return!
    if (_pageDataCache.containsKey(pageNumber)) {
      // Preload around this page in background
      preloadAroundPage(pageNumber);
      return _pageDataCache[pageNumber]!;
    }

    // Load this page and preload around it
    await _preloadPageData(pageNumber);
    preloadAroundPage(pageNumber);

    return _pageDataCache[pageNumber] ?? {
      'pageNumber': pageNumber,
      'lines': [],
      'surahName': 'Holy Quran',
      'juzNumber': 1,
    };
  }

  // Fast surah lookup for page
  static Future<int> getSurahForPage(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return 1;
    return _pageSurahCache[pageNumber] ?? 1;
  }

  // Fast surah start page with caching
  static Future<int> getSurahStartPage(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return 1;
    return _surahPageCache[surahId] ?? MushafUtils.getApproximateSurahStartPage(surahId);
  }

  // Get all juz data from cache
  static Future<List<JuzModel>> getAllJuz() async {
    if (_juzCache.isEmpty) {
      await _loadJuzData();
    }
    return List.from(_juzCache);
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
    _surahPagesCache.clear();
    _pageSurahNameCache.clear();
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
      'pageSurahNames': _pageSurahNameCache.length,
    };
  }
}