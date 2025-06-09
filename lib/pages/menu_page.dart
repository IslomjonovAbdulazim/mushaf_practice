// lib/pages/menu_page.dart - Updated with theme awareness
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

      for (var surah in allSurahs) {
        final juzNumber = await DataService.getJuzForSurah(surah.id);
        final startPage = await DataService.getSurahStartPage(surah.id);

        surahDetailsList.add(SurahWithDetails(
          surah: surah,
          startPage: startPage,
          juzNumber: juzNumber,
        ));
      }

      setState(() {
        surahs = surahDetailsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
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
        'فهرس السور',
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
            'جاري تحميل السور...',
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
              'إعادة المحاولة',
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
        'لا توجد سور متاحة',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 16,
          color: theme.colorScheme.onBackground.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _getListItemCount(),
      itemBuilder: (context, index) => _buildListItem(index),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withOpacity(0.6),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Text(
                DataService.getJuzName(juzNumber),
                style: TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withOpacity(0.6),
              thickness: 1,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 1,
      color: theme.colorScheme.surface,
      child: ListTile(
        onTap: () => _navigateToSurah(surahDetails),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '${surah.id}',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          surah.nameArabic,
          style: TextStyle(
            fontFamily: 'Digital',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          '${MushafUtils.formatPageInfo(surahDetails.startPage)} • ${MushafUtils.formatVerseCount(surah.versesCount)} • $revelationPlace',
          style: TextStyle(
            fontFamily: 'Digital',
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }
}