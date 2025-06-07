// lib/services/data_service.dart - Clean service layer for data operations
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class DataService {
  // Cache for performance
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, List<PageModel>> _pageCache = {};
  static final List<JuzModel> _juzCache = [];
  static final Map<int, String> _juzNameCache = {};

  // Initialize cache
  static Future<void> initializeCache() async {
    try {
      await _loadJuzData();
      await _loadAllSurahs();
      print('✅ Cache initialized successfully');
    } catch (e) {
      print('❌ Cache initialization failed: $e');
    }
  }

  // Load juz data and names from database
  static Future<void> _loadJuzData() async {
    try {
      final database = await DatabaseManager.juzDatabase;
      final result = await database.query('juz', orderBy: 'juz_number ASC');

      _juzCache.clear();
      _juzNameCache.clear();

      for (var row in result) {
        final juz = JuzModel.fromJson(row);
        _juzCache.add(juz);

        // Get juz name from database
        final juzName = await _getJuzNameFromDatabase(juz.juzNumber, juz.firstVerseKey);
        _juzNameCache[juz.juzNumber] = juzName;
      }
    } catch (e) {
      print('Error loading juz data: $e');
      // Initialize with traditional names as fallback
      for (int i = 1; i <= 30; i++) {
        _juzNameCache[i] = MushafUtils.getTraditionalJuzName(i);
      }
    }
  }

  // Get juz name from database using first verse
  static Future<String> _getJuzNameFromDatabase(int juzNumber, String firstVerseKey) async {
    try {
      final parts = firstVerseKey.split(':');
      if (parts.length >= 2) {
        final surahId = MushafUtils.safeParseInt(parts[0], defaultValue: 1);
        final ayahNumber = MushafUtils.safeParseInt(parts[1], defaultValue: 1);

        final database = await DatabaseManager.scriptDatabase;
        final result = await database.query(
          'words',
          where: 'surah = ? AND ayah = ? AND word = 1',
          whereArgs: [surahId, ayahNumber],
          limit: 1,
        );

        if (result.isNotEmpty) {
          final word = UthmaniModel.fromJson(result.first);
          // Clean the text and return first few words
          final cleanText = word.text.trim();
          if (cleanText.isNotEmpty) {
            return cleanText;
          }
        }
      }
    } catch (e) {
      print('Error getting juz name for juz $juzNumber: $e');
    }

    // Fallback to traditional name
    return MushafUtils.getTraditionalJuzName(juzNumber);
  }

  // Load all surahs into cache
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
      throw e;
    }
  }

  // Get surah by ID
  static Future<SurahModel?> getSurahById(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return null;

    if (_surahCache.containsKey(surahId)) {
      return _surahCache[surahId];
    }

    try {
      final database = await DatabaseManager.surahDatabase;
      final result = await database.query(
        'chapters',
        where: 'id = ?',
        whereArgs: [surahId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final surah = SurahModel.fromJson(result.first);
        _surahCache[surahId] = surah;
        return surah;
      }
    } catch (e) {
      print('Error getting surah $surahId: $e');
    }

    return null;
  }

  // Get all surahs
  static Future<List<SurahModel>> getAllSurahs() async {
    if (_surahCache.isEmpty) {
      await _loadAllSurahs();
    }
    return _surahCache.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  // Get juz number for surah
  static Future<int> getJuzForSurah(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return 1;

    for (var juz in _juzCache) {
      final firstVerse = juz.firstVerseKey.split(':');
      final lastVerse = juz.lastVerseKey.split(':');

      if (firstVerse.length >= 2 && lastVerse.length >= 2) {
        final firstSurah = MushafUtils.safeParseInt(firstVerse[0]);
        final lastSurah = MushafUtils.safeParseInt(lastVerse[0]);

        if (surahId >= firstSurah && surahId <= lastSurah) {
          return juz.juzNumber;
        }
      }
    }

    // Fallback calculation
    return ((surahId - 1) ~/ 4) + 1;
  }

  // Get juz name
  static String getJuzName(int juzNumber) {
    return _juzNameCache[juzNumber] ?? MushafUtils.getTraditionalJuzName(juzNumber);
  }

  // Get page layout
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return [];

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

      // Cache result (limit cache size to prevent memory issues)
      if (_pageCache.length < 50) {
        _pageCache[pageNumber] = pageLayout;
      } else {
        // Remove oldest entry
        final oldestKey = _pageCache.keys.first;
        _pageCache.remove(oldestKey);
        _pageCache[pageNumber] = pageLayout;
      }

      return pageLayout;
    } catch (e) {
      print('Error getting page layout for page $pageNumber: $e');
      return [];
    }
  }

  // Get words for line
  static Future<List<UthmaniModel>> getWordsForLine(PageModel line) async {
    if (line.firstWordId == null || line.lastWordId == null) {
      return [];
    }

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

  // Get complete page data
  static Future<Map<String, dynamic>> getCompletePageData(int pageNumber) async {
    final pageLayout = await getPageLayout(pageNumber);
    final lines = <Map<String, dynamic>>[];

    // Process each line
    for (var line in pageLayout) {
      final words = await getWordsForLine(line);
      lines.add({
        'line': line,
        'words': words,
      });
    }

    // Get surah name for this page
    final surahId = await getSurahForPage(pageNumber);
    final surah = await getSurahById(surahId);

    return {
      'pageNumber': pageNumber,
      'lines': lines,
      'surahName': surah?.nameArabic ?? 'القرآن الكريم',
      'juzNumber': MushafUtils.getJuzFromPage(pageNumber),
    };
  }

  // Get surah for page using database queries
  static Future<int> getSurahForPage(int pageNumber) async {
    if (!MushafUtils.isValidPageNumber(pageNumber)) return 1;

    try {
      final database = await DatabaseManager.mushafDatabase;

      // Get first word of this page
      final pageResult = await database.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC',
        limit: 1,
      );

      if (pageResult.isNotEmpty) {
        final firstWordId = pageResult.first['first_word_id'] as int?;

        if (firstWordId != null) {
          final scriptDb = await DatabaseManager.scriptDatabase;
          final wordResult = await scriptDb.query(
            'words',
            where: 'id = ?',
            whereArgs: [firstWordId],
            limit: 1,
          );

          if (wordResult.isNotEmpty) {
            return MushafUtils.safeParseInt(wordResult.first['surah'], defaultValue: 1);
          }
        }
      }
    } catch (e) {
      print('Error getting surah for page $pageNumber: $e');
    }

    return 1; // Default: Al-Fatiha
  }

  // Get surah start page using database
  static Future<int> getSurahStartPage(int surahId) async {
    if (!MushafUtils.isValidSurahNumber(surahId)) return 1;

    try {
      final scriptDb = await DatabaseManager.scriptDatabase;

      // Get first word of this surah
      final wordResult = await scriptDb.query(
        'words',
        where: 'surah = ? AND ayah = 1 AND word = 1',
        whereArgs: [surahId],
        limit: 1,
      );

      if (wordResult.isNotEmpty) {
        final firstWordId = wordResult.first['id'] as int;

        // Find which page contains this word
        final mushafDb = await DatabaseManager.mushafDatabase;
        final pageResult = await mushafDb.query(
          'pages',
          where: 'first_word_id <= ? AND last_word_id >= ?',
          whereArgs: [firstWordId, firstWordId],
          limit: 1,
        );

        if (pageResult.isNotEmpty) {
          return MushafUtils.safeParseInt(pageResult.first['page_number'], defaultValue: 1);
        }
      }
    } catch (e) {
      print('Error getting start page for surah $surahId: $e');
    }

    return 1; // Default
  }

  // Get all juz data
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
    _juzCache.clear();
    _juzNameCache.clear();
    print('Cache cleared');
  }

  // Get cache status for debugging
  static Map<String, int> getCacheStatus() {
    return {
      'surahs': _surahCache.length,
      'pages': _pageCache.length,
      'juz': _juzCache.length,
      'juzNames': _juzNameCache.length,
    };
  }
}