// lib/main.dart - Clean controls without redundant surah name
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
    print('🚀 Initializing Mushaf App with ULTRA caching...');

    // Initialize GetStorage for theme persistence
    await GetStorage.init();

    // Initialize databases and ULTRA-AGGRESSIVE cache
    await DatabaseManager.initializeDatabases();
    await DataService.initializeCache(); // Now preloads 50+ pages!

    // Debug: Print cache status
    final cacheStatus = DataService.getCacheStatus();
    print('📊 Cache Status: $cacheStatus');

    // Initialize theme controller
    Get.put(ThemeController());

    print('✅ App initialized with heavy caching active');
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

        // FONT SCALING FIX - Ignore system font size and bold settings
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
            boldText: false,
          ),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior(),
            child: child ?? const Scaffold(),
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setFullScreen();
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

    // Trigger aggressive preloading around new page
    DataService.preloadAroundPage(_currentPage);
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

      setState(() {
        _currentPage = pageNumber;
      });

      // Start aggressive preloading around target page
      DataService.preloadAroundPage(pageNumber);
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
            child: MushafPage(pageNumber: pageNumber),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _openMenu,
                    icon: Icon(
                      Icons.menu,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  // Clean page display - surah name is now shown on the page itself
                  Text(
                    'Page $_currentPage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: _openSettings,
                    icon: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 24,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('1', style: TextStyle(fontSize: 12)),
                      Text(
                        'Page $_currentPage of 604',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text('604', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Slider(
                    value: _currentPage.toDouble(),
                    min: 1,
                    max: 604,
                    divisions: 603,
                    onChanged: (value) => _goToPage(value.round()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}