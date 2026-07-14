import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'family_models.dart';
import 'family_theme.dart';

class SharedGoalsScreen extends StatefulWidget {
  const SharedGoalsScreen({required this.id, super.key});

  final String id;

  @override
  State<SharedGoalsScreen> createState() => _SharedGoalsScreenState();
}

class _SharedGoalsScreenState extends State<SharedGoalsScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 500));
  FamilyJar? _jar;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    final goals = jar?.goals ?? [];
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _load,
          builder: (context, snap) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ScreenHeader(
                      title: 'Shared Goals',
                      subtitle: jar == null ? null : 'Grow toward them together',
                      action: IconButton(
                        onPressed: () => _showComingSoon(context, 'New Goal'),
                        icon: const Icon(Icons.add_circle_outline, color: fBronze),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
                if (snap.connectionState != ConnectionState.done)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(height: 160, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20)))))))
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
            );
          },
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
                decoration: BoxDecoration(color: goal.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.flag_outlined, size: 20, color: goal.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                    const SizedBox(height: 3),
                    Text(goal.subtitle, style: const TextStyle(fontSize: 11.5, color: fStoneLight)),
                  ],
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: goal.accent, fontFamily: 'Georgia')),
            ],
          ),
          const SizedBox(height: 16),
          // Editorial progress — a thin warm band, no numbers shouting.
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.circular(99)),
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
          const Text('Create a gentle intention your family can grow toward — together, one act at a time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String title) {
  showModalBottomSheet(
    context: context,
    backgroundColor: fIvory,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('This gentle flow is being crafted with care.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
          const SizedBox(height: 20),
          MizanButton(label: 'Close', onTap: () => context.pop()),
        ],
      ),
    ),
  );
}
