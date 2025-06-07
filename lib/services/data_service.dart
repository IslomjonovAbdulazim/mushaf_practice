// lib/services/data_service.dart - Service layer for data operations
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';

class DataService {
  // Cache for performance
  static final Map<int, SurahModel> _surahCache = {};
  static final Map<int, List<PageModel>> _pageCache = {};
  static final List<JuzModel> _juzCache = [];
  static final Map<int, String> _juzNameCache = {};

  // Initialize cache
  static Future<void> initializeCache() async {
    await _loadJuzNames();
    await _loadAllSurahs();
  }

  // Load juz names from database
  static Future<void> _loadJuzNames() async {
    try {
      final database = await DatabaseManager.juzDatabase;
      final result = await database.query('juz', orderBy: 'juz_number ASC');

      _juzCache.clear();
      _juzNameCache.clear();

      for (var row in result) {
        final juz = JuzModel.fromJson(row);
        _juzCache.add(juz);

        // Extract juz name from first verse
        final juzName = await _getJuzName(juz.juzNumber, juz.firstVerseKey);
        _juzNameCache[juz.juzNumber] = juzName;
      }
    } catch (e) {
      print('Error loading juz names: $e');
    }
  }

  // Get juz name from database
  static Future<String> _getJuzName(int juzNumber, String firstVerseKey) async {
    try {
      final parts = firstVerseKey.split(':');
      if (parts.length >= 2) {
        final surahId = int.tryParse(parts[0]) ?? 1;
        final ayahNumber = int.tryParse(parts[1]) ?? 1;

        final database = await DatabaseManager.scriptDatabase;
        final result = await database.query(
          'words',
          where: 'surah = ? AND ayah = ? AND word = 1',
          whereArgs: [surahId, ayahNumber],
          limit: 1,
        );

        if (result.isNotEmpty) {
          final word = UthmaniModel.fromJson(result.first);
          return word.text;
        }
      }
    } catch (e) {
      print('Error getting juz name for juz $juzNumber: $e');
    }

    return 'الجزء $juzNumber';
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
    }
  }

  // Get surah by ID
  static Future<SurahModel?> getSurahById(int surahId) async {
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
    for (var juz in _juzCache) {
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

    // Fallback
    return ((surahId - 1) ~/ 4) + 1;
  }

  // Get juz name
  static String getJuzName(int juzNumber) {
    return _juzNameCache[juzNumber] ?? 'الجزء $juzNumber';
  }

  // Get page layout
  static Future<List<PageModel>> getPageLayout(int pageNumber) async {
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

      // Cache result (limit cache size)
      if (_pageCache.length < 50) {
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
    };
  }

  // Get surah for page
  static Future<int> getSurahForPage(int pageNumber) async {
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
            return wordResult.first['surah'] as int? ?? 1;
          }
        }
      }
    } catch (e) {
      print('Error getting surah for page $pageNumber: $e');
    }

    return 1; // Default: Al-Fatiha
  }

  // Get surah start page
  static Future<int> getSurahStartPage(int surahId) async {
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
          return pageResult.first['page_number'] as int;
        }
      }
    } catch (e) {
      print('Error getting start page for surah $surahId: $e');
    }

    return 1; // Default
  }

  // Clear cache
  static void clearCache() {
    _surahCache.clear();
    _pageCache.clear();
    _juzCache.clear();
    _juzNameCache.clear();
  }
}