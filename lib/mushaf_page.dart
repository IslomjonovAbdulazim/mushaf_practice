// lib/mushaf_page.dart - Simple Mushaf page display
import 'package:flutter/material.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;

  const MushafPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseManager.getCompletePageData(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MushafPageContent(pageData: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ في تحميل الصفحة $pageNumber',
              style: const TextStyle(fontSize: 16, fontFamily: 'Digital'),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;

  const MushafPageContent({Key? key, required this.pageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;
    final int pageNumber = pageData['pageNumber'] as int;
    final String surahName = pageData['surahName'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main text content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
              child: SingleChildScrollView(
                child: Column(
                  children: lines.map<Widget>((lineData) {
                    final PageModel line = lineData['line'];
                    final List<UthmaniModel> words =
                    List<UthmaniModel>.from(lineData['words']);
                    return _buildLine(line, words);
                  }).toList(),
                ),
              ),
            ),

            // Simple header with just surah name in Arabic
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Text(
                surahName,
                style: const TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),

            // Simple page number at bottom
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Text(
                '$pageNumber',
                style: const TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(PageModel line, List<UthmaniModel> words) {
    if (line.lineType == 'basmallah') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: const TextStyle(
              fontFamily: 'Digital',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    if (words.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: line.isCentered ? _buildCenteredLine(words) : _buildJustifiedLine(words),
    );
  }

  Widget _buildCenteredLine(List<UthmaniModel> words) {
    return Center(
      child: Wrap(
        textDirection: TextDirection.rtl,
        spacing: 4,
        children: words.map((word) => Text(
          word.text,
          style: const TextStyle(
            fontFamily: 'Digital',
            fontSize: 16,
            color: Colors.black,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        )).toList(),
      ),
    );
  }

  Widget _buildJustifiedLine(List<UthmaniModel> words) {
    if (words.length == 1) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          words.first.text,
          style: const TextStyle(
            fontFamily: 'Digital',
            fontSize: 16,
            color: Colors.black,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: words.map((word) => Text(
        word.text,
        style: const TextStyle(
          fontFamily: 'Digital',
          fontSize: 16,
          color: Colors.black,
          height: 1.8,
        ),
        textDirection: TextDirection.rtl,
      )).toList(),
    );
  }
}