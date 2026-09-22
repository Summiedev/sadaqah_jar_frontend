import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'add_act_screen.dart';
import '../../services/offline_action_queue.dart';
import '../../services/queue_sync_service.dart';
import '../../widgets/sync_status_banner.dart';
import '../../widgets/prayer_tracker_card.dart';
import '../../widgets/notification_action_button.dart';
import '../journey/quran/quran_data.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.openSadaqah = false});

  final bool openSadaqah;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _openedSadaqah = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.openSadaqah || _openedSadaqah) return;
    _openedSadaqah = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AddActScreen.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final acts = ref.watch(actStoreProvider);
    final colors = context.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.background, colors.surface, colors.surfaceElevated],
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
                      const CardEntrance(index: 4, child: _HomeQuickActions()),
                      const SizedBox(height: 14),
                      const CardEntrance(index: 5, child: _QuranQuietRhythm()),
                      const SizedBox(height: 14),
                      const CardEntrance(
                        index: 6,
                        child: _SectionHeading('Explore'),
                      ),
                      const SizedBox(height: 12),
                      const CardEntrance(
                        index: 7,
                        child: _VerifiedDonationsCard(),
                      ),
                      const SizedBox(height: 12),
                      const CardEntrance(index: 8, child: _LastReadCard()),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 9, child: _TodaysReflection()),
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

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actions = [
      (
        'Qur\'an',
        Icons.menu_book_outlined,
        () => context.push('/journey?tab=quran'),
      ),
      (
        'Adhkar',
        Icons.auto_awesome_outlined,
        () => context.push('/journey/adhkar/morning'),
      ),
      (
        'Give',
        Icons.volunteer_activism_outlined,
        () => unawaited(AddActScreen.show(context)),
      ),
      (
        'Reflect',
        Icons.edit_note_outlined,
        () => context.push('/journey?tab=reflection'),
      ),
    ];
    return LayoutBuilder(
      builder:
          (context, constraints) => Row(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: actions[index].$3,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 70),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            actions[index].$2,
                            color: colors.primary,
                            size: 21,
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              actions[index].$1,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}

class _QuranQuietRhythm extends StatefulWidget {
  const _QuranQuietRhythm();

  @override
  State<_QuranQuietRhythm> createState() => _QuranQuietRhythmState();
}

class _QuranQuietRhythmState extends State<_QuranQuietRhythm> {
  late Future<(int, int)> _future = _load();
  late final StreamSubscription<DateTime> _activitySubscription;

  @override
  void initState() {
    super.initState();
    _activitySubscription = QuranRepository.instance.readingActivity.listen((
      _,
    ) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _activitySubscription.cancel();
    super.dispose();
  }

  Future<(int, int)> _load() async => (
    await QuranRepository.instance.readingDaysLast30(),
    await QuranRepository.instance.readingReflectionCount(),
  );

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FutureBuilder<(int, int)>(
      future: _future,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? (0, 0);
        return InkWell(
          onTap: () => context.push('/journey?tab=quran'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: colors.primary, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your quiet Qur\'an rhythm',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${stats.$1} reading day${stats.$1 == 1 ? '' : 's'} this month | ${stats.$2} reflection${stats.$2 == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Refresh Qur\'an rhythm',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: colors.textSecondary,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumHomeHeader extends StatefulWidget {
  const _PremiumHomeHeader();

  @override
  State<_PremiumHomeHeader> createState() => _PremiumHomeHeaderState();
}

class _PremiumHomeHeaderState extends State<_PremiumHomeHeader> {
  late Future<AccountSnapshot?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendApi.instance.getAccountSnapshot();
    accountRevision.addListener(_refreshProfile);
  }

  @override
  void dispose() {
    accountRevision.removeListener(_refreshProfile);
    super.dispose();
  }

  void _refreshProfile() {
    if (!mounted) return;
    setState(() {
      _profileFuture = BackendApi.instance.getAccountSnapshot();
    });
  }

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
      // The Home screen is already inside SafeArea. Including the device
      // top inset here made the flexible space taller than the SliverAppBar
      // on some phones, which caused a vertical RenderFlex overflow.
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: tokens.scrim.withValues(alpha: dark ? 0.18 : 0.08),
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
          final avatarBytes = account?.avatarBytes;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Open profile',
                    child: Semantics(
                      button: true,
                      label: 'Open profile',
                      child: InkWell(
                        onTap: () => context.push('/profile'),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  dark
                                      ? [
                                        tokens.accent,
                                        tokens.accent.withValues(alpha: 0.35),
                                      ]
                                      : [
                                        tokens.primary,
                                        tokens.primary.withValues(alpha: 0.35),
                                      ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.primary.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor:
                                dark
                                    ? tokens.surfaceContainerHigh
                                    : tokens.surface,
                            child:
                                avatarBytes == null
                                    ? Text(
                                      initial,
                                      style: TextStyle(
                                        color:
                                            dark
                                                ? tokens.accent
                                                : tokens.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    )
                                    : ClipOval(
                                      child: Image.memory(
                                        avatarBytes,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Text(
                                                    initial,
                                                    style: TextStyle(
                                                      color:
                                                          dark
                                                              ? tokens.accent
                                                              : tokens.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
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
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _gregorianLabel(now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: compact ? 9.5 : 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.surfaceElevated,
                      border: Border.all(color: border),
                    ),
                    child: NotificationActionButton(
                      onPressed: () => context.push('/notifications'),
                    ),
                  ),
                ],
              );
            },
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
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
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
    final colors = context.colors;
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
                        color: colors.textPrimary,
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
                        color: colors.textSecondary,
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
    return IconButton(
      icon: Icon(
        Icons.notifications_none_outlined,
        color: context.colors.iconPrimary,
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
    final colors = context.colors;
    final chipBg = colors.surfaceContainerHigh;
    final chipBorder = colors.border;
    final chipText = colors.textSecondary;
    final primaryText = colors.textPrimary;
    final accent = colors.primary;

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
          color: colors.surfaceElevated,
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
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(MizanRadii.control),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: colors.error,
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
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final heroBg = dark ? colors.surfaceElevated : colors.textPrimary;
    final heroPrimaryText = dark ? colors.textPrimary : colors.textInverse;
    final heroSecondaryText =
        dark
            ? colors.textSecondary
            : colors.textInverse.withValues(alpha: 0.82);
    final ctaColor = colors.primary;
    final heroShadow = colors.scrim.withValues(alpha: dark ? 0.2 : 0.08);

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
                            style: TextStyle(
                              color: colors.accent,
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
                            color: colors.accent,
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
                            color: colors.accent,
                            backgroundColor: colors.surfaceContainerHigh,
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
                          foregroundColor: colors.onPrimary,
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
                                    colors.accent.withValues(alpha: 0.6),
                                    colors.accent.withValues(alpha: 0),
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
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MizanRadii.sheet),
      ),
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

                Future<void> complete() async {
                  final confirmed = await showDialog<bool>(
                    context: sheetContext,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: const Text('Complete this goal?'),
                          content: const Text(
                            'Your progress will stay in goal history, and you can choose another goal afterwards.',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Keep goal'),
                            ),
                            FilledButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(true),
                              child: const Text('Complete'),
                            ),
                          ],
                        ),
                  );
                  if (confirmed != true || !sheetContext.mounted || saving)
                    return;
                  setSheetState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await sheetRef.read(actStoreProvider).completeGoal();
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  } catch (_) {
                    setSheetState(
                      () =>
                          error =
                              'Could not complete this goal. Please try again.',
                    );
                  } finally {
                    if (sheetContext.mounted)
                      setSheetState(() => saving = false);
                  }
                }

                Future<void> replace() async {
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
                  final confirmed = await showDialog<bool>(
                    context: sheetContext,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: const Text('Replace this goal?'),
                          content: const Text(
                            'The current goal will remain in your history and this will become your new active goal.',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(true),
                              child: const Text('Replace'),
                            ),
                          ],
                        ),
                  );
                  if (confirmed != true || !sheetContext.mounted || saving)
                    return;
                  setSheetState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await sheetRef
                        .read(actStoreProvider)
                        .replaceGoal(
                          title: title.text.trim(),
                          subtitle:
                              subtitle.text.trim().isEmpty
                                  ? null
                                  : subtitle.text.trim(),
                          actsTarget: parsedTarget,
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  } catch (_) {
                    setSheetState(
                      () =>
                          error =
                              'Could not replace this goal. Please try again.',
                    );
                  } finally {
                    if (sheetContext.mounted)
                      setSheetState(() => saving = false);
                  }
                }

                final bottom =
                    MediaQuery.viewInsetsOf(sheetContext).bottom +
                    MediaQuery.paddingOf(sheetContext).bottom;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    MizanSpacing.xl,
                    MizanSpacing.xl,
                    MizanSpacing.xl,
                    MizanSpacing.xl + bottom,
                  ),
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
                            style: TextStyle(
                              color: sheetContext.colors.error,
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
                                      color: sheetContext.colors.onPrimary,
                                    ),
                                  )
                                  : const Text('Save changes'),
                        ),
                        if (store.goalId != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: saving ? null : complete,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Complete goal'),
                          ),
                          TextButton(
                            onPressed: saving ? null : replace,
                            child: const Text('Replace current goal'),
                          ),
                        ],
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
    final colors = context.colors;
    final cardBg = colors.surfaceElevated;
    final cardBorder = colors.border;
    final titleColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final iconBg = colors.primaryContainer;
    final accent = colors.primary;

    return FadeScaleTransition(
      beginScale: 0.97,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(MizanRadii.card),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/charities'),
          borderRadius: BorderRadius.circular(MizanRadii.card),
          child: Container(
            padding: MizanSpacing.card,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(MizanRadii.card),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.scrim.withValues(alpha: 0.04),
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
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 21,
        color: context.colors.textPrimary,
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
        '\u{671}\u{644}\u{651}\u{64e}\u{630}\u{650}\u{64a}\u{646}\u{64e} \u{621}\u{64e}\u{627}\u{645}\u{64e}\u{646}\u{64f}\u{648}\u{627}\u{6df} \u{648}\u{64e}\u{62a}\u{64e}\u{637}\u{652}\u{645}\u{64e}\u{626}\u{650}\u{646}\u{651}\u{64f} \u{642}\u{64f}\u{644}\u{64f}\u{648}\u{628}\u{64f}\u{647}\u{64f}\u{645} \u{628}\u{650}\u{630}\u{650}\u{643}\u{652}\u{631}\u{650} \u{671}\u{644}\u{644}\u{651}\u{64e}\u{647}\u{650} \u{6d7} \u{623}\u{64e}\u{644}\u{64e}\u{627} \u{628}\u{650}\u{630}\u{650}\u{643}\u{652}\u{631}\u{650} \u{671}\u{644}\u{644}\u{651}\u{64e}\u{647}\u{650} \u{62a}\u{64e}\u{637}\u{652}\u{645}\u{64e}\u{626}\u{650}\u{646}\u{651}\u{64f} \u{671}\u{644}\u{652}\u{642}\u{64f}\u{644}\u{64f}\u{648}\u{628}\u{64f}',
    body:
        '(These are) those who believe (in the Oneness of Allah), and whose hearts find rest in the remembrance of Allah. Verily, in the remembrance of Allah do hearts find rest.',
    source: 'Quran 13:28 - Hilali & Khan',
    prompt: 'Where is your heart asking for rest today?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Begin with intention',
    arabic:
        '\u{625}\u{650}\u{646}\u{651}\u{64e}\u{645}\u{64e}\u{627} \u{627}\u{644}\u{652}\u{623}\u{64e}\u{639}\u{652}\u{645}\u{64e}\u{627}\u{644}\u{64f} \u{628}\u{650}\u{627}\u{644}\u{646}\u{651}\u{650}\u{64a}\u{651}\u{64e}\u{627}\u{62a}\u{650}\u{60c} \u{648}\u{64e}\u{625}\u{650}\u{646}\u{651}\u{64e}\u{645}\u{64e}\u{627} \u{644}\u{650}\u{643}\u{64f}\u{644}\u{651}\u{650} \u{627}\u{645}\u{652}\u{631}\u{650}\u{626}\u{64d} \u{645}\u{64e}\u{627} \u{646}\u{64e}\u{648}\u{64e}\u{649}',
    body:
        'The reward of deeds depends upon the intentions, and every person will get the reward according to what he has intended.',
    source: 'Sahih al-Bukhari 1',
    prompt: 'What intention do you want to renew before the day continues?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Ease follows hardship',
    arabic:
        '\u{641}\u{64e}\u{625}\u{650}\u{646}\u{651}\u{64e} \u{645}\u{64e}\u{639}\u{64e} \u{627}\u{644}\u{652}\u{639}\u{64f}\u{633}\u{652}\u{631}\u{650} \u{64a}\u{64f}\u{633}\u{652}\u{631}\u{64b}\u{627} \u{6dd} \u{625}\u{650}\u{646}\u{651}\u{64e} \u{645}\u{64e}\u{639}\u{64e} \u{627}\u{644}\u{652}\u{639}\u{64f}\u{633}\u{652}\u{631}\u{650} \u{64a}\u{64f}\u{633}\u{652}\u{631}\u{64b}\u{627}',
    body:
        'So, verily, with the hardship, there is relief, verily, with the hardship, there is relief.',
    source: 'Quran 94:5-6 - Hilali & Khan',
    prompt: 'Where do you need to trust Allah through difficulty?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Steady deeds',
    arabic:
        '\u{648}\u{64e}\u{623}\u{64e}\u{646}\u{651}\u{64e} \u{623}\u{64e}\u{62d}\u{64e}\u{628}\u{651}\u{64e} \u{627}\u{644}\u{623}\u{64e}\u{639}\u{652}\u{645}\u{64e}\u{627}\u{644}\u{650} \u{623}\u{64e}\u{62f}\u{652}\u{648}\u{64e}\u{645}\u{64f}\u{647}\u{64e}\u{627} \u{625}\u{650}\u{644}\u{64e}\u{649} \u{627}\u{644}\u{644}\u{651}\u{64e}\u{647}\u{650}\u{60c} \u{648}\u{64e}\u{625}\u{650}\u{646}\u{652} \u{642}\u{64e}\u{644}\u{651}\u{64e}',
    body:
        'Do good deeds properly, sincerely and moderately, and know that the most beloved deed to Allah is the most regular and constant even if it were little.',
    source: 'Sahih al-Bukhari 6464',
    prompt: 'What small act can you keep returning to?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Allah is near',
    arabic:
        '\u{648}\u{64e}\u{625}\u{650}\u{630}\u{64e}\u{627} \u{633}\u{64e}\u{623}\u{64e}\u{644}\u{64e}\u{643}\u{64e} \u{639}\u{650}\u{628}\u{64e}\u{627}\u{62f}\u{650}\u{64a} \u{639}\u{64e}\u{646}\u{651}\u{650}\u{64a} \u{641}\u{64e}\u{625}\u{650}\u{646}\u{651}\u{650}\u{64a} \u{642}\u{64e}\u{631}\u{650}\u{64a}\u{628}\u{64c} \u{6d6} \u{623}\u{64f}\u{62c}\u{650}\u{64a}\u{628}\u{64f} \u{62f}\u{64e}\u{639}\u{652}\u{648}\u{64e}\u{629}\u{64e} \u{627}\u{644}\u{62f}\u{651}\u{64e}\u{627}\u{639}\u{650} \u{625}\u{650}\u{630}\u{64e}\u{627} \u{62f}\u{64e}\u{639}\u{64e}\u{627}\u{646}\u{650} \u{6d6} \u{641}\u{64e}\u{644}\u{652}\u{64a}\u{64e}\u{633}\u{652}\u{62a}\u{64e}\u{62c}\u{650}\u{64a}\u{628}\u{64f}\u{648}\u{627} \u{644}\u{650}\u{64a} \u{648}\u{64e}\u{644}\u{652}\u{64a}\u{64f}\u{624}\u{652}\u{645}\u{650}\u{646}\u{64f}\u{648}\u{627} \u{628}\u{650}\u{64a} \u{644}\u{64e}\u{639}\u{64e}\u{644}\u{651}\u{64e}\u{647}\u{64f}\u{645}\u{652} \u{64a}\u{64e}\u{631}\u{652}\u{634}\u{64f}\u{62f}\u{64f}\u{648}\u{646}\u{64e}',
    body:
        'And when My slaves ask you (O Muhammad) concerning Me, then (answer them), I am indeed near (to them by My Knowledge). I respond to the invocations of the supplicant when he calls on Me (without any mediator or intercessor). So let them obey Me and believe in Me, so that they may be led aright.',
    source: 'Quran 2:186 - Hilali & Khan',
    prompt: 'What dua has been waiting quietly inside you?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Learn and teach',
    arabic:
        '\u{62e}\u{64e}\u{64a}\u{652}\u{631}\u{64f}\u{643}\u{64f}\u{645}\u{652} \u{645}\u{64e}\u{646}\u{652} \u{62a}\u{64e}\u{639}\u{64e}\u{644}\u{651}\u{64e}\u{645}\u{64e} \u{627}\u{644}\u{652}\u{642}\u{64f}\u{631}\u{652}\u{622}\u{646}\u{64e} \u{648}\u{64e}\u{639}\u{64e}\u{644}\u{651}\u{64e}\u{645}\u{64e}\u{647}\u{64f}',
    body: 'The best among you are those who learn the Quran and teach it.',
    source: 'Sahih al-Bukhari 5027',
    prompt: 'What is one thing from the Quran you want to live or share today?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Do not despair',
    arabic:
        '\u{642}\u{64f}\u{644}\u{652} \u{64a}\u{64e}\u{627} \u{639}\u{650}\u{628}\u{64e}\u{627}\u{62f}\u{650}\u{64a}\u{64e} \u{627}\u{644}\u{651}\u{64e}\u{630}\u{650}\u{64a}\u{646}\u{64e} \u{623}\u{64e}\u{633}\u{652}\u{631}\u{64e}\u{641}\u{64f}\u{648}\u{627} \u{639}\u{64e}\u{644}\u{64e}\u{649}\u{670} \u{623}\u{64e}\u{646}\u{652}\u{641}\u{64f}\u{633}\u{650}\u{647}\u{650}\u{645}\u{652} \u{644}\u{64e}\u{627} \u{62a}\u{64e}\u{642}\u{652}\u{646}\u{64e}\u{637}\u{64f}\u{648}\u{627} \u{645}\u{650}\u{646}\u{652} \u{631}\u{64e}\u{62d}\u{652}\u{645}\u{64e}\u{629}\u{650} \u{627}\u{644}\u{644}\u{651}\u{64e}\u{647}\u{650} \u{6da} \u{625}\u{650}\u{646}\u{651}\u{64e} \u{627}\u{644}\u{644}\u{651}\u{64e}\u{647}\u{64e} \u{64a}\u{64e}\u{63a}\u{652}\u{641}\u{650}\u{631}\u{64f} \u{627}\u{644}\u{630}\u{651}\u{64f}\u{646}\u{64f}\u{648}\u{628}\u{64e} \u{62c}\u{64e}\u{645}\u{650}\u{64a}\u{639}\u{64b}\u{627} \u{6da} \u{625}\u{650}\u{646}\u{651}\u{64e}\u{647}\u{64f} \u{647}\u{64f}\u{648}\u{64e} \u{627}\u{644}\u{652}\u{63a}\u{64e}\u{641}\u{64f}\u{648}\u{631}\u{64f} \u{627}\u{644}\u{631}\u{651}\u{64e}\u{62d}\u{650}\u{64a}\u{645}\u{64f}',
    body:
        'Say: "O My slaves who have transgressed against themselves (by committing evil deeds and sins)! Despair not of the Mercy of Allah, verily, Allah forgives all sins. Truly, He is Oft-Forgiving, Most Merciful."',
    source: 'Quran 39:53 - Hilali & Khan',
    prompt: 'Where do you need to receive mercy instead of carrying shame?',
  ),
  _HomeSource(
    kind: 'Hadith',
    title: 'Good character',
    arabic:
        '\u{625}\u{650}\u{646}\u{651}\u{64e} \u{645}\u{650}\u{646}\u{652} \u{62e}\u{650}\u{64a}\u{64e}\u{627}\u{631}\u{650}\u{643}\u{64f}\u{645}\u{652} \u{623}\u{64e}\u{62d}\u{652}\u{633}\u{64e}\u{646}\u{64e}\u{643}\u{64f}\u{645}\u{652} \u{623}\u{64e}\u{62e}\u{652}\u{644}\u{64e}\u{627}\u{642}\u{64b}\u{627}',
    body:
        'The Prophet never used bad language. He used to say: The best amongst you are those who have the best manners and character.',
    source: 'Sahih al-Bukhari 3559',
    prompt: 'What would good character look like in your next conversation?',
  ),
  _HomeSource(
    kind: 'Quran',
    title: 'Gratitude increases',
    arabic:
        '\u{648}\u{64e}\u{625}\u{650}\u{630}\u{652} \u{62a}\u{64e}\u{623}\u{64e}\u{630}\u{651}\u{64e}\u{646}\u{64e} \u{631}\u{64e}\u{628}\u{651}\u{64f}\u{643}\u{64f}\u{645}\u{652} \u{644}\u{64e}\u{626}\u{650}\u{646}\u{652} \u{634}\u{64e}\u{643}\u{64e}\u{631}\u{652}\u{62a}\u{64f}\u{645}\u{652} \u{644}\u{64e}\u{623}\u{64e}\u{632}\u{650}\u{64a}\u{62f}\u{64e}\u{646}\u{651}\u{64e}\u{643}\u{64f}\u{645}\u{652} \u{6d6} \u{648}\u{64e}\u{644}\u{64e}\u{626}\u{650}\u{646}\u{652} \u{643}\u{64e}\u{641}\u{64e}\u{631}\u{652}\u{62a}\u{64f}\u{645}\u{652} \u{625}\u{650}\u{646}\u{651}\u{64e} \u{639}\u{64e}\u{630}\u{64e}\u{627}\u{628}\u{650}\u{64a} \u{644}\u{64e}\u{634}\u{64e}\u{62f}\u{650}\u{64a}\u{62f}\u{64c}',
    body:
        'And (remember) when your Lord proclaimed: "If you give thanks (by accepting Faith and worshipping none but Allah), I will give you more (of My Blessings), but if you are thankless (i.e. disbelievers), verily, My Punishment is indeed severe."',
    source: 'Quran 14:7 - Hilali & Khan',
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

// Reused by focused reading surfaces; the home screen now keeps one primary
// daily suggestion in the rhythm card.
// ignore: unused_element
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
    final colors = context.colors;
    final labelColor = colors.textPrimary;
    final bodyColor = colors.textPrimary;
    final sourceColor = colors.textSecondary;
    final accentBg = colors.surfaceContainerHigh;
    final reminderBg = colors.primaryContainer;
    final reminderText = colors.onPrimaryContainer;
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
                    color: colors.primary,
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
  Timer? _slotTimer;

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
    _slotTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _applyRhythm(DateTime.now()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyRhythm(DateTime.now());
    }
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
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

  _RhythmChoice _choiceFor(DateTime now, {int rotation = 0}) {
    final base = _baseChoiceFor(now);
    if (rotation == 0) return base;

    final alternatives = switch (base.action) {
      _TodayLightAction.morningAdhkar => [
        const _RhythmChoice(
          slotKey: 'morning-quran',
          title: 'Read a page of Quran',
          body: 'Let one page set the pace for the day.',
          source: 'Quran',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        ),
        const _RhythmChoice(
          slotKey: 'morning-sadaqah',
          title: 'Do an act of sadaqah',
          body: 'Choose one quiet act of goodness before the day gets busy.',
          source: 'Sadaqah',
          icon: Icons.favorite_border_rounded,
          action: _TodayLightAction.sadaqah,
        ),
      ],
      _TodayLightAction.kahf => [
        const _RhythmChoice(
          slotKey: 'friday-salawat-alt',
          title: 'Send salawat upon the Nabi',
          body: 'Let Friday carry prayers and peace upon him.',
          source: 'Friday reminder',
          icon: Icons.favorite_outline_rounded,
          action: _TodayLightAction.salawat,
        ),
        const _RhythmChoice(
          slotKey: 'friday-sadaqah',
          title: 'Give a little sadaqah',
          body: 'A small private kindness is still a meaningful light.',
          source: 'Friday reminder',
          icon: Icons.volunteer_activism_outlined,
          action: _TodayLightAction.sadaqah,
        ),
      ],
      _TodayLightAction.quranPage => [
        const _RhythmChoice(
          slotKey: 'afternoon-sadaqah-alt',
          title: 'Do an act of sadaqah',
          body:
              'Choose one private act of goodness before the afternoon passes.',
          source: 'Sadaqah',
          icon: Icons.favorite_border_rounded,
          action: _TodayLightAction.sadaqah,
        ),
        const _RhythmChoice(
          slotKey: 'afternoon-nawafil',
          title: 'A quiet nawafil moment',
          body: 'Make space for a small voluntary prayer if you are able.',
          source: 'Nawafil',
          icon: Icons.self_improvement_outlined,
          action: _TodayLightAction.nawafil,
        ),
      ],
      _TodayLightAction.sadaqah => [
        const _RhythmChoice(
          slotKey: 'afternoon-quran-alt',
          title: 'Read a page of Quran',
          body: 'Let one page bring a little stillness to the afternoon.',
          source: 'Quran',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        ),
        const _RhythmChoice(
          slotKey: 'afternoon-nawafil-alt',
          title: 'A quiet nawafil moment',
          body: 'Make space for a small voluntary prayer if you are able.',
          source: 'Nawafil',
          icon: Icons.self_improvement_outlined,
          action: _TodayLightAction.nawafil,
        ),
      ],
      _TodayLightAction.eveningAdhkar => [
        const _RhythmChoice(
          slotKey: 'evening-quran',
          title: 'Read a page of Quran',
          body: 'Close the day with a page read slowly and attentively.',
          source: 'Quran',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        ),
        const _RhythmChoice(
          slotKey: 'evening-sadaqah',
          title: 'Do an act of sadaqah',
          body: 'Leave one small kindness in the world before sleep.',
          source: 'Sadaqah',
          icon: Icons.favorite_border_rounded,
          action: _TodayLightAction.sadaqah,
        ),
      ],
      _TodayLightAction.salawat => [
        const _RhythmChoice(
          slotKey: 'friday-kahf-alt',
          title: 'Read Surah Al-Kahf',
          body: 'Return to the light of the cave on this blessed day.',
          source: 'Quran 18',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.kahf,
        ),
        const _RhythmChoice(
          slotKey: 'friday-sadaqah-alt',
          title: 'Give a little sadaqah',
          body: 'A small private kindness is still a meaningful light.',
          source: 'Friday reminder',
          icon: Icons.volunteer_activism_outlined,
          action: _TodayLightAction.sadaqah,
        ),
      ],
      _TodayLightAction.tahajjud => [
        const _RhythmChoice(
          slotKey: 'night-nawafil',
          title: 'A quiet nawafil moment',
          body: 'Make space for a small voluntary prayer if you are able.',
          source: 'Nawafil',
          icon: Icons.self_improvement_outlined,
          action: _TodayLightAction.nawafil,
        ),
        const _RhythmChoice(
          slotKey: 'night-quran',
          title: 'Read a page of Quran',
          body: 'Let the quiet of the night hold one page of Quran.',
          source: 'Quran',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        ),
      ],
      _TodayLightAction.nawafil => [
        const _RhythmChoice(
          slotKey: 'late-sadaqah',
          title: 'Do an act of sadaqah',
          body: 'Choose a private good deed before the day closes.',
          source: 'Sadaqah',
          icon: Icons.favorite_border_rounded,
          action: _TodayLightAction.sadaqah,
        ),
        const _RhythmChoice(
          slotKey: 'late-quran',
          title: 'Read a page of Quran',
          body: 'Let one page bring the day to a peaceful close.',
          source: 'Quran',
          icon: Icons.menu_book_outlined,
          action: _TodayLightAction.quranPage,
        ),
      ],
    };
    return alternatives[(rotation - 1) % alternatives.length];
  }

  _RhythmChoice _baseChoiceFor(DateTime now) {
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
    final colors = context.colors;
    final accent = isFriday ? colors.secondary : colors.primary;
    final iconBg = colors.primaryContainer;
    final titleColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final sourceColor = colors.textMuted;

    return InkWell(
      onTap: _openAction,
      borderRadius: BorderRadius.circular(MizanRadii.card),
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
            Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
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
    final colors = context.colors;
    final titleColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final accent = colors.primary;
    final iconBg = colors.primaryContainer;
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
                      Icon(Icons.menu_book_outlined, color: colors.secondary),
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
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: colors.secondary,
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

class _TodaysReflection extends StatefulWidget {
  const _TodaysReflection();

  @override
  State<_TodaysReflection> createState() => _TodaysReflectionState();
}

class _TodaysReflectionState extends State<_TodaysReflection> {
  Timer? _slotTimer;
  late int _slot;

  @override
  void initState() {
    super.initState();
    _slot = _daySlot(DateTime.now());
    _slotTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nextSlot = _daySlot(DateTime.now());
      if (nextSlot != _slot && mounted) {
        setState(() => _slot = nextSlot);
      }
    });
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verse = _sourceForSlot(_slot);
    final prompt = verse.prompt;
    final colors = context.colors;
    final iconBg = colors.primaryContainer;
    final bodyColor = colors.textPrimary;
    final sourceColor = colors.textSecondary;
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
                        color: colors.primary,
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
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
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
    backgroundColor: context.colors.surface,
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
              color: context.colors.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Your reflection was saved to your journey.',
              style: TextStyle(color: context.colors.onPrimary),
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
      final title = widget.verse.source;
      final reflectionBody =
          '${widget.verse.arabic}\n\n${widget.verse.body}\n\n${widget.prompt}\n\n$body';
      // Save to the durable outbox before attempting any network work. The
      // shared sync service handles retries and request-id deduplication.
      await QueueSyncService.instance.enqueueAndSync(
        OfflineQueueItem(
          id: localId,
          actionType: ActionType.createReflection,
          payload: {
            'title': title,
            'body': reflectionBody,
            'mood': 'Reflective',
            'is_private': false,
            'request_id': localId,
          },
          createdAt: DateTime.now(),
        ),
      );
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
    final colors = context.colors;
    final titleColor = colors.textPrimary;
    final bodyColor = colors.textPrimary;
    final promptBg = colors.primaryContainer;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MizanSpacing.xl,
        MizanSpacing.xl,
        MizanSpacing.xl,
        MizanSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
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
                style: TextStyle(
                  color: colors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
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
                          color: colors.onPrimary,
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        softWrap: true,
        style: TextStyle(
          color: colors.textPrimary,
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
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: MizanSpacing.card,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(MizanRadii.card),
        border: Border.all(color: tokens.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: tokens.scrim.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
