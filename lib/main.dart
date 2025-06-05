import 'package:flutter/material.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/simple_database.dart';

void main() {
  runApp(MushafApp());
}

// Main app to test
class MushafApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mushaf Reader',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MushafPage(pageNumber: 604),
    );
  }
}

class MushafPage extends StatefulWidget {
  final int pageNumber;

  const MushafPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  _MushafPageState createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  Map<String, dynamic>? pageData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPage();
  }

  Future<void> loadPage() async {
    try {
      final data = await SimpleDatabase.getCompletePage(widget.pageNumber);
      setState(() {
        pageData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading page: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pageData == null
          ? Center(child: Text('Error loading page'))
          : Column(
              children: [
                // Page content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: pageData!['lines'].length,
                      itemBuilder: (context, index) {
                        final lineData = pageData!['lines'][index];
                        final PageModel line = lineData['line'];
                        final List<UthmaniModel> words = lineData['words'];

                        return buildLine(line, words);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildLine(PageModel line, List<UthmaniModel> words) {
    // Handle different line types
    if (line.lineType == 'surah_name') {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            "57455",
            style: TextStyle(
              fontFamily: 'SurahNames2',
              fontSize: 24,
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    if (line.lineType == 'basmallah') {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: TextStyle(
              fontFamily: 'Uthman',
              fontSize: 18,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    // Regular ayah line
    if (words.isNotEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: line.isCentered ? Alignment.center : Alignment.centerRight,
          child: Wrap(
            textDirection: TextDirection.rtl,
            children: words.map((word) => buildWord(word)).toList(),
          ),
        ),
      );
    }

    return SizedBox(height: 8);
  }

  Widget buildWord(UthmaniModel word) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isOnlyArabicNumbers(word.text) ? 3 : 0,
      ),
      child: Text(
        word.text,
        style: TextStyle(
          fontFamily: isOnlyArabicNumbers(word.text) ? "Uthman" : 'Digital',
          fontSize: 16,
          height: 1.8,
        ),
      ),
    );
  }
}

bool isOnlyArabicNumbers(String text) {
  return RegExp(r'^[٠-٩۰-۹]+$').hasMatch(text);
}
