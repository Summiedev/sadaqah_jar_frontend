import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../features/journey/book_reader_screen.dart';
import '../../services/backend_api.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  late Future<AdminBookPage> _future = _load();
  final Set<int> _busyBooks = {};
  final TextEditingController _searchController = TextEditingController();
  String _publicationFilter = 'all';
  String _sort = 'recent';

  Future<AdminBookPage> _load() async {
    const pageSize = 200;
    var offset = 0;
    var total = 0;
    final books = <AdminBookRecord>[];
    do {
      final page = await BackendApi.instance.getAdminBooks(
        limit: pageSize,
        offset: offset,
      );
      total = page.total;
      books.addAll(page.data);
      if (page.data.isEmpty) break;
      offset += page.data.length;
    } while (books.length < total);
    return AdminBookPage(
      total: total,
      limit: books.length,
      offset: 0,
      data: books,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminBookRecord? book}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookEditorSheet(book: book),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _replaceFile(AdminBookRecord book, String format) async {
    final extensions =
        format == 'images' ? const ['jpg', 'jpeg', 'png'] : <String>[format];
    final selection = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: format == 'images',
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (selection == null) return;
    setState(() => _busyBooks.add(book.id));
    try {
      if (format == 'images') {
        final files =
            selection.files
                .where((file) => file.bytes != null)
                .map(
                  (file) =>
                      PickedUploadFile(filename: file.name, bytes: file.bytes!),
                )
                .toList();
        if (files.isEmpty) throw Exception('No page images selected');
        await BackendApi.instance.uploadAdminBookPages(
          bookId: book.id,
          files: files,
        );
      } else {
        final file = selection.files.single;
        if (file.bytes == null) throw Exception('Could not read selected file');
        await BackendApi.instance.uploadAdminBookFile(
          bookId: book.id,
          bytes: file.bytes!,
          filename: file.name,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book file updated.')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(e, fallback: 'Could not update book file.'),
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyBooks.remove(book.id));
    }
  }

  Future<void> _delete(AdminBookRecord book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete book?',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              book.published
                  ? 'This book is published. Deleting it will remove it from readers immediately.'
                  : 'Delete "${book.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await BackendApi.instance.deleteAdminBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book deleted.')));
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(error, fallback: 'Could not delete book.'),
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'Books',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<AdminBookPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load books',
              body: _adminBookError(snapshot.error),
            );
          }
          final books = snapshot.data?.data ?? [];
          if (books.isEmpty) {
            return const _EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No books yet',
              body:
                  'Create a book, upload its reading file, then publish it when ready.',
            );
          }
          final query = _searchController.text.trim().toLowerCase();
          final filteredBooks = books.where((book) {
            final matchesQuery = query.isEmpty ||
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.category.toLowerCase().contains(query);
            final matchesStatus = _publicationFilter == 'all' ||
                (_publicationFilter == 'published' && book.published) ||
                (_publicationFilter == 'draft' && !book.published);
            return matchesQuery && matchesStatus;
          }).toList();
          filteredBooks.sort((a, b) {
            switch (_sort) {
              case 'title':
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              case 'oldest':
                return a.id.compareTo(b.id);
              default:
                return b.id.compareTo(a.id);
            }
          });
          return LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Search title, author, or category',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _publicationFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(value: 'published', child: Text('Published')),
                            DropdownMenuItem(value: 'draft', child: Text('Drafts')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _publicationFilter = value);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Sort books',
                          child: DropdownButton<String>(
                            value: _sort,
                            items: const [
                              DropdownMenuItem(value: 'recent', child: Text('Recent')),
                              DropdownMenuItem(value: 'title', child: Text('Title')),
                              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _sort = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredBooks.isEmpty
                        ? const _EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching books',
                            body: 'Try a different search or publication filter.',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(18),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: twoColumns ? 2 : 1,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 236,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) => _BookCard(
                              book: filteredBooks[index],
                              busy: _busyBooks.contains(filteredBooks[index].id),
                              onEdit: () => _openForm(book: filteredBooks[index]),
                              onPreview: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookReaderScreen(
                                    book: filteredBooks[index].asBookRead(),
                                    adminPreview: true,
                                  ),
                                ),
                              ),
                              onDelete: () => _delete(filteredBooks[index]),
                              onUploadPdf: () => _replaceFile(filteredBooks[index], 'pdf'),
                              onUploadEpub: () => _replaceFile(filteredBooks[index], 'epub'),
                              onUploadImages: () => _replaceFile(filteredBooks[index], 'images'),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload Book'),
      ),
    );
  }
}

extension on AdminBookRecord {
  BookRead asBookRead() => BookRead(
    id: id,
    title: title,
    author: author,
    description: description,
    coverUrl: coverUrl,
    fileUrl: fileUrl,
    fileFormat: fileFormat,
    fileType: fileType,
    category: category,
    language: language,
    published: published,
    pageCount: pageCount,
  );
}

String _adminBookError(Object? error) {
  if (error is BackendApiException && error.statusCode >= 500) {
    return 'The books service is unavailable. Make sure the latest backend migrations have run, then refresh.';
  }
  return backendErrorMessage(
    error,
    fallback: 'We could not load the books right now. Please try again.',
  );
}

class _BookEditorSheet extends StatefulWidget {
  const _BookEditorSheet({this.book});

  final AdminBookRecord? book;

  @override
  State<_BookEditorSheet> createState() => _BookEditorSheetState();
}

class _BookEditorSheetState extends State<_BookEditorSheet> {
  late final _title = TextEditingController(text: widget.book?.title ?? '');
  late final _author = TextEditingController(text: widget.book?.author ?? '');
  late final _description = TextEditingController(
    text: widget.book?.description ?? '',
  );
  late final _category = TextEditingController(
    text: widget.book?.category ?? '',
  );
  late final _language = TextEditingController(
    text: widget.book?.language ?? 'en',
  );
  late final _sort = TextEditingController(
    text: '${widget.book?.sortOrder ?? 0}',
  );
  bool _published = false;
  String _format = 'pdf';
  PlatformFile? _bookFile;
  PlatformFile? _coverFile;
  List<PlatformFile> _pageFiles = [];
  String _status = 'Ready';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _published = widget.book?.published ?? false;
    _format =
        widget.book?.fileFormat == 'epub'
            ? 'epub'
            : widget.book?.fileFormat == 'images'
            ? 'images'
            : 'pdf';
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    _category.dispose();
    _language.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (result != null) setState(() => _coverFile = result.files.single);
  }

  Future<void> _pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: _format == 'images',
      type: FileType.custom,
      allowedExtensions:
          _format == 'images' ? const ['jpg', 'jpeg', 'png'] : [_format],
    );
    if (result == null) return;
    setState(() {
      if (_format == 'images') {
        _pageFiles = result.files;
        _bookFile = null;
      } else {
        _bookFile = result.files.single;
        _pageFiles = [];
      }
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final author = _author.text.trim();
    final category = _category.text.trim();
    if (title.isEmpty || author.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Title, author, and category are required.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    final selectedReadableFile =
        _format == 'images'
            ? _pageFiles.any((file) => file.bytes != null)
            : _bookFile?.bytes != null;
    final existingReadableFile =
        widget.book?.fileUrl?.isNotEmpty == true ||
        (widget.book?.pageCount ?? 0) > 0;
    if (widget.book == null && !selectedReadableFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select a PDF, EPUB, or ordered page images before creating a book.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    if (_published && !selectedReadableFile && !existingReadableFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload readable content before publishing this book.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _status = 'Saving book details';
    });
    try {
      final creating = widget.book == null;
      final book =
          creating
              ? await BackendApi.instance.createAdminBook(
                title: title,
                author: author,
                description:
                    _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                category: category,
                language:
                    _language.text.trim().isEmpty
                        ? 'en'
                        : _language.text.trim(),
                published: false,
                sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
              )
              : await BackendApi.instance.updateAdminBook(
                widget.book!.id,
                title: title,
                author: author,
                description:
                    _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                category: category,
                language:
                    _language.text.trim().isEmpty
                        ? 'en'
                        : _language.text.trim(),
                published: _published,
                sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
              );
      if (_coverFile?.bytes != null) {
        setState(() => _status = 'Uploading cover image');
        await BackendApi.instance.uploadAdminBookCover(
          bookId: book.id,
          bytes: _coverFile!.bytes!,
          filename: _coverFile!.name,
        );
      }
      if (_format == 'images' && _pageFiles.isNotEmpty) {
        setState(() => _status = 'Uploading ${_pageFiles.length} page images');
        final files =
            _pageFiles
                .where((file) => file.bytes != null)
                .map(
                  (file) =>
                      PickedUploadFile(filename: file.name, bytes: file.bytes!),
                )
                .toList();
        await BackendApi.instance.uploadAdminBookPages(
          bookId: book.id,
          files: files,
        );
      } else if (_bookFile?.bytes != null) {
        setState(() => _status = 'Uploading ${_format.toUpperCase()} file');
        await BackendApi.instance.uploadAdminBookFile(
          bookId: book.id,
          bytes: _bookFile!.bytes!,
          filename: _bookFile!.name,
        );
      }
      if (creating && _published) {
        setState(() => _status = 'Publishing book');
        await BackendApi.instance.updateAdminBook(book.id, published: true);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Failed. Check the file type and try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(e, fallback: 'Could not save book.'),
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final selectedLabel =
        _format == 'images'
            ? (_pageFiles.isEmpty
                ? 'No page images selected'
                : '${_pageFiles.length} ordered page images selected')
            : (_bookFile?.name ?? 'No ${_format.toUpperCase()} selected');
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder:
          (context, controller) => Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
              color: colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.book == null ? 'Upload Book' : 'Edit Book',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _title,
                  label: 'Title',
                  icon: Icons.title_rounded,
                ),
                _Field(
                  controller: _author,
                  label: 'Author',
                  icon: Icons.person_outline_rounded,
                ),
                _Field(
                  controller: _category,
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),
                _Field(
                  controller: _description,
                  label: 'Description',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _language,
                        label: 'Language',
                        icon: Icons.language_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        controller: _sort,
                        label: 'Sort',
                        icon: Icons.sort_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in const ['pdf', 'epub', 'images'])
                      ChoiceChip(
                        label: Text(format.toUpperCase()),
                        selected: _format == format,
                        onSelected: (_) => setState(() => _format = format),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickCover,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_coverFile?.name ?? 'Select cover image'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickBookFile,
                  icon: Icon(
                    _format == 'images'
                        ? Icons.photo_library_outlined
                        : Icons.upload_file_rounded,
                  ),
                  label: Text(selectedLabel, overflow: TextOverflow.ellipsis),
                ),
                SwitchListTile(
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
                  title: const Text('Published'),
                  subtitle: const Text('Visible to readers'),
                ),
                if (_saving) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(color: colors.primary),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    widget.book == null ? 'Create and upload' : 'Save changes',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.busy,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
    required this.onUploadPdf,
    required this.onUploadEpub,
    required this.onUploadImages,
  });

  final AdminBookRecord book;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onUploadPdf;
  final VoidCallback onUploadEpub;
  final VoidCallback onUploadImages;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final format = (book.fileFormat ?? 'no file').toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Cover(url: book.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          book.published ? 'Published' : 'Draft',
                          book.published ? colors.success : colors.error,
                        ),
                        _Chip(format, colors.primary),
                        if (book.pageCount > 0)
                            _Chip('${book.pageCount} pages', colors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(color: colors.primary),
          ],
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Preview',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              PopupMenuButton<String>(
                tooltip: 'Replace file',
                padding: EdgeInsets.zero,
                iconSize: 22,
                icon: Icon(Icons.upload_file_rounded, color: colors.success),
                onSelected:
                    (value) =>
                        value == 'pdf'
                            ? onUploadPdf()
                            : value == 'epub'
                            ? onUploadEpub()
                            : onUploadImages(),
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'pdf', child: Text('Replace PDF')),
                      PopupMenuItem(value: 'epub', child: Text('Replace EPUB')),
                      PopupMenuItem(
                        value: 'images',
                        child: Text('Replace page images'),
                      ),
                    ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colors.error),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54,
        height: 72,
        color: colors.primaryContainer,
        child:
            url == null || url!.isEmpty
                ? Icon(Icons.menu_book_rounded, color: colors.primary)
                : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          Icon(Icons.menu_book_rounded, color: colors.primary),
                ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Georgia',
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
