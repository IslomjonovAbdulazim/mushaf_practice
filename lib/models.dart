// lib/models.dart - Clean data models

class UthmaniModel {
  final int id;
  final String text;
  final int surah;
  final int ayah;
  final int word;

  const UthmaniModel({
    required this.id,
    required this.text,
    required this.surah,
    required this.ayah,
    required this.word,
  });

  factory UthmaniModel.fromJson(Map<String, dynamic> json) {
    return UthmaniModel(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      surah: json['surah'] as int? ?? 0,
      ayah: json['ayah'] as int? ?? 0,
      word: json['word'] as int? ?? 0,
    );
  }
}

class PageModel {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;

  const PageModel({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      pageNumber: _parseInteger(json['page_number']),
      lineNumber: _parseInteger(json['line_number']),
      lineType: json['line_type']?.toString() ?? '',
      isCentered: _parseInteger(json['is_centered']) == 1,
      firstWordId: _parseInteger(json['first_word_id']),
      lastWordId: _parseInteger(json['last_word_id']),
    );
  }

  static int _parseInteger(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class SurahModel {
  final int id;
  final String nameArabic;
  final String nameSimple;
  final int versesCount;
  final int revelationOrder;
  final String revelationPlace;
  final int bismillahPre;

  const SurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.bismillahPre,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int? ?? 0,
      nameArabic: json['name_arabic'] as String? ?? '',
      nameSimple: json['name_simple'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      revelationOrder: json['revelation_order'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      bismillahPre: json['bismillah_pre'] as int? ?? 0,
    );
  }
}

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