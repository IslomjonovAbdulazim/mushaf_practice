// lib/utils/helpers.dart - Utility functions and helpers
class MushafUtils {

  // Calculate juz number from page number (approximate)
  static int getJuzFromPage(int pageNumber) {
    if (pageNumber <= 22) return 1;
    if (pageNumber <= 42) return 2;
    if (pageNumber <= 62) return 3;
    if (pageNumber <= 82) return 4;
    if (pageNumber <= 102) return 5;
    if (pageNumber <= 122) return 6;
    if (pageNumber <= 142) return 7;
    if (pageNumber <= 162) return 8;
    if (pageNumber <= 182) return 9;
    if (pageNumber <= 202) return 10;
    if (pageNumber <= 222) return 11;
    if (pageNumber <= 242) return 12;
    if (pageNumber <= 262) return 13;
    if (pageNumber <= 282) return 14;
    if (pageNumber <= 302) return 15;
    if (pageNumber <= 322) return 16;
    if (pageNumber <= 342) return 17;
    if (pageNumber <= 362) return 18;
    if (pageNumber <= 382) return 19;
    if (pageNumber <= 402) return 20;
    if (pageNumber <= 422) return 21;
    if (pageNumber <= 442) return 22;
    if (pageNumber <= 462) return 23;
    if (pageNumber <= 482) return 24;
    if (pageNumber <= 502) return 25;
    if (pageNumber <= 522) return 26;
    if (pageNumber <= 542) return 27;
    if (pageNumber <= 562) return 28;
    if (pageNumber <= 582) return 29;
    return 30;
  }

  // Check if text contains ayah number markers
  static bool isAyahNumber(String text) {
    return text.contains('۝') ||
        text.contains('﴾') ||
        text.contains('﴿') ||
        (text.length <= 3 && RegExp(r'^[٠-٩]+$').hasMatch(text));
  }

  // Format revelation place in Arabic
  static String formatRevelationPlace(String place) {
    return place.toLowerCase() == 'makkah' ? 'مكية' : 'مدنية';
  }

  // Get traditional juz names (fallback if database lookup fails)
  static String getTraditionalJuzName(int juzNumber) {
    const juzNames = {
      1: 'الم',
      2: 'سيقول',
      3: 'تلك الرسل',
      4: 'لن تنالوا',
      5: 'والمحصنات',
      6: 'لا يحب الله',
      7: 'وإذا سمعوا',
      8: 'ولو أننا',
      9: 'قال الملأ',
      10: 'واعلموا',
      11: 'يعتذرون',
      12: 'وما من دابة',
      13: 'وما أبرئ',
      14: 'ربما',
      15: 'سبحان الذي',
      16: 'قال ألم',
      17: 'اقترب للناس',
      18: 'قد أفلح',
      19: 'وقال الذين',
      20: 'أمن خلق',
      21: 'اتل ما أوحي',
      22: 'ومن يقنت',
      23: 'وما لي',
      24: 'فمن أظلم',
      25: 'إليه يرد',
      26: 'حم',
      27: 'قال فما خطبكم',
      28: 'قد سمع الله',
      29: 'تبارك الذي',
      30: 'عم',
    };

    return juzNames[juzNumber] ?? 'الجزء $juzNumber';
  }

  // Validate page number
  static bool isValidPageNumber(int pageNumber) {
    return pageNumber >= 1 && pageNumber <= 604;
  }

  // Validate surah number
  static bool isValidSurahNumber(int surahNumber) {
    return surahNumber >= 1 && surahNumber <= 114;
  }

  // Get font family based on text type
  static String getFontFamily(String text, {bool isAyahNumber = false}) {
    if (isAyahNumber || MushafUtils.isAyahNumber(text)) {
      return 'Uthmani';
    }
    return 'Digital';
  }

  // Get font size based on text type
  static double getFontSize(String text, {bool isAyahNumber = false}) {
    if (isAyahNumber || MushafUtils.isAyahNumber(text)) {
      return 13.0;
    }
    return 14.5;
  }

  // Format verse count in Arabic
  static String formatVerseCount(int count) {
    return '$count آية';
  }

  // Format page info
  static String formatPageInfo(int pageNumber) {
    return 'الصفحة $pageNumber';
  }

  // Safe integer parsing
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Safe string parsing
  static String safeParseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }
}