// lib/pages/menu_page.dart - Clean menu page with database integration
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mushaf_practice/models.dart';
import 'package:mushaf_practice/services/data_service.dart';

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
    ),
      ],
    ),
    );