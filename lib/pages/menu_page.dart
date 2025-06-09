// lib/pages/menu_page.dart - Authentic design with English language
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/services/data_service.dart';
import 'package:mushaf_practice/utils/helpers.dart';

class SurahWithDetails {
  final SurahModel surah;
  final int startPage;
  final int juzNumber;

  const SurahWithDetails({
    required this.surah,
    required this.startPage,
    required this.juzNumber,
  });
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<SurahWithDetails> surahs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final allSurahs = await DataService.getAllSurahs();
      final surahDetailsList = <SurahWithDetails>[];

      // Fast parallel loading
      final futures = allSurahs.map((surah) async {
        final juzNumber = await DataService.getJuzForSurah(surah.id);
        final startPage = await DataService.getSurahStartPage(surah.id);

        return SurahWithDetails(
          surah: surah,
          startPage: startPage,
          juzNumber: juzNumber,
        );
      });

      final results = await Future.wait(futures);
      surahDetailsList.addAll(results);

      setState(() {
        surahs = surahDetailsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading chapters: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToSurah(SurahWithDetails surahDetails) {
    Get.back(result: surahDetails.startPage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.background,
      elevation: 0,
      title: Text(
        'Index of Chapters',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onBackground),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (isLoading) {
      return _buildLoadingWidget(theme);
    }

    if (errorMessage != null) {
      return _buildErrorWidget(theme);
    }

    if (surahs.isEmpty) {
      return _buildEmptyWidget(theme);
    }

    return _buildSurahList();
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chapters...',
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 16,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 16,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSurahs,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontFamily: 'Digital'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ThemeData theme) {
    return Center(
      child: Text(
        'No chapters available',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 16,
          color: theme.colorScheme.onBackground.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),

        // Chapters list grouped by Juz
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => _buildListItem(index),
            childCount: _getListItemCount(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Holy Quran',
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '114 Chapters • 604 Pages',
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tap any chapter to navigate',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getListItemCount() {
    int count = surahs.length;
    final juzNumbers = surahs.map((s) => s.juzNumber).toSet();
    count += juzNumbers.length; // Add juz headers
    return count;
  }

  Widget _buildListItem(int index) {
    int currentJuz = -1;
    int adjustedIndex = 0;

    for (int i = 0; i < surahs.length; i++) {
      if (surahs[i].juzNumber != currentJuz) {
        if (adjustedIndex == index) {
          return _buildJuzDivider(surahs[i].juzNumber);
        }
        currentJuz = surahs[i].juzNumber;
        adjustedIndex++;
      }

      if (adjustedIndex == index) {
        return _buildSurahTile(surahs[i]);
      }
      adjustedIndex++;
    }

    return const SizedBox.shrink();
  }

  Widget _buildJuzDivider(int juzNumber) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Part $juzNumber',
                  style: TextStyle(
                    fontFamily: 'Digital',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.5),
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahTile(SurahWithDetails surahDetails) {
    final theme = Theme.of(context);
    final surah = surahDetails.surah;
    final revelationPlace = MushafUtils.formatRevelationPlace(surah.revelationPlace);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.1),
        child: InkWell(
          onTap: () => _navigateToSurah(surahDetails),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Chapter number
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${surah.id}',
                      style: TextStyle(
                        fontFamily: 'Digital',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic name
                      Text(
                        surah.nameArabic,
                        style: TextStyle(
                          fontFamily: 'Digital',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textDirection: TextDirection.rtl,
                      ),

                      const SizedBox(height: 4),

                      // English name
                      Text(
                        surah.nameSimple,
                        style: TextStyle(
                          fontFamily: 'Digital',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Details
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.bookmark_outline,
                            text: 'Page ${surahDetails.startPage}',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.format_list_numbered,
                            text: '${surah.versesCount} verses',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.place,
                            text: revelationPlace == 'مكية' ? 'Makkah' : 'Madinah',
                            theme: theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}