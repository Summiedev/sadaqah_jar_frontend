import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/backend_api.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/mizan_async_state.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final goals = await BackendApi.instance.getFamilyGoals(familyId);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = backendErrorMessage(
          e,
          fallback: 'Could not load family goals. Please try again.',
        );
        _loading = false;
      });
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
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.colors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'New Goal',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: ctx.colors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal title',
                    hintText: 'e.g. Monthly Giving',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: actsTargetController,
                  decoration: const InputDecoration(labelText: 'Target acts'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: ctx.colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: Text(
                  'Create',
                  style: TextStyle(
                    color: ctx.colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );

    if (result != true) return;
    final title = titleController.text.trim();
    final subtitle = subtitleController.text.trim();
    final actsTarget = int.tryParse(actsTargetController.text.trim()) ?? 10;
    if (title.isEmpty) return;

    try {
      await BackendApi.instance.createFamilyGoal(
        familyId,
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        actsTarget: actsTarget,
      );
      if (!mounted) return;
      await _loadGoals();
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.colors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    final goals =
        _goals.isEmpty && !_loading
            ? jar?.goals ?? []
            : _goals.map((g) {
              final progress =
                  (g['acts_done'] as num? ?? 0) /
                  (g['acts_target'] as num? ?? 1);
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
      backgroundColor: context.colors.background,
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
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: context.colors.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: MizanLoadingState(label: 'Loading family goals...'),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: MizanErrorState(
                  title: 'Could not load goals',
                  message: _error!,
                  onRetry: _loadGoals,
                ),
              )
            else if (goals.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: MizanEmptyState(
                  title: 'No goals yet',
                  message:
                      'Create a gentle intention your family can grow toward, together.',
                  icon: Icons.flag_outlined,
                ),
              )
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
    final colors = context.colors;
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
                decoration: BoxDecoration(
                  color: goal.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.flag_outlined, size: 20, color: goal.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goal.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: goal.accent,
                  fontFamily: 'Georgia',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: goal.progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: goal.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${goal.actsDone} of ${goal.actsTarget} gentle acts offered',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
