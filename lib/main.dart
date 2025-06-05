import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/simple_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        fontFamily: 'Me', // Default to Me font
      ),
      home: const MushafPageController(initialPage: 1),
    );
  }
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
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
        itemCount: widget.totalPages,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return SimpleMushafPage(pageNumber: pageNumber);
        },
      ),
    );
  }
}

class SimpleMushafPage extends StatelessWidget {
  final int pageNumber;

  const SimpleMushafPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SimpleDatabase.getCompletePage(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SimpleMushafContent(pageData: snapshot.data!);
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      },
    );
  }
}

class SimpleMushafContent extends StatelessWidget {
  final Map<String, dynamic> pageData;

  // Simple regex for Arabic numbers
  static final RegExp arabicNumbers = RegExp(r'^[٠-٩۰-۹]+$');

  const SimpleMushafContent({Key? key, required this.pageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: lines.map<Widget>((lineData) {
              final PageModel line = lineData['line'];
              final List<UthmaniModel> words = List<UthmaniModel>.from(lineData['words']);
              return _buildLine(line, words);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLine(PageModel line, List<UthmaniModel> words) {
    // Handle special line types
    if (line.lineType == 'basmallah') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: _getTextStyle(false, isBasmallah: true),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    // Regular line with words
    if (words.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Wrap(
            textDirection: TextDirection.rtl,
            children: words.map((word) => _buildWord(word)).toList(),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }

  Widget _buildWord(UthmaniModel word) {
    final isNumber = arabicNumbers.hasMatch(word.text);

    return Text(
      word.text + ' ', // Add space after each word
      style: _getTextStyle(isNumber),
    );
  }

  TextStyle _getTextStyle(bool isArabicNumber, {bool isBasmallah = false}) {
    if (isArabicNumber) {
      // Use Uthmani for Arabic numbers
      return const TextStyle(
        fontFamily: 'Uthmani',
        fontSize: 20,
        height: 1.8,
        color: Colors.black,
      );
    } else {
      // Use Me for everything else
      return TextStyle(
        fontFamily: 'Me',
        fontSize: isBasmallah ? 22 : 20,
        height: 1.8,
        color: Colors.black,
        fontWeight: isBasmallah ? FontWeight.w500 : FontWeight.normal,
      );
    }
  }
}