import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backend_api.dart';
import 'book_reader_screen.dart';

const _ivory = Color(0xFFF5EDE1);
const _paper = Color(0xFFFFFBF6);
const _ink = Color(0xFF30241E);
const _muted = Color(0xFF756457);
const _bronze = Color(0xFF92704B);
const _line = Color(0xFFE4D5C3);
const _softBronze = Color(0xFFF0E3D4);
const _sage = Color(0xFF6D8D72);
const _softSage = Color(0xFFDCE7D8);

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  late Future<List<BookRead>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getBooks();
  }

  void _refresh() {
    setState(() {
      _future = BackendApi.instance.getBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      appBar: AppBar(
        backgroundColor: _ivory,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        title: const Text('Library', style: TextStyle(color: _ink, fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: _ink),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<BookRead>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _bronze));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load books: ${snapshot.error}', style: const TextStyle(color: _muted)));
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(child: Text('No books available yet.', style: TextStyle(color: _muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final book = books[index];
              return Material(
                color: _paper,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 68,
                          decoration: BoxDecoration(
                            color: _softBronze,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _line),
                          ),
                          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(book.coverUrl!, fit: BoxFit.cover, width: 52, height: 68, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded, color: _bronze, size: 28)),
                                )
                              : const Icon(Icons.menu_book_rounded, color: _bronze, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title, style: const TextStyle(color: _ink, fontFamily: 'Georgia', fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(book.author, style: const TextStyle(color: _bronze, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              if (book.description != null && book.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(book.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, height: 1.5, fontSize: 12.5)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _softSage, borderRadius: BorderRadius.circular(8)),
                                    child: Text('${book.chapterCount} chapters', style: const TextStyle(color: _sage, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${book.totalReadingTime} min', style: const TextStyle(color: _muted, fontSize: 11.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A8A7A), size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
