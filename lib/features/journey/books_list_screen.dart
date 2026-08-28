import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import 'book_reader_screen.dart';

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.colors.iconPrimary,
          ),
        ),
        title: Text(
          'Library',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: context.colors.iconPrimary,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<BookRead>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load books. Please try again.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Text(
                'No books available yet.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final book = books[index];
              final format = (book.fileFormat ?? '').toUpperCase();
              final meta =
                  book.pageCount > 0
                      ? '${book.pageCount} pages'
                      : (book.chapterCount ?? 0) > 0
                      ? '${book.chapterCount} chapters'
                      : format.isNotEmpty
                      ? format
                      : 'Preparing';
              return Material(
                color: context.colors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookReaderScreen(book: book),
                        ),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 68,
                          decoration: BoxDecoration(
                            color: kSoftBronze,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.border),
                          ),
                          child:
                              book.coverUrl != null && book.coverUrl!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      book.coverUrl!,
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 68,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.menu_book_rounded,
                                            color: context.colors.primary,
                                            size: 28,
                                          ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.menu_book_rounded,
                                    color: context.colors.primary,
                                    size: 28,
                                  ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontFamily: 'Georgia',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (book.description != null &&
                                  book.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  book.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    height: 1.5,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.successContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      meta,
                                      style: TextStyle(
                                        color: context.colors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if ((book.totalReadingTime ?? 0) > 0)
                                    Text(
                                      '${book.totalReadingTime ?? 0} min',
                                      style: TextStyle(
                                        color: context.colors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.iconSecondary,
                          size: 18,
                        ),
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
