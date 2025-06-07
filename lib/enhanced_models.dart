// lib/enhanced_models.dart
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

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      juzNumber: json['juz_number'] as int? ?? 0,
      versesCount: json['verses_count'] as int? ?? 0,
      firstVerseKey: json['first_verse_key'] as String? ?? '',
      lastVerseKey: json['last_verse_key'] as String? ?? '',
      verseMapping: json['verse_mapping'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SurahModel {
  final int id;
  final int name; // Changed to int as requested
  final String nameSimple;
  final String nameArabic;
  final int revelationOrder;
  final String revelationPlace;
  final int versesCount;
  final int bismillahPre; // Changed to int (0/1) as requested

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

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as int? ?? 0, // Now expecting int
      nameSimple: json['name_simple'] as String? ?? '',
      nameArabic: json['name_arabic'] as String? ?? '',
      revelationOrder: json['revelation_order'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      bismillahPre: json['bismillah_pre'] as int? ?? 0, // Now int (0/1)
    );
  }

  // Convenience getter to check if bismillah is present
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