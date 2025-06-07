// lib/main.dart - Main application entry point with optimized structure
// This consolidates the previous main.dart functionality with better organization

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/mushaf_page.dart';

// Application entry point
void main() async {
  // Ensure Flutter framework is properly initialized before database operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all required databases at app startup for better performance
  try {
    await DatabaseManager.initializeDatabases();
    print('✅ All databases initialized successfully');
  } catch (error) {
    print('❌ Error initializing databases: $error');
    // Continue app execution even if database initialization fails
    // The app will handle individual database errors gracefully
  }

  // Launch the main application
  runApp(const MushafReaderApp());
}

// Root widget of the Mushaf reading application
class MushafReaderApp extends StatelessWidget {
  const MushafReaderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove debug banner for cleaner appearance
      debugShowCheckedModeBanner: false,

      // Application metadata
      title: 'Mushaf Reader - قارئ المصحف',

      // Application theme configuration
      theme: ThemeData(
        // Primary color scheme using traditional Islamic green
        primarySwatch: Colors.green,

        // Default font family for consistent Arabic text rendering
        fontFamily: 'Digital',

        // Clean white background for optimal text readability
        scaffoldBackgroundColor: Colors.white,

        // Minimal app bar styling for distraction-free reading
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),

        // Smooth page transitions for better user experience
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),

        // Additional theme customizations for Islamic aesthetics
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade600,
          brightness: Brightness.light,
        ),

        // Text theme optimizations for Arabic content
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Digital',
            height: 1.8, // Increased line height for Arabic text readability
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Digital',
            height: 1.8,
          ),
        ),
      ),

      // Set the home screen to the main page controller
      home: const MushafPageController(initialPage: 1),
    );
  }
}

// Main controller widget that manages page navigation and user interactions
class MushafPageController extends StatefulWidget {
  final int initialPage;
  final int totalPages;

  const MushafPageController({
    Key? key,
    this.initialPage = 1,
    this.totalPages = 604, // Standard Mushaf contains 604 pages
  }) : super(key: key);

  @override
  State<MushafPageController> createState() => _MushafPageControllerState();
}

// State class that handles the page controller logic and lifecycle management
class _MushafPageControllerState extends State<MushafPageController>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  // Core navigation components
  late PageController _pageController;
  late int _currentPage;
  bool _isNavigating = false;

  // Animation controller for smooth UI transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize page tracking
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);

    // Set up animations for UI feedback
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Configure immersive reading mode
    _enableImmersiveMode();

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Preload surrounding pages for smooth navigation
    _preloadSurroundingPages(_currentPage);
  }

  @override
  void dispose() {
    // Clean up resources
    _pageController.dispose();
    _animationController.dispose();

    // Restore normal system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // Handle app lifecycle changes for optimal performance
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // Restore immersive mode when returning to app
        _enableImmersiveMode();
        break;
      case AppLifecycleState.paused:
      // Clear caches to free memory when app is backgrounded
        DatabaseManager.clearAllCaches();
        break;
      case AppLifecycleState.detached:
      // Final cleanup when app is being terminated
        DatabaseManager.clearAllCaches();
        break;
      default:
        break;
    }
  }

  // Enable full-screen immersive reading mode
  void _enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [], // Hide all system overlays for distraction-free reading
    );
  }

  // Handle page changes with smooth transitions and preloading
  void _onPageChanged(int pageIndex) {
    if (_isNavigating) return; // Prevent multiple simultaneous navigation events

    setState(() {
      _currentPage = pageIndex + 1; // Convert 0-based index to 1-based page number
    });

    // Preload pages around the new current page
    _preloadSurroundingPages(_currentPage);

    // Add subtle haptic feedback for page turns
    HapticFeedback.lightImpact();
  }

  // Preload pages around the current page for smoother navigation
  void _preloadSurroundingPages(int centerPage) {
    // Use microtask to avoid blocking the UI thread
    Future.microtask(() {
      DatabaseManager.preloadSurroundingPages(centerPage, range: 3);
    });
  }

  // Navigate to a specific page with smooth animation
  Future<void> _navigateToPage(int targetPageNumber) async {
    if (targetPageNumber < 1 ||
        targetPageNumber > widget.totalPages ||
        targetPageNumber == _currentPage ||
        _isNavigating) {
      return; // Invalid page number or already navigating
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      await _pageController.animateToPage(
        targetPageNumber - 1, // Convert to 0-based index
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } catch (error) {
      print('Navigation error: $error');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الانتقال إلى الصفحة $targetPageNumber'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  // Show page navigation dialog for quick jumping to specific pages
  void _showPageNavigationDialog() {
    final TextEditingController pageInputController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.navigation, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'الانتقال إلى صفحة',
                style: TextStyle(
                  fontFamily: 'Digital',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: pageInputController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'رقم الصفحة (1-${widget.totalPages})',
                  hintText: 'أدخل رقم الصفحة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.book, color: Colors.green.shade600),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3), // Max 3 digits for page 604
                ],
                onSubmitted: (value) {
                  _handlePageNavigation(dialogContext, pageInputController.text);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الصفحة الحالية: $_currentPage',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Digital',
                    ),
                  ),
                  Text(
                    'المجموع: ${widget.totalPages}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Digital',
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _handlePageNavigation(dialogContext, pageInputController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  // Handle page navigation from the dialog
  void _handlePageNavigation(BuildContext dialogContext, String inputValue) {
    final targetPage = int.tryParse(inputValue);

    if (targetPage != null && targetPage >= 1 && targetPage <= widget.totalPages) {
      Navigator.of(dialogContext).pop(); // Close dialog
      _navigateToPage(targetPage);
    } else {
      // Show error for invalid page number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رقم صفحة غير صحيح. يرجى إدخال رقم بين 1 و ${widget.totalPages}',
            style: const TextStyle(fontFamily: 'Digital'),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          // Double tap anywhere to show navigation dialog
          onDoubleTap: _showPageNavigationDialog,

          // Page view for horizontal swiping between pages
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.totalPages,

            // Optimize page building for performance
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return MushafPage(pageNumber: pageNumber);
            },

            // Add physics for better scrolling feel
            physics: const ClampingScrollPhysics(),
          ),
        ),
      ),

      // Optional: Add floating action button for quick navigation
      // Uncomment the following lines to enable it
      /*
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showPageNavigationDialog,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.search, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      */
    );
  }
}

// Extension methods for additional navigation functionality
extension MushafNavigationExtensions on _MushafPageControllerState {

  // Quick navigation methods for programmatic use

  void jumpToNextPage() {
    if (_currentPage < widget.totalPages && !_isNavigating) {
      _navigateToPage(_currentPage + 1);
    }
  }

  void jumpToPreviousPage() {
    if (_currentPage > 1 && !_isNavigating) {
      _navigateToPage(_currentPage - 1);
    }
  }

  void jumpToFirstPage() {
    if (_currentPage != 1 && !_isNavigating) {
      _navigateToPage(1);
    }
  }

  void jumpToLastPage() {
    if (_currentPage != widget.totalPages && !_isNavigating) {
      _navigateToPage(widget.totalPages);
    }
  }

  // Navigation by Juz (30 sections of the Quran)
  void jumpToJuzStart(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30 || _isNavigating) return;

    // Approximate starting pages for each Juz
    final juzStartPages = [
      1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582
    ];

    if (juzNumber <= juzStartPages.length) {
      _navigateToPage(juzStartPages[juzNumber - 1]);
    }
  }

  // Get current reading progress as percentage
  double get readingProgress {
    return (_currentPage / widget.totalPages) * 100;
  }

  // Get current Juz number
  int get currentJuzNumber {
    // Simple calculation based on page number
    if (_currentPage <= 21) return 1;
    if (_currentPage <= 41) return 2;
    if (_currentPage <= 61) return 3;
    if (_currentPage <= 81) return 4;
    if (_currentPage <= 101) return 5;
    if (_currentPage <= 120) return 6;
    if (_currentPage <= 141) return 7;
    if (_currentPage <= 161) return 8;
    if (_currentPage <= 181) return 9;
    if (_currentPage <= 200) return 10;
    if (_currentPage <= 221) return 11;
    if (_currentPage <= 241) return 12;
    if (_currentPage <= 261) return 13;
    if (_currentPage <= 281) return 14;
    if (_currentPage <= 301) return 15;
    if (_currentPage <= 321) return 16;
    if (_currentPage <= 341) return 17;
    if (_currentPage <= 361) return 18;
    if (_currentPage <= 381) return 19;
    if (_currentPage <= 401) return 20;
    if (_currentPage <= 421) return 21;
    if (_currentPage <= 441) return 22;
    if (_currentPage <= 461) return 23;
    if (_currentPage <= 481) return 24;
    if (_currentPage <= 501) return 25;
    if (_currentPage <= 521) return 26;
    if (_currentPage <= 541) return 27;
    if (_currentPage <= 561) return 28;
    if (_currentPage <= 581) return 29;
    return 30;
  }
}