import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../services/backend_api.dart';

enum QuranReadingMode { mushaf, continuous, ayah }

enum QuranDownloadState {
  idle,
  queued,
  downloading,
  waitingForNetwork,
  paused,
  complete,
  failed,
  cancelled,
}

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
  static const minArabicSize = 24.0;
  static const maxArabicSize = 40.0;
  static const arabicSizeDivisions = 16;

  static double normalizeArabicSize(double value) =>
      value.clamp(minArabicSize, maxArabicSize).roundToDouble();

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
    readingMode: QuranReadingMode.mushaf,
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
      arabicSize: normalizeArabicSize(arabicSize ?? this.arabicSize),
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
    arabicSize: normalizeArabicSize(
      (json['arabicSize'] as num?)?.toDouble() ?? defaults.arabicSize,
    ),
    readingMode: _readingModeFromJson(json['readingMode']),
  );

  static QuranReadingMode _readingModeFromJson(Object? value) {
    final name = value?.toString();
    if (name == 'page') return QuranReadingMode.mushaf;
    if (name == 'verses') return QuranReadingMode.continuous;
    return QuranReadingMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => defaults.readingMode,
    );
  }
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

  static const sourcePlan =
      'Mizan backend imports Quran.Foundation Content API data into PostgreSQL. Flutter syncs only from Mizan and stores the Quran locally for offline reading.';
  static const hilaliKhanTranslationId = 203;
  static const reciters = <String, int>{
    'Mishary Rashid Alafasy': 7,
    'Abdul Basit': 1,
    'Saad Al Ghamdi': 3,
    'Maher Al Muaiqly': 4,
  };

  static const _settingsKey = 'mizan.quran.settings';
  static const _progressKey = 'mizan.quran.progress';
  static const _offlineReadyKey = 'mizan.quran.offline.ready.v3';
  static const _completedChaptersKey =
      'mizan.quran.offline.completed_chapters.v3';
  static const _completedPagesKey = 'mizan.quran.offline.completed_pages.v3';
  static const _downloadJobKey = 'mizan.quran.offline.job.v3';
  static const _readingDaysKey = 'mizan.quran.reading.days.v1';
  static const _readingReflectionsKey = 'mizan.quran.reading.reflections.v1';
  static const _translationIdKey = 'mizan.quran.translation.hilali_khan.id';
  // Bump this whenever the bundled/backend contract changes. Older local
  // content must never be presented as the current Mushaf dataset.
  static const _datasetVersion = 3;
  static const _downloadTotal = 114 + 604;

  final _statusController = StreamController<QuranDownloadStatus>.broadcast();
  final _readingActivityController = StreamController<DateTime>.broadcast();
  Database? _db;
  Directory? _filesDir;
  Future<void>? _activeDownload;

  Stream<QuranDownloadStatus> get downloadStatus => _statusController.stream;
  Stream<DateTime> get readingActivity => _readingActivityController.stream;

  void emitDownloadStatus(QuranDownloadStatus status) {
    _statusController.add(status);
  }

  Future<void> persistDownloadStatus(QuranDownloadStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    var localPath = '';
    try {
      localPath = (await filesDir).path;
    } catch (_) {}
    await prefs.setString(
      _downloadJobKey,
      jsonEncode({
        'download_id': 'quran-dataset-v$_datasetVersion',
        'content_id': 'full-quran-uthmani-hilali-khan-ibn-kathir-mushaf',
        'status': status.state.name,
        'completed': status.completed,
        'total': status.total,
        'downloaded_bytes': prefs.getInt('$_downloadJobKey.bytes') ?? 0,
        'total_bytes': 0,
        'local_file_path': localPath,
        'failure_reason':
            status.state == QuranDownloadState.failed ? status.message : null,
        'message': status.message,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> refreshPersistedDownloadStatus() async {
    emitDownloadStatus(await loadDownloadStatus());
  }

  Future<QuranDownloadStatus> loadDownloadStatus() async {
    final ready = await isOfflineReady();
    if (ready) {
      return const QuranDownloadStatus(
        state: QuranDownloadState.complete,
        completed: _downloadTotal,
        total: _downloadTotal,
        message: 'Quran is ready offline',
      );
    }
    final completed = await _downloadedUnitCount();
    final prefs = await SharedPreferences.getInstance();
    QuranDownloadState persistedState = QuranDownloadState.idle;
    String persistedMessage = '';
    try {
      final raw = prefs.getString(_downloadJobKey);
      final job = raw == null ? null : jsonDecode(raw);
      if (job is Map) {
        persistedState = QuranDownloadState.values.firstWhere(
          (state) => state.name == job['status']?.toString(),
          orElse: () => QuranDownloadState.idle,
        );
        persistedMessage = job['message']?.toString() ?? '';
      }
    } catch (_) {}
    if (persistedState == QuranDownloadState.complete) {
      persistedState = QuranDownloadState.failed;
    }
    return QuranDownloadStatus(
      state:
          persistedState == QuranDownloadState.idle && completed > 0
              ? QuranDownloadState.paused
              : persistedState,
      completed: completed,
      total: _downloadTotal,
      message:
          persistedMessage.isNotEmpty
              ? persistedMessage
              : completed == 0
              ? 'Quran download is ready to start'
              : 'Quran download can resume from $completed of $_downloadTotal',
    );
  }

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
    final db = await database;
    final verseCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM verses'),
        ) ??
        0;
    var complete = verseCount == 6236;
    for (var page = 1; page <= 604; page++) {
      if (!await _isPageDownloaded(page)) {
        complete = false;
        break;
      }
    }
    // The persisted flag is only a cache. The stored Quran content is the
    // source of truth, so repair the flag after an interrupted/restarted app.
    if (prefs.getBool(_offlineReadyKey) != complete) {
      await prefs.setBool(_offlineReadyKey, complete);
    }
    return complete;
  }

  /// Returns whether a single page can be rendered without a session or
  /// network. A page is useful when either its downloaded Mushaf artwork or
  /// its complete local ayah range is present; the reader can render the
  /// latter using the same Uthmani data if artwork is still downloading.
  Future<bool> isPageAvailableOffline(int page) async {
    if (page < 1 || page > 604) return false;
    if (await _isPageDownloaded(page)) return true;
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM verses WHERE page = ?', [page]),
    );
    return (count ?? 0) > 0;
  }

  Future<bool> isSurahAvailableOffline(int surahId) async {
    if (surahId < 1 || surahId > 114) return false;
    return _isChapterDownloaded(surahId);
  }

  Future<int> offlineAyahCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM verses')) ?? 0;
  }

  Future<void> ensureOfflineDataset() {
    final active = _activeDownload;
    if (active != null) return active;
    final operation = _ensureOfflineDataset();
    _activeDownload = operation;
    return operation.whenComplete(() {
      if (identical(_activeDownload, operation)) _activeDownload = null;
    });
  }

  Future<void> _ensureOfflineDataset() async {
    await _resetStaleDatasetIfNeeded();
    if (await isOfflineReady()) {
      await _publishDownloadStatus(
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
    await _publishDownloadStatus(
      QuranDownloadStatus(
        state: QuranDownloadState.downloading,
        completed: completed,
        total: _downloadTotal,
        message: 'Preparing Quran download',
      ),
    );
    try {
      // Put the actual Mushaf pages first. The reader becomes useful early,
      // instead of making users wait for all 114 text requests before page 1
      // is even attempted. Six independent image requests also avoid a
      // needlessly long serial download while keeping memory bounded.
      for (var start = 1; start <= 604; start += 6) {
        final pages = [
          for (var page = start; page <= 604 && page < start + 6; page++) page,
        ];
        final pending = <int>[];
        for (final page in pages) {
          if (!await _isPageDownloaded(page)) pending.add(page);
        }
        await Future.wait(
          pending.map((page) async {
            await _downloadPageImage(page);
          }),
        );
        completed = await _downloadedUnitCount();
        await _publishDownloadStatus(
          QuranDownloadStatus(
            state: QuranDownloadState.downloading,
            completed: completed,
            total: _downloadTotal,
            message: 'Downloaded Mushaf pages through ${pages.last} of 604',
          ),
        );
      }

      final translationId = await _resolveHilaliKhanTranslationId();
      final surahMetadata = await BackendApi.instance.getQuranSurahs();
      // Chapter requests are independent. A small bounded batch makes the
      // first readable surahs arrive sooner without flooding the API or local
      // database with an unbounded Future.wait.
      for (var start = 1; start <= 114; start += 3) {
        final chapters = [
          for (var chapter = start;
              chapter <= 114 && chapter < start + 3;
              chapter++)
            chapter,
        ];
        final pending = <int>[];
        for (final chapter in chapters) {
          if (!await _isChapterDownloaded(chapter)) pending.add(chapter);
        }
        await Future.wait(
          pending.map((chapter) async {
            await _downloadChapter(
              chapter,
              translationId,
              allSurahs: surahMetadata,
            );
          }),
        );
        completed = await _downloadedUnitCount();
        await _publishDownloadStatus(
          QuranDownloadStatus(
            state: QuranDownloadState.downloading,
            completed: completed,
            total: _downloadTotal,
            message: 'Downloaded surahs through ${chapters.last} of 114',
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
      await _publishDownloadStatus(
        const QuranDownloadStatus(
          state: QuranDownloadState.complete,
          completed: _downloadTotal,
          total: _downloadTotal,
          message: 'Quran is ready offline',
        ),
      );
    } catch (error) {
      try {
        completed = await _downloadedUnitCount();
      } catch (_) {
        // Preserve the last known progress if reconciliation itself is the
        // part that failed (for example while the device is out of space).
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineReadyKey, false);
      final waiting = _isNetworkError(error);
      await _publishDownloadStatus(
        QuranDownloadStatus(
          state:
              waiting
                  ? QuranDownloadState.waitingForNetwork
                  : QuranDownloadState.failed,
          completed: completed,
          total: _downloadTotal,
          message:
              waiting
                  ? 'Waiting for internet. Completed Quran content is available.'
                  : _friendlyError(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> _publishDownloadStatus(QuranDownloadStatus status) async {
    await persistDownloadStatus(status);
    _statusController.add(status);
  }

  Future<void> _resetStaleDatasetIfNeeded() async {
    final db = await database;
    final rows = await db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['dataset_version'],
      limit: 1,
    );
    final storedValue = rows.isEmpty ? null : rows.first['value'];
    final version = int.tryParse(storedValue?.toString() ?? '');
    if (version == _datasetVersion) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineReadyKey);
    await prefs.remove(_completedChaptersKey);
    await prefs.remove(_completedPagesKey);
    await prefs.remove(_downloadJobKey);
    await prefs.remove('$_downloadJobKey.bytes');

    await db.transaction((txn) async {
      await txn.delete('words');
      await txn.delete('verses');
      await txn.delete('surahs');
      await txn.delete('metadata');
    });
    final pages = Directory(p.join((await filesDir).path, 'pages'));
    if (await pages.exists()) {
      await for (final entity in pages.list()) {
        if (entity is File) await entity.delete();
      }
    }
  }

  Future<int> _downloadedUnitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final chapters =
        (prefs.getStringList(_completedChaptersKey) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>()
            .where((chapter) => chapter >= 1 && chapter <= 114)
            .toSet();
    final pages =
        (prefs.getStringList(_completedPagesKey) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>()
            .where((page) => page >= 1 && page <= 604)
            .toSet();
    // Reconcile only complete surahs. A partial transaction must not make a
    // surah appear available or advance the logical download count.
    try {
      final db = await database;
      final rows = await db.rawQuery(
        'SELECT s.id FROM surahs s LEFT JOIN verses v ON v.surah_id = s.id '
        'WHERE s.id BETWEEN 1 AND 114 GROUP BY s.id, s.verses_count '
        'HAVING COUNT(v.verse_key) = s.verses_count',
      );
      final actual = rows.map((row) => _asInt(row['id'], fallback: 0)).toSet();
      chapters.retainAll(actual);
      chapters.addAll(actual);
    } catch (_) {}
    try {
      final pageDir = Directory(p.join((await filesDir).path, 'pages'));
      if (await pageDir.exists()) {
        final actual = <int>{};
        for (final file in pageDir.listSync().whereType<File>()) {
          if (file.lengthSync() <= 0) continue;
          final page = int.tryParse(p.basenameWithoutExtension(file.path));
          if (page != null && page >= 1 && page <= 604) actual.add(page);
        }
        pages.retainAll(actual);
        pages.addAll(actual);
      }
    } catch (_) {}
    return (chapters.length + pages.length).clamp(0, _downloadTotal);
  }

  Future<bool> _isChapterDownloaded(int chapter) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(v.verse_key) AS actual, s.verses_count AS expected '
      'FROM surahs s LEFT JOIN verses v ON v.surah_id = s.id '
      'WHERE s.id = ? GROUP BY s.id, s.verses_count',
      [chapter],
    );
    if (rows.isEmpty) return false;
    return _asInt(rows.first['actual'], fallback: 0) ==
        _asInt(rows.first['expected'], fallback: -1);
  }

  Future<bool> _isPageDownloaded(int page) async {
    final dir = Directory(p.join((await filesDir).path, 'pages'));
    if (!await dir.exists()) return false;
    return ['png', 'jpg', 'jpeg', 'svg'].any(
      (extension) {
        final file = File(p.join(dir.path, '$page.$extension'));
        return file.existsSync() && file.lengthSync() > 0;
      },
    );
  }

  Future<List<QuranSurah>> surahs() async {
    final db = await database;
    final rows = await db.query('surahs', orderBy: 'id ASC');
    if (rows.length == 114) return rows.map(QuranSurah.fromMap).toList();
    try {
      final remote = await BackendApi.instance.getQuranSurahs();
      await _persistSurahMetadata(remote);
      return remote.map((row) => _surahFromBackend(row)).toList();
    } catch (_) {
      return rows.map(QuranSurah.fromMap).toList();
    }
  }

  QuranSurah _surahFromBackend(Map<String, dynamic> row) => QuranSurah(
    id: _asInt(row['id'], fallback: 0),
    nameArabic: (row['name_ar'] ?? '').toString(),
    nameTransliteration: (row['name_transliteration'] ?? 'Surah').toString(),
    nameEnglish: (row['name_en'] ?? '').toString(),
    versesCount: _asInt(row['ayah_count'], fallback: 0),
    revelationPlace: (row['revelation_type'] ?? '').toString(),
    firstPage: _asInt(row['first_page'], fallback: 1),
    lastPage: _asInt(row['last_page'], fallback: 1),
    firstJuz: _asInt(row['first_juz'], fallback: 1),
  );

  Future<void> _persistSurahMetadata(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final row in rows) {
        final surah = _surahFromBackend(row);
        if (surah.id < 1 || surah.id > 114) continue;
        await txn.insert('surahs', {
          'id': surah.id,
          'name_arabic': surah.nameArabic,
          'name_transliterated': surah.nameTransliteration,
          'name_english': surah.nameEnglish,
          'revelation_place': surah.revelationPlace,
          'verses_count': surah.versesCount,
          'first_page': surah.firstPage,
          'last_page': surah.lastPage,
          'first_juz': surah.firstJuz,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<QuranSurah?> surahById(int id) async {
    final db = await database;
    final rows = await db.query(
      'surahs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) return QuranSurah.fromMap(rows.first);
    try {
      final remote = await BackendApi.instance.getQuranSurahs();
      await _persistSurahMetadata(remote);
      final match = remote.where((row) => _asInt(row['id'], fallback: 0) == id);
      return match.isEmpty ? null : _surahFromBackend(match.first);
    } catch (_) {
      return null;
    }
  }

  Future<List<QuranVerse>> versesForSurah(int surahId) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah ASC',
    );
    if (rows.isNotEmpty) {
      final surah = await surahById(surahId);
      if (surah == null || rows.length >= surah.versesCount) {
        return Future.wait(rows.map(_verseFromRow));
      }
      try {
        final remote = await BackendApi.instance.getQuranSurahAyahs(surahId);
        await _persistBackendAyahs(remote);
        return await versesForSurah(surahId);
      } catch (_) {
        return Future.wait(rows.map(_verseFromRow));
      }
    }
    try {
      final remote = await BackendApi.instance.getQuranSurahAyahs(surahId);
      await _persistSurahMetadata(
        (await BackendApi.instance.getQuranSurahs())
            .where((row) => _asInt(row['id'], fallback: 0) == surahId)
            .toList(),
      );
      await _persistBackendAyahs(remote);
      return await versesForSurah(surahId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<QuranVerse>> versesForPage(int page) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'surah_id ASC, ayah ASC',
    );
    if (rows.isNotEmpty) return Future.wait(rows.map(_verseFromRow));
    try {
      final remote = await BackendApi.instance.getQuranPage(page);
      final ayahs = _mapList(remote['ayahs']);
      await _persistBackendAyahs(ayahs);
      return await versesForPage(page);
    } catch (_) {
      return const [];
    }
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
      if (rows.isEmpty && (field == 'juz' || field == 'hizb')) {
        try {
          final remote =
              field == 'juz'
                  ? await BackendApi.instance.getQuranJuzAyahs(number)
                  : await BackendApi.instance.getQuranHizbAyahs(number);
          await _persistBackendAyahs(remote);
          return await _rangeItems(field, count, label);
        } catch (_) {
          // Keep the item visible as unavailable until connectivity returns.
        }
      }
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
    final directory = (await filesDir).path;
    for (final extension in ['png', 'jpg', 'jpeg', 'svg']) {
      final file = File(p.join(directory, 'pages', '$page.$extension'));
      if (file.existsSync() && file.lengthSync() > 0) return file;
    }
    return null;
  }

  /// Returns a cached Mushaf page, downloading it once when online reading
  /// needs it. The same file is then reused by offline reading and downloads.
  Future<File?> pageImage(int page) async {
    final local = await localPageImage(page);
    if (local != null) return local;
    try {
      final pageData = await BackendApi.instance.getQuranPage(page);
      final imageUrl = pageData['image_url']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) return null;
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final pagesDir = p.join((await filesDir).path, 'pages');
      final extension = p.extension(uri.path).toLowerCase() == '.svg' ? 'svg' : 'png';
      final file = File(p.join(pagesDir, '$page.$extension'));
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(response.bodyBytes, flush: true);
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<Uri> audioUriFor(QuranVerse verse, QuranSettings _) async {
    if (verse.audioUrl != null && verse.audioUrl!.startsWith('http')) {
      return Uri.parse(verse.audioUrl!);
    }
    throw Exception(
      'Recitation audio for ${verse.key} is not available offline yet.',
    );
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        // Local state wins for an already-used device. This is what lets a
        // downloaded Mushaf open immediately after logout or without a
        // network request. A new device with no local state still restores
        // the account's server position below.
        return QuranProgress(
          surahId: _asInt(json['surahId'], fallback: 1),
          verseKey: json['verseKey']?.toString() ?? '1:1',
          page: _asInt(json['page'], fallback: 1),
        );
      } catch (_) {
        // Fall through to a remote restore if the local record is malformed.
      }
    }
    final remote = await _loadRemoteProgress();
    if (remote != null) {
      await _saveLocalProgress(remote);
      return remote;
    }
    return const QuranProgress(surahId: 1, verseKey: '1:1', page: 1);
  }

  Future<void> saveProgress(QuranProgress progress) async {
    await _saveLocalProgress(progress);
    await recordPageRead(progress.page);
    final token = await BackendApi.instance.getToken();
    if (token == null || token.isEmpty) return;
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

  Future<void> recordReflection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _readingReflectionsKey,
      (prefs.getInt(_readingReflectionsKey) ?? 0) + 1,
    );
    _readingActivityController.add(DateTime.now());
  }

  Future<void> recordPageRead(int page) async {
    if (page < 1 || page > 604) return;
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final days = {...?prefs.getStringList(_readingDaysKey)};
    final isNewReadingDay = days.add(today);
    final sorted = days.toList()..sort();
    // Keep the local rhythm small and useful. It is device-local by design,
    // just like the offline reading cache, and never blocks reading.
    await prefs.setStringList(
      _readingDaysKey,
      sorted.length > 120 ? sorted.sublist(sorted.length - 120) : sorted,
    );
    if (isNewReadingDay) _readingActivityController.add(DateTime.now());
  }

  Future<int> readingDaysLast30() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 29));
    return (prefs.getStringList(_readingDaysKey) ?? const <String>[])
        .map(_parseDay)
        .whereType<DateTime>()
        .where((day) => !day.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day)))
        .length;
  }

  Future<int> readingReflectionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_readingReflectionsKey) ?? 0;
  }

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime? _parseDay(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
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
      final token = await BackendApi.instance.getToken();
      if (token == null || token.isEmpty) return null;
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

  Future<void> _downloadChapter(
    int chapter,
    int _, {
    required List<Map<String, dynamic>> allSurahs,
  }) async {
    final db = await database;
    final surahInfo = allSurahs.firstWhere(
      (surah) => _asInt(surah['id'], fallback: 0) == chapter,
      orElse:
          () =>
              throw Exception(
                'Mizan Quran dataset is not seeded for surah $chapter',
              ),
    );
    final ayahs = await BackendApi.instance.getQuranSurahAyahs(chapter);
    if (ayahs.isEmpty) {
      throw Exception(
        'Mizan Quran dataset is not seeded for surah $chapter. Run the backend Quran import first.',
      );
    }
    final chapterInfo = {
      'id': chapter,
      'name_arabic': (surahInfo['name_ar'] ?? '').toString(),
      'name_transliterated':
          (surahInfo['name_transliteration'] ?? 'Surah $chapter').toString(),
      'name_english': (surahInfo['name_en'] ?? '').toString(),
      'revelation_place': (surahInfo['revelation_type'] ?? '').toString(),
      'verses_count': _asInt(surahInfo['ayah_count'], fallback: ayahs.length),
      'first_page': _asInt(
        surahInfo['first_page'],
        fallback: _pageFromBackendAyah(ayahs.first),
      ),
      'last_page': _asInt(
        surahInfo['last_page'],
        fallback: _pageFromBackendAyah(ayahs.last),
      ),
      'first_juz': _asInt(
        surahInfo['first_juz'],
        fallback: _metaInt(ayahs.first, 'juz', fallback: 1),
      ),
    };
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
    await _persistBackendAyahs(ayahs);
  }

  Future<void> _persistBackendAyahs(List<Map<String, dynamic>> ayahs) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final ayah in ayahs) {
        final verseKey = (ayah['verse_key'] ?? '').toString();
        final arabic = Map<String, dynamic>.from(
          (ayah['arabic'] as Map?) ?? {},
        );
        if (verseKey.isEmpty ||
            (arabic['uthmani'] ?? '').toString().trim().isEmpty) {
          throw FormatException(
            'Quran ayah response is missing its Uthmani text',
          );
        }
        final translation = Map<String, dynamic>.from(
          (ayah['translation'] as Map?) ?? {},
        );
        final audio = _mapList(ayah['audio']);
        await txn.insert('verses', {
          'verse_key': verseKey,
          'surah_id': _asInt(
            ayah['surah_id'],
            fallback: _surahFromVerseKey(verseKey),
          ),
          'ayah': _asInt(
            ayah['ayah_number'],
            fallback: _ayahFromVerseKey(verseKey),
          ),
          'juz': _metaInt(ayah, 'juz', fallback: 1),
          'hizb': _metaInt(ayah, 'hizb', fallback: 1),
          'page': _pageFromBackendAyah(ayah),
          'arabic': (arabic['uthmani'] ?? '').toString(),
          'transliteration': (ayah['transliteration'] ?? '').toString(),
          'translation': _stripHtml((translation['text'] ?? '').toString()),
          'tafsir': '',
          'audio_url':
              audio.isEmpty ? null : (audio.first['url'] ?? '').toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _downloadPageImage(int page) async {
    final pageData = await BackendApi.instance.getQuranPage(page);
    final imageUrl = pageData['image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception(
        'Mizan Quran dataset is missing the Mushaf page $page asset. Run the backend Quran import first.',
      );
    }
    final uri = Uri.parse(imageUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
        'Could not download mushaf page $page (${response.statusCode})',
      );
    }
    final pathExtension = p.extension(uri.path).toLowerCase();
    final extension = pathExtension == '.svg' ? 'svg' : 'png';
    final pagesDir = p.join((await filesDir).path, 'pages');
    final file = File(p.join(pagesDir, '$page.$extension'));
    final partial = File('${file.path}.part');
    // A process kill can happen during the write. A .part file is never
    // counted as a downloaded page and is safely replaced on retry.
    if (await partial.exists()) await partial.delete();
    await partial.writeAsBytes(response.bodyBytes, flush: true);
    if (await file.exists()) await file.delete();
    await partial.rename(file.path);
    final prefs = await SharedPreferences.getInstance();
    final bytesKey = '$_downloadJobKey.bytes';
    await prefs.setInt(
      bytesKey,
      (prefs.getInt(bytesKey) ?? 0) + response.bodyBytes.length,
    );
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

  static int _metaInt(
    Map<String, dynamic> ayah,
    String key, {
    required int fallback,
  }) {
    final meta = Map<String, dynamic>.from((ayah['meta'] as Map?) ?? {});
    return _asInt(meta[key], fallback: fallback);
  }

  static int _pageFromBackendAyah(Map<String, dynamic> ayah) =>
      _metaInt(ayah, 'page', fallback: 1);

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

  static bool _isNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return error is SocketException ||
        error is http.ClientException ||
        text.contains('timeout') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('network');
  }
}
