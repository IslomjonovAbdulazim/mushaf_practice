// lib/models.dart - Simplified models for basic Mushaf display

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UthmaniModel && id == other.id;

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
      pageNumber: _parseInt(json['page_number']),
      lineNumber: _parseInt(json['line_number']),
      lineType: json['line_type']?.toString() ?? '',
      isCentered: _parseInt(json['is_centered']) == 1,
      firstWordId: _parseInt(json['first_word_id']),
      lastWordId: _parseInt(json['last_word_id']),
    );
  }

  static int _parseInt(dynamic value) {
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

  const SurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
    required int name,
    required int revelationOrder,
    required String revelationPlace,
    required int bismillahPre,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int? ?? 0,
      nameArabic: json['name_arabic'] as String? ?? '',
      nameSimple: json['name_simple'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      name: json['chapters'] as int? ?? 0,
      revelationOrder: json['revelation_order'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      bismillahPre: json['bismillah_pre'] as int? ?? 0,
    );
  }
}