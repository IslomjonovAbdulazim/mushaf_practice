// lib/pages/menu_page.dart - Clean menu page with database integration
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'فهرس السور',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (surahs.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildSurahList();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل السور...',
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(
              fontFamily: 'Digital',
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSurahs,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text(
        'لا توجد سور متاحة',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 16,
          color: Colors.black54,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.green.shade300,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                DataService.getJuzName(juzNumber),
                style: TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.green.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahTile(SurahWithDetails surahDetails) {
    final surah = surahDetails.surah;
    final revelationPlace = MushafUtils.formatRevelationPlace(surah.revelationPlace);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 1,
      child: ListTile(
        onTap: () => _navigateToSurah(surahDetails),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Center(
            child: Text(
              '${surah.id}',
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ),
        title: Text(
          surah.nameArabic,
          style: const TextStyle(
            fontFamily: 'Digital',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          '${MushafUtils.formatPageInfo(surahDetails.startPage)} • ${MushafUtils.formatVerseCount(surah.versesCount)} • $revelationPlace',
          style: const TextStyle(
            fontFamily: 'Digital',
            fontSize: 12,
            color: Colors.black54,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.green.shade400,
        ),
      ),
    );
  }
}