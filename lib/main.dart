import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/simple_database.dart';

import 'mushaf_page_controller.dart';

// Add font preloading to main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts to prevent rendering issues
  await FontManager.preloadFonts();

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
        // Set default font fallbacks for the entire app
        fontFamily: 'Me',
        fontFamilyFallback: const ['Uthman', 'Digital', 'Nas'],
      ),
      home: const MushafPageController(initialPage: 1),
    );
  }
}

class FontManager {
  static bool _fontsLoaded = false;

  static Future<void> preloadFonts() async {
    if (_fontsLoaded) return;

    try {
      // Force load fonts by creating text with each font
      final testTexts = [
        ('Uthman', '١٢٣٤٥'), // Arabic numbers
        ('Me', 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), // Basic Arabic
        ('Digital', 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), // With diacritics
        ('Nas', 'قُلْ هُوَ اللَّهُ أَحَدٌ'), // Complex text
      ];

      for (final (fontFamily, text) in testTexts) {
        await _loadFont(fontFamily, text);
      }

      _fontsLoaded = true;
      print('All fonts preloaded successfully');
    } catch (e) {
      print('Error preloading fonts: $e');
    }
  }

  static Future<void> _loadFont(String fontFamily, String testText) async {
    return Future.delayed(const Duration(milliseconds: 50), () {
      // Create a temporary widget to force font loading
      final testWidget = Text(
        testText,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
        ),
      );
      // The widget creation forces font loading
      testWidget.toString();
    });
  }
}

// Updated PageController with better font handling
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

  final Map<int, Widget> _prebuiltPages = {};
  final Map<int, Map<String, dynamic>> _pageDataCache = {};
  final Set<int> _currentlyLoading = {};
  static const int _cacheSize = 5;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(
      initialPage: widget.initialPage - 1,
      viewportFraction: 1.0,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializePages() async {
    await _loadAndBuildPage(_currentPage);
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
      final pageData = await SimpleDatabase.getCompletePage(pageNumber);
      _pageDataCache[pageNumber] = pageData;

      // Use improved font rendering
      final widget = ImprovedMushafPageContent(pageData: pageData);
      _prebuiltPages[pageNumber] = widget;

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
    final priorities = [
      centerPage,
      centerPage + 1,
      centerPage - 1,
      centerPage + 2,
      centerPage - 2,
    ];

    for (final pageNum in priorities) {
      if (pageNum >= 1 && pageNum <= widget.totalPages) {
        _loadAndBuildPage(pageNum);
      }
    }

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

          if (_prebuiltPages.containsKey(pageNumber)) {
            return _prebuiltPages[pageNumber]!;
          }

          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        },
      ),
    );
  }
}

// The ImprovedMushafPageContent class goes here (from previous artifact)