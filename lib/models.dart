class UthmaniModel {
  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;

  // Const constructor for better performance
  const UthmaniModel({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  // Optimized fromJson with null safety and default values
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

  // Add equality and hashCode for better caching
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

  // Optimized fromJson with better parsing
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

  // Helper method for consistent int parsing
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