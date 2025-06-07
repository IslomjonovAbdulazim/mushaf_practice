// lib/main.dart - Clean main app
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/pages/menu_page.dart';
import 'package:mushaf_practice/services/data_service.dart';
import 'package:mushaf_practice/widgets/mushaf_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseManager.initializeDatabases();
    await DataService.initializeCache();
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
    return GetMaterialApp(
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
    }
  }

  Future<void> _openMenu() async {
    final result = await Get.to(() => const MenuPage());
    if (result != null && result is int) {
      _goToPage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
    return SlideTransition(
      position: _topSlideAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          color: Colors.white.withOpacity(0.95),
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
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                  ),
                  Text(
                    'صفحة $_currentPage',
                    style: TextStyle(
                      fontFamily: 'Digital',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Settings functionality
                    },
                    icon: Icon(
                      Icons.settings,
                      color: Colors.green.shade700,
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
    return SlideTransition(
      position: _bottomSlideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          color: Colors.white.withOpacity(0.95),
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
    return Column(
      children: [
        Slider(
          value: _currentPage.toDouble(),
          min: 1,
          max: 604,
          divisions: 603,
          activeColor: Colors.green.shade600,
          inactiveColor: Colors.green.shade200,
          onChanged: (value) {
            _goToPage(value.round());
          },
        ),
      ],
    );
  }
}