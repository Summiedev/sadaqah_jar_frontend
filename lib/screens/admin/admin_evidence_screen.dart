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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(evidence == null ? 'Add Evidence' : 'Edit Evidence', style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      controller: actIdController,
                      label: 'Act ID',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: sourceTypeController,
                      label: 'Source Type',
                      icon: Icons.source_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: referenceController,
                      label: 'Reference',
                      icon: Icons.link,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: gradeController,
                      label: 'Grade',
                      icon: Icons.star_outline,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: arabicController,
                      label: 'Arabic Text',
                      icon: Icons.text_fields,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: englishController,
                      label: 'English Text',
                      icon: Icons.translate,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: verified,
                      onChanged: (value) => setDialogState(() => verified = value),
                      title: const Text('Verified', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Mark as verified evidence'),
                      activeThumbColor: kBronze,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Please fill in all required fields'), backgroundColor: Colors.red),
                      );
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
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kBronze, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(evidence == null ? 'Create' : 'Save', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete evidence?', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        content: Text('This will remove evidence #${evidence.id}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
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
      appBar: AppBar(
        title: const Text('Evidence', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
        backgroundColor: kClayLight,
        foregroundColor: kInk,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, color: kInk), tooltip: 'Refresh'),
        ],
      ),
      backgroundColor: kClayLight,
      body: FutureBuilder<AdminEvidencePage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kBronze));
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: kMuted)));
          }
          final rows = snapshot.data?.data ?? const <AdminEvidenceRecord>[];
          if (rows.isEmpty) {
            return const Center(child: Text('No evidence yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final evidence = rows[index];
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: evidence.isVerified ? kSoftSage : kDraftBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(evidence.isVerified ? 'Verified' : 'Unverified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: evidence.isVerified ? kSage : kDanger)),
                        ),
                        const Spacer(),
                        IconButton(onPressed: () => _openForm(evidence: evidence), icon: const Icon(Icons.edit_outlined, size: 18, color: kBronze), tooltip: 'Edit'),
                        IconButton(onPressed: () => _confirmDelete(evidence), icon: const Icon(Icons.delete_outline, size: 18, color: kDanger), tooltip: 'Delete'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Act #${evidence.actId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 4),
                    Text('Source: ${evidence.sourceType}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    const SizedBox(height: 2),
                    Text('Reference: ${evidence.reference}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    if (evidence.arabicText != null && evidence.arabicText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(evidence.arabicText!, style: const TextStyle(fontSize: 13, color: kInk, fontStyle: FontStyle.italic)),
                    ],
                    if (evidence.englishText != null && evidence.englishText!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(evidence.englishText!, style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                    if (evidence.grade != null && evidence.grade!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Grade: ${evidence.grade}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kBronze)),
                    ],
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
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
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