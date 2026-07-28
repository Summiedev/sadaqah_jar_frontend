import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  late Future<AdminBookPage> _future = _load();

  Future<AdminBookPage> _load() => BackendApi.instance.getAdminBooks(limit: 100, offset: 0);

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminBookRecord? book}) async {
    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final descriptionController = TextEditingController(text: book?.description ?? '');
    final coverController = TextEditingController(text: book?.coverUrl ?? '');
    final categoryController = TextEditingController(text: book?.category ?? '');
    final languageController = TextEditingController(text: book?.language ?? 'en');
    bool published = book?.published ?? true;
    final sortController = TextEditingController(text: '${book?.sortOrder ?? 0}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(book == null ? 'Add Book' : 'Edit Book', style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      controller: titleController,
                      label: 'Title',
                      icon: Icons.title,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: authorController,
                      label: 'Author',
                      icon: Icons.person_outline,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: categoryController,
                      label: 'Category',
                      icon: Icons.category_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: coverController,
                      label: 'Cover URL (optional)',
                      icon: Icons.image_outlined,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            controller: languageController,
                            label: 'Language',
                            icon: Icons.language,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _FormField(
                            controller: sortController,
                            label: 'Sort Order',
                            icon: Icons.sort,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: published,
                      onChanged: (value) => setDialogState(() => published = value),
                      title: const Text('Published', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Whether the book is visible to all users'),
                      activeThumbColor: kBronze,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final author = authorController.text.trim();
                    final category = categoryController.text.trim();
                    if (title.isEmpty || author.isEmpty || category.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Please fill in all required fields'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    try {
                      if (book == null) {
                        await BackendApi.instance.createAdminBook(
                          title: title,
                          author: author,
                          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          coverUrl: coverController.text.trim().isEmpty ? null : coverController.text.trim(),
                          category: category,
                          language: languageController.text.trim().isEmpty ? 'en' : languageController.text.trim(),
                          published: published,
                          sortOrder: int.tryParse(sortController.text.trim()) ?? 0,
                        );
                      } else {
                        await BackendApi.instance.updateAdminBook(
                          book.id,
                          title: title,
                          author: author,
                          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          coverUrl: coverController.text.trim().isEmpty ? null : coverController.text.trim(),
                          category: category,
                          language: languageController.text.trim().isEmpty ? 'en' : languageController.text.trim(),
                          published: published,
                          sortOrder: int.tryParse(sortController.text.trim()) ?? 0,
                        );
                      }
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kBronze, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(book == null ? 'Create' : 'Save', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _delete(AdminBookRecord book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete book?', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${book.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await BackendApi.instance.deleteAdminBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book deleted'), backgroundColor: kBronze));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _uploadBookFile(AdminBookRecord book) async {
    final selection = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: const ['pdf', 'epub', 'txt', 'md']);
    final file = selection?.files.single;
    if (file == null || file.bytes == null) return;
    try {
      await BackendApi.instance.uploadAdminBookFile(bookId: book.id, bytes: file.bytes!, filename: file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading file uploaded and ready for users.')));
        _refresh();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please use a file smaller than 25 MB.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books', style: TextStyle(color: kInk, fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        backgroundColor: kIvory,
        foregroundColor: kInk,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: kInk),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: kIvory,
      body: FutureBuilder<AdminBookPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBronze));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: kMuted)));
          }
          final books = snapshot.data?.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: kClay),
                  const SizedBox(height: 16),
                  Text('No books yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kMuted, fontFamily: 'Georgia')),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to add your first book.', style: TextStyle(color: kMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kSoftBronze.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_outlined, color: kBronze, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: const TextStyle(color: kInk, fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(book.author, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: book.published ? kSoftSage : kDraftBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(book.published ? 'Published' : 'Draft', style: TextStyle(color: book.published ? kSage : kDanger, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Text(book.category, style: const TextStyle(color: kMuted, fontSize: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _uploadBookFile(book),
                      icon: Icon(book.fileUrl == null ? Icons.upload_file_outlined : Icons.file_present_rounded, color: kSage),
                      tooltip: book.fileUrl == null ? 'Upload PDF, EPUB, TXT, or Markdown' : 'Replace reading file',
                    ),
                    IconButton(
                      onPressed: () => _openForm(book: book),
                      icon: const Icon(Icons.edit_outlined, color: kBronze),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _delete(book),
                      icon: const Icon(Icons.delete_outline, color: kDanger),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kBronze,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: const TextStyle(color: kMuted),
        prefixIcon: Icon(icon, size: 20, color: kBronze),
        filled: true,
        fillColor: kClayPale,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kClay)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kClay)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kBronze)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
