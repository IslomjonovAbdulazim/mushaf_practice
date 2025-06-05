import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/simple_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts to prevent rendering issues
  await QuranFontManager.preloadQuranFonts();

  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mushaf Reader',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Me', // Set Me as default
        fontFamilyFallback: const ['Uthmani'],
      ),
      home: const MushafPageController(initialPage: 1),
    );
  }
}

// Font preloader for Me + Uthmani fonts
class QuranFontManager {
  static bool _fontsLoaded = false;

  static Future<void> preloadQuranFonts() async {
    if (_fontsLoaded) return;

    try {
      // Test text samples to force font loading
      final testCases = [
        ('Me', 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
        ('Uthmani', '١٢٣٤٥٦٧٨٩٠'), // Arabic numbers
        ('Header', 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'),
        ('SurahName', 'مَالِكِ يَوْمِ الدِّينِ'),
      ];

      for (final (fontFamily, testText) in testCases) {
        await _preloadSingleFont(fontFamily, testText);
      }

      _fontsLoaded = true;
      print('Me + Uthmani fonts preloaded successfully');
    } catch (e) {
      print('Error preloading Quran fonts: $e');
    }
  }

  static Future<void> _preloadSingleFont(String fontFamily, String testText) async {
    return Future.delayed(const Duration(milliseconds: 30), () {
      Text(
        testText,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
        ),
      ).toString();
    });
  }
}

// Font styles with Me as primary and Uthmani for numbers
class QuranTextStyles {
  // Primary Quran text style with Me font
  static const TextStyle quranText = TextStyle(
    fontFamily: "Me", // Primary font for Quran text
    fontFamilyFallback: [
      "Uthmani", // Fallback for missing glyphs
      "Arial Unicode MS", // System fallback
      "Tahoma", // Windows fallback
      "DejaVu Sans", // Linux fallback
    ],
    fontSize: 20,
    height: 1.9,
    color: Colors.black,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
      FontFeature.enable('calt'),
      FontFeature.enable('ccmp'), // Character composition
      FontFeature.enable('mark'), // Mark positioning
      FontFeature.enable('mkmk'), // Mark to mark positioning
    ],
  );

  // For Arabic ayah numbers (use Uthmani as before)
  static const TextStyle arabicNumbers = TextStyle(
    fontFamily: "Uthmani", // Uthmani for ayah numbers
    fontFamilyFallback: [
      "Me", // Me as fallback
      "Arial Unicode MS",
      "Tahoma",
    ],
    fontSize: 20,
    height: 1.9,
    color: Colors.black,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
      FontFeature.enable('lnum'), // Lining numbers
    ],
  );

  // For Basmallah (use Me font)
  static const TextStyle basmallah = TextStyle(
    fontFamily: "Me",
    fontFamilyFallback: [
      "Uthmani",
      "Arial Unicode MS",
    ],
    fontSize: 22, // Slightly larger for Basmallah
    height: 2.0,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
      FontFeature.enable('calt'),
      FontFeature.enable('ccmp'),
      FontFeature.enable('mark'),
      FontFeature.enable('mkmk'),
    ],
  );

  // For headers (using dedicated header font)
  static const TextStyle header = TextStyle(
    fontFamily: "Header",
    fontFamilyFallback: [
      "Me",
      "Uthmani",
    ],
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

  // For surah names (using dedicated surah font)
  static const TextStyle surahName = TextStyle(
    fontFamily: "SurahName",
    fontFamilyFallback: [
      "Header",
      "Me",
      "Uthmani",
    ],
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
}

class MushafPageController extends StatefulWidget {
  final int initialPage;
  final int totalPages;

  const MushafPageController({
    Key? key,
    this.initialPage = 1,
    this.totalPages = 604,
  }) : super(key: key);

  @override
  State<MushafPageController> createState() => _MushafPageControllerState();
}

class _MushafPageControllerState extends State<MushafPageController> {
  late PageController _pageController;
  late int _currentPage;

  // Pre-built widgets cache
  final Map<int, Widget> _prebuiltPages = {};
  final Map<int, Map<String, dynamic>> _pageDataCache = {};

  // Loading management
  final Set<int> _currentlyLoading = {};
  static const int _cacheSize = 5; // Keep 5 pages ready (2 before, current, 2 after)

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(
      initialPage: widget.initialPage - 1,
      viewportFraction: 1.0,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Immediately start building pages around initial page
    _initializePages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializePages() async {
    // Load current page first
    await _loadAndBuildPage(_currentPage);

    // Then load adjacent pages
    _preloadPagesAround(_currentPage);
  }

  Future<void> _loadAndBuildPage(int pageNumber) async {
    if (_prebuiltPages.containsKey(pageNumber) ||
        _currentlyLoading.contains(pageNumber) ||
        pageNumber < 1 || pageNumber > widget.totalPages) {
      return;
    }

    _currentlyLoading.add(pageNumber);

    try {
      // Load data
      final pageData = await SimpleDatabase.getCompletePage(pageNumber);
      _pageDataCache[pageNumber] = pageData;

      // Pre-build the widget
      final widget = OptimizedMushafPageContent(pageData: pageData);
      _prebuiltPages[pageNumber] = widget;

      // Trigger rebuild if this is current page
      if (pageNumber == _currentPage && mounted) {
        setState(() {});
      }
    } catch (error) {
      print('Error loading page $pageNumber: $error');
    } finally {
      _currentlyLoading.remove(pageNumber);
    }
  }

  void _preloadPagesAround(int centerPage) {
    // Load pages in order of priority
    final priorities = [
      centerPage,     // Current page (highest priority)
      centerPage + 1, // Next page
      centerPage - 1, // Previous page
      centerPage + 2, // Further ahead
      centerPage - 2, // Further back
    ];

    for (final pageNum in priorities) {
      if (pageNum >= 1 && pageNum <= widget.totalPages) {
        _loadAndBuildPage(pageNum);
      }
    }

    // Clean up distant pages
    _cleanupDistantPages(centerPage);
  }

  void _cleanupDistantPages(int currentPage) {
    final pagesToRemove = <int>[];

    for (final pageNum in _prebuiltPages.keys) {
      if ((pageNum - currentPage).abs() > _cacheSize) {
        pagesToRemove.add(pageNum);
      }
    }

    for (final pageNum in pagesToRemove) {
      _prebuiltPages.remove(pageNum);
      _pageDataCache.remove(pageNum);
    }
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });

      // Immediately start preloading for smooth experience
      _preloadPagesAround(newPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.totalPages,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;

          // Return pre-built page if available
          if (_prebuiltPages.containsKey(pageNumber)) {
            return _prebuiltPages[pageNumber]!;
          }

          // Show loading for pages not yet ready
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        },
      ),
    );
  }
}

// Updated Mushaf content with Me + Uthmani fonts
class OptimizedMushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;
  static final RegExp _arabicNumberRegex = RegExp(r'^[٠-٩۰-۹]+$');

  const OptimizedMushafPageContent({Key? key, required this.pageData}) : super(key: key);

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
              style: QuranTextStyles.header,
            ),
          ),
        );

      case 'basmallah':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: QuranTextStyles.basmallah,
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
        style: isArabicNumber ? QuranTextStyles.arabicNumbers : QuranTextStyles.quranText,
      ),
    );
  }
}