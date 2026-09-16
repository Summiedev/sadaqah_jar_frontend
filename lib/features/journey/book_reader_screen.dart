import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epub_view/epub_view.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import '../../services/book_offline_store.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({
    super.key,
    required this.book,
    this.adminPreview = false,
  });

  final BookRead book;
  final bool adminPreview;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late Future<BookDetail> _future;
  EpubController? _epubController;
  int _page = 0;
  bool _bookmarked = false;
  bool _bookmarkBusy = false;
  bool _offlineBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _loadBook();
    if (!widget.adminPreview) _loadBookmark();
  }

  Future<BookDetail> _loadBook() async {
    if (!widget.adminPreview) {
      final cached = await BookOfflineStore.instance.loadDetail(widget.book.id);
      if (cached != null) return cached;
    }
    final book =
        widget.adminPreview
            ? await BackendApi.instance.getAdminBook(widget.book.id)
            : await BackendApi.instance.getBook(widget.book.id);
    if (!widget.adminPreview) {
      await BookOfflineStore.instance.saveDetail(book);
    }
    return book;
  }

  Future<void> _saveForOffline() async {
    if (_offlineBusy || widget.adminPreview) return;
    setState(() => _offlineBusy = true);
    try {
      final book = await _future;
      await BookOfflineStore.instance.saveDetail(book);
      final format = (book.fileFormat ?? '').toLowerCase();
      if (book.fileUrl != null && (format == 'pdf' || format == 'epub')) {
        await BookOfflineStore.instance.downloadContent(
          bookId: book.id,
          url: BackendApi.instance.absoluteApiUrl(book.fileUrl!),
          format: format,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == 'images'
                ? 'Book saved. Pages become available offline as you read them.'
                : 'This book is available offline.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendErrorMessage(
              error,
              fallback: 'Could not save this book for offline reading.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _offlineBusy = false);
    }
  }

  Future<void> _loadBookmark() async {
    try {
      final rows = await BackendApi.instance.getBookmarks();
      if (!mounted) return;
      setState(
        () =>
            _bookmarked = rows.any(
              (row) => (row['book_id'] as num?)?.toInt() == widget.book.id,
            ),
      );
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkBusy || widget.adminPreview) return;
    final previous = _bookmarked;
    setState(() {
      _bookmarkBusy = true;
      _bookmarked = !previous;
    });
    try {
      if (_bookmarked) {
        await BackendApi.instance.bookmarkBook(bookId: widget.book.id);
      } else {
        await BackendApi.instance.unbookmarkBook(bookId: widget.book.id);
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _bookmarked ? 'Book saved' : 'Book removed from saved',
            ),
          ),
        );
    } catch (_) {
      if (mounted) setState(() => _bookmarked = previous);
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!widget.adminPreview)
            IconButton(
              onPressed: _bookmarkBusy ? null : _toggleBookmark,
              tooltip: _bookmarked ? 'Remove bookmark' : 'Save bookmark',
              icon: Icon(
                _bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          if (!widget.adminPreview)
            IconButton(
              onPressed: _offlineBusy ? null : _saveForOffline,
              tooltip: 'Save for offline',
              icon:
                  _offlineBusy
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.download_for_offline_outlined),
            ),
        ],
      ),
      body: FutureBuilder<BookDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }
          if (snapshot.hasError) {
            return _ReaderState(
              icon: Icons.menu_book_outlined,
              title: 'This book is not available',
              body: 'It may have been unpublished or removed.',
            );
          }
          final book = snapshot.data!;
          final format =
              (book.fileFormat ?? widget.book.fileFormat ?? '').toLowerCase();
          if (format == 'pdf' && (book.fileUrl ?? '').isNotEmpty) {
            unawaited(
              BackendApi.instance.saveReadingProgress(
                bookId: book.id,
                chapterNumber: 1,
              ),
            );
            return _PdfBook(
              bookId: book.id,
              url: BackendApi.instance.absoluteApiUrl(book.fileUrl!),
              title: book.title,
            );
          }
          if (format == 'epub' && (book.fileUrl ?? '').isNotEmpty) {
            return _EpubBook(
              bookId: book.id,
              url: BackendApi.instance.absoluteApiUrl(book.fileUrl!),
              controllerBuilder: _setEpubController,
            );
          }
          if (format == 'images' || book.pages.isNotEmpty) {
            return _ImageBook(
              pages: book.pages,
              index: _page,
              onChanged: (value) => setState(() => _page = value),
            );
          }
          if (book.chapters.isNotEmpty) {
            return _ChapterBook(chapters: book.chapters, bookId: book.id);
          }
          return const _ReaderState(
            icon: Icons.hourglass_empty_rounded,
            title: 'Reading content is not ready yet',
            body: 'Please check back after this book has finished processing.',
          );
        },
      ),
    );
  }

  EpubController _setEpubController(Uint8List bytes) {
    _epubController?.dispose();
    _epubController = EpubController(document: EpubDocument.openData(bytes));
    return _epubController!;
  }
}

class _PdfBook extends StatefulWidget {
  const _PdfBook({required this.bookId, required this.url, required this.title});

  final int bookId;
  final String url;
  final String title;

  @override
  State<_PdfBook> createState() => _PdfBookState();
}

class _PdfBookState extends State<_PdfBook> {
  late Future<File> _future;

  @override
  void initState() {
    super.initState();
    _future = BookOfflineStore.instance.downloadContent(
      bookId: widget.bookId,
      url: widget.url,
      format: 'pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ReaderState(
            icon: Icons.download_for_offline_outlined,
            title: 'Preparing this book',
            body: 'Saving it on this device for reliable reading.',
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const _ReaderState(
            icon: Icons.error_outline_rounded,
            title: 'Could not open this PDF',
            body: 'Connect to the internet and try again.',
          );
        }
        return SfPdfViewer.file(
          snapshot.data!,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        );
      },
    );
  }
}

class _EpubBook extends StatefulWidget {
  const _EpubBook({
    required this.bookId,
    required this.url,
    required this.controllerBuilder,
  });

  final int bookId;
  final String url;
  final EpubController Function(Uint8List bytes) controllerBuilder;

  @override
  State<_EpubBook> createState() => _EpubBookState();
}

class _EpubBookState extends State<_EpubBook> {
  late Future<EpubController> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<EpubController> _load() async {
    final file = await BookOfflineStore.instance.downloadContent(
      bookId: widget.bookId,
      url: widget.url,
      format: 'epub',
    );
    return widget.controllerBuilder(await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpubController>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          );
        }
        if (snapshot.hasError) {
          return const _ReaderState(
            icon: Icons.error_outline_rounded,
            title: 'Could not open EPUB',
            body: 'Try again in a moment.',
          );
        }
        return EpubView(controller: snapshot.data!);
      },
    );
  }
}

class _ImageBook extends StatelessWidget {
  const _ImageBook({
    required this.pages,
    required this.index,
    required this.onChanged,
  });

  final List<BookPageRead> pages;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const _ReaderState(
        icon: Icons.image_not_supported_outlined,
        title: 'No pages uploaded',
        body: 'This image-based book has no readable pages yet.',
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: MizanSpacing.lg,
            vertical: MizanSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(bottom: BorderSide(color: context.colors.border)),
          ),
          child: Text(
            'Page ${index + 1} of ${pages.length}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            itemCount: pages.length,
            onPageChanged: onChanged,
            itemBuilder: (context, pageIndex) {
              final page = pages[pageIndex];
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: _CachedBookPage(page: page),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CachedBookPage extends StatefulWidget {
  const _CachedBookPage({required this.page});

  final BookPageRead page;

  @override
  State<_CachedBookPage> createState() => _CachedBookPageState();
}

class _CachedBookPageState extends State<_CachedBookPage> {
  late Future<File> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<File> _load() async {
    final cached = await BookOfflineStore.instance.existingPage(widget.page);
    if (cached != null) return cached;
    final url = BackendApi.instance.absoluteApiUrl(widget.page.imageUrl);
    return BookOfflineStore.instance.cachePage(page: widget.page, url: url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const _ReaderState(
            icon: Icons.broken_image_outlined,
            title: 'Page image unavailable',
            body: 'Connect to the internet to save this page for offline reading.',
          );
        }
        return Center(
          child: Image.file(snapshot.data!, fit: BoxFit.contain),
        );
      },
    );
  }
}

class _ChapterBook extends StatefulWidget {
  const _ChapterBook({required this.chapters, required this.bookId});

  final List<BookChapterRead> chapters;
  final int bookId;

  @override
  State<_ChapterBook> createState() => _ChapterBookState();
}

class _ChapterBookState extends State<_ChapterBook> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapters[_selectedIndex];
    final isFirst = _selectedIndex == 0;
    final isLast = _selectedIndex == widget.chapters.length - 1;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              MizanSpacing.xxl,
              MizanSpacing.lg,
              MizanSpacing.xxl,
              MizanSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 26,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chapter ${chapter.chapterNumber}',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: context.colors.divider),
                const SizedBox(height: 20),
                Text(
                  chapter.content ?? '',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 19,
                    height: 1.9,
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              MizanSpacing.xl,
              MizanSpacing.md,
              MizanSpacing.xl,
              MizanSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(top: BorderSide(color: context.colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        isFirst
                            ? null
                            : () {
                              setState(() => _selectedIndex--);
                              BackendApi.instance.saveReadingProgress(
                                bookId: widget.bookId,
                                chapterNumber:
                                    widget
                                        .chapters[_selectedIndex]
                                        .chapterNumber,
                              );
                            },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        isLast
                            ? null
                            : () {
                              setState(() => _selectedIndex++);
                              BackendApi.instance.saveReadingProgress(
                                bookId: widget.bookId,
                                chapterNumber:
                                    widget
                                        .chapters[_selectedIndex]
                                        .chapterNumber,
                              );
                            },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderState extends StatelessWidget {
  const _ReaderState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MizanSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.colors.primary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
