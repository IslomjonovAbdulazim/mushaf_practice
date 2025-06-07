// lib/enhanced_mushaf_page.dart
import 'package:flutter/material.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/enhanced_models.dart';
import 'package:mushaf_practice/enhanced_database.dart';

class EnhancedMushafPage extends StatelessWidget {
  final int pageNumber;

  const EnhancedMushafPage({Key? key, required this.pageNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: EnhancedDatabase.getCompletePage(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return EnhancedMushafContent(pageData: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading page $pageNumber',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      },
    );
  }
}

class EnhancedMushafContent extends StatelessWidget {
  final Map<String, dynamic> pageData;
  static final RegExp arabicNumbers = RegExp(r'^[٠-٩۰-۹]+$');

  const EnhancedMushafContent({Key? key, required this.pageData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;
    final PageMetadata metadata = pageData['metadata'] as PageMetadata;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 55, 15, 55),
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

            // Header with Surah name and Juz
            _buildHeader(context, metadata),

            // Footer with page number
            _buildFooter(context, metadata),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PageMetadata metadata) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah name (top left)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic surah name
                  Text(
                    metadata.primarySurah.nameArabic,
                    style: const TextStyle(
                      fontFamily: 'Digital',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // English surah name and info
                  Text(
                    metadata.primarySurah.nameSimple,
                    style: const TextStyle(
                      fontFamily: 'Digital',
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Multiple surahs indicator
                  if (metadata.hasMultipleSurahs) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${metadata.allSurahs.length - 1} more',
                      style: TextStyle(
                        fontFamily: 'Digital',
                        fontSize: 9,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Juz number (top right)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الجزء',
                    style: TextStyle(
                      fontFamily: 'Digital',
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _convertToArabicNumber(metadata.juzNumber),
                    style: TextStyle(
                      fontFamily: 'Uthmani',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
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

  Widget _buildFooter(BuildContext context, PageMetadata metadata) {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: metadata.isRightPage
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator icon
                  Icon(
                    metadata.isRightPage ? Icons.chevron_right : Icons.chevron_left,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),

                  // Page number in Arabic
                  Text(
                    _convertToArabicNumber(metadata.pageNumber),
                    style: const TextStyle(
                      fontFamily: 'Uthmani',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  String _convertToArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      int digitInt = int.tryParse(digit) ?? 0;
      return arabicDigits[digitInt];
    }).join('');
  }

  Widget _buildLine(
      BuildContext context,
      PageModel line,
      List<UthmaniModel> words,
      ) {
    // Handle Basmallah
    if (line.lineType == 'basmallah') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: _getTextStyle(context, false, isBasmallah: true),
              textDirection: TextDirection.rtl,
            ),
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
          spacing: 4,
          children: words.map((word) => _buildWord(context, word, true)).toList(),
        ),
      );
    } else {
      // Justify the words to fill the line
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

    // Multiple words - distribute evenly across the line
    return words
        .map(
          (word) => Center(
            child: Text(
              word.text,
              style: _getTextStyle(context, arabicNumbers.hasMatch(word.text)),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: center ? 2 : 0),
      child: Text(
        word.text,
        style: _getTextStyle(context, isNumber),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  TextStyle _getTextStyle(
      BuildContext context,
      bool isArabicNumber, {
        bool isBasmallah = false,
      }) {
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
      // Use Digital for everything else
      return TextStyle(
        fontFamily: 'Digital',
        fontSize: isBasmallah ? fontSize.basmallah : fontSize.text,
        height: 1.8,
        color: Colors.black,
        fontWeight: isBasmallah ? FontWeight.w600 : FontWeight.w500,
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