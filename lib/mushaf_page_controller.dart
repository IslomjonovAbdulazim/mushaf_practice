import 'package:flutter/material.dart';
import 'package:mushaf_practice/models.dart';

// Solution 1: Enhanced Font Fallback System
class ImprovedMushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;

  // Multiple font fallbacks for different Arabic characters
  static final RegExp _arabicNumberRegex = RegExp(r'^[٠-٩۰-۹]+$');
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F\u0670\u0671]');
  static final RegExp _specialCharsRegex = RegExp(r'[\uFB50-\uFDFF\uFE70-\uFEFF]');

  const ImprovedMushafPageContent({Key? key, required this.pageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: lines.map<Widget>((lineData) {
              final PageModel line = lineData['line'];
              final List<UthmaniModel> words = List<UthmaniModel>.from(lineData['words']);
              return _buildLine(line, words, pageData['pageNumber']);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLine(PageModel line, List<UthmaniModel> words, int pageNumber) {
    switch (line.lineType) {
      case 'surah_name':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'صفحة $pageNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                // Use system font for page numbers
                fontFamily: null,
              ),
            ),
          ),
        );

      case 'basmallah':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: _getOptimalTextStyle('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
              textDirection: TextDirection.rtl,
            ),
          ),
        );

      default:
        if (words.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Align(
              alignment: Alignment.center,
              child: Wrap(
                textDirection: TextDirection.rtl,
                children: words.map((word) => _buildOptimizedWord(word)).toList(),
              ),
            ),
          );
        }
        return const SizedBox(height: 12);
    }
  }

  Widget _buildOptimizedWord(UthmaniModel word) {
    final isArabicNumber = _arabicNumberRegex.hasMatch(word.text);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isArabicNumber ? 3 : 0),
      child: Text(
        word.text,
        style: _getOptimalTextStyle(word.text),
      ),
    );
  }

  // Smart font selection based on character analysis
  TextStyle _getOptimalTextStyle(String text) {
    // Check character types to determine best font
    final hasSpecialChars = _specialCharsRegex.hasMatch(text);
    final hasDiacritics = _diacriticsRegex.hasMatch(text);
    final isNumber = _arabicNumberRegex.hasMatch(text);

    if (isNumber) {
      // Use Uthman for Arabic numbers
      return const TextStyle(
        fontFamily: "Uthman",
        fontSize: 20,
        height: 1.9,
        fontFeatures: [
          FontFeature.enable('kern'), // Enable kerning
          FontFeature.enable('liga'), // Enable ligatures
        ],
      );
    } else if (hasSpecialChars || hasDiacritics) {
      // Use multiple fallbacks for complex characters
      return const TextStyle(
        fontFamily: "Me",
        fontFamilyFallback: ["Uthman", "Digital", "Nas"], // Multiple fallbacks
        fontSize: 20,
        height: 1.9,
        fontFeatures: [
          FontFeature.enable('kern'),
          FontFeature.enable('liga'),
          FontFeature.enable('calt'), // Contextual alternates
          FontFeature.enable('ccmp'), // Character composition
        ],
      );
    } else {
      // Standard Arabic text
      return const TextStyle(
        fontFamily: "Me",
        fontFamilyFallback: ["Uthman", "Digital"], // Fallback fonts
        fontSize: 20,
        height: 1.9,
        fontFeatures: [
          FontFeature.enable('kern'),
          FontFeature.enable('liga'),
        ],
      );
    }
  }
}

// Solution 2: Alternative with RichText for character-level control
class CharacterLevelMushafContent extends StatelessWidget {
  final Map<String, dynamic> pageData;
  static final RegExp _arabicNumberRegex = RegExp(r'^[٠-٩۰-۹]+$');

  const CharacterLevelMushafContent({Key? key, required this.pageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: lines.map<Widget>((lineData) {
              final PageModel line = lineData['line'];
              final List<UthmaniModel> words = List<UthmaniModel>.from(lineData['words']);
              return _buildRichTextLine(line, words);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRichTextLine(PageModel line, List<UthmaniModel> words) {
    if (words.isEmpty) return const SizedBox(height: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.center,
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: words.map((word) => _buildWordSpan(word)).toList(),
          ),
        ),
      ),
    );
  }

  TextSpan _buildWordSpan(UthmaniModel word) {
    final isArabicNumber = _arabicNumberRegex.hasMatch(word.text);

    return TextSpan(
      text: word.text + ' ', // Add space between words
      style: TextStyle(
        fontFamily: isArabicNumber ? "Uthman" : "Me",
        fontFamilyFallback: const ["Uthman", "Digital", "Nas"],
        fontSize: 18,
        height: 1.9,
        color: Colors.black,
        fontFeatures: const [
          FontFeature.enable('kern'),
          FontFeature.enable('liga'),
          FontFeature.enable('calt'),
        ],
      ),
    );
  }
}

// Solution 3: Custom Font Loader
class FontManager {
  static bool _fontsLoaded = false;

  static Future<void> preloadFonts() async {
    if (_fontsLoaded) return;

    try {
      // Force load fonts by creating invisible text widgets
      await Future.wait([
        _loadFont("Uthman"),
        _loadFont("Me"),
        _loadFont("Digital"),
        _loadFont("Nas"),
      ]);
      _fontsLoaded = true;
    } catch (e) {
      print('Error preloading fonts: $e');
    }
  }

  static Future<void> _loadFont(String fontFamily) async {
    return Future.delayed(const Duration(milliseconds: 10), () {
      // Create a temporary widget to force font loading
      Text(
        'تجربة', // Test Arabic text
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1,
        ),
      );
    });
  }
}

// Solution 4: Enhanced Text Rendering Widget
class EnhancedArabicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextDirection textDirection;

  const EnhancedArabicText(
      this.text, {
        Key? key,
        this.style,
        this.textDirection = TextDirection.rtl,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontFamilyFallback: const [
          "Me",
          "Uthman",
        ],
        fontFeatures: const [
          FontFeature.enable('kern'),
          FontFeature.enable('liga'),
          FontFeature.enable('calt'),
          FontFeature.enable('ccmp'),
          FontFeature.enable('mark'), // Mark positioning
          FontFeature.enable('mkmk'), // Mark to mark positioning
        ],
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    );
  }
}