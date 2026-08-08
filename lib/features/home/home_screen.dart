import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'add_act_screen.dart';
import '../../services/offline_action_queue.dart';
import '../../services/queue_sync_service.dart';
import '../../widgets/sync_status_banner.dart';
import '../../widgets/prayer_tracker_card.dart';
import '../../widgets/notification_action_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acts = ref.watch(actStoreProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                dark
                    ? const [kScaffoldDark, kSurfaceDark, kPaperDark]
                    : const [kSurface, kClayLight, kPaper],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  floating: false,
                  toolbarHeight: 92,
                  collapsedHeight: 92,
                  expandedHeight: 92,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: _PremiumHomeHeader(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  sliver: SliverList.list(
                    children: [
                      CardEntrance(index: 0, child: PrayerTrackerCard()),
                      const SizedBox(height: 10),
                      const SyncStatusBanner(),
                      const SizedBox(height: 10),
                      CardEntrance(
                        index: 1,
                        child: _JarHero(
                          totalActs: acts.totalStars,
                          progress: acts.progress,
                          onAdd: () => AddActScreen.show(context),
                          remainingActs: acts.remainingActs,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const CardEntrance(
                        index: 3,
                        child: _RhythmOfTheDayCard(),
                      ),
                      const SizedBox(height: 10),
                      const CardEntrance(
                        index: 4,
                        child: _SectionHeading('Explore'),
                      ),
                      const SizedBox(height: 12),
                      const CardEntrance(
                        index: 5,
                        child: _VerifiedDonationsCard(),
                      ),
                      const SizedBox(height: 12),
                      const CardEntrance(index: 6, child: _TodaysGentleActs()),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 7, child: _LastReadCard()),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 8, child: _TodaysReflection()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumHomeHeader extends StatefulWidget {
  const _PremiumHomeHeader();

  @override
  State<_PremiumHomeHeader> createState() => _PremiumHomeHeaderState();
}

class _PremiumHomeHeaderState extends State<_PremiumHomeHeader> {
  late final Future<AccountSnapshot?> _profileFuture =
      BackendApi.instance.getAccountSnapshot();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tokens = context.colors;
    final bg = dark ? tokens.surface : tokens.surfaceContainer;
    final border = dark ? tokens.borderSubtle : tokens.border;
    final primary = tokens.textPrimary;
    final secondary = tokens.textSecondary;
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 20,
        12,
        20,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color:
                dark
                    ? Colors.black.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.14),
            blurRadius: dark ? 16 : 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FutureBuilder<AccountSnapshot?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final account = snapshot.data;
          final name = _firstName(account?.username ?? account?.email ?? '');
          final initial =
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push('/profile'),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          dark
                              ? [
                                kBronzeLight.withValues(alpha: 0.6),
                                kBronzeLight.withValues(alpha: 0.15),
                              ]
                              : [
                                kBronzeDark.withValues(alpha: 0.5),
                                kBronzeDark.withValues(alpha: 0.12),
                              ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor:
                        dark ? tokens.surfaceContainerHigh : tokens.surface,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: dark ? kBronzeLight : kBronzeDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Assalamu alaikum, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primary,
                        fontFamily: 'Georgia',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hijriLabel(now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _gregorianLabel(now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary.withValues(alpha: 0.82),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? kElevatedDark : kWhite,
                  border: Border.all(color: border),
                ),
                child: NotificationActionButton(
                  onPressed: () => context.push('/notifications'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _firstName(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'Friend';
    final base = clean.contains('@') ? clean.split('@').first : clean;
    return base.split(RegExp(r'\s+')).first;
  }

  String _gregorianLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _hijriLabel(DateTime date) {
    const months = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Shaaban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qadah',
      'Dhu al-Hijjah',
    ];
    final jd = (date.millisecondsSinceEpoch / 86400000).floor() + 2440588;
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j =
        (((10985 - l2) / 5316).floor()) * (((50 * l2) / 17719).floor()) +
        ((l2 / 5670).floor()) * (((43 * l2) / 15238).floor());
    final l3 =
        l2 -
        (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        (j / 16).floor() * (((15238 * j) / 43).floor()) +
        29;
    final month = ((24 * l3) / 709).floor();
    final day = l3 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return '${day.round()} ${months[(month - 1).clamp(0, 11)]} ${year.round()} AH';
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  Future<UserProfile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendApi.instance.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        String display;
        if (snapshot.hasData && snapshot.data!.username.isNotEmpty) {
          display = 'Assalamu alaikum, ${snapshot.data!.username}';
        } else if (snapshot.hasError) {
          display = 'Assalamu alaikum';
        } else {
          display = 'Assalamu alaikum';
        }
        return AnimatedSwitcher(
          duration: MizanMotion.normal,
          switchInCurve: MizanMotion.gentle,
          switchOutCurve: MizanMotion.gentle,
          child: Row(
            key: ValueKey(display),
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      style: TextStyle(
                        color: dark ? kInkDark : kInk,
                        fontFamily: 'Georgia',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Small goodness, beautifully kept.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _NotifIcon extends StatelessWidget {
  const _NotifIcon();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        Icons.notifications_none_outlined,
        color: dark ? kInkDark : kInk,
      ),
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
    );
  }
}

// ignore: unused_element
class _StreakPill extends ConsumerWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actStoreProvider);
    final streak = acts.currentStreak;
    final hasError = acts.streakError;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = dark ? kElevatedDark : kClayPale;
    final chipBorder = dark ? kLineDark : kLine;
    final chipText = dark ? kMutedDark : kMuted;
    final primaryText = dark ? kInkDark : kInk;
    final accent = dark ? kBronzeDarkMode : kBronze;

    Widget child;

    if (streak == null && !hasError) {
      child = Container(
        key: const ValueKey('streak-loading'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: accent),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );
    } else if (streak == null && hasError) {
      child = Container(
        key: const ValueKey('streak-error'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(actStoreProvider).retryStreak(),
              icon: Icon(Icons.refresh_rounded, size: 18, color: accent),
              tooltip: 'Retry',
            ),
            Text(
              '-',
              style: TextStyle(
                color: chipText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      child = Container(
        key: ValueKey('streak-$streak'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kBronzeLight,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kBronze.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: kDanger,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedNumber(
              value: streak!,
              style: TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: MizanMotion.normal,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      transitionBuilder:
          (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
      child: child,
    );
  }
}

class _JarHero extends ConsumerWidget {
  const _JarHero({
    required this.totalActs,
    required this.progress,
    required this.onAdd,
    required this.remainingActs,
  });
  final int totalActs;
  final double progress;
  final VoidCallback onAdd;
  final int remainingActs;

  String _progressMessage() {
    if (totalActs == 0) return 'Start with one small act';
    if (progress >= 1.0) return 'Intention fulfilled';
    return remainingActs > 0
        ? '$remainingActs acts to go'
        : 'Intention reached';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actStoreProvider);
    final goalTitle = acts.goalTitle;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final heroBg = dark ? kPaperDark : kInk;
    final heroPrimaryText = dark ? kInkDark : kPaper;
    final heroSecondaryText = dark ? kMutedDark : kClayLight;
    final ctaColor = dark ? kBronzeDarkMode : kBronze;
    final heroShadow =
        dark ? kInk.withValues(alpha: 0.28) : kInk.withValues(alpha: 0.13);

    return AnimatedSwitcher(
      duration: MizanMotion.slow,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          color: heroBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: heroShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goalTitle != null
                                ? goalTitle.toUpperCase()
                                : 'MY SADAQAH JAR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kBronzeLight,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Edit goal',
                          onPressed: () => _showEditGoal(context, ref),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: dark ? kBronzeDarkMode : kBronzeLight,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    TweenAnimationBuilder<double>(
                      duration: MizanMotion.slow,
                      curve: MizanMotion.gentle,
                      tween: Tween(begin: 0, end: progress),
                      builder:
                          (context, value, _) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${(value * 100).round()}% filled',
                              style: TextStyle(
                                color: heroPrimaryText,
                                fontFamily: 'Georgia',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 8),

                    TweenAnimationBuilder<double>(
                      duration: MizanMotion.slow,
                      curve: MizanMotion.gentle,
                      tween: Tween(begin: 0, end: progress),
                      builder:
                          (context, value, _) => SmoothProgress(
                            value: value,
                            height: 6,
                            color: kBronzeLight,
                            backgroundColor: kStone,
                          ),
                    ),
                    const SizedBox(height: 6),

                    AnimatedSwitcher(
                      duration: MizanMotion.slow,
                      switchInCurve: MizanMotion.gentle,
                      switchOutCurve: MizanMotion.gentle,
                      transitionBuilder:
                          (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _progressMessage(),
                        key: ValueKey(_progressMessage()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: heroSecondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add an act'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ctaColor,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              SizedBox(
                width: 88,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      tween: Tween(begin: 0.85, end: 1.0),
                      builder:
                          (context, glow, child) => Opacity(
                            opacity: (0.15 + 0.15 * progress) * glow,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    kBronzeLight.withValues(alpha: 0.6),
                                    kBronzeLight.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),
                    ExcludeSemantics(
                      child: FamilyJarView(fill: progress, size: 88, glow: .9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showEditGoal(BuildContext context, WidgetRef ref) async {
  final store = ref.read(actStoreProvider);
  final title = TextEditingController(text: store.goalTitle ?? '');
  final target = TextEditingController(text: '${store.goalTarget ?? 30}');
  final subtitle = TextEditingController(text: store.goalSubtitle ?? '');
  bool saving = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (sheetContext) => Consumer(
          builder: (sheetContext, sheetRef, _) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                Future<void> save() async {
                  final parsedTarget = int.tryParse(target.text.trim());
                  if (title.text.trim().isEmpty ||
                      parsedTarget == null ||
                      parsedTarget <= 0 ||
                      saving) {
                    setSheetState(
                      () => error = 'Add a title and a valid target.',
                    );
                    return;
                  }
                  setSheetState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await sheetRef
                        .read(actStoreProvider)
                        .updateGoal(
                          title: title.text.trim(),
                          subtitle:
                              subtitle.text.trim().isEmpty
                                  ? null
                                  : subtitle.text.trim(),
                          actsTarget: parsedTarget,
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  } catch (_) {
                    setSheetState(() {
                      saving = false;
                      error = 'Could not update goal. Please try again.';
                    });
                  }
                }

                final bottom =
                    MediaQuery.viewInsetsOf(sheetContext).bottom +
                    MediaQuery.paddingOf(sheetContext).bottom;
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Edit goal',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: title,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Goal title',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: target,
                          enabled: !saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target acts',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: subtitle,
                          enabled: !saving,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description or intention',
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            error!,
                            style: const TextStyle(
                              color: kDanger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: saving ? null : save,
                          child:
                              saving
                                  ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(
                                            sheetContext,
                                          ).colorScheme.onPrimary,
                                    ),
                                  )
                                  : const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
  );

  title.dispose();
  target.dispose();
  subtitle.dispose();
}

class _VerifiedDonationsCard extends StatelessWidget {
  const _VerifiedDonationsCard();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? kElevatedDark : kWhite;
    final cardBorder = dark ? kLineDark : kLine;
    final titleColor = dark ? kInkDark : kInk;
    final bodyColor = dark ? kMutedDark : kInk.withValues(alpha: 0.65);
    final iconBg = dark ? kSurfaceDark : kClay;
    final accent = dark ? kBronzeDarkMode : kBronze;

    return FadeScaleTransition(
      beginScale: 0.97,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/charities'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: iconBg,
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Donations',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discover and support trusted causes.',
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 21,
        color: dark ? kInkDark : kInk,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HomeSource {
  const _HomeSource({
    required this.kind,
    required this.title,
    required this.arabic,
    required this.body,
    required this.source,
    required this.prompt,
  });

  final String kind;
  final String title;
  final String arabic;
  final String body;
  final String source;
  final String prompt;
}

const _homeReflectionSources = [
  _HomeSource(
    kind: 'Quran',
    title: 'Hearts find rest',
    arabic:
        '\u{623}\u{644}\u{627} \u{628}\u{630}\u{643}\u{631} \u{627}\u{644}\u{644}\u{647} \u{62a}\u{637}\u{645}\u{626}\u{646} \u{627}\u{644}\u{642}\u{644}\u{648}\u{628}',
    body:
        'Those who believe and whose hearts find rest in the remembrance of Allah. Surely in the remembrance of Allah do hearts find rest.',
    source: 'Quran 13:28',
    prompt: 'Where is your heart asking for rest today?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Begin with intention',
    arabic:
        '\u{625}\u{646}\u{645}\u{627} \u{627}\u{644}\u{623}\u{639}\u{645}\u{627}\u{644} \u{628}\u{627}\u{644}\u{646}\u{64a}\u{627}\u{62a}',
    body:
        'Actions are only by intentions, and every person will have only what they intended. So the direction of the heart matters before the size of the deed.',
    source: 'Sahih al-Bukhari 1',
    prompt: 'What intention do you want to renew before the day continues?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Ease follows hardship',
    arabic:
        '\u{641}\u{625}\u{646} \u{645}\u{639} \u{627}\u{644}\u{639}\u{633}\u{631} \u{64a}\u{633}\u{631}\u{627} \u{625}\u{646} \u{645}\u{639} \u{627}\u{644}\u{639}\u{633}\u{631} \u{64a}\u{633}\u{631}\u{627}',
    body:
        'For indeed, with hardship comes ease. Indeed, with hardship comes ease. Allah repeats the promise so the heart can hold it firmly.',
    source: 'Quran 94:5-6',
    prompt: 'Where do you need to trust Allah through difficulty?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Steady deeds',
    arabic:
        '\u{623}\u{62d}\u{628} \u{627}\u{644}\u{623}\u{639}\u{645}\u{627}\u{644} \u{625}\u{644}\u{649} \u{627}\u{644}\u{644}\u{647} \u{623}\u{62f}\u{648}\u{645}\u{647}\u{627} \u{648}\u{625}\u{646} \u{642}\u{644}',
    body:
        'The most beloved deeds to Allah are those done consistently, even if they are small. A small act kept alive can become a mercy that shapes the whole day.',
    source: 'Sahih al-Bukhari 6464',
    prompt: 'What small act can you keep returning to?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Allah is near',
    arabic:
        '\u{641}\u{625}\u{646}\u{64a} \u{642}\u{631}\u{64a}\u{628} \u{623}\u{62c}\u{64a}\u{628} \u{62f}\u{639}\u{648}\u{629} \u{627}\u{644}\u{62f}\u{627}\u{639} \u{625}\u{630}\u{627} \u{62f}\u{639}\u{627}\u{646}',
    body:
        'Indeed, I am near. I respond to the call of the caller when he calls upon Me. So let them respond to Me and believe in Me that they may be guided.',
    source: 'Quran 2:186',
    prompt: 'What dua has been waiting quietly inside you?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Learn and teach',
    arabic:
        '\u{62e}\u{64a}\u{631}\u{643}\u{645} \u{645}\u{646} \u{62a}\u{639}\u{644}\u{645} \u{627}\u{644}\u{642}\u{631}\u{622}\u{646} \u{648}\u{639}\u{644}\u{645}\u{647}',
    body:
        'The best of you are those who learn the Quran and teach it. Learning can begin with one ayah read carefully, carried gently, and shared beautifully.',
    source: 'Sahih al-Bukhari 5027',
    prompt: 'What is one thing from the Quran you want to live or share today?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Do not despair',
    arabic:
        '\u{644}\u{627} \u{62a}\u{642}\u{646}\u{637}\u{648}\u{627} \u{645}\u{646} \u{631}\u{62d}\u{645}\u{629} \u{627}\u{644}\u{644}\u{647}',
    body:
        'Say, O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins.',
    source: 'Quran 39:53',
    prompt: 'Where do you need to receive mercy instead of carrying shame?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Good character',
    arabic:
        '\u{625}\u{646} \u{645}\u{646} \u{62e}\u{64a}\u{627}\u{631}\u{643}\u{645} \u{623}\u{62d}\u{633}\u{646}\u{643}\u{645} \u{623}\u{62e}\u{644}\u{627}\u{642}\u{627}',
    body:
        'Indeed, among the best of you are those with the best character. Faith becomes visible in gentleness, restraint, truthfulness, and mercy with people.',
    source: 'Sahih al-Bukhari 3559',
    prompt: 'What would good character look like in your next conversation?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Gratitude increases',
    arabic:
        '\u{644}\u{626}\u{646} \u{634}\u{643}\u{631}\u{62a}\u{645} \u{644}\u{623}\u{632}\u{64a}\u{62f}\u{646}\u{643}\u{645}',
    body:
        'And remember when your Lord proclaimed: If you are grateful, I will surely increase you. Gratitude opens the heart before it opens the hand.',
    source: 'Quran 14:7',
    prompt: 'What blessing can you name before asking for more?',
  ),
];

_HomeSource _sourceForSlot(int slot) {
  final now = DateTime.now();
  final index = (now.day * 3 + slot) % _homeReflectionSources.length;
  return _homeReflectionSources[index];
}

int _daySlot(DateTime now) {
  if (now.hour < 11) return 0;
  if (now.hour < 17) return 1;
  return 2;
}

class _TodaysGentleActs extends StatelessWidget {
  const _TodaysGentleActs();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final source = _sourceForSlot(_daySlot(now) + 1);
    final reminder =
        const [
          'Pause for one sincere intention before your next task.',
          'Let one verse or hadith shape how you speak today.',
          'Return to Allah quietly before the day becomes noisy.',
          'Choose the small good deed you can repeat without strain.',
          'Keep mercy in your tone, even when you are tired.',
          'Make one private dua before you move on.',
        ][(now.day + _daySlot(now)) % 6];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = dark ? kInkDark : kInk;
    final bodyColor =
        dark ? kInkDark.withValues(alpha: 0.9) : kInk.withValues(alpha: 0.85);
    final sourceColor = dark ? kMutedDark : kInk.withValues(alpha: 0.55);
    final accentBg = dark ? kElevatedDark : kWhite;
    final reminderBg =
        dark
            ? kBronzeDarkMode.withValues(alpha: 0.2)
            : kBronze.withValues(alpha: 0.1);
    final reminderText = dark ? kBronzeDarkMode : kBronzeDark;
    return FadeScaleTransition(
      beginScale: 0.97,
      child: _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    color: dark ? kBronzeDarkMode : kBronze,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A gentle reminder',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              source.body,
              style: TextStyle(
                color: bodyColor,
                fontSize: 15.5,
                height: 1.55,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: reminderBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                reminder,
                style: TextStyle(
                  color: reminderText,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${source.kind} - ${source.source}',
              style: TextStyle(
                color: sourceColor,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmOfTheDayCard extends StatefulWidget {
  const _RhythmOfTheDayCard();

  @override
  State<_RhythmOfTheDayCard> createState() => _RhythmOfTheDayCardState();
}

class _RhythmOfTheDayCardState extends State<_RhythmOfTheDayCard>
    with WidgetsBindingObserver {
  String _title = 'Morning Adhkar';
  String _body = 'Begin your day with the remembrance that steadies the heart.';
  String _source = 'Hisnul Muslim';
  String _slotKey = '';
  bool _isFriday = false;
  IconData _icon = Icons.wb_twilight_outlined;
  _TodayLightAction _action = _TodayLightAction.morningAdhkar;

  // Static prayer times used as gentle placeholders until live timings are wired.
  // Wire to location-based calculation (e.g. adhan API) when geo permissions
  // and backend support are ready.
  static const _dhuhr = TimeOfDay(hour: 12, minute: 15);
  static const _asr = TimeOfDay(hour: 15, minute: 45);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyRhythm(DateTime.now(), notify: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyRhythm(DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _applyRhythm(DateTime now, {bool notify = true}) {
    final choice = _choiceFor(now);
    if (_slotKey == choice.slotKey) return;
    void assign() {
      _slotKey = choice.slotKey;
      _isFriday = now.weekday == DateTime.friday;
      _title = choice.title;
      _body = choice.body;
      _source = choice.source;
      _icon = choice.icon;
      _action = choice.action;
    }

    if (notify && mounted) {
      setState(assign);
    } else {
      assign();
    }
  }

  void _openAction() {
    switch (_action) {
      case _TodayLightAction.morningAdhkar:
        context.push('/journey/adhkar/morning');
        break;
      case _TodayLightAction.kahf:
        context.push('/journey?tab=quran&surah=18');
        break;
      case _TodayLightAction.quranPage:
        context.push('/journey?tab=quran');
        break;
      case _TodayLightAction.eveningAdhkar:
        context.push('/journey/adhkar/evening');
        break;
      case _TodayLightAction.salawat:
      case _TodayLightAction.sadaqah:
      case _TodayLightAction.nawafil:
      case _TodayLightAction.tahajjud:
        AddActScreen.show(context);
        break;
    }
  }

  _RhythmChoice _choiceFor(DateTime now) {
    final isFriday = now.weekday == DateTime.friday;
    final minutes = now.hour * 60 + now.minute;
    final morningEnd = _dhuhr.hour * 60 + _dhuhr.minute;
    final afternoonEnd = _asr.hour * 60 + _asr.minute;
    const eveningStart = 17 * 60;
    const nightStart = 22 * 60;

    if (minutes < 4 * 60) {
      return const _RhythmChoice(
        slotKey: 'night-tahajjud',
        title: 'Tahajjud',
        body: 'Stand for a quiet prayer while the world is still.',
        source: 'Night prayer',
        icon: Icons.nights_stay_outlined,
        action: _TodayLightAction.tahajjud,
      );
    }
    if (minutes < morningEnd) {
      return const _RhythmChoice(
        slotKey: 'morning-adhkar',
        title: 'Morning Adhkar',
        body: 'Begin your day with the remembrance that steadies the heart.',
        source: 'Hisnul Muslim',
        icon: Icons.wb_twilight_outlined,
        action: _TodayLightAction.morningAdhkar,
      );
    }
    if (isFriday && minutes < eveningStart) {
      return const _RhythmChoice(
        slotKey: 'friday-kahf',
        title: 'Read Surah Al-Kahf',
        body: 'A light for the day and the path ahead.',
        source: 'Quran 18',
        icon: Icons.menu_book_outlined,
        action: _TodayLightAction.kahf,
      );
    }
    if (minutes < afternoonEnd) {
      final light = _sourceForSlot(_daySlot(now));
      if (now.day.isEven) {
        return _RhythmChoice(
          slotKey: 'afternoon-quran',
          title: 'Read a page of Quran',
          body: light.body,
          source: '${light.kind} - ${light.source}',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        );
      }
      return const _RhythmChoice(
        slotKey: 'afternoon-sadaqah',
        title: 'Do an act of sadaqah',
        body: 'Choose one private act of goodness before the afternoon passes.',
        source: 'Sadaqah',
        icon: Icons.favorite_border_rounded,
        action: _TodayLightAction.sadaqah,
      );
    }
    if (minutes < nightStart) {
      if (isFriday && now.hour >= 19) {
        return const _RhythmChoice(
          slotKey: 'friday-salawat',
          title: 'Send salawat upon the Nabi',
          body: 'Let your evening carry prayers and peace upon him.',
          source: 'Friday reminder',
          icon: Icons.favorite_outline_rounded,
          action: _TodayLightAction.salawat,
        );
      }
      return const _RhythmChoice(
        slotKey: 'evening-adhkar',
        title: 'Evening Adhkar',
        body: 'Close the day with remembrance, protection, and gratitude.',
        source: 'Hisnul Muslim',
        icon: Icons.nights_stay_outlined,
        action: _TodayLightAction.eveningAdhkar,
      );
    }
    return const _RhythmChoice(
      slotKey: 'late-nawafil',
      title: 'A quiet nawafil moment',
      body: 'Add a small voluntary prayer or good deed before the day closes.',
      source: 'Nawafil',
      icon: Icons.self_improvement_outlined,
      action: _TodayLightAction.nawafil,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    final isFriday = _isFriday;
    final icon = _icon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        dark
            ? (isFriday ? kSageSoft : kBronzeDarkMode)
            : (isFriday ? kSage : kBronze);
    final iconBg = dark ? kSurfaceDark : kSoftBronze;
    final titleColor = dark ? kInkDark : kInk;
    final bodyColor = dark ? kMutedDark : kInk.withValues(alpha: 0.7);
    final sourceColor =
        dark ? kMutedDark.withValues(alpha: 0.9) : kInk.withValues(alpha: 0.55);

    return InkWell(
      onTap: _openAction,
      borderRadius: BorderRadius.circular(22),
      child: _Surface(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rhythm of the day',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 10.5,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _title,
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  if (_body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _source,
                      style: TextStyle(
                        color: sourceColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: dark ? kBronzeDarkMode : kBronze,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmChoice {
  const _RhythmChoice({
    required this.slotKey,
    required this.title,
    required this.body,
    required this.source,
    required this.icon,
    required this.action,
  });

  final String slotKey;
  final String title;
  final String body;
  final String source;
  final IconData icon;
  final _TodayLightAction action;
}

enum _TodayLightAction {
  morningAdhkar,
  kahf,
  quranPage,
  eveningAdhkar,
  salawat,
  sadaqah,
  nawafil,
  tahajjud,
}

class _LastReadCard extends StatefulWidget {
  const _LastReadCard();

  @override
  State<_LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<_LastReadCard> {
  late final Future<Map<String, dynamic>?> _future =
      BackendApi.instance.getLastReadingProgress();
  String? _bookTitle;
  String? _chapterTitle;
  bool _resolvingTitles = false;

  Future<void> _resolveTitles(Map<String, dynamic> progress) async {
    final bookId = progress['book_id'] as int? ?? 0;
    final chapterNumber = progress['chapter_number'] as int? ?? 1;
    if (_bookTitle != null && _chapterTitle != null) return;
    if (_resolvingTitles) return;
    _resolvingTitles = true;
    try {
      final book = await BackendApi.instance.getBook(bookId);
      final chapters = await BackendApi.instance.getBookChapters(bookId);
      final chapter = chapters.firstWhere(
        (c) => c.chapterNumber == chapterNumber,
        orElse:
            () =>
                chapters.isNotEmpty
                    ? chapters.first
                    : BookChapterRead(
                      id: 0,
                      bookId: bookId,
                      chapterNumber: chapterNumber,
                      title: 'Chapter $chapterNumber',
                    ),
      );
      if (!mounted) return;
      setState(() {
        _bookTitle = book.title;
        _chapterTitle = chapter.title;
        _resolvingTitles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingTitles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? kInkDark : kInk;
    final bodyColor = dark ? kMutedDark : kInk.withValues(alpha: 0.65);
    final accent = dark ? kBronzeDarkMode : kBronze;
    final iconBg = dark ? kSurfaceDark : kSoftBronze;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _Surface(
            key: const ValueKey('lastread-loading'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Finding your reading place...',
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          final progress = snapshot.data;
          if (progress == null) {
            child = FadeScaleTransition(
              key: const ValueKey('lastread-empty'),
              beginScale: 0.97,
              child: InkWell(
                onTap: () => context.push('/journey'),
                child: _Surface(
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, color: kSage),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start your first reading',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Open the journey to explore',
                              style: TextStyle(
                                color: bodyColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: accent),
                    ],
                  ),
                ),
              ),
            );
          } else {
            final bookId = progress['book_id'] as int? ?? 0;
            final chapter = progress['chapter_number'] as int? ?? 1;
            final bookTitle = _bookTitle ?? 'Book $bookId';
            final chapterTitle = _chapterTitle ?? 'Chapter $chapter';
            if (_bookTitle == null && _chapterTitle == null) {
              _resolveTitles(progress);
            }
            child = FadeScaleTransition(
              key: const ValueKey('lastread-progress'),
              beginScale: 0.97,
              child: InkWell(
                onTap: () => context.push('/journey'),
                child: _Surface(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: kSage,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue reading',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$bookTitle, $chapterTitle',
                              style: TextStyle(
                                color: bodyColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: accent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
        return AnimatedSwitcher(
          duration: MizanMotion.normal,
          switchInCurve: MizanMotion.gentle,
          switchOutCurve: MizanMotion.gentle,
          child: child,
        );
      },
    );
  }
}

class _TodaysReflection extends StatelessWidget {
  const _TodaysReflection();
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final verse =
        _homeReflectionSources[now.day % _homeReflectionSources.length];
    final prompt = verse.prompt;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = dark ? kSurfaceDark : kSoftBronze;
    final bodyColor =
        dark ? kInkDark.withValues(alpha: 0.9) : kInk.withValues(alpha: 0.85);
    final sourceColor = dark ? kMutedDark : kInk.withValues(alpha: 0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Today\'s reflection'),
        const SizedBox(height: 12),
        FadeScaleTransition(
          beginScale: 0.97,
          child: _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: dark ? kBronzeDarkMode : kBronze,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${verse.kind} - ${verse.source}',
                        style: TextStyle(
                          color: sourceColor,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ArabicText(verse.arabic, fontSize: 22),
                const SizedBox(height: 10),
                Text(
                  verse.body,
                  style: TextStyle(
                    color: bodyColor,
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder:
                        (context, ref, _) => FilledButton.icon(
                          onPressed:
                              () => _showVerseReflection(
                                context,
                                verse,
                                prompt,
                                ref,
                              ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(
                            verse.kind == 'Quran'
                                ? 'Reflect on this verse'
                                : 'Reflect on this hadith',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: kBronze,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
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
    );
  }
}

Future<void> _showVerseReflection(
  BuildContext context,
  _HomeSource verse,
  String prompt,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder:
        (sheetContext) => _VerseReflectionSheet(
          verse: verse,
          prompt: prompt,
          controller: controller,
        ),
  );
  controller.dispose();
  if (saved == true && context.mounted) {
    ref.read(actStoreProvider).load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Your reflection was saved to your journey.',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseReflectionSheet extends StatefulWidget {
  const _VerseReflectionSheet({
    required this.verse,
    required this.prompt,
    required this.controller,
  });

  final _HomeSource verse;
  final String prompt;
  final TextEditingController controller;

  @override
  State<_VerseReflectionSheet> createState() => _VerseReflectionSheetState();
}

class _VerseReflectionSheetState extends State<_VerseReflectionSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final body = widget.controller.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final localId =
          'local_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
      final queueItem = OfflineQueueItem(
        id: localId,
        actionType: ActionType.createReflection,
        payload: {
          'title': widget.verse.source,
          'body':
              '${widget.verse.arabic}\n\n${widget.verse.body}\n\n${widget.prompt}\n\n$body',
          'mood': 'Reflective',
        },
        createdAt: DateTime.now(),
      );
      await QueueSyncService.instance.enqueueAndSync(queueItem);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? kInkDark : kInk;
    final bodyColor =
        dark ? kInkDark.withValues(alpha: 0.9) : kInk.withValues(alpha: 0.85);
    final promptBg = dark ? kElevatedDark : kSoftBronze;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reflect on ${widget.verse.source}',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            _ArabicText(widget.verse.arabic, fontSize: 22),
            const SizedBox(height: 12),
            Text(
              widget.verse.body,
              style: TextStyle(
                color: bodyColor,
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: promptBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.prompt,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: widget.controller,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                hintText: 'What does this verse invite you to carry today?',
              ),
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: kDanger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kBronze,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                      : const Text('Save to my journey'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArabicText extends StatelessWidget {
  const _ArabicText(this.text, {this.fontSize = 20});
  final String text;
  final double fontSize;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      softWrap: true,
      style: TextStyle(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? kInkDark.withValues(alpha: 0.96)
                : kInk,
        fontSize: fontSize,
        height: 1.9,
        fontFamilyFallback: const [
          'Noto Naskh Arabic',
          'Noto Sans Arabic',
          'Arial Unicode MS',
          'Tahoma',
        ],
      ),
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tokens = context.colors;
    final bg =
        brightness == Brightness.dark ? tokens.surfaceElevated : tokens.surface;
    final border =
        brightness == Brightness.dark ? tokens.borderSubtle : tokens.border;
    final shadowColor =
        brightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: brightness == Brightness.light ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
