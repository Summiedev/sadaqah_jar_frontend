import 'dart:async';
import 'dart:typed_data';

import 'package:epub_view/epub_view.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key, required this.book, this.adminPreview = false});

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

  @override
  void initState() {
    super.initState();
    _future = widget.adminPreview ? BackendApi.instance.getAdminBook(widget.book.id) : BackendApi.instance.getBook(widget.book.id);
    if (!widget.adminPreview) _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    try {
      final rows = await BackendApi.instance.getBookmarks();
      if (!mounted) return;
      setState(() => _bookmarked = rows.any((row) => (row['book_id'] as num?)?.toInt() == widget.book.id));
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkBusy || widget.adminPreview) return;
    final previous = _bookmarked;
    setState(() { _bookmarkBusy = true; _bookmarked = !previous; });
    try {
      if (_bookmarked) {
        await BackendApi.instance.bookmarkBook(bookId: widget.book.id);
      } else {
        await BackendApi.instance.unbookmarkBook(bookId: widget.book.id);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_bookmarked ? 'Book saved' : 'Book removed from saved')));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        actions: [
          if (!widget.adminPreview)
            IconButton(
              onPressed: _bookmarkBusy ? null : _toggleBookmark,
              tooltip: _bookmarked ? 'Remove bookmark' : 'Save bookmark',
              icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            ),
        ],
      ),
      body: FutureBuilder<BookDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBronze));
          }
          if (snapshot.hasError) {
            return _ReaderState(icon: Icons.menu_book_outlined, title: 'This book is not available', body: 'It may have been unpublished or removed.');
          }
          final book = snapshot.data!;
          final format = (book.fileFormat ?? widget.book.fileFormat ?? '').toLowerCase();
          if (format == 'pdf' && (book.fileUrl ?? '').isNotEmpty) {
            unawaited(BackendApi.instance.saveReadingProgress(bookId: book.id, chapterNumber: 1));
            return _PdfBook(url: BackendApi.instance.absoluteApiUrl(book.fileUrl!), title: book.title);
          }
          if (format == 'epub' && (book.fileUrl ?? '').isNotEmpty) {
            return _EpubBook(url: BackendApi.instance.absoluteApiUrl(book.fileUrl!), controllerBuilder: _setEpubController);
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
          return const _ReaderState(icon: Icons.hourglass_empty_rounded, title: 'Reading content is not ready yet', body: 'Please check back after this book has finished processing.');
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

class _PdfBook extends StatelessWidget {
  const _PdfBook({required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.network(
      url,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoadFailed: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this PDF. Please try again.')),
      ),
    );
  }
}

class _EpubBook extends StatefulWidget {
  const _EpubBook({required this.url, required this.controllerBuilder});

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
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode >= 400 || response.bodyBytes.isEmpty) {
      throw BackendApiException('Could not download EPUB', response.statusCode);
    }
    return widget.controllerBuilder(response.bodyBytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpubController>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBronze));
        }
        if (snapshot.hasError) {
          return const _ReaderState(icon: Icons.error_outline_rounded, title: 'Could not open EPUB', body: 'Try again in a moment.');
        }
        return EpubView(controller: snapshot.data!);
      },
    );
  }
}

class _ImageBook extends StatelessWidget {
  const _ImageBook({required this.pages, required this.index, required this.onChanged});

  final List<BookPageRead> pages;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const _ReaderState(icon: Icons.image_not_supported_outlined, title: 'No pages uploaded', body: 'This image-based book has no readable pages yet.');
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: kLine))),
          child: Text('Page ${index + 1} of ${pages.length}', textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
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
                child: Center(
                  child: Image.network(
                    page.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _ReaderState(icon: Icons.broken_image_outlined, title: 'Page image unavailable', body: 'This page could not be loaded.'),
                    loadingBuilder: (context, child, event) => event == null ? child : const Center(child: CircularProgressIndicator(color: kBronze)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.title, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 26, height: 1.3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Chapter ${chapter.chapterNumber}', style: const TextStyle(color: kMuted, fontSize: 12.5, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
                const Divider(color: kLine),
                const SizedBox(height: 20),
                Text(chapter.content ?? '', style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 19, height: 1.9)),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: kLine))),
            child: Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: isFirst ? null : () { setState(() => _selectedIndex--); BackendApi.instance.saveReadingProgress(bookId: widget.bookId, chapterNumber: widget.chapters[_selectedIndex].chapterNumber); }, icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Previous'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(onPressed: isLast ? null : () { setState(() => _selectedIndex++); BackendApi.instance.saveReadingProgress(bookId: widget.bookId, chapterNumber: widget.chapters[_selectedIndex].chapterNumber); }, icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Next'), style: FilledButton.styleFrom(backgroundColor: kBronze))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderState extends StatelessWidget {
  const _ReaderState({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kBronze, size: 48),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
