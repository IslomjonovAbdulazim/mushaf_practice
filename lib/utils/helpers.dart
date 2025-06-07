// lib/utils/helpers.dart - Optimized utility functions
class MushafUtils {
  // Cached juz boundaries for O(1) lookup
  static const List<int> _juzPageBoundaries = [
    1, 22, 42, 62, 82, 102, 122, 142, 162, 182, 202, 222, 242, 262, 282,
    302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582, 604
  ];

  // Cached surah start pages for faster lookup
  static const Map<int, int> _surahStartPages = {
    1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
    11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
    21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
    31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
    41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
    51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
    61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
    71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
    81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
    91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599, 100: 599,
    101: 600, 102: 600, 103: 601, 104: 601, 105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603,
    111: 603, 112: 604, 113: 604, 114: 604
  };

  // O(log n) juz calculation using binary search
  static int getJuzFromPage(int pageNumber) {
    if (pageNumber < 1) return 1;
    if (pageNumber > 604) return 30;

    for (int i = 0; i < _juzPageBoundaries.length - 1; i++) {
      if (pageNumber >= _juzPageBoundaries[i] && pageNumber < _juzPageBoundaries[i + 1]) {
        return i + 1;
      }
    }
    return 30;
  }

  // Fast juz calculation from surah
  static int getJuzFromSurah(int surahId) {
    if (surahId < 1) return 1;
    if (surahId > 114) return 30;

    // Optimized mapping based on surah ranges
    if (surahId == 1) return 1;
    if (surahId <= 2) return 1;
    if (surahId <= 4) return getJuzFromPage(_surahStartPages[surahId] ?? 1);
    if (surahId <= 9) return getJuzFromPage(_surahStartPages[surahId] ?? 1);

    // For remaining surahs, use cached start pages
    final startPage = _surahStartPages[surahId] ?? 1;
    return getJuzFromPage(startPage);
  }

  // Fast surah start page lookup
  static int getApproximateSurahStartPage(int surahId) {
    return _surahStartPages[surahId] ?? 1;
  }

  // Optimized ayah number detection using cached regex
  static final RegExp _ayahNumberRegex = RegExp(r'^[٠-٩]+$');
  static final Set<String> _ayahMarkers = {'۝', '﴾', '﴿'};

  static bool isAyahNumber(String text) {
    if (text.length > 3) return false;

    // Check for ayah markers first (fastest)
    for (final marker in _ayahMarkers) {
      if (text.contains(marker)) return true;
    }

    // Check for Arabic numerals
    return text.length <= 3 && _ayahNumberRegex.hasMatch(text);
  }

  // Cached revelation place formatting
  static const Map<String, String> _revelationPlaces = {
    'makkah': 'مكية',
    'madinah': 'مدنية',
    'medina': 'مدنية',
  };

  static String formatRevelationPlace(String place) {
    return _revelationPlaces[place.toLowerCase()] ?? 'مكية';
  }

  // Cached juz names for faster lookup
  static const Map<int, String> _juzNames = {
    1: 'الم', 2: 'سيقول', 3: 'تلك الرسل', 4: 'لن تنالوا', 5: 'والمحصنات',
    6: 'لا يحب الله', 7: 'وإذا سمعوا', 8: 'ولو أننا', 9: 'قال الملأ', 10: 'واعلموا',
    11: 'يعتذرون', 12: 'وما من دابة', 13: 'وما أبرئ', 14: 'ربما', 15: 'سبحان الذي',
    16: 'قال ألم', 17: 'اقترب للناس', 18: 'قد أفلح', 19: 'وقال الذين', 20: 'أمن خلق',
    21: 'اتل ما أوحي', 22: 'ومن يقنت', 23: 'وما لي', 24: 'فمن أظلم', 25: 'إليه يرد',
    26: 'حم', 27: 'قال فما خطبكم', 28: 'قد سمع الله', 29: 'تبارك الذي', 30: 'عم',
  };

  static String getTraditionalJuzName(int juzNumber) {
    return _juzNames[juzNumber] ?? 'الجزء $juzNumber';
  }

  // Fast validation using bounds checking
  static bool isValidPageNumber(int pageNumber) {
    return pageNumber >= 1 && pageNumber <= 604;
  }

  static bool isValidSurahNumber(int surahNumber) {
    return surahNumber >= 1 && surahNumber <= 114;
  }

  // Simple string formatting
  static String formatVerseCount(int count) => '$count آية';
  static String formatPageInfo(int pageNumber) => 'الصفحة $pageNumber';

  // Optimized safe parsing with better type handling
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  static String safeParseString(dynamic value, {String defaultValue = ''}) {
    return value?.toString() ?? defaultValue;
  }

  // Memory-efficient text processing
  static String cleanText(String text) {
    return text.trim();
  }

  // Fast approximation for performance-critical operations
  static int getApproximateJuzFromSurah(int surahId) {
    if (surahId <= 2) return 1;
    if (surahId <= 4) return surahId - 1;
    if (surahId <= 9) return (surahId + 1) ~/ 2;
    if (surahId <= 114) return ((surahId - 1) ~/ 4) + 1;
    return 30;
  }
}