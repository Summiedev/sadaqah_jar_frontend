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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(charity == null ? 'Create Charity' : 'Edit Charity', style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      controller: nameController,
                      label: 'Name',
                      icon: Icons.store_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: websiteController,
                      label: 'Website URL',
                      icon: Icons.link,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: categoryController,
                      label: 'Category',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: verified,
                      onChanged: (value) => setDialogState(() => verified = value),
                      title: const Text('Verified', style: TextStyle(fontWeight: FontWeight.w600)),
subtitle: const Text('Mark as verified'),
                      activeThumbColor: kBronze,
                    ),
                    SwitchListTile(
                      value: active,
                      onChanged: (value) => setDialogState(() => active = value),
                      title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Whether the charity is currently active'),
                      activeThumbColor: kBronze,
                    ),
                    SwitchListTile(
                      value: featured,
                      onChanged: (value) => setDialogState(() => featured = value),
                      title: const Text('Featured', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Show in featured section'),
                      activeThumbColor: kBronze,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Please fill in all required fields'), backgroundColor: Colors.red),
                      );
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
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kBronze, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(charity == null ? 'Create' : 'Save', style: const TextStyle(color: Colors.white)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Deactivate charity?', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        content: Text('This will mark "${charity.name}" as inactive.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
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
      appBar: AppBar(
        title: const Text('Charities', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        backgroundColor: kClayLight,
        foregroundColor: kInk,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, color: kInk), tooltip: 'Refresh'),
        ],
      ),
      backgroundColor: kClayLight,
      body: FutureBuilder<AdminCharityPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kBronze));
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: kMuted)));
          }
          final page = snapshot.data;
          final rows = page?.data ?? const <AdminCharityRecord>[];
          if (rows.isEmpty) {
            return const Center(child: Text('No charities yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final charity = rows[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(charity.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                              const SizedBox(height: 2),
                              Text(charity.category ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
                            ],
                          ),
                        ),
                        if (charity.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Featured', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kBronze)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(charity.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted, height: 1.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatusChip(label: charity.isVerified ? 'Verified' : 'Unverified', active: charity.isVerified),
                        const SizedBox(width: 8),
                        _StatusChip(label: charity.isActive ? 'Active' : 'Inactive', active: charity.isActive),
                        const Spacer(),
                        IconButton(onPressed: () => _openForm(charity: charity), icon: const Icon(Icons.edit_outlined, size: 18, color: kBronze), tooltip: 'Edit'),
                        IconButton(onPressed: () => _confirmDelete(charity), icon: const Icon(Icons.delete_outline, size: 18, color: kDanger), tooltip: 'Delete'),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: kBronze,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? kSoftSage : kDraftBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? kSage : kDanger)),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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