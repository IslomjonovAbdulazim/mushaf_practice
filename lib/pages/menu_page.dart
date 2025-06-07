// lib/pages/menu_page.dart - Optimized menu page with better performance
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SurahWithDetails &&
              runtimeType == other.runtimeType &&
              surah.id == other.surah.id;

  @override
  int get hashCode => surah.id.hashCode;
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

  // Cache for grouped surahs by juz
  Map<int, List<SurahWithDetails>> _groupedSurahs = {};

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

      // Process surahs in batches for better performance
      for (var surah in allSurahs) {
        final juzNumber = await DataService.getJuzForSurah(surah.id);
        final startPage = await DataService.getSurahStartPage(surah.id);

        surahDetailsList.add(SurahWithDetails(
          surah: surah,
          startPage: startPage,
          juzNumber: juzNumber,
        ));
      }

      // Group surahs by juz for efficient rendering
      _groupedSurahs = {};
      for (var surahDetails in surahDetailsList) {
        final juzNumber = surahDetails.juzNumber;
        _groupedSurahs.putIfAbsent(juzNumber, () => []).add(surahDetails);
      }

      setState(() {
        surahs = surahDetailsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
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

  PreferredSizeWidget _buildAppBar() {
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

    return _buildOptimizedSurahList();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSurahs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Digital'),
              ),
            ),
          ],
        ),
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

  // Optimized list building using ListView.builder with grouped data
  Widget _buildOptimizedSurahList() {
    final juzNumbers = _groupedSurahs.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _calculateTotalItems(juzNumbers),
      itemBuilder: (context, index) => _buildOptimizedListItem(index, juzNumbers),
    );
  }

  int _calculateTotalItems(List<int> juzNumbers) {
    int total = juzNumbers.length; // Juz headers
    for (final juzNumber in juzNumbers) {
      total += _groupedSurahs[juzNumber]?.length ?? 0;
    }
    return total;
  }

  Widget _buildOptimizedListItem(int index, List<int> juzNumbers) {
    int currentIndex = 0;

    for (final juzNumber in juzNumbers) {
      // Check if this index is for a juz header
      if (currentIndex == index) {
        return _buildJuzDivider(juzNumber);
      }
      currentIndex++;

      // Check if this index is for a surah in this juz
      final surahsInJuz = _groupedSurahs[juzNumber]!;
      for (final surahDetails in surahsInJuz) {
        if (currentIndex == index) {
          return _buildOptimizedSurahTile(surahDetails);
        }
        currentIndex++;
      }
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

  Widget _buildOptimizedSurahTile(SurahWithDetails surahDetails) {
    final surah = surahDetails.surah;
    final revelationPlace = MushafUtils.formatRevelationPlace(surah.revelationPlace);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 1,
      child: ListTile(
        onTap: () => _navigateToSurah(surahDetails),
        leading: _buildSurahNumber(surah.id),
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

  Widget _buildSurahNumber(int surahId) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Center(
        child: Text(
          '$surahId',
          style: TextStyle(
            fontFamily: 'Digital',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }
}