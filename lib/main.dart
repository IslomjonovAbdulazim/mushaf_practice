// lib/main.dart - Simplified main app without dialogs
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
  int _currentPage = 600;
  final int _totalPages = 604;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
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
      _currentPage = index + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _totalPages,
        itemBuilder: (context, index) {
          return MushafPage(pageNumber: index + 1);
        },
      ),
    );
  }
}