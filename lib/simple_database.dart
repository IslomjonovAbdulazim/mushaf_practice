import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SimpleDatabase {
  static Database? _script;
  static Database? _mushaf;

  static Future<Database> get script async {
    if (_script != null) return _script!;

    // Copy from assets to app directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "script.db");  // Your actual filename

    // Copy from assets if doesn't exist
    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/script/uthmani.db");  // Your actual filename
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _script = await openDatabase(path, readOnly: true);
    return _script!;
  }

  static Future<Database> get mushaf async {
    if (_mushaf != null) return _mushaf!;

    // Copy from assets to app directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "mushaf.db");  // Your actual filename

    // Copy from assets if doesn't exist
    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/mushaf/qpc.db");  // Your actual filename
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _mushaf = await openDatabase(path, readOnly: true);
    return _mushaf!;
  }

  static Future<List<UthmaniModel>> getAllData() async {
    final db = await script;

    // Replace 'people' with your actual table name
    final List<Map<String, dynamic>> maps = await db.query('words');

    // Convert each map to a Person object
    return List.generate(maps.length, (i) {
      return UthmaniModel.fromJson(maps[i]);
    });
  }

  static Future<List<PageModel>> getPage(int pageNumber) async {
    final db = await mushaf;
    final List<Map<String, dynamic>> maps = await db.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    return List.generate(maps.length, (i) => PageModel.fromJson(maps[i]));
  }

  // Get words for a specific line
  static Future<List<UthmaniModel>> getWordsForLine(int firstWordId, int lastWordId) async {
    final db = await script;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [firstWordId, lastWordId],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => UthmaniModel.fromJson(maps[i]));
  }

  // Get complete page with words
  static Future<Map<String, dynamic>> getCompletePage(int pageNumber) async {
    final pageLayout = await getPage(pageNumber);
    List<Map<String, dynamic>> pageLines = [];

    for (PageModel line in pageLayout) {
      if (line.firstWordId != null && line.lastWordId != null) {
        final words = await getWordsForLine(line.firstWordId!, line.lastWordId!);
        pageLines.add({
          'line': line,
          'words': words,
        });
      } else {
        // Handle surah headers, etc.
        pageLines.add({
          'line': line,
          'words': <UthmaniModel>[],
        });
      }
    }

    return {
      'pageNumber': pageNumber,
      'lines': pageLines,
    };
  }
}