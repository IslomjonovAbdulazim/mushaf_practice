// lib/menu_page.dart - Optimized menu with real database integration
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mushaf_practice/database.dart';
import 'package:mushaf_practice/models.dart';

// Enhanced SurahModel with proper constructor
class EnhancedSurahModel {
  final int id;
  final String nameArabic;
  final String nameSimple;
  final int versesCount;
  final int revelationOrder;
  final String revelationPlace;
  final int bismillahPre;

  const EnhancedSurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.bismillahPre,
  });

  factory EnhancedSurahModel.fromJson(Map<String, dynamic> json) {
    return EnhancedSurahModel(
      id: json['id'] as int? ?? 0,
      nameArabic: json['name_arabic'] as String? ?? '',
      nameSimple: json['name_simple'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
      revelationOrder: json['revelation_order'] as int? ?? 0,
      revelationPlace: json['revelation_place'] as String? ?? '',
      bismillahPre: json['bismillah_pre'] as int? ?? 0,
    );
  }
}

class SurahWithDetails {
  final EnhancedSurahModel surah;
  final int startPage;
  final int juzNumber;
  final String? juzName;

  const SurahWithDetails({
    required this.surah,
    required this.startPage,
    required this.juzNumber,
    this.juzName,
  });
}

class JuzInfo {
  final int juzNumber;
  final String firstVerseKey;
  final String lastVerseKey;
  final int versesCount;

  const JuzInfo({
    required this.juzNumber,
    required this.firstVerseKey,
    required this.lastVerseKey,
    required this.versesCount,
  });

  factory JuzInfo.fromJson(Map<String, dynamic> json) {
    return JuzInfo(
      juzNumber: json['juz_number'] as int? ?? 0,
      firstVerseKey: json['first_verse_key'] as String? ?? '',
      lastVerseKey: json['last_verse_key'] as String? ?? '',
      versesCount: json['verses_count'] as int? ?? 0,
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<SurahWithDetails> surahs = [];
  Map<int, JuzInfo> juzData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load juz data first
      await _loadJuzData();
      // Then load surahs with their details
      await _loadSurahsWithDetails();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadJuzData() async {
    try {
      final database = await DatabaseManager.juzDatabase;
      final queryResults = await database.query(
        'juz',
        orderBy: 'juz_number ASC',
      );

      for (var row in queryResults) {
        final juz = JuzInfo.fromJson(row);
        juzData[juz.juzNumber] = juz;
      }
    } catch (e) {
      print('Error loading juz data: $e');
    }
  }

  Future<void> _loadSurahsWithDetails() async {
    try {
      final database = await DatabaseManager.surahDatabase;
      final queryResults = await database.query(
        'chapters',
        orderBy: 'id ASC',
      );

      List<SurahWithDetails> surahList = [];

      for (var row in queryResults) {
        final surah = EnhancedSurahModel.fromJson(row);
        final juzNumber = await _getJuzForSurah(surah.id);
        final startPage = await _getStartPageForSurah(surah.id, juzNumber);

        surahList.add(SurahWithDetails(
          surah: surah,
          startPage: startPage,
          juzNumber: juzNumber,
        ));
      }

      setState(() {
        surahs = surahList;
      });
    } catch (e) {
      print('Error loading surahs: $e');
      throw e;
    }
  }

  Future<int> _getJuzForSurah(int surahId) async {
    try {
      // Find which juz this surah belongs to by checking verse ranges
      for (var entry in juzData.entries) {
        final juz = entry.value;
        final firstVerse = juz.firstVerseKey.split(':');
        final lastVerse = juz.lastVerseKey.split(':');

        if (firstVerse.length >= 2 && lastVerse.length >= 2) {
          final firstSurah = int.tryParse(firstVerse[0]) ?? 0;
          final lastSurah = int.tryParse(lastVerse[0]) ?? 0;

          if (surahId >= firstSurah && surahId <= lastSurah) {
            return juz.juzNumber;
          }
        }
      }
    } catch (e) {
      print('Error getting juz for surah $surahId: $e');
    }

    // Fallback calculation
    return ((surahId - 1) ~/ 4) + 1;
  }

  Future<int> _getStartPageForSurah(int surahId, int juzNumber) async {
    try {
      // Try to get from mushaf database first
      final mushafDb = await DatabaseManager.mushafDatabase;

      // Get the first word of this surah from script database
      final scriptDb = await DatabaseManager.scriptDatabase;
      final wordQuery = await scriptDb.query(
        'words',
        where: 'surah = ? AND ayah = 1 AND word = 1',
        whereArgs: [surahId],
        limit: 1,
      );

      if (wordQuery.isNotEmpty) {
        final firstWordId = wordQuery.first['id'] as int;

        // Find which page contains this word
        final pageQuery = await mushafDb.query(
          'pages',
          where: 'first_word_id <= ? AND last_word_id >= ?',
          whereArgs: [firstWordId, firstWordId],
          limit: 1,
        );

        if (pageQuery.isNotEmpty) {
          return pageQuery.first['page_number'] as int;
        }
      }
    } catch (e) {
      print('Error getting start page for surah $surahId: $e');
    }

    // Fallback: approximate calculation based on juz
    return ((juzNumber - 1) * 20) + 1;
  }

  String _getJuzDisplayName(int juzNumber) {
    const juzNames = {
      1: 'الم',
      2: 'سيقول',
      3: 'تلك الرسل',
      4: 'لن تنالوا',
      5: 'والمحصنات',
      6: 'لا يحب الله',
      7: 'وإذا سمعوا',
      8: 'ولو أننا',
      9: 'قال الملأ',
      10: 'واعلموا',
      11: 'يعتذرون',
      12: 'وما من دابة',
      13: 'وما أبرئ',
      14: 'ربما',
      15: 'سبحان الذي',
      16: 'قال ألم',
      17: 'اقترب للناس',
      18: 'قد أفلح',
      19: 'وقال الذين',
      20: 'أمن خلق',
      21: 'اتل ما أوحي',
      22: 'ومن يقنت',
      23: 'وما لي',
      24: 'فمن أظلم',
      25: 'إليه يرد',
      26: 'حم',
      27: 'قال فما خطبكم',
      28: 'قد سمع الله',
      29: 'تبارك الذي',
      30: 'عم',
    };

    return juzNames[juzNumber] ?? 'الجزء $juzNumber';
  }

  void _navigateToSurah(SurahWithDetails surahDetails) {
    // Navigate back to main page with the start page of selected surah
    Get.back(result: surahDetails.startPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
      ),
      body: isLoading
          ? const Center(
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
      )
          : errorMessage != null
          ? Center(
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
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadData();
              },
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
      )
          : _buildSurahList(),
    );
  }

  Widget _buildSurahList() {
    if (surahs.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _getListItemCount(),
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  int _getListItemCount() {
    int count = surahs.length;
    // Add dividers for new juz sections
    Set<int> juzNumbers = surahs.map((s) => s.juzNumber).toSet();
    count += juzNumbers.length; // Add juz headers
    return count;
  }

  Widget _buildListItem(int index) {
    int surahIndex = 0;
    int currentJuz = -1;
    int adjustedIndex = 0;

    // Calculate actual surah index accounting for juz dividers
    for (int i = 0; i < surahs.length; i++) {
      if (surahs[i].juzNumber != currentJuz) {
        if (adjustedIndex == index) {
          // This is a juz header
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
                _getJuzDisplayName(juzNumber),
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
    final revelationPlace = surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية';

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
          'الصفحة ${surahDetails.startPage} • ${surah.versesCount} آية • $revelationPlace',
          style: TextStyle(
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