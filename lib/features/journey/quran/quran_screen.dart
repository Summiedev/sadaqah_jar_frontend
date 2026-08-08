import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import 'quran_data.dart';

class QuranTab extends StatefulWidget {
  const QuranTab({super.key, this.initialSurahId});

  final int? initialSurahId;

  @override
  State<QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<QuranTab>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final _repo = QuranRepository.instance;
  QuranProgress _progress = const QuranProgress(
    surahId: 1,
    verseKey: '1:1',
    page: 1,
  );
  bool _offlineReady = false;
  bool _downloadStarted = false;
  bool _openedInitialSurah = false;
  late Future<List<QuranSurah>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _surahsFuture = _repo.surahs();
    _restore();
    _repo.downloadStatus.listen((status) {
      if (mounted && status.state == QuranDownloadState.complete) {
        setState(() {
          _offlineReady = true;
          _downloadStarted = false;
          _surahsFuture = _repo.surahs();
        });
      } else if (mounted && status.state == QuranDownloadState.failed) {
        setState(() => _downloadStarted = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final progress = await _repo.loadProgress();
    final ready = await _repo.isOfflineReady();
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _offlineReady = ready;
    });
    _openInitialSurahIfNeeded();
    if (!ready) _startDownload();
  }

  void _openInitialSurahIfNeeded() {
    final surahId = widget.initialSurahId;
    if (_openedInitialSurah || surahId == null) return;
    _openedInitialSurah = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSurah(surahId);
    });
  }

  Future<void> _startDownload() async {
    if (_downloadStarted) return;
    _downloadStarted = true;
    try {
      await _repo.ensureOfflineDataset();
    } catch (error) {
      _downloadStarted = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quran download paused. Your completed files were kept. Tap retry when the connection is stable.',
          ),
        ),
      );
    }
  }

  Future<void> _openSurah(int surahId, {int? page}) async {
    final verses = await _repo.versesForSurah(surahId);
    if (!mounted) return;
    if (verses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This surah is not available offline yet. Download the Quran first.',
          ),
        ),
      );
      return;
    }
    final progress = await Navigator.of(context).push<QuranProgress>(
      PageRouteBuilder<QuranProgress>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.18),
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder:
            (_, animation, __) => SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: QuranReaderOverlay(surahId: surahId, initialPage: page),
            ),
      ),
    );
    if (progress != null && mounted) setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuranSurah>>(
      future: _surahsFuture,
      builder: (context, snapshot) {
        final surahs = snapshot.data ?? const <QuranSurah>[];
        final currentMatches = surahs.where(
          (surah) => surah.id == _progress.surahId,
        );
        final current = currentMatches.isEmpty ? null : currentMatches.first;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ContinueCard(
                    surah: current,
                    progress: _progress,
                    offlineReady: _offlineReady,
                    onTap:
                        current == null
                            ? null
                            : () => _openSurah(
                              _progress.surahId,
                              page: _progress.page,
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DownloadProgressCard(
                    offlineReady: _offlineReady,
                    onDownload: _startDownload,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _QuranSegments(controller: _controller),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.62,
              child: TabBarView(
                controller: _controller,
                children: [
                  _SurahList(
                    surahs: surahs,
                    onOpen:
                        (surah) => _openSurah(surah.id, page: surah.firstPage),
                  ),
                  _AsyncRangeList(
                    future: _repo.juzItems(),
                    icon: Icons.view_agenda_outlined,
                    onOpen:
                        (item) =>
                            _openSurah(item.startSurahId, page: item.startPage),
                  ),
                  _AsyncRangeList(
                    future: _repo.hizbItems(),
                    icon: Icons.density_medium_rounded,
                    onOpen:
                        (item) =>
                            _openSurah(item.startSurahId, page: item.startPage),
                  ),
                  _AsyncRangeList(
                    future: _repo.pageItems(),
                    icon: Icons.chrome_reader_mode_outlined,
                    onOpen:
                        (item) =>
                            _openSurah(item.startSurahId, page: item.startPage),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DownloadProgressCard extends StatelessWidget {
  const _DownloadProgressCard({
    required this.offlineReady,
    required this.onDownload,
  });

  final bool offlineReady;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return StreamBuilder<QuranDownloadStatus>(
      stream: QuranRepository.instance.downloadStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final downloading = status?.state == QuranDownloadState.downloading;
        final failed = status?.state == QuranDownloadState.failed;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: offlineReady || downloading ? null : onDownload,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 104),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      failed
                          ? tokens.warning.withValues(alpha: 0.45)
                          : tokens.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    offlineReady
                        ? Icons.offline_pin_rounded
                        : failed
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_download_outlined,
                    color: failed ? tokens.warning : tokens.primary,
                    size: 19,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offlineReady
                        ? 'Offline ready'
                        : failed
                        ? 'Retry download'
                        : downloading
                        ? 'Downloading'
                        : 'Download Quran',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (downloading || failed) ...[
                    LinearProgressIndicator(
                      minHeight: 4,
                      value: status!.progress.clamp(0.0, 1.0),
                      color: failed ? tokens.warning : tokens.primary,
                      backgroundColor: tokens.surfaceContainerHigh,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      failed ? 'Tap to resume' : '${status.percent}% complete',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: failed ? tokens.warning : tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else
                    Text(
                      offlineReady ? 'Text and pages saved' : 'Text + Mushaf',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surah,
    required this.progress,
    required this.offlineReady,
    required this.onTap,
  });

  final QuranSurah? surah;
  final QuranProgress progress;
  final bool offlineReady;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SizedBox(
      height: 104,
      child: Material(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                Icon(Icons.menu_book_rounded, color: tokens.primary, size: 19),
                const SizedBox(height: 8),
                Text(
                  'Continue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  surah == null ? 'Start Quran' : surah!.nameTransliteration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  offlineReady
                      ? '${progress.verseKey} / p.${progress.page}'
                      : 'Download first',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranSegments extends StatelessWidget {
  const _QuranSegments({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: kSoftBronze,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kLine),
    ),
    child: TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      labelColor: kInk,
      unselectedLabelColor: kMuted,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      tabs: const [
        Tab(text: 'Surah'),
        Tab(text: 'Juz'),
        Tab(text: 'Hizb'),
        Tab(text: 'Page'),
      ],
    ),
  );
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.surahs, required this.onOpen});
  final List<QuranSurah> surahs;
  final ValueChanged<QuranSurah> onOpen;

  @override
  Widget build(BuildContext context) {
    if (surahs.isEmpty) return const _UnavailableList();
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return _BrowseTile(
          number: surah.id,
          title: surah.nameTransliteration,
          arabic: surah.nameArabic,
          subtitle: '${surah.nameEnglish} - ${surah.revelationPlace}',
          meta:
              '${surah.versesCount} verses - pages ${surah.firstPage}-${surah.lastPage}',
          onTap: () => onOpen(surah),
        );
      },
    );
  }
}

class _AsyncRangeList extends StatelessWidget {
  const _AsyncRangeList({
    required this.future,
    required this.icon,
    required this.onOpen,
  });
  final Future<List<QuranRangeItem>> future;
  final IconData icon;
  final ValueChanged<QuranRangeItem> onOpen;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<QuranRangeItem>>(
    future: future,
    builder: (context, snapshot) {
      final items = snapshot.data ?? const <QuranRangeItem>[];
      if (items.isEmpty) return const _UnavailableList();
      return ListView.separated(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _BrowseTile(
            number: item.number,
            icon: icon,
            title: item.title,
            arabic: '${item.number}',
            subtitle: item.subtitle,
            meta: item.rangeLabel,
            onTap: () => onOpen(item),
          );
        },
      );
    },
  );
}

class _UnavailableList extends StatelessWidget {
  const _UnavailableList();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(22),
      child: Text(
        'Quran content is not available yet. Start the offline download first.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kMuted, height: 1.5),
      ),
    ),
  );
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.number,
    required this.title,
    required this.arabic,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    this.icon,
  });
  final int number;
  final String title;
  final String arabic;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
    color: kPaper,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kSoftBronze,
                shape: BoxShape.circle,
                border: Border.all(color: kLine),
              ),
              child: Center(
                child:
                    icon == null
                        ? Text(
                          '$number',
                          style: const TextStyle(
                            color: kBronze,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                        : Icon(icon, color: kBronze, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kInk,
                      fontFamily: 'Georgia',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kBronze,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                arabic,
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class QuranReaderOverlay extends StatefulWidget {
  const QuranReaderOverlay({
    super.key,
    required this.surahId,
    this.initialPage,
  });
  final int surahId;
  final int? initialPage;

  @override
  State<QuranReaderOverlay> createState() => _QuranReaderOverlayState();
}

class _QuranReaderOverlayState extends State<QuranReaderOverlay> {
  final _repo = QuranRepository.instance;
  final _player = AudioPlayer();
  QuranSettings _settings = QuranSettings.defaults;
  late int _page = widget.initialPage ?? 1;
  String? _playingVerse;
  bool _translationRevealed = false;
  List<QuranVerse> _currentVerses = const [];
  bool _continuousPlayback = false;

  @override
  void initState() {
    super.initState();
    _repo.loadSettings().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
    _player.onPlayerComplete.listen((_) => _playNextVerse());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(QuranSurah?, List<QuranVerse>)>(
    future: _readerData(),
    builder: (context, snapshot) {
      final tokens = context.colors;
      final surah = snapshot.data?.$1;
      final verses = snapshot.data?.$2 ?? const <QuranVerse>[];
      _currentVerses = verses;
      return Scaffold(
        backgroundColor: tokens.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ReaderTopBar(
                title:
                    surah == null
                        ? 'Quran'
                        : '${surah.nameArabic} - ${surah.nameTransliteration}',
                mode: _settings.readingMode,
                onBack:
                    () => Navigator.of(context).pop(
                      QuranProgress(
                        surahId: widget.surahId,
                        verseKey:
                            _playingVerse ??
                            (verses.isEmpty ? '1:1' : verses.first.key),
                        page: _page,
                      ),
                    ),
                onMode: _toggleMode,
                onSettings: _openSettings,
              ),
              Expanded(
                child:
                    verses.isEmpty
                        ? const _UnavailableReader()
                        : _settings.readingMode == QuranReadingMode.verses
                        ? _VerseReadingMode(
                          verses: verses,
                          settings: _settings,
                          playingVerse: _playingVerse,
                          onPlay: _playVerse,
                          onReflect: _reflect,
                          onWord: _showWordMeaning,
                        )
                        : _MushafPageMode(
                          page: _page,
                          settings: _settings,
                          playingVerse: _playingVerse,
                          translationRevealed: _translationRevealed,
                          onTapTranslation:
                              () => setState(
                                () =>
                                    _translationRevealed =
                                        !_translationRevealed,
                              ),
                          onPageChanged:
                              (page) => setState(() {
                                _page = page;
                                _translationRevealed = false;
                              }),
                        ),
              ),
              _MiniPlayer(
                reciter: _settings.reciter,
                playingVerse: _playingVerse,
                continuousPlayback: _continuousPlayback,
                onToggle: verses.isEmpty ? null : _toggleSurahPlayback,
                onDownload:
                    verses.isEmpty
                        ? null
                        : () => _downloadSurahAudio(widget.surahId),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<(QuranSurah?, List<QuranVerse>)> _readerData() async => (
    await _repo.surahById(widget.surahId),
    await _repo.versesForSurah(widget.surahId),
  );

  Future<void> _toggleMode() async {
    final next = _settings.copyWith(
      readingMode:
          _settings.readingMode == QuranReadingMode.verses
              ? QuranReadingMode.page
              : QuranReadingMode.verses,
    );
    setState(() => _settings = next);
    await _repo.saveSettings(next);
  }

  Future<void> _openSettings() async {
    final next = await showModalBottomSheet<QuranSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _QuranSettingsSheet(settings: _settings),
    );
    if (next == null) return;
    setState(() => _settings = next);
    await _repo.saveSettings(next);
  }

  Future<void> _playVerse(QuranVerse verse) async {
    setState(() {
      _playingVerse = verse.key;
      _page = verse.page;
    });
    await _repo.saveProgress(
      QuranProgress(
        surahId: verse.surahId,
        verseKey: verse.key,
        page: verse.page,
      ),
    );
    final local = await _repo.localVerseAudio(verse, _settings);
    if (local != null) {
      await _player.play(DeviceFileSource(local.path));
    } else {
      final url = await _repo.audioUriFor(verse, _settings);
      await _player.play(UrlSource(url.toString()));
    }
  }

  Future<void> _toggleSurahPlayback() async {
    if (_continuousPlayback) {
      setState(() => _continuousPlayback = false);
      await _player.pause();
      return;
    }
    if (_currentVerses.isEmpty) return;
    setState(() => _continuousPlayback = true);
    final start =
        _playingVerse == null
            ? _currentVerses.first
            : _currentVerses.firstWhere(
              (verse) => verse.key == _playingVerse,
              orElse: () => _currentVerses.first,
            );
    await _playVerse(start);
  }

  Future<void> _playNextVerse() async {
    if (!_continuousPlayback ||
        _currentVerses.isEmpty ||
        _playingVerse == null) {
      return;
    }
    final index = _currentVerses.indexWhere(
      (verse) => verse.key == _playingVerse,
    );
    if (index == -1 || index >= _currentVerses.length - 1) {
      if (mounted) setState(() => _continuousPlayback = false);
      return;
    }
    await _playVerse(_currentVerses[index + 1]);
  }

  Future<void> _downloadSurahAudio(int surahId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${_settings.reciter} audio...')),
    );
    try {
      final bytes = await _repo.downloadSurahAudio(surahId, _settings);
      if (!mounted) return;
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Surah audio saved offline ($mb MB).')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio download failed: $error')));
    }
  }

  void _showWordMeaning(QuranWord word) {
    if (_settings.showWordMeanings) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${word.text}: ${word.meaning}')));
    }
  }

  void _reflect(QuranVerse verse) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReflectionSheet(verse: verse),
    );
  }
}

class _UnavailableReader extends StatelessWidget {
  const _UnavailableReader();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'This surah has not been downloaded yet. The app will not substitute another surah here.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kMuted, height: 1.5),
      ),
    ),
  );
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.title,
    required this.mode,
    required this.onBack,
    required this.onMode,
    required this.onSettings,
  });
  final String title;
  final QuranReadingMode mode;
  final VoidCallback onBack;
  final VoidCallback onMode;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Close Quran',
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _CircleButton(
            icon:
                mode == QuranReadingMode.verses
                    ? Icons.chrome_reader_mode_outlined
                    : Icons.format_align_right_rounded,
            tooltip: 'Switch reading mode',
            onTap: onMode,
          ),
          const SizedBox(width: 4),
          _CircleButton(
            icon: Icons.tune_rounded,
            tooltip: 'Quran settings',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _VerseReadingMode extends StatelessWidget {
  const _VerseReadingMode({
    required this.verses,
    required this.settings,
    required this.playingVerse,
    required this.onPlay,
    required this.onReflect,
    required this.onWord,
  });
  final List<QuranVerse> verses;
  final QuranSettings settings;
  final String? playingVerse;
  final ValueChanged<QuranVerse> onPlay;
  final ValueChanged<QuranVerse> onReflect;
  final ValueChanged<QuranWord> onWord;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
    itemCount: verses.length,
    separatorBuilder: (_, __) => const SizedBox(height: 14),
    itemBuilder:
        (context, index) => _VerseCard(
          verse: verses[index],
          settings: settings,
          active: playingVerse == verses[index].key,
          onPlay: () => onPlay(verses[index]),
          onReflect: () => onReflect(verses[index]),
          onWord: onWord,
        ),
  );
}

class _VerseCard extends StatefulWidget {
  const _VerseCard({
    required this.verse,
    required this.settings,
    required this.active,
    required this.onPlay,
    required this.onReflect,
    required this.onWord,
  });
  final QuranVerse verse;
  final QuranSettings settings;
  final bool active;
  final VoidCallback onPlay;
  final VoidCallback onReflect;
  final ValueChanged<QuranWord> onWord;

  @override
  State<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<_VerseCard> {
  bool _tafsirOpen = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color:
            widget.active ? tokens.secondaryContainer : tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.active ? tokens.secondary : tokens.border,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.verse.key,
                style: TextStyle(
                  color: tokens.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onReflect,
                icon: Icon(Icons.edit_note_rounded, color: tokens.primary),
              ),
              IconButton(
                onPressed: widget.onPlay,
                icon: Icon(
                  Icons.play_circle_fill_rounded,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.end,
                textDirection: TextDirection.rtl,
                spacing: 7,
                runSpacing: 10,
                children:
                    widget.verse.words
                        .map(
                          (word) => InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => widget.onWord(word),
                            child: Text(
                              word.text,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: widget.settings.arabicSize,
                                height: 1.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          if (widget.settings.showPronunciation) ...[
            const SizedBox(height: 14),
            Text(
              widget.verse.transliteration,
              style: TextStyle(
                color: tokens.primary,
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (widget.settings.showTranslation) ...[
            const SizedBox(height: 10),
            Text(
              widget.verse.translation,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
          ],
          if (widget.settings.showTafsir) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _tafsirOpen = !_tafsirOpen),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  _tafsirOpen
                      ? widget.verse.tafsir
                      : 'Tafsir Ibn Kathir - tap to expand',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MushafPageMode extends StatelessWidget {
  const _MushafPageMode({
    required this.page,
    required this.settings,
    required this.playingVerse,
    required this.translationRevealed,
    required this.onTapTranslation,
    required this.onPageChanged,
  });
  final int page;
  final QuranSettings settings;
  final String? playingVerse;
  final bool translationRevealed;
  final VoidCallback onTapTranslation;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(File?, List<QuranVerse>)>(
        future: _pageData(),
        builder: (context, snapshot) {
          final file = snapshot.data?.$1;
          final verses = snapshot.data?.$2 ?? const <QuranVerse>[];
          return GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -120 && page < 604) onPageChanged(page + 1);
              if (velocity > 120 && page > 1) onPageChanged(page - 1);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPaper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBronzeLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.68,
                      child:
                          file == null
                              ? const Center(
                                child: Text(
                                  'Mushaf page image not downloaded yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: kMuted),
                                ),
                              )
                              : SvgPicture.file(
                                file,
                                fit: BoxFit.contain,
                                placeholderBuilder:
                                    (_) => const Center(
                                      child: CircularProgressIndicator(
                                        color: kBronze,
                                      ),
                                    ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: onTapTranslation,
                    icon: Icon(
                      translationRevealed
                          ? Icons.visibility_off_outlined
                          : Icons.translate_rounded,
                      size: 18,
                    ),
                    label: Text(
                      translationRevealed
                          ? 'Hide translation'
                          : 'Reveal translation',
                    ),
                    style: TextButton.styleFrom(foregroundColor: kBronze),
                  ),
                ),
                if (translationRevealed)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPaper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kLine),
                    ),
                    child: Text(
                      verses
                          .map((verse) => '${verse.key} ${verse.translation}')
                          .join('\n\n'),
                      style: const TextStyle(color: kMuted, height: 1.55),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Future<(File?, List<QuranVerse>)> _pageData() async => (
    await QuranRepository.instance.localPageImage(page),
    await QuranRepository.instance.versesForPage(page),
  );
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.reciter,
    required this.playingVerse,
    required this.continuousPlayback,
    required this.onToggle,
    required this.onDownload,
  });
  final String reciter;
  final String? playingVerse;
  final bool continuousPlayback;
  final VoidCallback? onToggle;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      10,
      16,
      14 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: kSurface,
      border: Border(top: BorderSide(color: kLine)),
    ),
    child: Row(
      children: [
        _CircleButton(
          icon:
              continuousPlayback
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
          tooltip: 'Play surah',
          onTap: onToggle,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playingVerse == null
                    ? 'Ready to recite'
                    : 'Now reciting $playingVerse',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reciter,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDownload,
          icon: const Icon(Icons.download_for_offline_outlined, color: kBronze),
        ),
      ],
    ),
  );
}

class _QuranSettingsSheet extends StatefulWidget {
  const _QuranSettingsSheet({required this.settings});
  final QuranSettings settings;

  @override
  State<_QuranSettingsSheet> createState() => _QuranSettingsSheetState();
}

class _QuranSettingsSheetState extends State<_QuranSettingsSheet> {
  late QuranSettings _settings = widget.settings;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quran settings',
            style: TextStyle(
              color: kInk,
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _SettingSwitch(
            'Pronunciation',
            _settings.showPronunciation,
            (value) => setState(
              () => _settings = _settings.copyWith(showPronunciation: value),
            ),
          ),
          _SettingSwitch(
            'Translation',
            _settings.showTranslation,
            (value) => setState(
              () => _settings = _settings.copyWith(showTranslation: value),
            ),
          ),
          _SettingSwitch(
            'Word meanings',
            _settings.showWordMeanings,
            (value) => setState(
              () => _settings = _settings.copyWith(showWordMeanings: value),
            ),
          ),
          _SettingSwitch(
            'Explanation',
            _settings.showTafsir,
            (value) => setState(
              () => _settings = _settings.copyWith(showTafsir: value),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _settings.reciter,
            decoration: const InputDecoration(labelText: 'Reciter'),
            items:
                QuranRepository.reciters.keys
                    .map(
                      (reciter) => DropdownMenuItem(
                        value: reciter,
                        child: Text(reciter, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged:
                (value) => setState(
                  () => _settings = _settings.copyWith(reciter: value),
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Arabic text size: ${_settings.arabicSize.round()}',
            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700),
          ),
          Slider(
            value: _settings.arabicSize,
            min: 24,
            max: 40,
            divisions: 8,
            activeColor: kBronze,
            onChanged:
                (value) => setState(
                  () => _settings = _settings.copyWith(arabicSize: value),
                ),
          ),
          SegmentedButton<QuranReadingMode>(
            segments: const [
              ButtonSegment(
                value: QuranReadingMode.verses,
                icon: Icon(Icons.format_align_right_rounded),
                label: Text('Verses'),
              ),
              ButtonSegment(
                value: QuranReadingMode.page,
                icon: Icon(Icons.chrome_reader_mode_outlined),
                label: Text('Page'),
              ),
            ],
            selected: {_settings.readingMode},
            onSelectionChanged:
                (value) => setState(
                  () =>
                      _settings = _settings.copyWith(readingMode: value.first),
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _settings),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class _ReflectionSheet extends StatelessWidget {
  const _ReflectionSheet({required this.verse});
  final QuranVerse verse;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      22,
      18,
      22,
      22 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reflect on ${verse.key}',
          style: const TextStyle(
            color: kInk,
            fontFamily: 'Georgia',
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        const TextField(
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: 'Write what this ayah opens in you',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save reflection'),
          ),
        ),
      ],
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: kSoftBronze,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: kBronze, size: 22),
        ),
      ),
    ),
  );
}
