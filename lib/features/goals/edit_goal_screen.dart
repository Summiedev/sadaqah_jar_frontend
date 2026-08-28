import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/act_store.dart';
import '../../core/theme/app_theme.dart';

class EditGoalScreen extends ConsumerStatefulWidget {
  const EditGoalScreen({super.key});

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _subtitle = TextEditingController();
  bool _saving = false;
  String? _error;
  late final String _initialTitle;
  late final String _initialTarget;
  late final String _initialSubtitle;

  @override
  void initState() {
    super.initState();
    final store = ref.read(actStoreProvider);
    _title.text = store.goalTitle ?? '';
    _target.text = '${store.goalTarget ?? 30}';
    _subtitle.text = store.goalSubtitle ?? '';
    _initialTitle = _title.text;
    _initialTarget = _target.text;
    _initialSubtitle = _subtitle.text;
  }

  bool get _hasUnsavedChanges =>
      _title.text != _initialTitle ||
      _target.text != _initialTarget ||
      _subtitle.text != _initialSubtitle;

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your goal changes have not been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = int.tryParse(_target.text.trim());
    if (_title.text.trim().isEmpty || parsed == null || parsed <= 0) {
      setState(() => _error = 'Please provide a title and valid target');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(actStoreProvider)
          .updateGoal(
            title: _title.text.trim(),
            subtitle:
                _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
            actsTarget: parsed,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save changes: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Goal'),
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Goal title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _target,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target count'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subtitle,
                  onChanged: (_) => setState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle / intention',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: kDanger)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(),
                          )
                          : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
