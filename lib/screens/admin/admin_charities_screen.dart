import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class AdminCharitiesScreen extends StatefulWidget {
  const AdminCharitiesScreen({super.key});

  @override
  State<AdminCharitiesScreen> createState() => _AdminCharitiesScreenState();
}

class _AdminCharitiesScreenState extends State<AdminCharitiesScreen> {
  late Future<AdminCharityPage> _future = _load();

  Future<AdminCharityPage> _load() => BackendApi.instance.getAdminCharities(limit: 100, offset: 0);

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminCharityRecord? charity}) async {
    final nameController = TextEditingController(text: charity?.name ?? '');
    final websiteController = TextEditingController(text: charity?.websiteUrl ?? '');
    final descriptionController = TextEditingController(text: charity?.description ?? '');
    final categoryController = TextEditingController(text: charity?.category ?? '');
    bool verified = charity?.isVerified ?? true;
    bool active = charity?.isActive ?? true;
    bool featured = charity?.isFeatured ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(charity == null ? 'Create Charity' : 'Edit Charity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: websiteController, decoration: const InputDecoration(labelText: 'Website URL')),
                    TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      value: verified,
                      onChanged: (value) => setDialogState(() => verified = value),
                      title: const Text('Verified'),
                    ),
                    SwitchListTile(
                      value: active,
                      onChanged: (value) => setDialogState(() => active = value),
                      title: const Text('Active'),
                    ),
                    SwitchListTile(
                      value: featured,
                      onChanged: (value) => setDialogState(() => featured = value),
                      title: const Text('Featured'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final website = websiteController.text.trim();
                    if (name.isEmpty || website.isEmpty) {
                      return;
                    }
                    try {
                      if (charity == null) {
                        await BackendApi.instance.createAdminCharity(
                          name: name,
                          websiteUrl: website,
                          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                        );
                      } else {
                        await BackendApi.instance.updateAdminCharity(
                          charityId: charity.id,
                          name: name,
                          websiteUrl: website,
                          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                          isVerified: verified,
                          isActive: active,
                          isFeatured: featured,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                      }
                    }
                  },
                  child: Text(charity == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _refresh();
    }
  }

  Future<void> _confirmDelete(AdminCharityRecord charity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Deactivate charity?'),
        content: Text('This will mark "${charity.name}" as inactive.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    await BackendApi.instance.deleteAdminCharity(charity.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charities'), backgroundColor: kClayLight),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<AdminCharityPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final page = snapshot.data;
          final rows = page?.data ?? const <AdminCharityRecord>[];
          if (rows.isEmpty) {
            return const Center(child: Text('No charities yet.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Verified')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Featured')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map(
                      (charity) => DataRow(
                        cells: [
                          DataCell(Text(charity.name), onTap: () => _openForm(charity: charity)),
                          DataCell(Text(charity.category ?? '')),
                          DataCell(Text(charity.isVerified ? 'Yes' : 'No')),
                          DataCell(Text(charity.isActive ? 'Yes' : 'No')),
                          DataCell(Text(charity.isFeatured ? 'Yes' : 'No')),
                          DataCell(
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(onPressed: () => _openForm(charity: charity), child: const Text('Edit')),
                                TextButton(
                                  onPressed: () => BackendApi.instance.updateAdminCharity(
                                    charityId: charity.id,
                                    isFeatured: true,
                                  ).then((_) => _refresh()),
                                  child: const Text('Feature'),
                                ),
                                TextButton(
                                  onPressed: () => _confirmDelete(charity),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

