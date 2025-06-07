// lib/main.dart - Updated with tap controllers and RTL navigation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/mushaf_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseManager.initializeDatabases();
    print('✅ Databases initialized');
  } catch (error) {
    print('❌ Database error: $error');
  }

  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المصحف',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Digital',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MushafController(),
    );
  }
}

class MushafController extends StatefulWidget {
  const MushafController({Key? key}) : super(key: key);

  @override
  State<MushafController> createState() => _MushafControllerState();
}

class _MushafControllerState extends State<MushafController> {
  late PageController _pageController;
  int _currentPage = 600; // Display page number (1-604)
  final int _totalPages = 604;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    // Start from the correct page index (600 - 1 = 599)
    _pageController = PageController(initialPage: _currentPage - 1);
    _setFullScreen();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      // Direct mapping: index 0 = page 1, index 599 = page 600
      _currentPage = index + 1;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _goToPage() {
    // TODO: Implement go to page functionality
    print('Go to page tapped');
  }

  void _showBookmarks() {
    // TODO: Implement bookmarks functionality
    print('Bookmarks tapped');
  }

  void _showSettings() {
    // TODO: Implement settings functionality
    print('Settings tapped');
  }

  void _showSearch() {
    // TODO: Implement search functionality
    print('Search tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main PageView with custom RTL navigation
            PageView.builder(
              reverse: true,
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _totalPages,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                // Direct mapping: show actual page numbers
                int actualPageNumber = index + 1;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip back the content
                    child: MushafPage(pageNumber: actualPageNumber),
                  ),
                );
              },
            ),

            // Control overlay
            if (_showControls)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  children: [
                    // Top controls
                    SafeArea(
                      bottom: false,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.bookmark,
                              label: 'المرجعيات',
                              onTap: _showBookmarks,
                            ),
                            _buildControlButton(
                              icon: Icons.search,
                              label: 'البحث',
                              onTap: _showSearch,
                            ),
                            _buildControlButton(
                              icon: Icons.format_list_numbered,
                              label: 'اذهب إلى',
                              onTap: _goToPage,
                            ),
                            _buildControlButton(
                              icon: Icons.settings,
                              label: 'الإعدادات',
                              onTap: _showSettings,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom page info
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'صفحة $_currentPage من $_totalPages',
                                style: const TextStyle(
                                  fontFamily: 'Digital',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}