import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/backend_api.dart';

const _ivory = Color(0xFFF5EDE1);
const _paper = Color(0xFFFFFBF6);
const _ink = Color(0xFF30241E);
const _muted = Color(0xFF756457);
const _bronze = Color(0xFF92704B);
const _line = Color(0xFFE4D5C3);

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key, required this.book});

  final BookRead book;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late Future<List<BookChapterRead>> _future;
  int _selectedIndex = 0;
  BookChapterRead? _currentChapter;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getBookChapters(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        title: Text(widget.book.title, style: const TextStyle(color: _ink, fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_rounded, color: _bronze),
            tooltip: 'Bookmark',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<BookChapterRead>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _bronze));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load chapters: ${snapshot.error}', style: const TextStyle(color: _muted)));
          }
          final chapters = snapshot.data ?? [];
          if (chapters.isEmpty) {
            if (widget.book.fileUrl != null && widget.book.fileUrl!.isNotEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: _bronze, size: 52),
                  const SizedBox(height: 14),
                  const Text('This book is available as a reading file.', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => launchUrl(Uri.parse('${BackendApi.instance.baseUrl}${widget.book.fileUrl}'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const Text('Open book')),
                ]),
              ));
            }
            return const Center(child: Text('No reading content is available yet.', style: TextStyle(color: _muted)));
          }
          if (_currentChapter == null || _selectedIndex >= chapters.length) {
            _currentChapter = chapters[0];
            _selectedIndex = 0;
          }
          final chapter = _currentChapter!;
          final isLast = _selectedIndex >= chapters.length - 1;
          final isFirst = _selectedIndex <= 0;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chapter.title, style: const TextStyle(color: _ink, fontFamily: 'Georgia', fontSize: 26, height: 1.3, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Chapter ${chapter.chapterNumber}', style: const TextStyle(color: _muted, fontSize: 12.5, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 24),
                      const Divider(color: _line),
                      const SizedBox(height: 20),
                      Text(chapter.content ?? '', style: const TextStyle(color: _ink, fontFamily: 'Georgia', fontSize: 19, height: 1.9)),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(color: _ivory, border: Border(top: BorderSide(color: _line))),
                child: Row(
                  children: [
                    if (!isFirst)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _goTo(chapters, _selectedIndex - 1),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Previous'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            side: BorderSide(color: _line),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (!isFirst && !isLast) const SizedBox(width: 12),
                    if (!isLast)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _goTo(chapters, _selectedIndex + 1),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(isLast ? 'Finish' : 'Next'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _bronze,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goTo(List<BookChapterRead> chapters, int index) {
    if (index < 0 || index >= chapters.length) return;
    setState(() {
      _selectedIndex = index;
      _currentChapter = chapters[index];
    });
  }
}
