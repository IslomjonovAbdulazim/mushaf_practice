// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/enhanced_database.dart';
import 'package:mushaf_practice/enhanced_mushaf_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize databases on app start
  try {
    await EnhancedDatabase.initializeDatabases();
    print('Databases initialized successfully');
  } catch (e) {
    print('Error initializing databases: $e');
  }

  runApp(const EnhancedMushafApp());
}

class EnhancedMushafApp extends StatelessWidget {
  const EnhancedMushafApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enhanced Mushaf Reader',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Digital',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        // Customize page transition for smoother navigation
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const EnhancedMushafPageController(initialPage: 1),
    );
  }
}

class EnhancedMushafPageController extends StatefulWidget {
  final int initialPage;
  final int totalPages;

  const EnhancedMushafPageController({
    Key? key,
    this.initialPage = 1,
    this.totalPages = 604,
  }) : super(key: key);

  @override
  State<EnhancedMushafPageController> createState() => _EnhancedMushafPageControllerState();
}

class _EnhancedMushafPageControllerState extends State<EnhancedMushafPageController>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentPage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);

    // Set immersive mode for full-screen reading experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Add observer to handle app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Preload pages around initial page
    _preloadPages(_currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // Restore immersive mode when app is resumed
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        break;
      case AppLifecycleState.paused:
      // Clear some cache when app is paused to free memory
        EnhancedDatabase.clearCache();
        break;
      default:
        break;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1;
    });

    // Preload pages around current page for smooth navigation
    _preloadPages(_currentPage);
  }

  void _preloadPages(int centerPage) {
    // Preload pages in background without blocking UI
    Future.microtask(() {
      EnhancedDatabase.preloadPagesAround(centerPage, range: 3);
    });
  }

  // Navigate to specific page
  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= widget.totalPages) {
      _pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Show page navigation dialog
  void _showPageNavigationDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Go to Page',
            style: TextStyle(fontFamily: 'Digital'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Page Number (1-${widget.totalPages})',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Current page: $_currentPage',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pageNumber = int.tryParse(controller.text);
                if (pageNumber != null &&
                    pageNumber >= 1 &&
                    pageNumber <= widget.totalPages) {
                  Navigator.of(context).pop();
                  _goToPage(pageNumber);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid page number (1-${widget.totalPages})',
                      ),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        // Double tap to show page navigation
        onDoubleTap: _showPageNavigationDialog,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.totalPages,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            return EnhancedMushafPage(pageNumber: pageNumber);
          },
        ),
      ),

      // Floating action button for quick navigation (optional)
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB on debug mode or for demonstration
    return null; // Remove this line to enable FAB

    /* Uncomment to enable floating action button
    return FloatingActionButton.small(
      onPressed: _showPageNavigationDialog,
      backgroundColor: Colors.green.shade600,
      child: const Icon(
        Icons.search,
        color: Colors.white,
        size: 20,
      ),
    );
    */
  }
}

// Extension for additional utility methods
extension PageControllerExtension on _EnhancedMushafPageControllerState {
  // Quick navigation methods
  void nextPage() {
    if (_currentPage < widget.totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void firstPage() {
    _goToPage(1);
  }

  void lastPage() {
    _goToPage(widget.totalPages);
  }
}