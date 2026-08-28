import 'morning_adhkar_data.dart' as morning_adhkar_data;
import 'evening_adhkar_data.dart' as evening_adhkar_data;
import 'after_salah_adhkar_data.dart' as after_salah_adhkar_data;
import 'sleep_adhkar_data.dart' as sleep_adhkar_data;
import 'travel_adhkar_data.dart' as travel_adhkar_data;
import 'others_adhkar_data.dart' as others_adhkar_data;

class JourneySearchResult {
  final String category;
  final String title;
  final String subtitle;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final String? source;
  final String? commonName;
  final int id;
  final double relevance;

  const JourneySearchResult({
    required this.category,
    required this.title,
    required this.subtitle,
    this.arabic,
    this.transliteration,
    this.translation,
    this.source,
    this.commonName,
    required this.id,
    required this.relevance,
  });
}

class JourneySearchIndex {
  static final List<JourneySearchResult> _index = [];

  static void build() {
    _index.clear();

    _addAdhkarCategory('Morning', morning_adhkar_data.MorningAdhkarData.duas);
    _addAdhkarCategory('Evening', evening_adhkar_data.EveningAdhkarData.duas);
    _addAdhkarCategory(
      'After Salah',
      after_salah_adhkar_data.AfterSalahAdhkarData.duas,
    );
    _addAdhkarCategory('Sleep', sleep_adhkar_data.SleepAdhkarData.duas);
    _addAdhkarCategory('Travel', travel_adhkar_data.TravelAdhkarData.duas);
    _addAdhkarCategory('Others', others_adhkar_data.OtherAdhkarData.duas);
    _addAdhkarCategory('Protection', [
      JourneySearchResult(
        category: 'Protection',
        title: 'Audhu bikalimatillahit-tammati',
        subtitle: 'I seek refuge in the perfect words of Allah.',
        arabic:
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        transliteration: 'Audhu bikalimatillahit-tammati min sharri ma khalaq',
        translation:
            'I seek refuge in the perfect words of Allah, from the evil of what He has created.',
        source: 'Muslim',
        commonName: 'Protection dhikr',
        id: 1001,
        relevance: 0,
      ),
    ]);
    _addAdhkarCategory('Gratitude', [
      JourneySearchResult(
        category: 'Gratitude',
        title: 'Alhamdulillah',
        subtitle: 'All praise is due to Allah.',
        arabic: 'الْحَمْدُ لِلَّهِ',
        transliteration: 'Alhamdulillah',
        translation: 'All praise is due to Allah.',
        source: 'Muslim',
        commonName: 'Gratitude dhikr',
        id: 1002,
        relevance: 0,
      ),
    ]);
    _addAdhkarCategory('Forgiveness', [
      JourneySearchResult(
        category: 'Forgiveness',
        title: 'Astaghfirullah',
        subtitle: 'I seek forgiveness of Allah.',
        arabic: 'أَسْتَغْفِرُ اللَّهَ',
        transliteration: 'Astaghfirullah',
        translation: 'I seek forgiveness of Allah.',
        source: 'Muslim',
        commonName: 'Forgiveness dhikr',
        id: 1003,
        relevance: 0,
      ),
    ]);

    _addReflection(
      'Reflection',
      'Grateful',
      'Service at home',
      'I prepared breakfast quietly for my parents. May our home stay gentle and grateful.',
    );
    _addReflection(
      'Reflection',
      'Quiet',
      'A slower morning',
      'I let the first hour be slow. No phone, just the window and the light.',
    );
    _addReflection(
      'Reflection',
      'Hopeful',
      'Beginning again',
      'Consistency broke for a while. Today I begin again, gently.',
    );

    _addReading(
      'Reading',
      'Continue reading',
      'On patience',
      'A few quiet minutes on the virtue of steady, unhurried effort.',
    );
    _addReading(
      'Reading',
      'Lesson',
      'The etiquette of remembrance',
      'Remembrance is the heart returning, again and again, to its Lord.',
    );
    _addReading(
      'Reading',
      'Quran reflection',
      'On the clearing of the heart',
      'By the remembrance of Allah do hearts find rest.',
    );
  }

  static void _addAdhkarCategory(String category, List<dynamic> duas) {
    for (final dua in duas) {
      final title = dua.commonName ?? category;
      final subtitle = dua.translation;
      _index.add(
        JourneySearchResult(
          category: category,
          title: title,
          subtitle: subtitle,
          arabic: dua.arabic,
          transliteration: dua.transliteration,
          translation: dua.translation,
          source: dua.source,
          commonName: dua.commonName,
          id: dua.id,
          relevance: 0,
        ),
      );
    }
  }

  static void _addReflection(
    String category,
    String mood,
    String title,
    String preview,
  ) {
    _index.add(
      JourneySearchResult(
        category: category,
        title: title,
        subtitle: preview,
        id: 0,
        relevance: 0,
      ),
    );
  }

  static void _addReading(
    String category,
    String type,
    String title,
    String copy,
  ) {
    _index.add(
      JourneySearchResult(
        category: category,
        title: title,
        subtitle: copy,
        id: 0,
        relevance: 0,
      ),
    );
  }

  static List<JourneySearchResult> search(String query) {
    if (query.isEmpty) return const [];
    final normalized = normalize(query);
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];

    final results = <JourneySearchResult>[];
    for (final item in _index) {
      final score = _score(item, words, normalized);
      if (score > 0) {
        results.add(
          JourneySearchResult(
            category: item.category,
            title: item.title,
            subtitle: item.subtitle,
            arabic: item.arabic,
            transliteration: item.transliteration,
            translation: item.translation,
            source: item.source,
            commonName: item.commonName,
            id: item.id,
            relevance: score,
          ),
        );
      }
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results;
  }

  /// Resolves the stable adhkar id stored by the favorites API back to the
  /// bundled content used by the reader. Favorites intentionally store only
  /// ids, so the Saved tab must not render a bare "Adhkar #..." label.
  static JourneySearchResult? findAdhkarById(int id) {
    if (_index.isEmpty) build();
    for (final item in _index) {
      if (item.category != 'Reflection' &&
          item.category != 'Reading' &&
          item.id == id) {
        return item;
      }
    }
    return null;
  }

  static double _score(
    JourneySearchResult item,
    List<String> words,
    String fullQuery,
  ) {
    double score = 0;
    final titleN = normalize(item.title);
    final subtitleN = normalize(item.subtitle);
    final arabicN = normalize(item.arabic ?? '');
    final translitN = normalize(item.transliteration ?? '');
    final translationN = normalize(item.translation ?? '');
    final sourceN = normalize(item.source ?? '');
    final categoryN = normalize(item.category);
    final commonN = normalize(item.commonName ?? '');

    for (final word in words) {
      if (titleN == word) {
        score += 100;
      } else if (titleN.startsWith(word)) {
        score += 80;
      } else if (titleN.contains(word)) {
        score += 60;
      }

      if (commonN == word) {
        score += 90;
      } else if (commonN.contains(word)) {
        score += 70;
      }

      if (categoryN == word) {
        score += 50;
      } else if (categoryN.contains(word)) {
        score += 30;
      }

      if (translationN.contains(word)) {
        score += 25;
      }
      if (translitN.contains(word)) {
        score += 20;
      }
      if (arabicN.contains(word)) {
        score += 15;
      }
      if (sourceN.contains(word)) {
        score += 10;
      }
      if (subtitleN.contains(word)) {
        score += 5;
      }
    }

    return score;
  }

  static String normalize(String input) {
    final normalized = input.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final codeUnit in normalized.codeUnits) {
      if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
          (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
          (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
          (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF) ||
          codeUnit == 0x060D ||
          codeUnit == 0x0610 ||
          codeUnit == 0x0611 ||
          codeUnit == 0x0612 ||
          codeUnit == 0x0613 ||
          codeUnit == 0x0614 ||
          codeUnit == 0x0615 ||
          codeUnit == 0x064B ||
          codeUnit == 0x064C ||
          codeUnit == 0x064D ||
          codeUnit == 0x064E ||
          codeUnit == 0x064F ||
          codeUnit == 0x0650 ||
          codeUnit == 0x0651 ||
          codeUnit == 0x0652 ||
          codeUnit == 0x0653 ||
          codeUnit == 0x0654 ||
          codeUnit == 0x0655 ||
          codeUnit == 0x0656 ||
          codeUnit == 0x0657 ||
          codeUnit == 0x0658 ||
          codeUnit == 0x0659 ||
          codeUnit == 0x065A ||
          codeUnit == 0x065B ||
          codeUnit == 0x065C ||
          codeUnit == 0x065D ||
          codeUnit == 0x065E ||
          codeUnit == 0x065F ||
          codeUnit >= 0x0660 && codeUnit <= 0x0669) {
        buffer.writeCharCode(codeUnit);
      } else if (codeUnit >= 97 && codeUnit <= 122) {
        buffer.writeCharCode(codeUnit);
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      } else if (codeUnit == 32) {
        buffer.writeCharCode(32);
      }
    }
    return buffer.toString().trim();
  }
}
