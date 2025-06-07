// lib/models.dart - All models consolidated into one file
// This combines the previous models.dart and enhanced_models.dart

class UthmaniModel {
  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;

  // Using const constructor for better performance with immutable objects
  const UthmaniModel({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  // Factory constructor with null safety and sensible defaults
  factory UthmaniModel.fromJson(Map<String, dynamic> json) {
    return UthmaniModel(
      id: json['id'] as int? ?? 0,
      location: json['location'] as String? ?? '',
      surah: json['surah'] as int? ?? 0,
      ayah: json['ayah'] as int? ?? 0,
      word: json['word'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  // Convert model back to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'surah': surah,
      'ayah': ayah,
      'word': word,
      'text': text,
    };
  }

  @override
  String toString() {
    return "UthmaniModel(id: $id, surah: $surah, ayah: $ayah, word: $word, text: '$text')";
  }

  // Implementing equality operators for efficient caching and comparisons
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UthmaniModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PageModel {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;

  const PageModel({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahNumber,
  });

  // Factory constructor with improved parsing logic
  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      pageNumber: _parseIntSafely(json['page_number']),
      lineNumber: _parseIntSafely(json['line_number']),
      lineType: json['line_type']?.toString() ?? '',
      isCentered: _parseIntSafely(json['is_centered']) == 1,
      firstWordId: _parseIntSafely(json['first_word_id']),
      lastWordId: _parseIntSafely(json['last_word_id']),
      surahNumber: _parseIntSafely(json['surah_number']),
    );
  }

  // Helper method to safely parse integers from various data types
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PageModel &&
              runtimeType == other.runtimeType &&
              pageNumber == other.pageNumber &&
              lineNumber == other.lineNumber;

  @override
  int get hashCode => pageNumber.hashCode ^ lineNumber.hashCode;
}

class JuzModel {
  final int juzNumber;
  final int versesCount;
  final String firstVerseKey;
  final String lastVerseKey;
  final Map<String, dynamic> verseMapping;

  const JuzModel({
    required this.juzNumber,
    required this.versesCount,
    required this.firstVerseKey,
    required this.lastVerseKey,
    required this.verseMapping,
  });

  // Factory constructor for creating JuzModel from JSON data
  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      juzNumber: json['juz'] as int? ?? 0, // Using 'juz' column name
      versesCount: json['verses_count'] as int? ?? 0,
      firstVerseKey: json['first_verse_key'] as String? ?? '',
      lastVerseKey: json['last_verse_key'] as String? ?? '',
      verseMapping: json['verse_mapping'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SurahModel {
  final int id;
  final int name;
  final String nameSimple;
  final String nameArabic;
  final int revelationOrder;
  final String revelationPlace;
  final int versesCount;
  final int bismillahPre;

  const SurahModel({
    required this.id,
    required this.name,
    required this.nameSimple,
    required this.nameArabic,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.versesCount,
    required this.bismillahPre,
  });

  // Factory constructor with proper column name mapping
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int? ?? 0,
      name: json['chapters'] as int? ?? 0, // Using 'chapters' column name
      nameSimple: json['name_simple'] as String? ?? '',
      nameArabic: json['name_arabic'] as String? ?? '',
      revelationOrder: json['revelation_order'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      bismillahPre: json['bismillah_pre'] as int? ?? 0,
    );
  }

  // Convenience getter to check if this surah has bismillah
  bool get hasBismillah => bismillahPre == 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SurahModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PageMetadata {
  final int pageNumber;
  final int juzNumber;
  final SurahModel primarySurah;
  final List<SurahModel> allSurahs;
  final bool isRightPage;
  final bool isLeftPage;

  const PageMetadata({
    required this.pageNumber,
    required this.juzNumber,
    required this.primarySurah,
    required this.allSurahs,
    required this.isRightPage,
    required this.isLeftPage,
  });

  // Helper property to check if page contains multiple surahs
  bool get hasMultipleSurahs => allSurahs.length > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PageMetadata &&
              runtimeType == other.runtimeType &&
              pageNumber == other.pageNumber;

  @override
  int get hashCode => pageNumber.hashCode;
}