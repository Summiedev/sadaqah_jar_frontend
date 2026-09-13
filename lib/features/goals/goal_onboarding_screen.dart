import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/session_controller.dart';
import '../../core/animations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import 'goal_providers.dart';

class GoalOnboardingScreen extends ConsumerStatefulWidget {
  const GoalOnboardingScreen({super.key});

  @override
  ConsumerState<GoalOnboardingScreen> createState() =>
      _GoalOnboardingScreenState();
}

class _GoalOnboardingScreenState extends ConsumerState<GoalOnboardingScreen> {
  int _selectedIndex = -1;
  bool _saving = false;
  bool _skipped = false;
  bool _checkingExistingGoal = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _skipIfAlreadySetUp());
  }

  Future<void> _skipIfAlreadySetUp() async {
    try {
      final goals = await BackendApi.instance.getGoals(status: 'active');
      final items = goals['goals'];
      if (items is List && items.isNotEmpty) {
        await ref.read(sessionProvider).completeGoalSetup();
        if (mounted) context.go('/home');
        return;
      }
    } catch (_) {
      // Keep the form available when the account is temporarily offline.
    }
    if (mounted) setState(() => _checkingExistingGoal = false);
  }

  List<Map<String, dynamic>> get _suggestions {
    final mode = ref.read(modeProvider);
    if (mode == kModePersonal) return kPersonalGoalSuggestions;
    if (mode == kModeFamily) return kFamilyGoalSuggestions;
    // Both mode - show personal suggestions (user can set family goals later)
    return kPersonalGoalSuggestions;
  }

  String get _title {
    final mode = ref.read(modeProvider);
    if (mode == kModePersonal) return 'Set your first intention';
    if (mode == kModeFamily) return 'Set a family intention';
    return 'Set your first intention';
  }

  String get _subtitle {
    final mode = ref.read(modeProvider);
    if (mode == kModePersonal) {
      return 'Choose a gentle goal to begin your journey. You can always change it later.';
    }
    if (mode == kModeFamily) {
      return 'Choose a shared goal for your family to grow toward together.';
    }
    return 'Choose a gentle goal to begin your journey. You can always change it later.';
  }

  Future<void> _saveGoal() async {
    if (_selectedIndex < 0) return;
    setState(() => _saving = true);

    final suggestion = _suggestions[_selectedIndex];
    final now = DateTime.now();
    final month =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    try {
      await BackendApi.instance.createGoal(
        title: suggestion['title'] as String,
        subtitle: suggestion['subtitle'] as String?,
        actsTarget: suggestion['target'] as int,
        month: month,
      );
    } catch (e) {
      // On failure, keep the user on the onboarding screen so they can
      // retry. Do NOT mark goal setup complete or navigate away - that
      // would strand the user with no goal actually created.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(
                e,
                fallback:
                    'Could not save your goal. Please try again.',
              ),
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
      return;
    }

    await ref.read(sessionProvider).completeGoalSetup();
    if (mounted) {
      ref.read(goalSetupCompleteProvider.notifier).state = true;
      context.go('/home');
    }
  }

  Future<void> _skip() async {
    setState(() => _skipped = true);
    await ref.read(sessionProvider).completeGoalSetup();
    if (mounted) {
      ref.read(goalSetupCompleteProvider.notifier).state = true;
      context.go('/home');
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'volunteer_activism':
        return Icons.volunteer_activism_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'groups':
        return Icons.groups_outlined;
      case 'calendar_month':
        return Icons.calendar_month_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_checkingExistingGoal) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 0),
              child: Row(
                children: [
                  Text(
                    'MIZAN',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipped ? null : _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _title,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Goal suggestions
                    ...List.generate(_suggestions.length, (index) {
                      final suggestion = _suggestions[index];
                      final isSelected = _selectedIndex == index;
                      return CardEntrance(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color:
                                isSelected
                                    ? colors.primaryContainer
                                    : colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              MizanRadii.card,
                            ),
                            child: InkWell(
                              onTap:
                                  () => setState(() => _selectedIndex = index),
                              borderRadius: BorderRadius.circular(
                                MizanRadii.card,
                              ),
                              child: AnimatedContainer(
                                duration: MizanMotion.fast,
                                curve: MizanMotion.gentle,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    MizanRadii.card,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? colors.primary
                                            : colors.borderSubtle,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? colors.primary.withValues(
                                                  alpha: 0.18,
                                                )
                                                : colors.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          MizanRadii.control,
                                        ),
                                      ),
                                      child: Icon(
                                        _getIcon(suggestion['icon'] as String),
                                        color: colors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion['title'] as String,
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            suggestion['subtitle'] as String,
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${suggestion['target']}',
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? colors.primary
                                                : colors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color:
                                          isSelected
                                              ? colors.primary
                                              : colors.textMuted,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Custom goal option
                    FadeScaleTransition(
                      beginScale: 0.98,
                      child: Material(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(MizanRadii.card),
                        child: InkWell(
                          onTap: () => _showCustomGoalDialog(),
                          borderRadius: BorderRadius.circular(MizanRadii.card),
                          child: Container(
                            padding: MizanSpacing.card,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                MizanRadii.card,
                              ),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      MizanRadii.control,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: colors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set a custom goal',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Define your own intention',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: colors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                      child: AnimatedSwitcher(
                        key: const ValueKey('goal-button'),
                        duration: MizanMotion.fast,
                        switchInCurve: MizanMotion.gentle,
                        switchOutCurve: MizanMotion.gentle,
                        child: SizedBox(
                          key: ValueKey(_saving),
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _selectedIndex >= 0 && !_saving
                                    ? _saveGoal
                                    : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              disabledBackgroundColor: colors.surfaceContainerHigh,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                _saving
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    )
                                    : const Text(
                                      'Begin with this intention',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomGoalDialog() async {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '10');
    String? targetError;

    final _ = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => DialogFadeScale(
                  child: AlertDialog(
                    backgroundColor: ctx.colors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    title: Text(
                      'Custom goal',
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
                          decoration: InputDecoration(
                            labelText: 'What is your intention?',
                            hintText: 'e.g. Pray 5 daily prayers',
                            filled: true,
                            fillColor: ctx.colors.inputBackground,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: targetController,
                          decoration: InputDecoration(
                            labelText: 'Target count',
                            hintText: 'e.g. 30',
                            filled: true,
                            fillColor: ctx.colors.inputBackground,
                            border: const OutlineInputBorder(),
                            errorText: targetError,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: ctx.colors.textSecondary),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final rawTarget = targetController.text.trim();
                          final target = int.tryParse(rawTarget);
                          if (target == null || target < 1 || target > 10000) {
                            setDialogState(() {
                              targetError =
                                  'Enter a number between 1 and 10,000';
                            });
                            return;
                          }
                          if (title.isEmpty) return;
                          Navigator.pop(ctx, true);
                          _saveCustomGoal(title, target);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: ctx.colors.primary,
                        ),
                        child: const Text('Set goal'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _saveCustomGoal(String title, int target) async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final month =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    try {
      await BackendApi.instance.createGoal(
        title: title,
        actsTarget: target,
        month: month,
      );
    } catch (e) {
      // On failure, keep the user on the onboarding screen so they can
      // retry. Do NOT mark goal setup complete or navigate away.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save goal: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
      return;
    }

    await ref.read(sessionProvider).completeGoalSetup();
    if (mounted) {
      ref.read(goalSetupCompleteProvider.notifier).state = true;
      context.go('/home');
    }
  }
}
