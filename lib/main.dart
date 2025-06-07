// lib/main.dart - Simple sliding controls display only
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

class _MushafControllerState extends State<MushafController>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;

  int _currentPage = 600;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage - 1);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(_animationController);

    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(_animationController);

    _setFullScreen();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main PageView
            PageView.builder(
              reverse: true,
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: 604,
              itemBuilder: (context, index) {
                int actualPageNumber = index + 1;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: MushafPage(pageNumber: actualPageNumber),
                  ),
                );
              },
            ),

            if (_showControls) Container(color: Colors.black.withOpacity(0.2)),

            // Top controls - Menu and Settings
            SlideTransition(
              position: _topSlideAnimation,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.95),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.menu,
                            color: Colors.green.shade700,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
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

            // Bottom controls
            SlideTransition(
              position: _bottomSlideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Reciter button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              'عبد الباسط',
                              style: TextStyle(
                                fontFamily: 'Digital',
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Play button
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.95),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slider(
                              value: _currentPage.toDouble(),
                              min: 1,
                              max: 604,
                              activeColor: Colors.green.shade600,
                              inactiveColor: Colors.green.shade200,
                              onChanged: (value) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
