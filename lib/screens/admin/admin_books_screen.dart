import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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

  Future<AdminBookPage> _load() =>
      BackendApi.instance.getAdminBooks(limit: 100, offset: 0);

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
            content: Text('Upload failed: $e'),
            backgroundColor: kDanger,
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
                style: FilledButton.styleFrom(backgroundColor: kDanger),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    await BackendApi.instance.deleteAdminBook(book.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book deleted.')));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Books',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            return const Center(
              child: CircularProgressIndicator(color: kBronze),
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              return GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoColumns ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 236,
                ),
                itemCount: books.length,
                itemBuilder:
                    (context, index) => _BookCard(
                      book: books[index],
                      busy: _busyBooks.contains(books[index].id),
                      onEdit: () => _openForm(book: books[index]),
                      onPreview:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => BookReaderScreen(
                                    book: books[index].asBookRead(),
                                    adminPreview: true,
                                  ),
                            ),
                          ),
                      onDelete: () => _delete(books[index]),
                      onUploadPdf: () => _replaceFile(books[index], 'pdf'),
                      onUploadEpub: () => _replaceFile(books[index], 'epub'),
                      onUploadImages:
                          () => _replaceFile(books[index], 'images'),
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kBronze,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
  final text = error?.toString() ?? '';
  if (text.contains('BackendApiException(500')) {
    return 'The books service is unavailable. Make sure the latest backend migrations have run, then refresh.';
  }
  return 'Check your connection and try again.';
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
        const SnackBar(
          content: Text('Title, author, and category are required.'),
          backgroundColor: kDanger,
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
        const SnackBar(
          content: Text(
            'Select a PDF, EPUB, or ordered page images before creating a book.',
          ),
          backgroundColor: kDanger,
        ),
      );
      return;
    }
    if (_published && !selectedReadableFile && !existingReadableFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload readable content before publishing this book.'),
          backgroundColor: kDanger,
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
            content: Text('Could not save book: $e'),
            backgroundColor: kDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: kLine,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.book == null ? 'Upload Book' : 'Edit Book',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: kInk,
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
                  const LinearProgressIndicator(color: kBronze),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: kMuted,
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
                    backgroundColor: kBronze,
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
    final format = (book.fileFormat ?? 'no file').toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
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
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        color: kInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kBronze,
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
                          book.published ? kSage : kDanger,
                        ),
                        _Chip(format, kBronze),
                        if (book.pageCount > 0)
                          _Chip('${book.pageCount} pages', kSage),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: kBronze),
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
                icon: const Icon(Icons.upload_file_rounded, color: kSage),
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
                icon: const Icon(Icons.delete_outline, color: kDanger),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54,
        height: 72,
        color: kSoftBronze,
        child:
            url == null || url!.isEmpty
                ? const Icon(Icons.menu_book_rounded, color: kBronze)
                : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.menu_book_rounded, color: kBronze),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kBronze),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kBronze, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
