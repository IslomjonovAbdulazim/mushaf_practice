// lib/services/data_service.dart - Ultra-optimized with aggressive caching
import 'dart:async';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class DataService {
  // Ultra-aggressive caching with massive cache sizes
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, List<PageModel>> _pageCache = {};
  static final Map<int, Map<String, dynamic>> _pageDataCache = {};
  static final Map<int, int> _pageSurahCache = {};
  static final Map<int, int> _surahPageCache = {};
  static final List<JuzModel> _juzCache = [];
  static final Map<int, String> _juzNameCache = {};
  static final Map<int, String> _pageSurahNameCache = {};
  static final Map<int, int> _pageJuzCache = {};

  // Preloading queues and trackers
  static final Set<int> _preloadingPages = {};
  static final Set<int> _preloadedPages = {};
  static Timer? _preloadTimer;

  static const int _maxCacheSize = 200; // Massive cache size
  static const int _aggressivePreloadRange = 25; // Preload 25 pages around current
  static const int _initialPreloadRange = 50; // Preload first 50 pages at startup
  static bool _isInitialized = false;
  static bool _heavyPreloadComplete = false;

  // Initialize with ultra-aggressive preloading
  static Future<void> initializeCache() async {
    if (_isInitialized) return;

    print('🚀 Starting ULTRA-AGGRESSIVE cache initialization...');
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Load essential data in correct order
      print('📖 Loading surahs first...');
      await _loadAllSurahs();

      print('📊 Loading juz data...');
      await _loadJuzData();

      print('🗺️ Building page mappings...');
      await _buildAllPageMappings();

      _isInitialized = true;

      // Phase 2: Heavy preloading (background)
      unawaited(_startHeavyPreloading());

      stopwatch.stop();
      print('✅ Essential cache initialized in ${stopwatch.elapsedMilliseconds}ms');
      print('🔥 Heavy preloading started in background...');
    } catch (e) {
      print('❌ Cache initialization failed: $e');
      rethrow;
    }
  }

  // Build ALL page mappings instantly
  static Future<void> _buildAllPageMappings() async {
    print('📚 Building ALL page mappings...');

    // Ensure surahs are loaded first
    if (_surahCache.isEmpty) {
      await _loadAllSurahs();
    }

    // Use optimized mappings from helpers
    for (int page = 1; page <= 604; page++) {
      // Fast juz calculation
      final juz = MushafUtils.getJuzFromPage(page);
      _pageJuzCache[page] = juz;

      // Fast surah calculation using approximate mappings
      int surahId = 1;
      for (int i = 114; i >= 1; i--) {
        final startPage = MushafUtils.getApproximateSurahStartPage(i);
        if (page >= startPage) {
          surahId = i;
          break;
        }
      }

      _pageSurahCache[page] = surahId;

      // Cache Arabic surah name for instant lookup
      final surah = _surahCache[surahId];
      if (surah != null) {
        _pageSurahNameCache[page] = surah.nameArabic;
        print('Cached page $page -> ${surah.nameArabic}'); // Debug log
      } else {
        print('No surah found for page $page, surahId: $surahId'); // Debug log
      }
    }

    print('✅ All page mappings built with ${_pageSurahNameCache.length} Arabic names');
  }

  // Heavy preloading in background
  static Future<void> _startHeavyPreloading() async {
    try {
      print('🔥 Starting heavy preloading of first $_initialPreloadRange pages...');

      // Preload critical pages first (surah starts)
      final criticalPages = <int>[];
      for (int surahId = 1; surahId <= 114; surahId++) {
        final startPage = MushafUtils.getApproximateSurahStartPage(surahId);
        if (!criticalPages.contains(startPage)) {
          criticalPages.add(startPage);
        }
      }

      // Preload critical pages first
      for (int page in criticalPages.take(20)) {
        await _preloadPageDataSilent(page);
        _preloadedPages.add(page);
      }

      // Then preload first 50 pages
      for (int page = 1; page <= _initialPreloadRange; page++) {
        if (!_preloadedPages.contains(page)) {
          await _preloadPageDataSilent(page);
          _preloadedPages.add(page);
        }
      }

      _heavyPreloadComplete = true;
      print('✅ Heavy preloading completed!');
      print('📊 Preloaded ${_preloadedPages.length} pages');
    } catch (e) {
      print('❌ Heavy preloading failed: $e');
    }
  }

  // Silent preloading without errors
  static Future<void> _preloadPageDataSilent(int pageNumber) async {
    try {
      if (_pageDataCache.containsKey(pageNumber)) return;

      final pageLayout = await _getPageLayoutFast(pageNumber);
      final lines = <Map<String, dynamic>>[];

      for (var line in pageLayout) {
        final words = await getWordsForLine(line);
        lines.add({
          'line': line,
          'words': words,
        });
      }

      final surahName = _pageSurahNameCache[pageNumber] ?? 'Holy Quran';
      final juzNumber = _pageJuzCache[pageNumber] ?? 1;

      final pageData = {
        'pageNumber': pageNumber,
        'lines': lines,
        'surahName': surahName,
        'juzNumber': juzNumber,
      };

      _pageDataCache[pageNumber] = pageData;
    } catch (e) {
      // Silent fail for background preloading
    }
  }

  // Ultra-aggressive preloading around current page
  static Future<void> preloadAroundPage(int currentPage) async {
    if (!_isInitialized) return;

    // Cancel previous preloading
    _preloadTimer?.cancel();

    // Start new preloading
    _preloadTimer = Timer(const Duration(milliseconds: 100), () async {
      final pagesToPreload = <int>[];

      // Aggressive range: 25 pages before and after
      for (int i = -_aggressivePreloadRange; i <= _aggressivePreloadRange; i++) {
        final pageNum = currentPage + i;
        if (pageNum >= 1 &&
            pageNum <= 604 &&
            !_pageDataCache.containsKey(pageNum) &&
            !_preloadingPages.contains(pageNum)) {
          pagesToPreload.add(pageNum);
          _preloadingPages.add(pageNum);
        }
      }

      // Preload in chunks for better performance
      const chunkSize = 5;
      for (int i = 0; i < pagesToPreload.length; i += chunkSize) {
        final chunk = pagesToPreload.skip(i).take(chunkSize);
        await Future.wait(
          chunk.map((page) async {
            await _preloadPageDataSilent(page);
            _preloadingPages.remove(page);
            _preloadedPages.add(page);
          }),
        );
      }
    });
  }

  // Ultra-fast page data retrieval
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    // Instant return if cached
    if (_pageDataCache.containsKey(pageNumber)) {
      // Start aggressive preloading around this page
      unawaited(preloadAroundPage(pageNumber));
      return _pageDataCache[pageNumber]!;
    }

    // If not cached, load immediately and start preloading
    await _preloadPageDataSilent(pageNumber);
    unawaited(preloadAroundPage(pageNumber));

    return _pageDataCache[pageNumber] ?? _buildFallbackPageData(pageNumber);
  }

  // Fallback page data for edge cases
  static Map<String, dynamic> _buildFallbackPageData(int pageNumber) {
    return {
      'pageNumber': pageNumber,
      'lines': [],
      'surahName': _pageSurahNameCache[pageNumber] ?? 'Holy Quran',
      'juzNumber': _pageJuzCache[pageNumber] ?? 1,
    };
  }

  // Ultra-fast surah name lookup (always returns Arabic name)
  static String getSurahNameForPage(int pageNumber) {
    // Try cache first
    if (_pageSurahNameCache.containsKey(pageNumber)) {
      final name = _pageSurahNameCache[pageNumber]!;
      print('Cache hit for page $pageNumber: $name'); // Debug log
      return name;
    }

    print('Cache miss for page $pageNumber, calculating...'); // Debug log

    // Fallback: calculate surah and get Arabic name
    final surahId = _pageSurahCache[pageNumber] ?? 1;
    print('Surah ID for page $pageNumber: $surahId'); // Debug log

    final surah = _surahCache[surahId];
    if (surah != null) {
      final arabicName = surah.nameArabic;
      print('Found Arabic name: $arabicName'); // Debug log
      _pageSurahNameCache[pageNumber] = arabicName; // Cache for next time
      return arabicName;
    }

    print('No surah found, using fallback'); // Debug log
    return 'القرآن الكريم'; // Arabic fallback: "The Noble Quran"
  }

  // Ultra-fast juz lookup
  static int getJuzForPage(int pageNumber) {
    return _pageJuzCache[pageNumber] ?? 1;
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

      // Cache with aggressive size management
      _manageCacheSize(_pageCache, pageNumber, pageLayout);

      return pageLayout;
    } catch (e) {
      print('Error getting page layout for page $pageNumber: $e');
      return [];
    }
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

  // Fast surah retrieval
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

  // Fast surah lookup for page
  static Future<int> getSurahForPage(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return 1;
    return _pageSurahCache[pageNumber] ?? 1;
  }

  // Fast surah start page
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

  // Aggressive cache size management
  static void _manageCacheSize<T>(Map<int, T> cache, int key, T value) {
    if (cache.length >= _maxCacheSize) {
      // Remove oldest entries
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
    _pageSurahNameCache.clear();
    _pageJuzCache.clear();
    _preloadingPages.clear();
    _preloadedPages.clear();
    _preloadTimer?.cancel();
    _isInitialized = false;
    _heavyPreloadComplete = false;
    print('Cache cleared');
  }

  // Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    print('=== CACHE DEBUG INFO ===');
    print('Surahs loaded: ${_surahCache.length}');
    print('Page surah mappings: ${_pageSurahCache.length}');
    print('Page surah names: ${_pageSurahNameCache.length}');
    print('Page juz mappings: ${_pageJuzCache.length}');

    // Print first few surahs for debugging
    if (_surahCache.isNotEmpty) {
      print('First few surahs:');
      for (int i = 1; i <= 5; i++) {
        final surah = _surahCache[i];
        if (surah != null) {
          print('  Surah $i: ${surah.nameArabic} (${surah.nameSimple})');
        }
      }
    }

    // Print first few page mappings
    if (_pageSurahNameCache.isNotEmpty) {
      print('First few page mappings:');
      for (int i = 1; i <= 5; i++) {
        final name = _pageSurahNameCache[i];
        if (name != null) {
          print('  Page $i: $name');
        }
      }
    }

    return {
      'surahs': _surahCache.length,
      'pages': _pageCache.length,
      'pageData': _pageDataCache.length,
      'pageSurah': _pageSurahCache.length,
      'surahPage': _surahPageCache.length,
      'juz': _juzCache.length,
      'juzNames': _juzNameCache.length,
      'pageSurahNames': _pageSurahNameCache.length,
      'pageJuz': _pageJuzCache.length,
      'preloadedPages': _preloadedPages.length,
      'heavyPreloadComplete': _heavyPreloadComplete,
    };
  }
}