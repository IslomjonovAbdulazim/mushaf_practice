// lib/widgets/mushaf_page.dart - Optimized with fixed surah name
import 'package:flutter/material.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/services/data_service.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final String? surahName; // Optional surah name from parent

  const MushafPage({
    Key? key,
    required this.pageNumber,
    this.surahName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DataService.getCompletePageData(pageNumber), // Now super fast with caching!
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MushafPageContent(
            pageData: snapshot.data!,
            overrideSurahName: surahName, // Use surah name from parent if provided
          );
        } else if (snapshot.hasError) {
          return _buildErrorWidget(context);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Page $pageNumber...',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Digital',
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading page $pageNumber',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Digital',
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class MushafPageContent extends StatelessWidget {
  final Map<String, dynamic> pageData;
  final String? overrideSurahName;

  const MushafPageContent({
    Key? key,
    required this.pageData,
    this.overrideSurahName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = pageData['lines'] as List;
    final pageNumber = pageData['pageNumber'] as int;

    // Use override surah name if provided, otherwise use from page data
    final surahName = overrideSurahName ?? (pageData['surahName'] as String? ?? 'Holy Quran');
    final isOddPage = pageNumber % 2 == 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _buildMainContent(lines, theme),

            // Header (only show if no override - controls will show it)
            if (overrideSurahName == null) _buildHeader(surahName, theme),

            // Page number
            _buildPageNumber(pageNumber, isOddPage, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List lines, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            10,
            overrideSurahName != null ? 10 : 50, // Less top padding if surah name shown in controls
            10,
            40
        ),
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

  Widget _buildHeader(String surahName, ThemeData theme) {
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            surahName,
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
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
          fontFamily: 'Digital',
          fontSize: 14,
          color: theme.colorScheme.onBackground.withOpacity(0.6),
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
            fontFamily: 'Digital',
            fontSize: 17,
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
        fontSize: isAyahNumber ? 13 : 14.5,
        color: theme.colorScheme.onBackground,
        height: 1.8,
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