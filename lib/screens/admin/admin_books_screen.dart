import 'package:flutter/material.dart';

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
              title: Text(book == null ? 'Add Book' : 'Edit Book'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author')),
                    TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                    TextField(controller: coverController, decoration: const InputDecoration(labelText: 'Cover URL (optional)')),
                    TextField(controller: languageController, decoration: const InputDecoration(labelText: 'Language')),
                    TextField(controller: sortController, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
                    SwitchListTile(
                      value: published,
                      onChanged: (value) => setDialogState(() => published = value),
                      title: const Text('Published'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final author = authorController.text.trim();
                    final category = categoryController.text.trim();
                    if (title.isEmpty || author.isEmpty || category.isEmpty) return;
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
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kBronze),
                  child: Text(book == null ? 'Create' : 'Save'),
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
        title: const Text('Delete book?'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await BackendApi.instance.deleteAdminBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book deleted')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
            return const Center(child: Text('No books yet. Tap + to add one.', style: TextStyle(color: kMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kPaper, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                child: Row(
                  children: [
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
