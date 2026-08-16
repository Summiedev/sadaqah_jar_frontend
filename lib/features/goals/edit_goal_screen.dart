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

  @override
  void initState() {
    super.initState();
    final store = ref.read(actStoreProvider);
    _title.text = store.goalTitle ?? '';
    _target.text = '${store.goalTarget ?? 30}';
    _subtitle.text = store.goalSubtitle ?? '';
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
      await ref.read(actStoreProvider).updateGoal(title: _title.text.trim(), subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(), actsTarget: parsed);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Goal')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Goal title')),
            const SizedBox(height: 12),
            TextField(controller: _target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target count')),
            const SizedBox(height: 12),
            TextField(controller: _subtitle, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Subtitle / intention')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kDanger)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Save changes'),
            ),
          ]),
        ),
      ),
    );
  }
}
