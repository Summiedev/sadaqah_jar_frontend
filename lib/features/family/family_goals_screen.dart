import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/backend_api.dart';
import 'family_models.dart';
import 'family_theme.dart';

class SharedGoalsScreen extends StatefulWidget {
  const SharedGoalsScreen({required this.id, super.key});

  final String id;

  @override
  State<SharedGoalsScreen> createState() => _SharedGoalsScreenState();
}

class _SharedGoalsScreenState extends State<SharedGoalsScreen> {
  FamilyJar? _jar;
  List<Map<String, dynamic>> _goals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() { _loading = true; _error = null; });
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final goals = await BackendApi.instance.getFamilyGoals(familyId);
      if (!mounted) return;
      setState(() { _goals = goals; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createGoal() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;

    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final actsTargetController = TextEditingController(text: '10');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('New Goal', style: TextStyle(fontFamily: 'Georgia', fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Goal title', hintText: 'e.g. Monthly Giving')),
          const SizedBox(height: 12),
          TextField(controller: subtitleController, decoration: const InputDecoration(labelText: 'Subtitle (optional)')),
          const SizedBox(height: 12),
          TextField(controller: actsTargetController, decoration: const InputDecoration(labelText: 'Target acts'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel', style: TextStyle(color: fStone))),
          TextButton(onPressed: () => context.pop(true), child: const Text('Create', style: TextStyle(color: fBronze, fontWeight: FontWeight.w700))),
        ],
      ),
    );

    if (result != true) return;
    final title = titleController.text.trim();
    final subtitle = subtitleController.text.trim();
    final actsTarget = int.tryParse(actsTargetController.text.trim()) ?? 10;
    if (title.isEmpty) return;

    try {
      await BackendApi.instance.createFamilyGoal(familyId, title: title, subtitle: subtitle.isEmpty ? null : subtitle, actsTarget: actsTarget);
      if (!mounted) return;
      await _loadGoals();
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.brown));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    final goals = _goals.isEmpty && !_loading ? jar?.goals ?? [] : _goals.map((g) {
      final progress = (g['acts_done'] as num? ?? 0) / (g['acts_target'] as num? ?? 1);
      return FamilyGoal(
        id: g['id']?.toString() ?? '',
        title: g['title']?.toString() ?? '',
        subtitle: g['subtitle']?.toString() ?? '',
        progress: progress.toDouble(),
        actsDone: (g['acts_done'] as num?)?.toInt() ?? 0,
        actsTarget: (g['acts_target'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ScreenHeader(
                  title: 'Shared Goals',
                  subtitle: jar == null ? null : 'Grow toward them together',
                  action: IconButton(
                    onPressed: _createGoal,
                    icon: const Icon(Icons.add_circle_outline, color: fBronze),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(height: 160, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20)))))))
            else if (_error != null)
              SliverFillRemaining(child: _ErrorState(message: _error!, onRetry: _loadGoals))
            else if (goals.isEmpty)
              const SliverFillRemaining(child: _EmptyGoals())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _GoalCard(goal: goals[index]),
                    ),
                    childCount: goals.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final FamilyGoal goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: goal.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.flag_outlined, size: 20, color: goal.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                    const SizedBox(height: 3),
                    Text(goal.subtitle, style: const TextStyle(fontSize: 11.5, color: fStone)),
                  ],
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: goal.accent, fontFamily: 'Georgia')),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99)),
              ),
              FractionallySizedBox(
                widthFactor: goal.progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: goal.accent, borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${goal.actsDone} of ${goal.actsTarget} gentle acts offered', style: const TextStyle(fontSize: 11.5, color: fStone)),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
            child: const Center(child: Icon(Icons.flag_outlined, size: 38, color: fBronze)),
          ),
          const SizedBox(height: 18),
          const Text('No goals yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('Create a gentle intention your family can grow toward - together, one act at a time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: fBronze),
          const SizedBox(height: 18),
          const Text('Could not load goals', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
