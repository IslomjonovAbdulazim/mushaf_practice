// lib/mushaf_page.dart - Optimized Mushaf page display component
// This file consolidates enhanced_mushaf_page.dart functionality with improvements

import 'package:flutter/material.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';

// Main widget that displays a single page of the Mushaf
// This widget handles the async loading of page data and displays appropriate loading/error states
class MushafPage extends StatelessWidget {
  final int pageNumber;

  const MushafPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseManager.getCompletePageData(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Data loaded successfully - display the page content
          return MushafPageContent(pageData: snapshot.data!);
        } else if (snapshot.hasError) {
          // Error occurred during loading - show user-friendly error message
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الصفحة $pageNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: 'Digital',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error loading page $pageNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 16),
                // Retry button for user convenience
                ElevatedButton.icon(
                  onPressed: () {
                    // Force rebuild by clearing cache and triggering setState
                    DatabaseManager.clearAllCaches();
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Loading state - show progress indicator with Quranic styling
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green.shade600,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل الصفحة $pageNumber...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontFamily: 'Digital',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget that renders the actual content of a Mushaf page
// This includes the Quranic text, headers, footers, and proper Arabic formatting
class MushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;

  // Regular expression to identify Arabic/Islamic numbers in the text
  static final RegExp arabicNumbers = RegExp(r'^[٠-٩۰-۹]+');

  const MushafPageContent({Key? key, required this.pageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List;
    final PageMetadata metadata = pageData['metadata'] as PageMetadata;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Quranic text content area
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 55, 15, 55),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Smooth iOS-style scrolling
                child: Column(
                  children: lines.map<Widget>((lineData) {
                    final PageModel line = lineData['line'];
                    final List<UthmaniModel> words = List<UthmaniModel>.from(
                      lineData['words'],
                    );
                    return _buildTextLine(context, line, words);
                  }).toList(),
                ),
              ),
            ),

            // Header section with Surah information and Juz number
            _buildPageHeader(context, metadata),

            // Footer section with page number and navigation indicators
            _buildPageFooter(context, metadata),
          ],
        ),
      ),
    );
  }

  // Build the header section displaying Surah name and Juz information
  Widget _buildPageHeader(BuildContext context, PageMetadata metadata) {
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
            // Left side: Surah information
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary surah name in Arabic
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

                  // Surah name in simplified English/transliteration
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

                  // Indicator for pages containing multiple surahs
                  if (metadata.hasMultipleSurahs) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${metadata.allSurahs.length - 1} سورة إضافية',
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

            // Right side: Juz number with decorative styling
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
                  // Using regular numbers (1,2,3...) as requested
                  Text(
                    '${metadata.juzNumber}',
                    style: TextStyle(
                      fontFamily: 'Digital',
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

  // Build the footer section with page number and position indicators
  Widget _buildPageFooter(BuildContext context, PageMetadata metadata) {
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
                  // Direction indicator icon
                  Icon(
                    metadata.isRightPage
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),

                  // Page number using regular numbers (1,2,3...) as requested
                  Text(
                    '${metadata.pageNumber}',
                    style: const TextStyle(
                      fontFamily: 'Digital',
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

  // Build individual lines of Quranic text with proper formatting
  Widget _buildTextLine(
    BuildContext context,
    PageModel line,
    List<UthmaniModel> words,
  ) {
    // Handle special case of Basmallah (بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ)
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
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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

    // Handle regular lines containing Quranic text
    if (words.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _buildLineWithAlignment(context, line, words),
      );
    }

    // Handle empty lines (used for spacing between sections)
    return const SizedBox(height: 8);
  }

  // Apply appropriate text alignment based on line type and content
  Widget _buildLineWithAlignment(
    BuildContext context,
    PageModel line,
    List<UthmaniModel> words,
  ) {
    if (line.isCentered) {
      // Center-aligned text (typically used for surah headers)
      return Center(
        child: Wrap(
          textDirection: TextDirection.rtl,
          spacing: 4,
          children: words
              .map((word) => _buildIndividualWord(context, word, true))
              .toList(),
        ),
      );
    } else {
      // Justified text to fill the line width (standard Quranic text layout)
      return Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _buildJustifiedWordsRow(context, words),
      );
    }
  }

  // Create a row of words with justified spacing for proper Mushaf layout
  List<Widget> _buildJustifiedWordsRow(
    BuildContext context,
    List<UthmaniModel> words,
  ) {
    if (words.length == 1) {
      // Single word: align to the right side
      return [
        Align(
          alignment: Alignment.centerRight,
          child: _buildIndividualWord(context, words.first),
        ),
      ];
    }

    // Multiple words: distribute evenly across the line width
    return words
        .map(
          (word) => Text(
            word.text,
            style: _getTextStyle(context, arabicNumbers.hasMatch(word.text)),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        )
        .toList();
  }

  // Build individual word widget with appropriate styling
  Widget _buildIndividualWord(
    BuildContext context,
    UthmaniModel word, [
    bool centerPadding = false,
  ]) {
    final isArabicNumber = arabicNumbers.hasMatch(word.text);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: centerPadding ? 2 : 0),
      child: Text(
        word.text,
        style: _getTextStyle(context, isArabicNumber),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // Get appropriate text style based on content type and screen size
  TextStyle _getTextStyle(
    BuildContext context,
    bool isArabicNumber, {
    bool isBasmallah = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveFontSizes = _calculateResponsiveFontSizes(screenWidth);

    if (isArabicNumber) {
      // Use Uthmani font for Arabic numerals in Quranic text
      return TextStyle(
        fontFamily: 'Uthmani',
        fontSize: responsiveFontSizes.number,
        height: 1.8,
        color: Colors.black,
        letterSpacing: 0,
        wordSpacing: 0,
      );
    } else {
      // Use Digital font for regular Quranic text and Arabic letters
      return TextStyle(
        fontFamily: 'Digital',
        fontSize: isBasmallah
            ? responsiveFontSizes.basmallah
            : responsiveFontSizes.text,
        height: 1.8,
        color: Colors.black,
        fontWeight: isBasmallah ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0,
        wordSpacing: 0,
      );
    }
  }

  // Calculate appropriate font sizes based on device screen width for responsive design
  ({double text, double number, double basmallah})
  _calculateResponsiveFontSizes(
    double screenWidth,
  ) {
    if (screenWidth >= 768) {
      // Large screens (tablets and large phones in landscape)
      return (text: 18.0, number: 19.0, basmallah: 20.0);
    } else if (screenWidth >= 400) {
      // Medium phones (most modern smartphones)
      return (text: 16.0, number: 17.0, basmallah: 18.0);
    } else if (screenWidth >= 350) {
      // Standard phones (common screen sizes)
      return (text: 15.0, number: 15.0, basmallah: 16.0);
    } else {
      // Small phones (compact devices)
      return (text: 13.0, number: 13.0, basmallah: 15.0);
    }
  }
}
