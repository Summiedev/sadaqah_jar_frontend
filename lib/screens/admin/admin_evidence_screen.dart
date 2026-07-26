import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class AdminEvidenceScreen extends StatefulWidget {
  const AdminEvidenceScreen({super.key});

  @override
  State<AdminEvidenceScreen> createState() => _AdminEvidenceScreenState();
}

class _AdminEvidenceScreenState extends State<AdminEvidenceScreen> {
  late Future<AdminEvidencePage> _future = _load();

  Future<AdminEvidencePage> _load() => BackendApi.instance.getAdminEvidence(limit: 100, offset: 0);

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminEvidenceRecord? evidence}) async {
    final actIdController = TextEditingController(text: evidence?.actId.toString() ?? '');
    final sourceTypeController = TextEditingController(text: evidence?.sourceType ?? '');
    final referenceController = TextEditingController(text: evidence?.reference ?? '');
    final arabicController = TextEditingController(text: evidence?.arabicText ?? '');
    final englishController = TextEditingController(text: evidence?.englishText ?? '');
    final gradeController = TextEditingController(text: evidence?.grade ?? '');
    bool verified = evidence?.isVerified ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(evidence == null ? 'Add Evidence' : 'Edit Evidence'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: actIdController, decoration: const InputDecoration(labelText: 'Act ID'), keyboardType: TextInputType.number),
                    TextField(controller: sourceTypeController, decoration: const InputDecoration(labelText: 'Source Type')),
                    TextField(controller: referenceController, decoration: const InputDecoration(labelText: 'Reference')),
                    TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'Grade')),
                    TextField(controller: arabicController, decoration: const InputDecoration(labelText: 'Arabic text'), maxLines: 3),
                    TextField(controller: englishController, decoration: const InputDecoration(labelText: 'English text'), maxLines: 3),
                    SwitchListTile(
                      value: verified,
                      onChanged: (value) => setDialogState(() => verified = value),
                      title: const Text('Verified'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final actId = int.tryParse(actIdController.text.trim());
                    final sourceType = sourceTypeController.text.trim();
                    final reference = referenceController.text.trim();
                    if (actId == null || sourceType.isEmpty || reference.isEmpty) {
                      return;
                    }
                    try {
                      if (evidence == null) {
                        await BackendApi.instance.createAdminEvidence(
                          actId: actId,
                          sourceType: sourceType,
                          reference: reference,
                          arabicText: arabicController.text.trim().isEmpty ? null : arabicController.text.trim(),
                          englishText: englishController.text.trim().isEmpty ? null : englishController.text.trim(),
                          grade: gradeController.text.trim().isEmpty ? null : gradeController.text.trim(),
                        );
                      } else {
                        await BackendApi.instance.updateAdminEvidence(
                          evidenceId: evidence.id,
                          actId: actId,
                          sourceType: sourceType,
                          reference: reference,
                          arabicText: arabicController.text.trim().isEmpty ? null : arabicController.text.trim(),
                          englishText: englishController.text.trim().isEmpty ? null : englishController.text.trim(),
                          grade: gradeController.text.trim().isEmpty ? null : gradeController.text.trim(),
                          isVerified: verified,
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
                  child: Text(evidence == null ? 'Create' : 'Save'),
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

  Future<void> _confirmDelete(AdminEvidenceRecord evidence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete evidence?'),
        content: Text('This will remove evidence #${evidence.id}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await BackendApi.instance.deleteAdminEvidence(evidence.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence'), backgroundColor: kClayLight),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<AdminEvidencePage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final rows = snapshot.data?.data ?? const <AdminEvidenceRecord>[];
          if (rows.isEmpty) {
            return const Center(child: Text('No evidence yet.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Act')),
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Reference')),
                  DataColumn(label: Text('Verified')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map(
                      (evidence) => DataRow(
                        cells: [
                          DataCell(Text('#${evidence.actId}'), onTap: () => _openForm(evidence: evidence)),
                          DataCell(Text(evidence.sourceType)),
                          DataCell(Text(evidence.reference)),
                          DataCell(Text(evidence.isVerified ? 'Yes' : 'No')),
                          DataCell(
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(onPressed: () => _openForm(evidence: evidence), child: const Text('Edit')),
                                TextButton(onPressed: () => _confirmDelete(evidence), child: const Text('Delete')),
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

