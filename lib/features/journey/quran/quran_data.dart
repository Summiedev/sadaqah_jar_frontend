import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../services/backend_api.dart';

enum QuranReadingMode { verses, page }

enum QuranDownloadState { idle, downloading, complete, failed }

class QuranDownloadStatus {
  const QuranDownloadStatus({
    required this.state,
    required this.completed,
    required this.total,
    this.message = '',
  });

  final QuranDownloadState state;
  final int completed;
  final int total;
  final String message;

  double get progress => total <= 0 ? 0 : completed / total;
  int get percent => (progress * 100).clamp(0, 100).round();
}

class QuranSurah {
  const QuranSurah({
    required this.id,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationPlace,
    required this.firstPage,
    required this.lastPage,
    required this.firstJuz,
  });

  final int id;
  final String nameArabic;
  final String nameTransliteration;
  final String nameEnglish;
  final int versesCount;
  final String revelationPlace;
  final int firstPage;
  final int lastPage;
  final int firstJuz;

  static QuranSurah fromMap(Map<String, Object?> row) => QuranSurah(
    id: QuranRepository._asInt(row['id'], fallback: 1),
    nameArabic: row['name_arabic']?.toString() ?? '',
    nameTransliteration: row['name_transliterated']?.toString() ?? 'Surah',
    nameEnglish: row['name_english']?.toString() ?? '',
    versesCount: QuranRepository._asInt(row['verses_count'], fallback: 0),
    revelationPlace: row['revelation_place']?.toString() ?? '',
    firstPage: QuranRepository._asInt(row['first_page'], fallback: 1),
    lastPage: QuranRepository._asInt(row['last_page'], fallback: 1),
    firstJuz: QuranRepository._asInt(row['first_juz'], fallback: 1),
  );
}

class QuranWord {
  const QuranWord({
    required this.text,
    required this.meaning,
    required this.transliteration,
  });

  final String text;
  final String meaning;
  final String transliteration;
}

class QuranVerse {
  const QuranVerse({
    required this.key,
    required this.surahId,
    required this.ayah,
    required this.juz,
    required this.hizb,
    required this.page,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.tafsir,
    required this.audioUrl,
    required this.words,
  });

  final String key;
  final int surahId;
  final int ayah;
  final int juz;
  final int hizb;
  final int page;
  final String arabic;
  final String transliteration;
  final String translation;
  final String tafsir;
  final String? audioUrl;
  final List<QuranWord> words;
}

class QuranRangeItem {
  const QuranRangeItem({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.rangeLabel,
    required this.startSurahId,
    required this.startVerseKey,
    required this.startPage,
  });

  final int number;
  final String title;
  final String subtitle;
  final String rangeLabel;
  final int startSurahId;
  final String startVerseKey;
  final int startPage;
}

class QuranSettings {
  const QuranSettings({
    required this.showPronunciation,
    required this.showTranslation,
    required this.showWordMeanings,
    required this.showTafsir,
    required this.reciter,
    required this.arabicSize,
    required this.readingMode,
  });

  static const defaults = QuranSettings(
    showPronunciation: true,
    showTranslation: true,
    showWordMeanings: true,
    showTafsir: false,
    reciter: 'Mishary Rashid Alafasy',
    arabicSize: 30,
    readingMode: QuranReadingMode.verses,
  );

  final bool showPronunciation;
  final bool showTranslation;
  final bool showWordMeanings;
  final bool showTafsir;
  final String reciter;
  final double arabicSize;
  final QuranReadingMode readingMode;

  QuranSettings copyWith({
    bool? showPronunciation,
    bool? showTranslation,
    bool? showWordMeanings,
    bool? showTafsir,
    String? reciter,
    double? arabicSize,
    QuranReadingMode? readingMode,
  }) {
    return QuranSettings(
      showPronunciation: showPronunciation ?? this.showPronunciation,
      showTranslation: showTranslation ?? this.showTranslation,
      showWordMeanings: showWordMeanings ?? this.showWordMeanings,
      showTafsir: showTafsir ?? this.showTafsir,
      reciter: reciter ?? this.reciter,
      arabicSize: arabicSize ?? this.arabicSize,
      readingMode: readingMode ?? this.readingMode,
    );
  }

  Map<String, Object> toJson() => {
    'showPronunciation': showPronunciation,
    'showTranslation': showTranslation,
    'showWordMeanings': showWordMeanings,
    'showTafsir': showTafsir,
    'reciter': reciter,
    'arabicSize': arabicSize,
    'readingMode': readingMode.name,
  };

  static QuranSettings fromJson(Map<String, dynamic> json) => QuranSettings(
    showPronunciation:
        json['showPronunciation'] as bool? ?? defaults.showPronunciation,
    showTranslation:
        json['showTranslation'] as bool? ?? defaults.showTranslation,
    showWordMeanings:
        json['showWordMeanings'] as bool? ?? defaults.showWordMeanings,
    showTafsir: json['showTafsir'] as bool? ?? defaults.showTafsir,
    reciter: json['reciter'] as String? ?? defaults.reciter,
    arabicSize: (json['arabicSize'] as num?)?.toDouble() ?? defaults.arabicSize,
    readingMode: QuranReadingMode.values.firstWhere(
      (mode) => mode.name == json['readingMode'],
      orElse: () => defaults.readingMode,
    ),
  );
}

class QuranProgress {
  const QuranProgress({
    required this.surahId,
    required this.verseKey,
    required this.page,
  });

  final int surahId;
  final String verseKey;
  final int page;
}

class QuranRepository {
  QuranRepository._();

  static final instance = QuranRepository._();

  static const baseApi = 'https://api.quran.com/api/v4';
  static const pageImageBase = 'https://api.islamic.app/v1/mushaf/page';
  static const sourcePlan =
      'Quran.Foundation Content API v4 for text, words, Hilali & Khan translation, Ibn Kathir tafsir, and verse audio. Islamic.app standard Madinah Mushaf SVG pages for the 604 page images.';
  static const tafsirIbnKathirId = 169;
  static const hilaliKhanTranslationId = 203;
  static const reciters = <String, int>{
    'Mishary Rashid Alafasy': 7,
    'Abdul Basit': 1,
    'Saad Al Ghamdi': 3,
    'Maher Al Muaiqly': 4,
  };

  static const _settingsKey = 'mizan.quran.settings';
  static const _progressKey = 'mizan.quran.progress';
  static const _offlineReadyKey = 'mizan.quran.offline.ready.v2';
  static const _translationIdKey = 'mizan.quran.translation.hilali_khan.id';
  static const _datasetVersion = 2;
  static const _downloadTotal = 114 + 604;

  final _statusController = StreamController<QuranDownloadStatus>.broadcast();
  Database? _db;
  Directory? _filesDir;

  Stream<QuranDownloadStatus> get downloadStatus => _statusController.stream;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'mizan_quran.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE surahs (id INTEGER PRIMARY KEY, name_arabic TEXT NOT NULL, name_transliterated TEXT NOT NULL, name_english TEXT NOT NULL, revelation_place TEXT NOT NULL, verses_count INTEGER NOT NULL, first_page INTEGER NOT NULL, last_page INTEGER NOT NULL, first_juz INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE verses (verse_key TEXT PRIMARY KEY, surah_id INTEGER NOT NULL, ayah INTEGER NOT NULL, juz INTEGER NOT NULL, hizb INTEGER NOT NULL, page INTEGER NOT NULL, arabic TEXT NOT NULL, transliteration TEXT NOT NULL, translation TEXT NOT NULL, tafsir TEXT NOT NULL, audio_url TEXT)',
        );
        await db.execute(
          'CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, verse_key TEXT NOT NULL, position INTEGER NOT NULL, text TEXT NOT NULL, meaning TEXT NOT NULL, transliteration TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE INDEX idx_verses_surah ON verses(surah_id, ayah)',
        );
        await db.execute('CREATE INDEX idx_verses_page ON verses(page)');
        await db.execute('CREATE INDEX idx_verses_juz ON verses(juz)');
        await db.execute('CREATE INDEX idx_verses_hizb ON verses(hizb)');
      },
    );
    return _db!;
  }

  Future<Directory> get filesDir async {
    if (_filesDir != null) return _filesDir!;
    final dir = await getApplicationSupportDirectory();
    _filesDir = Directory(p.join(dir.path, 'quran'));
    await _filesDir!.create(recursive: true);
    await Directory(p.join(_filesDir!.path, 'pages')).create(recursive: true);
    await Directory(p.join(_filesDir!.path, 'audio')).create(recursive: true);
    return _filesDir!;
  }

  Future<bool> isOfflineReady() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_offlineReadyKey) != true) return false;
    final db = await database;
    final verseCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM verses'),
        ) ??
        0;
    if (verseCount != 6236) return false;
    final pageDir = Directory(p.join((await filesDir).path, 'pages'));
    for (var page = 1; page <= 604; page++) {
      if (!await File(p.join(pageDir.path, '$page.svg')).exists()) return false;
    }
    return true;
  }

  Future<void> ensureOfflineDataset() async {
    if (await isOfflineReady()) {
      _statusController.add(
        const QuranDownloadStatus(
          state: QuranDownloadState.complete,
          completed: _downloadTotal,
          total: _downloadTotal,
          message: 'Quran is ready offline',
        ),
      );
      return;
    }
    var completed = await _downloadedUnitCount();
    _statusController.add(
      QuranDownloadStatus(
        state: QuranDownloadState.downloading,
        completed: completed,
        total: _downloadTotal,
        message: 'Preparing Quran download',
      ),
    );
    try {
      final translationId = await _resolveHilaliKhanTranslationId();
      for (var chapter = 1; chapter <= 114; chapter++) {
        await _downloadChapter(chapter, translationId);
        completed = await _downloadedUnitCount();
        _statusController.add(
          QuranDownloadStatus(
            state: QuranDownloadState.downloading,
            completed: completed,
            total: _downloadTotal,
            message: 'Downloaded surah $chapter of 114',
          ),
        );
      }
      for (var page = 1; page <= 604; page++) {
        await _downloadPageImage(page);
        completed = await _downloadedUnitCount();
        _statusController.add(
          QuranDownloadStatus(
            state: QuranDownloadState.downloading,
            completed: completed,
            total: _downloadTotal,
            message: 'Downloaded mushaf page $page of 604',
          ),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineReadyKey, true);
      final db = await database;
      await db.insert('metadata', {
        'key': 'dataset_version',
        'value': '$_datasetVersion',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _statusController.add(
        const QuranDownloadStatus(
          state: QuranDownloadState.complete,
          completed: _downloadTotal,
          total: _downloadTotal,
          message: 'Quran is ready offline',
        ),
      );
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineReadyKey, false);
      _statusController.add(
        QuranDownloadStatus(
          state: QuranDownloadState.failed,
          completed: completed,
          total: _downloadTotal,
          message: _friendlyError(error),
        ),
      );
      rethrow;
    }
  }

  Future<int> _downloadedUnitCount() async {
    var count = 0;
    try {
      final db = await database;
      final chapterRows = await db.rawQuery(
        'SELECT COUNT(DISTINCT surah_id) FROM verses',
      );
      count += Sqflite.firstIntValue(chapterRows) ?? 0;
    } catch (_) {}
    try {
      final pageDir = Directory(p.join((await filesDir).path, 'pages'));
      if (await pageDir.exists()) {
        count += pageDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.svg'))
            .length
            .clamp(0, 604);
      }
    } catch (_) {}
    return count.clamp(0, _downloadTotal);
  }

  Future<List<QuranSurah>> surahs() async {
    final db = await database;
    final rows = await db.query('surahs', orderBy: 'id ASC');
    return rows.map(QuranSurah.fromMap).toList();
  }

  Future<QuranSurah?> surahById(int id) async {
    final db = await database;
    final rows = await db.query(
      'surahs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : QuranSurah.fromMap(rows.first);
  }

  Future<List<QuranVerse>> versesForSurah(int surahId) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah ASC',
    );
    return Future.wait(rows.map(_verseFromRow));
  }

  Future<List<QuranVerse>> versesForPage(int page) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'surah_id ASC, ayah ASC',
    );
    return Future.wait(rows.map(_verseFromRow));
  }

  Future<QuranVerse> _verseFromRow(Map<String, Object?> row) async {
    final db = await database;
    final wordRows = await db.query(
      'words',
      where: 'verse_key = ?',
      whereArgs: [row['verse_key']],
      orderBy: 'position ASC',
    );
    return QuranVerse(
      key: row['verse_key']?.toString() ?? '1:1',
      surahId: _asInt(row['surah_id'], fallback: 1),
      ayah: _asInt(row['ayah'], fallback: 1),
      juz: _asInt(row['juz'], fallback: 1),
      hizb: _asInt(row['hizb'], fallback: 1),
      page: _asInt(row['page'], fallback: 1),
      arabic: row['arabic']?.toString() ?? '',
      transliteration: row['transliteration']?.toString() ?? '',
      translation: row['translation']?.toString() ?? '',
      tafsir: row['tafsir']?.toString() ?? '',
      audioUrl: row['audio_url']?.toString(),
      words:
          wordRows
              .map(
                (word) => QuranWord(
                  text: word['text']?.toString() ?? '',
                  meaning: word['meaning']?.toString() ?? '',
                  transliteration: word['transliteration']?.toString() ?? '',
                ),
              )
              .toList(),
    );
  }

  Future<List<QuranRangeItem>> juzItems() async =>
      _rangeItems('juz', 30, 'Juz');

  Future<List<QuranRangeItem>> hizbItems() async =>
      _rangeItems('hizb', 60, 'Hizb');

  Future<List<QuranRangeItem>> pageItems() async {
    final db = await database;
    final items = <QuranRangeItem>[];
    for (var page = 1; page <= 604; page++) {
      final rows = await db.query(
        'verses',
        where: 'page = ?',
        whereArgs: [page],
        orderBy: 'surah_id ASC, ayah ASC',
        limit: 1,
      );
      if (rows.isEmpty) {
        items.add(
          QuranRangeItem(
            number: page,
            title: 'Page $page',
            subtitle: 'Not downloaded yet',
            rangeLabel: 'Mushaf page $page of 604',
            startSurahId: 1,
            startVerseKey: '1:1',
            startPage: page,
          ),
        );
      } else {
        final surah = await surahById(
          _asInt(rows.first['surah_id'], fallback: 1),
        );
        items.add(
          QuranRangeItem(
            number: page,
            title: 'Page $page',
            subtitle:
                surah == null
                    ? 'Mushaf page'
                    : '${surah.nameTransliteration} - ${surah.nameArabic}',
            rangeLabel: 'Starts ${rows.first['verse_key']}',
            startSurahId: _asInt(rows.first['surah_id'], fallback: 1),
            startVerseKey: rows.first['verse_key']?.toString() ?? '1:1',
            startPage: page,
          ),
        );
      }
    }
    return items;
  }

  Future<List<QuranRangeItem>> _rangeItems(
    String field,
    int count,
    String label,
  ) async {
    final db = await database;
    final items = <QuranRangeItem>[];
    for (var number = 1; number <= count; number++) {
      final rows = await db.query(
        'verses',
        where: '$field = ?',
        whereArgs: [number],
        orderBy: 'surah_id ASC, ayah ASC',
      );
      if (rows.isEmpty) {
        items.add(
          QuranRangeItem(
            number: number,
            title: '$label $number',
            subtitle: 'Not downloaded yet',
            rangeLabel: 'Unavailable offline',
            startSurahId: 1,
            startVerseKey: '1:1',
            startPage: 1,
          ),
        );
      } else {
        final first = rows.first;
        final last = rows.last;
        items.add(
          QuranRangeItem(
            number: number,
            title: '$label $number',
            subtitle: '${first['verse_key']} - ${last['verse_key']}',
            rangeLabel: 'Pages ${first['page']}-${last['page']}',
            startSurahId: _asInt(first['surah_id'], fallback: 1),
            startVerseKey: first['verse_key']?.toString() ?? '1:1',
            startPage: _asInt(first['page'], fallback: 1),
          ),
        );
      }
    }
    return items;
  }

  Future<File?> localPageImage(int page) async {
    final file = File(p.join((await filesDir).path, 'pages', '$page.svg'));
    return file.existsSync() ? file : null;
  }

  Uri pageImageUri(int page) =>
      Uri.parse('$pageImageBase/$page.svg?font=uthmani&theme=light&width=900');

  Future<Uri> audioUriFor(QuranVerse verse, QuranSettings settings) async {
    final reciter = reciters[settings.reciter] ?? reciters.values.first;
    if (reciter == reciters.values.first &&
        verse.audioUrl != null &&
        verse.audioUrl!.startsWith('http')) {
      return Uri.parse(verse.audioUrl!);
    }
    final uri = Uri.parse('$baseApi/verses/by_key/${verse.key}?audio=$reciter');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Could not load recitation audio for ${verse.key}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final verseJson = Map<String, dynamic>.from(
      (decoded['verse'] as Map?) ?? {},
    );
    final audio = Map<String, dynamic>.from((verseJson['audio'] as Map?) ?? {});
    final url = audio['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('No recitation audio URL found for ${verse.key}');
    }
    return Uri.parse(_absoluteAudioUrl(url));
  }

  Future<int> downloadSurahAudio(int surahId, QuranSettings settings) async {
    final verses = await versesForSurah(surahId);
    if (verses.isEmpty) {
      throw Exception(
        'Surah audio cannot be downloaded before the surah text is available',
      );
    }
    final reciter = reciters[settings.reciter] ?? reciters.values.first;
    final audioDir = Directory(
      p.join((await filesDir).path, 'audio', '$reciter', '$surahId'),
    );
    await audioDir.create(recursive: true);
    var bytes = 0;
    for (final verse in verses) {
      final file = File(
        p.join(audioDir.path, '${verse.key.replaceAll(':', '_')}.mp3'),
      );
      if (await file.exists()) {
        bytes += await file.length();
        continue;
      }
      final uri = await audioUriFor(verse, settings);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Could not download audio for ${verse.key}');
      }
      await file.writeAsBytes(response.bodyBytes, flush: true);
      bytes += response.bodyBytes.length;
    }
    return bytes;
  }

  Future<File?> localVerseAudio(
    QuranVerse verse,
    QuranSettings settings,
  ) async {
    final reciter = reciters[settings.reciter] ?? reciters.values.first;
    final file = File(
      p.join(
        (await filesDir).path,
        'audio',
        '$reciter',
        '${verse.surahId}',
        '${verse.key.replaceAll(':', '_')}.mp3',
      ),
    );
    return file.existsSync() ? file : null;
  }

  Future<QuranSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return QuranSettings.defaults;
    try {
      return QuranSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return QuranSettings.defaults;
    }
  }

  Future<void> saveSettings(QuranSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<QuranProgress> loadProgress() async {
    final remote = await _loadRemoteProgress();
    if (remote != null) {
      await _saveLocalProgress(remote);
      return remote;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) {
      return const QuranProgress(surahId: 1, verseKey: '1:1', page: 1);
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return QuranProgress(
        surahId: _asInt(json['surahId'], fallback: 1),
        verseKey: json['verseKey']?.toString() ?? '1:1',
        page: _asInt(json['page'], fallback: 1),
      );
    } catch (_) {
      return const QuranProgress(surahId: 1, verseKey: '1:1', page: 1);
    }
  }

  Future<void> saveProgress(QuranProgress progress) async {
    await _saveLocalProgress(progress);
    try {
      await BackendApi.instance.saveQuranProgress(
        surahId: progress.surahId,
        verseKey: progress.verseKey,
        page: progress.page,
      );
    } catch (_) {
      // Offline or auth failures should never block local reading progress.
    }
  }

  Future<void> _saveLocalProgress(QuranProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _progressKey,
      jsonEncode({
        'surahId': progress.surahId,
        'verseKey': progress.verseKey,
        'page': progress.page,
      }),
    );
  }

  Future<QuranProgress?> _loadRemoteProgress() async {
    try {
      final json = await BackendApi.instance.getQuranProgress();
      if (json == null) return null;
      return QuranProgress(
        surahId: _asInt(json['surah_id'], fallback: 1),
        verseKey: json['verse_key']?.toString() ?? '1:1',
        page: _asInt(json['page'], fallback: 1),
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> _resolveHilaliKhanTranslationId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt(_translationIdKey);
    if (cached != null) return cached;
    await prefs.setInt(_translationIdKey, hilaliKhanTranslationId);
    return hilaliKhanTranslationId;
  }

  Future<int> verifyHilaliKhanTranslationId() async {
    final response = await http
        .get(Uri.parse('$baseApi/resources/translations?language=en'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load Quran translation resources (${response.statusCode})',
      );
    }
    final resources = _mapList(
      (jsonDecode(response.body) as Map<String, dynamic>)['translations'],
    );
    final resource = resources.firstWhere(
      (item) {
        final haystack =
            '${item['name']} ${item['author_name']} ${item['slug']}'
                .toLowerCase();
        return haystack.contains('hilali') && haystack.contains('khan');
      },
      orElse:
          () =>
              throw Exception(
                'Hilali & Khan translation is not available from Quran.Foundation resources',
              ),
    );
    final id = _asInt(resource['id'], fallback: hilaliKhanTranslationId);
    if (id != hilaliKhanTranslationId) {
      throw Exception(
        'Expected Hilali & Khan resource $hilaliKhanTranslationId but API returned $id',
      );
    }
    return id;
  }

  Future<void> _downloadChapter(int chapter, int translationId) async {
    final db = await database;
    final firstPage = await _fetchChapterPage(chapter, translationId);
    final chapterInfo = firstPage.chapterInfo;
    await db.transaction((txn) async {
      await txn.insert(
        'surahs',
        chapterInfo,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('verses', where: 'surah_id = ?', whereArgs: [chapter]);
      await txn.delete(
        'words',
        where: 'verse_key LIKE ?',
        whereArgs: ['$chapter:%'],
      );
    });
    var page = 1;
    ChapterPayload payload = firstPage;
    final tafsirs = await _fetchChapterTafsirs(chapter);
    while (true) {
      await _persistVerses(payload.verses, tafsirs);
      final nextPage = payload.nextPage;
      if (nextPage == null) {
        break;
      }
      page = nextPage;
      payload = await _fetchChapterPage(chapter, translationId, page: page);
    }
  }

  Future<ChapterPayload> _fetchChapterPage(
    int chapter,
    int translationId, {
    int page = 1,
  }) async {
    final reciter = reciters.values.first;
    final uri = Uri.parse('$baseApi/verses/by_chapter/$chapter').replace(
      queryParameters: {
        'words': 'true',
        'translations': '$translationId',
        'audio': '$reciter',
        'fields': 'text_uthmani',
        'word_fields': 'text_uthmani',
        'translation_fields':
            'resource_name,verse_key,chapter_id,verse_number,juz_number,hizb_number,page_number',
        'per_page': '50',
        'page': '$page',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(
        'Could not download surah $chapter (${response.statusCode})',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final verses = _mapList(body['verses']);
    if (verses.isEmpty) {
      throw Exception('Quran data for surah $chapter arrived empty');
    }
    final pagination = Map<String, dynamic>.from(
      (body['pagination'] as Map?) ?? {},
    );
    final next = _asNullableInt(pagination['next_page']);
    final chapterInfo = await _chapterInfo(chapter, verses);
    return ChapterPayload(
      chapterInfo: chapterInfo,
      verses: verses,
      nextPage: next,
    );
  }

  Future<Map<String, Object>> _chapterInfo(
    int chapter,
    List<Map<String, dynamic>> verses,
  ) async {
    final response = await http
        .get(Uri.parse('$baseApi/chapters/$chapter?language=en'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Could not download surah metadata $chapter');
    }
    final ch = Map<String, dynamic>.from(
      (jsonDecode(response.body)['chapter'] as Map?) ?? {},
    );
    return {
      'id': chapter,
      'name_arabic': (ch['name_arabic'] ?? '').toString(),
      'name_transliterated': (ch['name_simple'] ?? 'Surah $chapter').toString(),
      'name_english':
          ((ch['translated_name'] as Map?)?['name'] ?? '').toString(),
      'revelation_place': (ch['revelation_place'] ?? '').toString(),
      'verses_count': _asInt(ch['verses_count'], fallback: verses.length),
      'first_page': _asInt(verses.first['page_number'], fallback: 1),
      'last_page': _asInt(verses.last['page_number'], fallback: 1),
      'first_juz': _asInt(verses.first['juz_number'], fallback: 1),
    };
  }

  Future<Map<String, String>> _fetchChapterTafsirs(int chapter) async {
    final tafsirs = <String, String>{};
    var page = 1;
    while (true) {
      final uri = Uri.parse(
        '$baseApi/tafsirs/$tafsirIbnKathirId/by_chapter/$chapter',
      ).replace(
        queryParameters: {
          'fields':
              'verse_key,chapter_id,verse_number,juz_number,hizb_number,page_number,resource_name,language_name',
          'per_page': '50',
          'page': '$page',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception(
          'Could not download Ibn Kathir tafsir for surah $chapter (${response.statusCode})',
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      for (final item in _mapList(body['tafsirs'])) {
        final verseKey = item['verse_key']?.toString();
        if (verseKey == null || verseKey.isEmpty) continue;
        tafsirs[verseKey] = _stripHtml(item['text']?.toString() ?? '');
      }
      final nextPage = _asNullableInt(
        ((body['pagination'] as Map?) ?? {})['next_page'],
      );
      if (nextPage == null) break;
      page = nextPage;
    }
    return tafsirs;
  }

  Future<void> _persistVerses(
    List<Map<String, dynamic>> verses,
    Map<String, String> tafsirsByVerseKey,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final verse in verses) {
        final translations = _mapList(verse['translations']);
        final words = _mapList(verse['words']);
        final verseKey = (verse['verse_key'] ?? '').toString();
        if (verseKey.isEmpty) continue;
        await txn.insert('verses', {
          'verse_key': verseKey,
          'surah_id': _asInt(
            verse['chapter_id'],
            fallback: _surahFromVerseKey(verseKey),
          ),
          'ayah': _asInt(
            verse['verse_number'],
            fallback: _ayahFromVerseKey(verseKey),
          ),
          'juz': _asInt(verse['juz_number'], fallback: 1),
          'hizb': _asInt(verse['hizb_number'], fallback: 1),
          'page': _asInt(verse['page_number'], fallback: 1),
          'arabic': (verse['text_uthmani'] ?? '').toString(),
          'transliteration': words
              .map(
                (word) =>
                    ((word['transliteration'] as Map?)?['text'] ?? '')
                        .toString(),
              )
              .where((text) => text.isNotEmpty)
              .join(' '),
          'translation': _stripHtml(
            translations.isEmpty
                ? ''
                : (translations.first['text'] ?? '').toString(),
          ),
          'tafsir': tafsirsByVerseKey[verseKey] ?? '',
          'audio_url': _absoluteAudioUrl(
            ((verse['audio'] as Map?)?['url'] ?? '').toString(),
          ),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final word in words) {
          if (word['char_type_name'] != 'word') continue;
          await txn.insert('words', {
            'verse_key': verseKey,
            'position': _asInt(word['position'], fallback: 0),
            'text': (word['text_uthmani'] ?? '').toString(),
            'meaning':
                ((word['translation'] as Map?)?['text'] ?? '').toString(),
            'transliteration':
                ((word['transliteration'] as Map?)?['text'] ?? '').toString(),
          });
        }
      }
    });
  }

  Future<void> _downloadPageImage(int page) async {
    final file = File(p.join((await filesDir).path, 'pages', '$page.svg'));
    if (await file.exists()) {
      return;
    }
    final response = await http
        .get(pageImageUri(page))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Could not download mushaf page $page (${response.statusCode})',
      );
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
  }

  static String _stripHtml(String input) =>
      input
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

  static String _absoluteAudioUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://audio.qurancdn.com/$url';
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int _surahFromVerseKey(String key) =>
      int.tryParse(key.split(':').first) ?? 1;

  static int _ayahFromVerseKey(String key) {
    final parts = key.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
  }

  static String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('TimeoutException')) {
      return 'Connection dropped. Your downloaded Quran data is kept, and you can resume when internet returns.';
    }
    if (text.contains('Null') || text.contains('type')) {
      return 'A Quran data field arrived incomplete. The app kept the completed download and can retry safely.';
    }
    return text.replaceFirst('Exception: ', '');
  }
}

class ChapterPayload {
  const ChapterPayload({
    required this.chapterInfo,
    required this.verses,
    required this.nextPage,
  });

  final Map<String, Object> chapterInfo;
  final List<Map<String, dynamic>> verses;
  final int? nextPage;
}
