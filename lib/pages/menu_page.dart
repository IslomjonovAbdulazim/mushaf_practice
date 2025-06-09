// lib/pages/menu_page.dart - Simple and minimalist
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
      appBar: AppBar(
        title: const Text('Chapters'),
        centerTitle: true,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSurahs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (surahs.isEmpty) {
      return const Center(child: Text('No chapters available'));
    }

    return _buildSurahList();
  }

  Widget _buildSurahList() {
    return ListView.builder(
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
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Part $juzNumber',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurahTile(SurahWithDetails surahDetails) {
    final surah = surahDetails.surah;
    final revelationPlace = surah.revelationPlace.toLowerCase() == 'makkah' ? 'Meccan' : 'Medinan';

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        child: Text(
          '${surah.id}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        surah.nameSimple,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Page ${surahDetails.startPage} • ${surah.versesCount} verses • $revelationPlace',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _navigateToSurah(surahDetails),
    );
  }
}