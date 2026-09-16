import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../widgets/mizan_async_state.dart';
import '../../services/backend_api.dart';

class AdminEvidenceScreen extends StatefulWidget {
  const AdminEvidenceScreen({super.key});

  @override
  State<AdminEvidenceScreen> createState() => _AdminEvidenceScreenState();
}

class _AdminEvidenceScreenState extends State<AdminEvidenceScreen> {
  late Future<AdminEvidencePage> _future = _load();

  Future<AdminEvidencePage> _load() async {
    const pageSize = 100;
    var offset = 0;
    var total = 0;
    final records = <AdminEvidenceRecord>[];

    do {
      final page = await BackendApi.instance.getAdminEvidence(
        limit: pageSize,
        offset: offset,
      );
      records.addAll(page.data);
      total = page.total;
      offset += page.data.length;
      if (page.data.isEmpty) break;
    } while (offset < total);

    return AdminEvidencePage(
      total: total,
      limit: pageSize,
      offset: 0,
      data: records,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminEvidenceRecord? evidence}) async {
    final actIdController = TextEditingController(
      text: evidence?.actId.toString() ?? '',
    );
    final sourceTypeController = TextEditingController(
      text: evidence?.sourceType ?? '',
    );
    final referenceController = TextEditingController(
      text: evidence?.reference ?? '',
    );
    final arabicController = TextEditingController(
      text: evidence?.arabicText ?? '',
    );
    final englishController = TextEditingController(
      text: evidence?.englishText ?? '',
    );
    final gradeController = TextEditingController(text: evidence?.grade ?? '');
    bool verified = evidence?.isVerified ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                evidence == null ? 'Add Evidence' : 'Edit Evidence',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                      onChanged:
                          (value) => setDialogState(() => verified = value),
                      title: const Text(
                        'Verified',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Mark as verified evidence'),
                      activeThumbColor: context.colors.primary,
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
                    final actId = int.tryParse(actIdController.text.trim());
                    final sourceType = sourceTypeController.text.trim();
                    final reference = referenceController.text.trim();
                    if (actId == null ||
                        sourceType.isEmpty ||
                        reference.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Please fill in all required fields',
                          ),
                          backgroundColor: context.colors.error,
                        ),
                      );
                      return;
                    }
                    try {
                      if (evidence == null) {
                        await BackendApi.instance.createAdminEvidence(
                          actId: actId,
                          sourceType: sourceType,
                          reference: reference,
                          arabicText:
                              arabicController.text.trim().isEmpty
                                  ? null
                                  : arabicController.text.trim(),
                          englishText:
                              englishController.text.trim().isEmpty
                                  ? null
                                  : englishController.text.trim(),
                          grade:
                              gradeController.text.trim().isEmpty
                                  ? null
                                  : gradeController.text.trim(),
                        );
                      } else {
                        await BackendApi.instance.updateAdminEvidence(
                          evidenceId: evidence.id,
                          actId: actId,
                          sourceType: sourceType,
                          reference: reference,
                          arabicText:
                              arabicController.text.trim().isEmpty
                                  ? null
                                  : arabicController.text.trim(),
                          englishText:
                              englishController.text.trim().isEmpty
                                  ? null
                                  : englishController.text.trim(),
                          grade:
                              gradeController.text.trim().isEmpty
                                  ? null
                                  : gradeController.text.trim(),
                          isVerified: verified,
                        );
                      }
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              backendErrorMessage(
                                error,
                                fallback: 'Could not save evidence.',
                              ),
                            ),
                            backgroundColor: context.colors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    evidence == null ? 'Create' : 'Save',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Delete evidence?',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text('This will remove evidence #${evidence.id}.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: context.colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await BackendApi.instance.deleteAdminEvidence(evidence.id);
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendErrorMessage(
              error,
              fallback: 'Could not delete evidence.',
            ),
          ),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evidence',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded, color: colors.iconPrimary),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: colors.background,
      body: FutureBuilder<AdminEvidencePage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }
          if (snapshot.hasError) {
            return MizanErrorState(
              message: backendErrorMessage(
                snapshot.error,
                fallback: 'We could not load evidence right now.',
              ),
              onRetry: _refresh,
            );
          }
          final rows = snapshot.data?.data ?? const <AdminEvidenceRecord>[];
          if (rows.isEmpty) {
            return const MizanEmptyState(
              icon: Icons.verified_outlined,
              title: 'No evidence yet',
              message: 'Verified evidence added by admins will appear here.',
            );
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
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: colors.scrim.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                evidence.isVerified
                                    ? colors.successContainer
                                    : colors.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            evidence.isVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: evidence.isVerified
                                  ? colors.success
                                  : colors.error,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _openForm(evidence: evidence),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(evidence),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: colors.error,
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Act #${evidence.actId}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${evidence.sourceType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reference: ${evidence.reference}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (evidence.arabicText != null &&
                        evidence.arabicText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        evidence.arabicText!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (evidence.englishText != null &&
                        evidence.englishText!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        evidence.englishText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (evidence.grade != null &&
                        evidence.grade!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Grade: ${evidence.grade}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
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
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
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
    final colors = context.colors;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        filled: true,
        fillColor: colors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.inputFocusedBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
