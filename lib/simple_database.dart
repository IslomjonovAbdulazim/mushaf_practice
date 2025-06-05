import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SimpleDatabase {
  static Database? _script;
  static Database? _mushaf;

  // Enhanced cache management
  static final Map<int, Map<String, dynamic>> _pageCache = {};
  static const int _maxCacheSize = 15; // Increased for pagination
  static final List<int> _cacheOrder = []; // LRU tracking

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

  static Future<List<UthmaniModel>> getAllData() async {
    final db = await script;
    final List<Map<String, dynamic>> maps = await db.query('words');
    return maps.map((map) => UthmaniModel.fromJson(map)).toList();
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

    // Remove oldest entries if cache is full
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

    // Get all word IDs needed for this page in one go
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

      // Create a map for O(1) lookup
      for (var wordMap in wordMaps) {
        final word = UthmaniModel.fromJson(wordMap);
        wordsMap[word.id] = word;
      }
    }

    // Build page lines using the words map
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

    final result = {
      'pageNumber': pageNumber,
      'lines': pageLines,
    };

    // Cache the result
    _pageCache[pageNumber] = result;
    _updateCacheOrder(pageNumber);

    return result;
  }

  // Batch loading for preloading multiple pages
  static Future<List<Map<String, dynamic>>> getMultiplePages(List<int> pageNumbers) async {
    final List<Map<String, dynamic>> results = [];

    // Filter out already cached pages
    final List<int> pagesToLoad = pageNumbers
        .where((pageNum) => !_pageCache.containsKey(pageNum))
        .toList();

    // Load uncached pages
    for (int pageNum in pagesToLoad) {
      try {
        final pageData = await getCompletePage(pageNum);
        results.add(pageData);
      } catch (e) {
        print('Error loading page $pageNum: $e');
      }
    }

    // Add cached pages to results
    for (int pageNum in pageNumbers) {
      if (_pageCache.containsKey(pageNum)) {
        _updateCacheOrder(pageNum);
        results.add(_pageCache[pageNum]!);
      }
    }

    return results;
  }

  // Clear specific page from cache
  static void clearPageFromCache(int pageNumber) {
    _pageCache.remove(pageNumber);
    _cacheOrder.remove(pageNumber);
  }

  // Clear all cache
  static void clearCache() {
    _pageCache.clear();
    _cacheOrder.clear();
  }

  // Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedPages': _pageCache.keys.toList()..sort(),
      'cacheSize': _pageCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheOrder': List.from(_cacheOrder),
    };
  }

  // Preload pages around a center page
  static Future<void> preloadPagesAround(int centerPage, {int range = 2}) async {
    final List<int> pagesToPreload = [];

    for (int i = -range; i <= range; i++) {
      final pageNum = centerPage + i;
      if (pageNum >= 1 && pageNum <= 604 && !_pageCache.containsKey(pageNum)) {
        pagesToPreload.add(pageNum);
      }
    }

    if (pagesToPreload.isNotEmpty) {
      // Load in background without blocking UI
      getMultiplePages(pagesToPreload);
    }
  }

  // Keep this method for backward compatibility but mark as deprecated
  @deprecated
  static Future<List<UthmaniModel>> getWordsForLine(int firstWordId, int lastWordId) async {
    final db = await script;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [firstWordId, lastWordId],
      orderBy: 'id ASC',
    );
    return maps.map((map) => UthmaniModel.fromJson(map)).toList();
  }
}