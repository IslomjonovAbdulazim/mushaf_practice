// lib/widgets/mushaf_page.dart - Improved with surah/juz display and better caching
import 'package:flutter/material.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/services/data_service.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;

  const MushafPage({
    Key? key,
    required this.pageNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start preloading surrounding pages immediately
    DataService.preloadAroundPage(pageNumber);

    return FutureBuilder<Map<String, dynamic>>(
      future: DataService.getCompletePageData(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MushafPageContent(pageData: snapshot.data!);
        } else if (snapshot.hasError) {
          return _buildErrorWidget(context);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Page $pageNumber',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: theme.colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading page $pageNumber',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;

  const MushafPageContent({
    Key? key,
    required this.pageData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = pageData['lines'] as List;
    final pageNumber = pageData['pageNumber'] as int;
    final surahName = pageData['surahName'] as String? ?? 'Holy Quran';
    final juzNumber = pageData['juzNumber'] as int? ?? 1;
    final isOddPage = pageNumber % 2 == 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _buildMainContent(lines, theme),

            // Surah name (left side)
            _buildSurahName(surahName, theme),

            // Juz number (right side)
            _buildJuzNumber(juzNumber, theme),

            // Page number (bottom)
            _buildPageNumber(pageNumber, isOddPage, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List lines, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 45, 10, 40), // More top padding for Arabic surah name
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: lines.map<Widget>((lineData) {
              final PageModel line = lineData['line'];
              final List<UthmaniModel> words = List<UthmaniModel>.from(
                lineData['words'],
              );
              return _buildLine(line, words, theme);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahName(String surahName, ThemeData theme) {
    return Positioned(
      top: 8,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          surahName,
          style: TextStyle(
            fontFamily: 'Digital', // Use Arabic-optimized font
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            height: 1.2,
          ),
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildJuzNumber(int juzNumber, ThemeData theme) {
    return Positioned(
      top: 8,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Text(
          'Juz $juzNumber',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNumber, bool isOddPage, ThemeData theme) {
    return Positioned(
      bottom: 8,
      left: isOddPage ? null : 16,
      right: isOddPage ? 16 : null,
      child: Text(
        '$pageNumber',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onBackground.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildLine(PageModel line, List<UthmaniModel> words, ThemeData theme) {
    if (line.lineType == 'basmallah') {
      return _buildBasmallah(theme);
    }

    if (words.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: line.isCentered
          ? _buildCenteredLine(words, theme)
          : _buildJustifiedLine(words, theme),
    );
  }

  Widget _buildBasmallah(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildCenteredLine(List<UthmaniModel> words, ThemeData theme) {
    return Center(
      child: Wrap(
        textDirection: TextDirection.rtl,
        spacing: 4,
        children: words.map((word) => _buildWordText(word, theme)).toList(),
      ),
    );
  }

  Widget _buildJustifiedLine(List<UthmaniModel> words, ThemeData theme) {
    if (words.length == 1) {
      return Align(
        alignment: Alignment.centerRight,
        child: _buildWordText(words.first, theme),
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: words.map((word) => _buildWordText(word, theme)).toList(),
    );
  }

  Widget _buildWordText(UthmaniModel word, ThemeData theme) {
    final isAyahNumber = _isAyahNumber(word.text);

    return Text(
      word.text,
      style: TextStyle(
        fontFamily: isAyahNumber ? 'Uthmani' : 'Digital',
        fontSize: isAyahNumber ? 18 : 17,
        color: theme.colorScheme.onBackground,
        height: 2,
        letterSpacing: 0,
        wordSpacing: 0,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  bool _isAyahNumber(String text) {
    return text.contains('۝') ||
        text.contains('﴾') ||
        text.contains('﴿') ||
        (text.length <= 3 && RegExp(r'^[٠-٩]+').hasMatch(text));
  }
}