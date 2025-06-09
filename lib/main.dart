// lib/main.dart - Fixed surah name tracking + performance optimizations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mushaf_practice/controllers/theme_controller.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/pages/menu_page.dart';
import 'package:mushaf_practice/pages/settings_page.dart';
import 'package:mushaf_practice/services/data_service.dart';
import 'package:mushaf_practice/theme/app_theme.dart';
import 'package:mushaf_practice/widgets/mushaf_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Initializing Mushaf App...');

    // Initialize GetStorage for theme persistence
    await GetStorage.init();

    // Initialize databases and cache with heavy preloading
    await DatabaseManager.initializeDatabases();
    await DataService.initializeCache(); // This now preloads everything!

    // Initialize theme controller
    Get.put(ThemeController());

    print('✅ App initialized successfully');
  } catch (error) {
    print('❌ Initialization error: $error');
  }

  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mushaf Practice',

        // Use our custom theme system
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,

        // Custom transitions
        defaultTransition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),

        home: const MushafController(),

        // Custom route for settings
        getPages: [
          GetPage(
            name: '/settings',
            page: () => const SettingsPage(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/menu',
            page: () => const MenuPage(),
            transition: Transition.rightToLeft,
          ),
        ],
      );
    });
  }
}

class MushafController extends StatefulWidget {
  const MushafController({Key? key}) : super(key: key);

  @override
  State<MushafController> createState() => _MushafControllerState();
}

class _MushafControllerState extends State<MushafController>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;

  int _currentPage = 1;
  bool _showControls = false;
  String _currentSurahName = 'Holy Quran'; // Track surah name

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setFullScreen();
    _updateSurahName(); // Initialize surah name
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupControllers() {
    _pageController = PageController(initialPage: _currentPage - 1);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1;
    });
    _updateSurahName(); // Update surah name when page changes!
  }

  // Update surah name for current page
  void _updateSurahName() {
    // Use the fast lookup from optimized DataService
    final surahName = DataService.getSurahNameForPage(_currentPage);
    setState(() {
      _currentSurahName = surahName;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= 604) {
      _pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Update page and surah name immediately for responsiveness
      setState(() {
        _currentPage = pageNumber;
      });
      _updateSurahName();
    }
  }

  Future<void> _openMenu() async {
    final result = await Get.to(() => const MenuPage());
    if (result != null && result is int) {
      _goToPage(result);
    }
  }

  void _openSettings() {
    Get.to(() => const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            _buildPageView(),
            if (_showControls) _buildOverlay(),
            if (_showControls) _buildTopControls(),
            if (_showControls) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      reverse: true,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: 604,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: MushafPage(
              pageNumber: pageNumber,
              surahName: pageNumber == _currentPage ? _currentSurahName : null, // Only provide surah name for current page
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
    );
  }

  Widget _buildTopControls() {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _topSlideAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surface.withOpacity(0.95),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _openMenu,
                    icon: Icon(
                      Icons.menu,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  // Show current surah name and page
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentSurahName,
                          style: TextStyle(
                            fontFamily: 'Digital',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Page $_currentPage',
                          style: TextStyle(
                            fontFamily: 'Digital',
                            fontSize: 12,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openSettings,
                    icon: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _bottomSlideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surface.withOpacity(0.95),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPageSlider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageSlider() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 12,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
            Text(
              'Page $_currentPage of 604',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '604',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 12,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Slider(
          value: _currentPage.toDouble(),
          min: 1,
          max: 604,
          divisions: 603,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
          onChanged: (value) {
            _goToPage(value.round());
          },
        ),
      ],
    );
  }
}