import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../services/backend_api.dart';
import '../../../services/quran_download_service.dart';
import '../../../widgets/mizan_async_state.dart';
import 'quran_data.dart';
import '../reflection_action_suggestion.dart';

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
  StreamSubscription<QuranDownloadStatus>? _downloadSubscription;
  Timer? _downloadPoller;
  String? _loadError;
  late Future<List<QuranSurah>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _surahsFuture = _repo.surahs();
    _restore();
    _downloadSubscription = _repo.downloadStatus.listen((status) {
      if (mounted && status.state == QuranDownloadState.complete) {
        setState(() {
          _offlineReady = true;
          _downloadStarted = false;
          _surahsFuture = _repo.surahs();
        });
      } else if (mounted &&
          status.state != QuranDownloadState.downloading &&
          status.state != QuranDownloadState.queued) {
        setState(() => _downloadStarted = false);
      }
    });
    _downloadPoller = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_downloadStarted) return;
      await _repo.refreshPersistedDownloadStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _downloadSubscription?.cancel();
    _downloadPoller?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final progress = await _repo.loadProgress();
      final ready = await _repo.isOfflineReady();
      final downloadStatus = await _repo.loadDownloadStatus();
      if (!mounted) return;
      _repo.emitDownloadStatus(downloadStatus);
      setState(() {
        _progress = progress;
        _offlineReady = ready;
        _downloadStarted =
            downloadStatus.state == QuranDownloadState.queued ||
            downloadStatus.state == QuranDownloadState.downloading;
      });
      _openInitialSurahIfNeeded();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError =
              'Quran data could not be loaded yet. Check your connection and try again.';
        });
      }
    }
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
    setState(() => _downloadStarted = true);
    try {
      await QuranDownloadService.instance.enqueue();
      await _repo.refreshPersistedDownloadStatus();
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
        barrierColor: context.colors.scrim.withValues(alpha: 0.18),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MizanLoadingState(label: 'Loading your Quran...');
        }
        if (snapshot.hasError || _loadError != null) {
          return _QuranUnavailableState(
            message: _loadError ?? 'Quran data could not be loaded yet.',
            onRetry: () {
              setState(() {
                _loadError = null;
                _surahsFuture = _repo.surahs();
              });
              _restore();
            },
          );
        }
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
                    onCancel: QuranDownloadService.instance.cancel,
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
                    load: _repo.juzItems,
                    icon: Icons.view_agenda_outlined,
                    onOpen:
                        (item) =>
                            _openSurah(item.startSurahId, page: item.startPage),
                  ),
                  _AsyncRangeList(
                    load: _repo.hizbItems,
                    icon: Icons.density_medium_rounded,
                    onOpen:
                        (item) =>
                            _openSurah(item.startSurahId, page: item.startPage),
                  ),
                  _AsyncRangeList(
                    load: _repo.pageItems,
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

class _QuranUnavailableState extends StatelessWidget {
  const _QuranUnavailableState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 44, color: colors.primary),
            const SizedBox(height: 14),
            Text(
              'Your Quran is safe',
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadProgressCard extends StatelessWidget {
  const _DownloadProgressCard({
    required this.offlineReady,
    required this.onDownload,
    required this.onCancel,
  });

  final bool offlineReady;
  final VoidCallback onDownload;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return StreamBuilder<QuranDownloadStatus>(
      stream: QuranRepository.instance.downloadStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final downloading = status?.state == QuranDownloadState.downloading;
        final queued = status?.state == QuranDownloadState.queued;
        final waiting = status?.state == QuranDownloadState.waitingForNetwork;
        final active = downloading || queued || waiting;
        final failed = status?.state == QuranDownloadState.failed;
        final paused = status?.state == QuranDownloadState.paused;
        final cancelled = status?.state == QuranDownloadState.cancelled;
        final resumable = failed || paused || cancelled;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: offlineReady || active ? null : onDownload,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      resumable
                          ? tokens.warning.withValues(alpha: 0.45)
                          : tokens.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        offlineReady
                            ? Icons.offline_pin_rounded
                            : resumable
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_download_outlined,
                        color: resumable ? tokens.warning : tokens.primary,
                        size: 19,
                      ),
                      const Spacer(),
                      if (active)
                        InkResponse(
                          onTap: onCancel,
                          radius: 18,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: tokens.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    offlineReady
                        ? 'Offline ready'
                        : failed
                        ? 'Retry download'
                        : paused
                        ? 'Resume download'
                        : cancelled
                        ? 'Download cancelled'
                        : queued
                        ? 'Queued'
                        : waiting
                        ? 'Waiting for internet'
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
                  if (active || resumable) ...[
                    LinearProgressIndicator(
                      minHeight: 4,
                      value: status!.progress.clamp(0.0, 1.0),
                      color: resumable ? tokens.warning : tokens.primary,
                      backgroundColor: tokens.surfaceContainerHigh,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      waiting
                          ? 'Will resume when online'
                          : resumable
                          ? 'Tap to resume'
                          : '${status.percent}% complete',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            resumable ? tokens.warning : tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else
                    Text(
                      offlineReady
                          ? 'Text and Mushaf pages saved'
                          : 'Text and Mushaf pages',
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92),
      child: Material(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                Icon(Icons.menu_book_rounded, color: tokens.primary, size: 19),
                const SizedBox(height: 5),
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
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: tokens.textPrimary,
        unselectedLabelColor: tokens.textSecondary,
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

class _AsyncRangeList extends StatefulWidget {
  const _AsyncRangeList({
    required this.load,
    required this.icon,
    required this.onOpen,
  });
  final Future<List<QuranRangeItem>> Function() load;
  final IconData icon;
  final ValueChanged<QuranRangeItem> onOpen;

  @override
  State<_AsyncRangeList> createState() => _AsyncRangeListState();
}

class _AsyncRangeListState extends State<_AsyncRangeList> {
  late Future<List<QuranRangeItem>> _future = widget.load();

  @override
  void didUpdateWidget(covariant _AsyncRangeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load != widget.load) _future = widget.load();
  }

  void _retry() => setState(() {
    _future = widget.load();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<List<QuranRangeItem>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const MizanLoadingState(label: 'Loading Quran sections...');
      }
      if (snapshot.hasError) {
        return MizanErrorState(
          title: 'Could not load this section',
          message: 'Your Quran is safe. Check your connection and try again.',
          onRetry: _retry,
        );
      }
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
            icon: widget.icon,
            title: item.title,
            arabic: '${item.number}',
            subtitle: item.subtitle,
            meta: item.rangeLabel,
            onTap: () => widget.onOpen(item),
          );
        },
      );
    },
  );
}

class _UnavailableList extends StatelessWidget {
  const _UnavailableList();

  @override
  Widget build(BuildContext context) => const MizanEmptyState(
    icon: Icons.menu_book_outlined,
    title: 'No Quran sections yet',
    message: 'Start the download to make Quran reading available offline.',
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
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      color: tokens.surfaceElevated,
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
                  color: tokens.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.border),
                ),
                child: Center(
                  child:
                      icon == null
                          ? Text(
                            '$number',
                            style: TextStyle(
                              color: tokens.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                          : Icon(icon, color: tokens.primary, size: 20),
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
                      style: TextStyle(
                        color: tokens.textPrimary,
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
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primary,
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
                  style: TextStyle(
                    color: tokens.textPrimary,
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
  Timer? _settingsSaveTimer;
  late final Future<(QuranSurah?, List<QuranVerse>)> _readerFuture;

  @override
  void initState() {
    super.initState();
    _readerFuture = _readerData();
    _repo.loadSettings().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
    _player.onPlayerComplete.listen((_) => _playNextVerse());
  }

  @override
  void dispose() {
    _settingsSaveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(QuranSurah?, List<QuranVerse>)>(
    future: _readerFuture,
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
                        : _settings.readingMode == QuranReadingMode.mushaf
                        ? _MushafPageMode(
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
                              (page) {
                                setState(() {
                                  _page = page;
                                  _translationRevealed = false;
                                });
                                final pageVerses = verses.where(
                                  (verse) => verse.page == page,
                                );
                                final first = pageVerses.isEmpty
                                    ? (verses.isEmpty ? null : verses.first)
                                    : pageVerses.first;
                                if (first != null) {
                                  unawaited(
                                    _repo.saveProgress(
                                      QuranProgress(
                                        surahId: first.surahId,
                                        verseKey: first.key,
                                        page: page,
                                      ),
                                    ),
                                  );
                                }
                              },
                        )
                        : _VerseReadingMode(
                          verses: verses,
                          settings: _settings,
                          playingVerse: _playingVerse,
                          onPlay: _playVerse,
                          onReflect: _reflect,
                          onWord: _showWordMeaning,
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

  void _toggleMode() {
    final nextMode = switch (_settings.readingMode) {
      QuranReadingMode.mushaf => QuranReadingMode.continuous,
      QuranReadingMode.continuous => QuranReadingMode.ayah,
      QuranReadingMode.ayah => QuranReadingMode.mushaf,
    };
    if (_canSetReadingMode(nextMode)) {
      _applySettings(_settings.copyWith(readingMode: nextMode));
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<QuranSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _QuranSettingsSheet(
        settings: _settings,
        onSettingsChanged: _applySettings,
        onModeChanged: _canSetReadingMode,
      ),
    );
  }

  void _applySettings(QuranSettings next) {
    if (!mounted) return;
    setState(() => _settings = next);
    // The slider updates the reader immediately, while writes are coalesced so
    // dragging it does not create a storage write for every pixel moved.
    _settingsSaveTimer?.cancel();
    _settingsSaveTimer = Timer(const Duration(milliseconds: 140), () {
      unawaited(_repo.saveSettings(next).catchError((_) {}));
    });
  }

  bool _canSetReadingMode(QuranReadingMode mode) {
    if (mode == QuranReadingMode.ayah && _currentVerses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verse-by-verse is not ready yet. Please let this Quran section finish loading or downloading.',
          ),
        ),
      );
      return false;
    }
    return true;
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

  Future<void> _reflect(QuranVerse verse) async {
    final reflection = await showModalBottomSheet<JourneyReflection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReflectionSheet(verse: verse),
    );
    if (reflection != null && mounted) {
      await showReflectionActionSuggestion(context, reflection);
    }
  }
}

class _UnavailableReader extends StatelessWidget {
  const _UnavailableReader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'This surah has not been downloaded yet. The app will not substitute another surah here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textSecondary, height: 1.5),
        ),
      ),
    );
  }
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
            icon: switch (mode) {
              QuranReadingMode.mushaf => Icons.view_stream_outlined,
              QuranReadingMode.continuous => Icons.format_list_numbered_rtl,
              QuranReadingMode.ayah => Icons.menu_book_outlined,
            },
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
          if (widget.verse.words.isEmpty)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.verse.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontFamily: 'Noto Naskh Arabic',
                  fontSize: widget.settings.arabicSize,
                  height: 1.8,
                ),
              ),
            )
          else
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

class _MushafPageMode extends StatefulWidget {
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
  State<_MushafPageMode> createState() => _MushafPageModeState();
}

class _MushafPageModeState extends State<_MushafPageMode> {
  late Future<List<QuranVerse>> _versesFuture;
  File? _pageImage;
  bool _pageImageLoading = true;
  int _pageRequest = 0;

  @override
  void initState() {
    super.initState();
    _beginPageLoad();
  }

  @override
  void didUpdateWidget(covariant _MushafPageMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _beginPageLoad();
    }
  }

  void _beginPageLoad() {
    final request = ++_pageRequest;
    _versesFuture = QuranRepository.instance.versesForPage(widget.page);
    _pageImage = null;
    _pageImageLoading = true;
    // Artwork is deliberately independent of text. A cached/local page can
    // render immediately while a missing image is fetched in the background.
    QuranRepository.instance.pageImage(widget.page).then((file) {
      if (!mounted || request != _pageRequest) return;
      setState(() {
        _pageImage = file;
        _pageImageLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<QuranVerse>>(
    future: _versesFuture,
    builder: (context, snapshot) {
      final tokens = context.colors;
      final file = _pageImage;
      final verses = snapshot.data ?? const <QuranVerse>[];
      final loading =
          file == null &&
          verses.isEmpty &&
          (snapshot.connectionState != ConnectionState.done ||
              _pageImageLoading);
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -120 && widget.page < 604) {
            widget.onPageChanged(widget.page + 1);
          }
          if (velocity > 120 && widget.page > 1) {
            widget.onPageChanged(widget.page - 1);
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Madani page proportions are kept stable so the reader
                // feels like one complete page rather than a clipped card.
                final pageRatio = 0.707;
                if (loading) {
                  return AspectRatio(
                    aspectRatio: pageRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.surfaceElevated,
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: tokens.primary),
                      ),
                    ),
                  );
                }
                if (file != null) {
                  return AspectRatio(
                    aspectRatio: pageRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.surfaceElevated,
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: ClipRect(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 3,
                          boundaryMargin: const EdgeInsets.all(24),
                          child:
                              file.path.toLowerCase().endsWith('.svg')
                                  ? SvgPicture.file(file, fit: BoxFit.contain)
                                  : Image.file(file, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                }
                if (verses.isNotEmpty) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(24),
                    child: _UthmaniTextPage(
                      page: widget.page,
                      verses: verses,
                      arabicSize: widget.settings.arabicSize,
                    ),
                  );
                }
                return AspectRatio(
                  aspectRatio: pageRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'This Mushaf page is not available yet. Connect to the internet or continue the offline download.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: widget.onTapTranslation,
                icon: Icon(
                  widget.translationRevealed
                      ? Icons.visibility_off_outlined
                      : Icons.translate_rounded,
                  size: 18,
                ),
                label: Text(
                  widget.translationRevealed
                      ? 'Hide translation'
                      : 'Reveal translation',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.primary,
                ),
              ),
            ),
            if (widget.translationRevealed)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  verses
                      .map((verse) => '${verse.key} ${verse.translation}')
                      .join('\n\n'),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _UthmaniTextPage extends StatelessWidget {
  const _UthmaniTextPage({
    required this.page,
    required this.verses,
    required this.arabicSize,
  });

  final int page;
  final List<QuranVerse> verses;
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final size = arabicSize.clamp(22.0, 48.0).toDouble();
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).width * 1.414,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: tokens.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '/* REMOVED BY REPOGUARD: obfuscated hex payload */ ''  \u2022  $page',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: tokens.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(child: Divider(color: tokens.borderSubtle)),
            ],
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final verse in verses) ...[
                    TextSpan(
                      text: verse.arabic,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontFamily: 'Noto Naskh Arabic',
                        fontSize: size,
                        height: 2.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '  \u06DD${_arabicIndicNumber(verse.ayah)}  ',
                      style: TextStyle(
                        color: tokens.primary,
                        fontFamily: 'Noto Naskh Arabic',
                        fontSize: size * 0.72,
                        height: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

String _arabicIndicNumber(int value) {
  const digits = '/* REMOVED BY REPOGUARD: obfuscated hex payload */ ''';
  return value
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
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
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border(top: BorderSide(color: context.colors.divider)),
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
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reciter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDownload,
            icon: Icon(
              Icons.download_for_offline_outlined,
              color: tokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranSettingsSheet extends StatefulWidget {
  const _QuranSettingsSheet({
    required this.settings,
    required this.onSettingsChanged,
    required this.onModeChanged,
  });
  final QuranSettings settings;
  final ValueChanged<QuranSettings> onSettingsChanged;
  final bool Function(QuranReadingMode mode) onModeChanged;

  @override
  State<_QuranSettingsSheet> createState() => _QuranSettingsSheetState();
}

class _QuranSettingsSheetState extends State<_QuranSettingsSheet> {
  late QuranSettings _settings = widget.settings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quran settings',
              style: TextStyle(
                color: tokens.textPrimary,
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _SettingSwitch(
              'Pronunciation',
              _settings.showPronunciation,
              (value) => _update(
                _settings.copyWith(showPronunciation: value),
              ),
            ),
            _SettingSwitch(
              'Translation',
              _settings.showTranslation,
              (value) => _update(_settings.copyWith(showTranslation: value)),
            ),
            _SettingSwitch(
              'Word meanings',
              _settings.showWordMeanings,
              (value) => _update(_settings.copyWith(showWordMeanings: value)),
            ),
            _SettingSwitch(
              'Explanation',
              _settings.showTafsir,
              (value) => _update(_settings.copyWith(showTafsir: value)),
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
                  (value) => _update(_settings.copyWith(reciter: value)),
            ),
            const SizedBox(height: 14),
            Text(
              'Mushaf text size: ${_settings.arabicSize.round()}',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Slider(
              value: _settings.arabicSize,
              min: 24,
              max: 40,
              divisions: 8,
              activeColor: tokens.primary,
              onChanged:
                  (value) => _update(_settings.copyWith(arabicSize: value)),
            ),
            SegmentedButton<QuranReadingMode>(
              segments: const [
                ButtonSegment(
                  value: QuranReadingMode.mushaf,
                  icon: Icon(Icons.menu_book_outlined),
                  label: Text('Mushaf'),
                ),
                ButtonSegment(
                  value: QuranReadingMode.continuous,
                  icon: Icon(Icons.format_align_right_rounded),
                  label: Text('Flow'),
                ),
                ButtonSegment(
                  value: QuranReadingMode.ayah,
                  icon: Icon(Icons.format_list_numbered_rtl),
                  label: Text('Ayah'),
                ),
              ],
              selected: {_settings.readingMode},
              onSelectionChanged:
                  (value) {
                    final mode = value.first;
                    if (widget.onModeChanged(mode)) {
                      _update(_settings.copyWith(readingMode: mode));
                    }
                  },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _settings),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _update(QuranSettings next) {
    setState(() => _settings = next);
    widget.onSettingsChanged(next);
  }
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
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class _ReflectionSheet extends StatefulWidget {
  const _ReflectionSheet({required this.verse});
  final QuranVerse verse;

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  late final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final reflection = await BackendApi.instance.createReflection(
        title: widget.verse.key,
        body: body,
        mood: 'Quran',
        isPrivate: true,
        requestId:
            'quran_${widget.verse.key}_${DateTime.now().microsecondsSinceEpoch}',
      );
      await QuranRepository.instance.recordReflection();
      if (mounted) Navigator.of(context).pop(reflection);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Your reflection is still here; please retry.';
      });
    }
  }

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
          'Reflect on ${widget.verse.key}',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontFamily: 'Georgia',
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: 'Write what this ayah opens in you',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: context.colors.error)),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save reflection'),
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
      color: context.colors.primaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: context.colors.primary, size: 22),
        ),
      ),
    ),
  );
}
