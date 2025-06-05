class UthmaniModel {
  late int id;
  late String location;
  late int surah;
  late int ayah;
  late int word;
  late String text;

  // Default constructor
  UthmaniModel({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  // Named constructor for creating from JSON
  UthmaniModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    location = json['location'] ?? '';
    surah = json['surah'] ?? 0;
    ayah = json['ayah'] ?? 0;
    word = json['word'] ?? 0;
    text = json['text'] ?? '';
  }

  // Optional: toJson method for serialization
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
    return "${toJson()}\n--------------------------------------\n";
  }
}

class PageModel {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;

  PageModel({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahNumber,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      pageNumber: int.tryParse(json['page_number'].toString()) ?? 0,
      lineNumber: int.tryParse(json['line_number'].toString()) ?? 0,
      lineType: json['line_type']?.toString() ?? '',
      isCentered: (int.tryParse(json['is_centered'].toString()) ?? 0) == 1,
      firstWordId: int.tryParse(json['first_word_id']!.toString()),
      lastWordId: int.tryParse(json['last_word_id']!.toString()),
      surahNumber: int.tryParse(json['surah_number']!.toString()),
    );
  }
}