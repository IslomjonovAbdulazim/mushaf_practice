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
        fontFamily: 'Digital', // Default to Me font
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

  const SimpleMushafPage({Key? key, required this.pageNumber})
    : super(key: key);

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

  const SimpleMushafContent({Key? key, required this.pageData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            children: lines.map<Widget>((lineData) {
              final PageModel line = lineData['line'];
              final List<UthmaniModel> words = List<UthmaniModel>.from(
                lineData['words'],
              );
              return _buildLine(context, line, words);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLine(
    BuildContext context,
    PageModel line,
    List<UthmaniModel> words,
  ) {
    // Handle special line types
    if (line.lineType == 'basmallah') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: _getTextStyle(context, false, isBasmallah: true),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    // Regular line with words
    if (words.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _buildLineAlignment(context, line, words),
      );
    }

    return const SizedBox(height: 8);
  }

  Widget _buildLineAlignment(
    BuildContext context,
    PageModel line,
    List<UthmaniModel> words,
  ) {
    if (line.isCentered) {
      // Center the words
      return Center(
        child: Wrap(
          textDirection: TextDirection.rtl,
          children: words.map((word) => _buildWord(context, word, true)).toList(),
        ),
      );
    } else {
      // Justify the words to fill the line - distribute entire words evenly
      return Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _buildJustifiedWords(context, words),
      );
    }
  }

  List<Widget> _buildJustifiedWords(
    BuildContext context,
    List<UthmaniModel> words,
  ) {
    if (words.length == 1) {
      // Single word - align to right
      return [
        Align(
          alignment: Alignment.centerRight,
          child: _buildWord(context, words.first),
        ),
      ];
    }

    // Multiple words - distribute entire words evenly across the line
    return words
        .map(
          (word) => Center(
            child: Text(
              word.text,
              style: _getTextStyle(context, arabicNumbers.hasMatch(word.text)),
              textDirection: TextDirection.rtl,
            ),
          ),
        )
        .toList();
  }

  Widget _buildWord(
    BuildContext context,
    UthmaniModel word, [
    bool center = false,
  ]) {
    final isNumber = arabicNumbers.hasMatch(word.text);

    return Text(
      "${word.text}${center ? "  " : ""}",
      style: _getTextStyle(context, isNumber),
    );
  }

  TextStyle _getTextStyle(
    BuildContext context,
    bool isArabicNumber, {
    bool isBasmallah = false,
  }) {
    // Get responsive font sizes based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = _getResponsiveFontSize(screenWidth);

    if (isArabicNumber) {
      // Use Uthmani for Arabic numbers
      return TextStyle(
        fontFamily: 'Uthmani',
        fontSize: fontSize.number,
        height: 1.8,
        color: Colors.black,
        letterSpacing: 0,
        wordSpacing: 0,
      );
    } else {
      // Use Me for everything else
      return TextStyle(
        fontFamily: 'Digital',
        fontSize: isBasmallah ? fontSize.basmallah : fontSize.text,
        height: 1.8,
        color: Colors.black,
        fontWeight: isBasmallah ? FontWeight.w500 : FontWeight.w500,
        letterSpacing: 0,
        wordSpacing: 0,
      );
    }
  }

  // Calculate responsive font sizes based on screen width
  ({double text, double number, double basmallah}) _getResponsiveFontSize(
    double screenWidth,
  ) {
    if (screenWidth >= 768) {
      // Tablet/Large screens
      return (text: 18.0, number: 19.0, basmallah: 20.0);
    } else if (screenWidth >= 400) {
      // Medium phones
      return (text: 16.0, number: 17.0, basmallah: 18.0);
    } else if (screenWidth >= 350) {
      // Regular phones
      return (text: 15.0, number: 15.0, basmallah: 16.0);
    } else {
      // Small phones
      return (text: 13.0, number: 13.0, basmallah: 15.0);
    }
  }
}
