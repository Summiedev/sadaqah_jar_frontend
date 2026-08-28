import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'goal_providers.dart';

class MonthlyReviewScreen extends ConsumerStatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  ConsumerState<MonthlyReviewScreen> createState() =>
      _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends ConsumerState<MonthlyReviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _goalsData;
  int _streak = 0;
  String? _selectedAction;
  final _notesController = TextEditingController();

  static const _actions = [
    {
      'value': 'continued',
      'label': 'Continue with my goals',
      'icon': Icons.check_circle_outline,
    },
    {
      'value': 'modified',
      'label': 'Adjust my goals',
      'icon': Icons.tune_rounded,
    },
    {
      'value': 'replaced',
      'label': 'Set new goals',
      'icon': Icons.refresh_rounded,
    },
    {
      'value': 'skipped',
      'label': 'Skip this month',
      'icon': Icons.skip_next_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final goals = await BackendApi.instance.getGoals(month: _currentMonth);
      final streak = await BackendApi.instance.getStreak();
      if (mounted) {
        setState(() {
          _goalsData = goals;
          _streak = streak.currentStreak;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _goalsData = {};
        });
    }
  }

  String get _currentMonth {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  String get _monthLabel {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[now.month - 1];
  }

  int get _activeGoals {
    if (_goalsData == null) return 0;
    return (_goalsData!['active_count'] as num?)?.toInt() ?? 0;
  }

  int get _completedGoals {
    if (_goalsData == null) return 0;
    return (_goalsData!['completed_count'] as num?)?.toInt() ?? 0;
  }

  int get _totalActs {
    if (_goalsData == null) return 0;
    final goals = _goalsData!['goals'] as List? ?? [];
    int total = 0;
    for (final g in goals) {
      total += (g['acts_done'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Future<void> _submitReview() async {
    if (_selectedAction == null) return;
    setState(() => _submitting = true);

    try {
      await BackendApi.instance.submitMonthlyReview(
        actionTaken: _selectedAction,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        goalsCompleted: _completedGoals,
        goalsActive: _activeGoals,
        totalActsDone: _totalActs,
        streakAtReview: _streak,
      );
      await saveLastMonthlyReview(_currentMonth);
      if (mounted) {
        ref.read(monthlyReviewShownProvider.notifier).state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your monthly review was saved.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save review: $e'),
            backgroundColor: Colors.brown,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'MIZAN',
                      style: TextStyle(
                        color: kBronze,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 3.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: kMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(color: kBronze),
                        )
                        : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                'Your $_monthLabel review',
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 28,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a moment to reflect on your journey this month.',
                                style: const TextStyle(
                                  color: kMuted,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Stats cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.flag_outlined,
                                      label: 'Active goals',
                                      value: '$_activeGoals',
                                      color: kBronze,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.check_circle_outline,
                                      label: 'Completed',
                                      value: '$_completedGoals',
                                      color: kSage,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.favorite_outline,
                                      label: 'Total acts',
                                      value: '$_totalActs',
                                      color: kBronze,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatCard(
                                      icon:
                                          Icons.local_fire_department_outlined,
                                      label: 'Day streak',
                                      value: '$_streak',
                                      color: kDanger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              // Celebration if goals completed
                              if (_completedGoals > 0) ...[
                                FadeScaleTransition(
                                  beginScale: 0.95,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: kSage.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: kSage.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: kSage.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.celebration_outlined,
                                            color: kSage,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Goals completed!',
                                                style: TextStyle(
                                                  color: kInk,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _completedGoals == 1
                                                    ? 'You completed 1 goal this month. Masha\'Allah!'
                                                    : 'You completed $_completedGoals goals this month. Masha\'Allah!',
                                                style: const TextStyle(
                                                  color: kMuted,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // What's next
                              const Text(
                                'What would you like to do next?',
                                style: TextStyle(
                                  color: kInk,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_actions.length, (index) {
                                final action = _actions[index];
                                final isSelected =
                                    _selectedAction == action['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: isSelected ? kClayLight : kPaper,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedAction =
                                                    action['value'] as String,
                                          ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected ? kBronze : kClay,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              action['icon'] as IconData,
                                              color: kBronze,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                action['label'] as String,
                                                style: TextStyle(
                                                  color: kInk,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              isSelected
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_off,
                                              color:
                                                  isSelected
                                                      ? kBronze
                                                      : kStonePale,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              // Notes
                              TextField(
                                controller: _notesController,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Add a note about your month (optional)',
                                  filled: true,
                                  fillColor: kPaper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: kClay),
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
              // Bottom button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _selectedAction != null && !_submitting
                            ? _submitReview
                            : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: kBronze,
                      disabledBackgroundColor: kClay,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _submitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                            : const Text(
                              'Save my review',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kClay),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: kInk,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }
}
