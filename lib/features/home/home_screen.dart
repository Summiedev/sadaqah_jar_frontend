import 'package:flutter/material.dart';
import '../../services/content_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'add_act_screen.dart';
import '../../core/mode_provider.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSurface, kClayLight, kPaper],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final offset = notification.metrics.pixels;
                if (offset > 10) {
                  if (!ref.read(isScrolledProvider.notifier).state) {
                    ref.read(isScrolledProvider.notifier).state = true;
                  }
                } else if (offset <= 0) {
                  if (ref.read(isScrolledProvider.notifier).state) {
                    ref.read(isScrolledProvider.notifier).state = false;
                  }
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    floating: false,
                    toolbarHeight: 122,
                    collapsedHeight: 122,
                    expandedHeight: 122,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: _PremiumHomeHeader(),
                  ),
                   SliverPadding(
                     padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                     sliver: SliverList.list(children: [
                       CardEntrance(index: 0, child: PrayerTrackerCard()),
                       const SizedBox(height: 10),
                       const SyncStatusBanner(),
                       const SizedBox(height: 10),
                       CardEntrance(index: 1, child: _JarHero(totalActs: acts.totalStars, progress: acts.progress, onAdd: () => AddActScreen.show(context), remainingActs: acts.remainingActs)),
                      const SizedBox(height: 10),
                      CardEntrance(index: 3, child: _RhythmOfTheDayCard(onTap: () {
                        final now = DateTime.now();
                        // reuse Rhythm card's internal logic: morning -> morning adhkar, afterAsr -> evening
                        final dhuhr = TimeOfDay(hour: 12, minute: 15);
                        final asr = TimeOfDay(hour: 15, minute: 45);
                        final minutes = now.hour * 60 + now.minute;
                        final dhuhrMins = dhuhr.hour * 60 + dhuhr.minute;
                        final asrMins = asr.hour * 60 + asr.minute;
                        if (minutes < dhuhrMins) {
                          context.push('/journey/adhkar/morning');
                        } else if (minutes < asrMins) {
                          // during dhuhr/asr window, go to after salah adhkar
                          context.push('/journey/adhkar/after_salah');
                        } else {
                          context.push('/journey/adhkar/evening');
                        }
                      })),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 4, child: _SectionHeading('Explore')),
                      const SizedBox(height: 12),
                      const CardEntrance(index: 4, child: _VerifiedDonationsCard()),
                      const SizedBox(height: 12),
                      const CardEntrance(index: 5, child: _TodaysGentleActs()),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 6, child: _LastReadCard()),
                      const SizedBox(height: 10),
                      const CardEntrance(index: 7, child: _TodaysReflection()),
                    ]),
                  ),
                ],
              ),
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
  late final Future<AccountSnapshot?> _profileFuture = BackendApi.instance.getAccountSnapshot();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = dark ? kSurfaceDark : kClayLight;
    final border = dark ? kLineDark : kLine;
    final primary = dark ? kInkDark : kInk;
    final secondary = dark ? kMutedDark : kMuted;
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [BoxShadow(color: dark ? Colors.black12 : Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: FutureBuilder<AccountSnapshot?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final account = snapshot.data;
          final name = _firstName(account?.username ?? account?.email ?? '');
          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(now)}, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: primary, fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, height: 1.15),
                    ),
                    const SizedBox(height: 7),
                    Text(_hijriLabel(now), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondary, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(_gregorianLabel(now), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondary.withValues(alpha: 0.82), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              NotificationActionButton(onPressed: () => context.push('/notifications')),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => context.push('/profile'),
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: dark ? kPaperDark : kPaper,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                    style: TextStyle(color: dark ? kBronzeLight : kBronzeDark, fontWeight: FontWeight.w800),
                  ),
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

  String _greeting(DateTime now) {
    if (now.hour < 5) return 'Assalamu Alaikum';
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    if (now.hour < 21) return 'Good Evening';
    return 'Assalamu Alaikum';
  }

  String _gregorianLabel(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _hijriLabel(DateTime date) {
    const months = ['Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah'];
    final jd = (date.millisecondsSinceEpoch / 86400000).floor() + 2440588;
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = (((10985 - l2) / 5316).floor()) * (((50 * l2) / 17719).floor()) + ((l2 / 5670).floor()) * (((43 * l2) / 15238).floor());
    final l3 = l2 - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) - (j / 16).floor() * (((15238 * j) / 43).floor()) + 29;
    final month = ((24 * l3) / 709).floor();
    final day = l3 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return '🌙 ${day.round()} ${months[(month - 1).clamp(0, 11)]} ${year.round()} AH';
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
                    Text(display, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 23, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text('Small goodness, beautifully kept.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
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

class _NotifIcon extends StatelessWidget {
  const _NotifIcon();
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.notifications_none_outlined, color: kInk),
        tooltip: 'Notifications',
        onPressed: () => context.push('/notifications'),
      );
}

class _StreakPill extends ConsumerWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actStoreProvider);
    final streak = acts.currentStreak;
    final hasError = acts.streakError;

    Widget child;

    if (streak == null && !hasError) {
      child = Container(
        key: const ValueKey('streak-loading'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kClayPale,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kLine),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: kBronze)),
          SizedBox(width: 8),
        ]),
      );
    } else if (streak == null && hasError) {
      child = Container(
        key: const ValueKey('streak-error'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kClayPale,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kLine),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            onPressed: () => ref.read(actStoreProvider).retryStreak(),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: kBronze),
            tooltip: 'Retry',
          ),
          const Text('—', style: TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      );
    } else {
      child = Container(
        key: ValueKey('streak-$streak'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kLine),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kBronzeLight,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: kBronze.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: kDanger, size: 18),
          ),
          const SizedBox(width: 8),
          AnimatedNumber(value: streak!, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      );
    }

    return AnimatedSwitcher(
      duration: MizanMotion.normal,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
  }
}

class _JarHero extends ConsumerWidget {
  const _JarHero({required this.totalActs, required this.progress, required this.onAdd, required this.remainingActs});
  final int totalActs;
  final double progress;
  final VoidCallback onAdd;
  final int remainingActs;

  String _progressMessage() {
    if (totalActs == 0) return 'Every act of kindness starts with one';
    if (progress >= 1.0) return 'Your jar is full — intention fulfilled 🤲';
    if (progress >= 0.75) return 'Almost there — $remainingActs to go';
    if (progress >= 0.4) return 'Halfway to your intention';
    if (progress >= 0.15) return 'Off to a good start';
    return 'Your jar is waiting to be filled';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actStoreProvider);
    final goalTitle = acts.goalTitle;

    return AnimatedSwitcher(
      key: ValueKey('jar-$totalActs-$progress'),
      duration: MizanMotion.slow,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey('jar-$totalActs-$progress'),
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? kPaperDark : kInk,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: kInk.withValues(alpha: 0.13), blurRadius: 24, offset: Offset(0, 12))],
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
                            goalTitle != null ? goalTitle.toUpperCase() : 'MY SADAQAH JAR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kBronzeLight, fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Edit goal',
                          onPressed: acts.goalId == null ? null : () => _showEditGoal(context, ref),
                          icon: const Icon(Icons.edit_outlined, color: kBronzeLight, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    TweenAnimationBuilder<double>(
                      duration: MizanMotion.slow,
                      curve: MizanMotion.gentle,
                      tween: Tween(begin: 0, end: progress),
                      builder: (context, value, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${(value * 100).round()}% filled',
                          style: const TextStyle(color: kPaper, fontFamily: 'Georgia', fontSize: 25, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    AnimatedSwitcher(
                      duration: MizanMotion.slow,
                      switchInCurve: MizanMotion.gentle,
                      switchOutCurve: MizanMotion.gentle,
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _progressMessage(),
                        key: ValueKey(_progressMessage()),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kClayLight, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 18),

                    TweenAnimationBuilder<double>(
                      duration: MizanMotion.slow,
                      curve: MizanMotion.gentle,
                      tween: Tween(begin: 0, end: progress),
                      builder: (context, value, _) => SmoothProgress(value: value, height: 7, color: kBronzeLight, backgroundColor: kStone),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      remainingActs > 0
                          ? '$remainingActs more acts to reach your intention'
                          : 'Intention reached — jazākumu Llāhu khayran',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kClayLight, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add an act'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kBronze,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              SizedBox(
                width: 92,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      tween: Tween(begin: 0.85, end: 1.0),
                      builder: (context, glow, child) => Opacity(
                        opacity: (0.15 + 0.15 * progress) * glow,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [kBronzeLight.withValues(alpha: 0.6), Colors.transparent]),
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(child: FamilyJarView(fill: progress, size: 92, glow: .9)),
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
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        Future<void> save() async {
          final parsedTarget = int.tryParse(target.text.trim());
          if (title.text.trim().isEmpty || parsedTarget == null || parsedTarget <= 0 || saving) {
            setSheetState(() => error = 'Add a title and a valid target.');
            return;
          }
          setSheetState(() {
            saving = true;
            error = null;
          });
          try {
            await ref.read(actStoreProvider).updateGoal(
                  title: title.text.trim(),
                  subtitle: subtitle.text.trim().isEmpty ? null : subtitle.text.trim(),
                  actsTarget: parsedTarget,
                );
            if (context.mounted) Navigator.of(context).pop();
          } catch (_) {
            setSheetState(() {
              saving = false;
              error = 'Could not update goal. Please try again.';
            });
          }
        }

        final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Edit goal', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: title, enabled: !saving, decoration: const InputDecoration(labelText: 'Goal title')),
              const SizedBox(height: 12),
              TextField(controller: target, enabled: !saving, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target acts')),
              const SizedBox(height: 12),
              TextField(controller: subtitle, enabled: !saving, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description or intention')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : const Text('Save changes'),
              ),
            ]),
          ),
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
  Widget build(BuildContext context) => FadeScaleTransition(
        beginScale: 0.97,
        child: Material(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          elevation: 0,
          shadowColor: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/charities'),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kLine),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: Offset(0, 3))],
              ),
                child: Row(children: [
                const CircleAvatar(radius: 24, backgroundColor: kClay, child: Icon(Icons.volunteer_activism_outlined, color: kBronze, size: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verified Donations', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Discover and support trusted causes.', style: TextStyle(color: kInk.withValues(alpha: 0.65), fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: kBronze),
              ]),
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, color: kInk, fontWeight: FontWeight.w700));
}

class _TodaysGentleActs extends StatelessWidget {
  const _TodaysGentleActs();

  // Intentional static curated content — rotated by day-of-month.
  // Move to backend when a content API is available.
  static const _reminders = [
    {
      'arabic': 'يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا وَسَبِّحُوهُ بُكْرَةً وَأَصِيلًا',
      'translation': 'O you who have believed, remember Allah with much remembrance and exalt Him morning and afternoon.',
      'source': 'Quran 33:41-42',
      'reminder': 'Don\'t forget to remember Allah today — in every moment, a remembrance.',
    },
    {
      'arabic': 'وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ ۖ وَلَئِن كَفَرْتُمْ إِنَّ عَذَابِي لَشَدِيدٌ',
      'translation': 'And when your Lord proclaimed, "If you are grateful, I will surely increase you; but if you deny, indeed, My punishment is severe."',
      'source': 'Quran 14:7',
      'reminder': 'Don\'t forget to thank Allah today — gratitude opens the door to more.',
    },
    {
      'arabic': 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'translation': 'Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured.',
      'source': 'Quran 13:28',
      'reminder': 'Don\'t forget to find peace in His remembrance today — it settles the heart.',
    },
    {
      'arabic': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'translation': 'All praise is due to Allah, Lord of the worlds, the Most Gracious, the Most Merciful, Master of the Day of Judgment. You alone we worship, and You alone we ask for help.',
      'source': 'Quran 1:2-5',
      'reminder': 'Don\'t forget — start everything with praise, and seek His help in all things.',
    },
    {
      'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      'translation': 'And whoever fears Allah — He will make for him a way out and will provide for him from where he does not expect.',
      'source': 'Quran 65:2-3',
      'reminder': 'Don\'t forget to trust Allah today — He always makes a way.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final item = _reminders[DateTime.now().day % _reminders.length];
    return FadeScaleTransition(
      beginScale: 0.97,
      child: _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                 color: kWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_outlined, color: kBronze, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'A gentle reminder',
                style: TextStyle(color: kInk, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _ArabicText(item['arabic']!),
          const SizedBox(height: 12),
          Text(
            item['translation']!,
            style: TextStyle(color: kInk.withValues(alpha: 0.85), fontSize: 15, height: 1.6, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kBronze.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '✨ ${item['reminder']!}',
              style: const TextStyle(color: kBronzeDark, fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['source']!,
            style: TextStyle(color: kInk.withValues(alpha: 0.55), fontSize: 11.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class _RhythmOfTheDayCard extends StatefulWidget {
  const _RhythmOfTheDayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_RhythmOfTheDayCard> createState() => _RhythmOfTheDayCardState();
}

class _RhythmOfTheDayCardState extends State<_RhythmOfTheDayCard> with WidgetsBindingObserver {
  bool _loading = true;
  String? _title;
  String? _body;
  String? _arabic;
  String? _source;
  bool _isFriday = false;

  // Static prayer times — intentionally hardcoded as gentle placeholders.
  // Wire to location-based calculation (e.g. adhan API) when geo permissions
  // and backend support are ready.
  static const _dhuhr = TimeOfDay(hour: 12, minute: 15);
  static const _asr = TimeOfDay(hour: 15, minute: 45);

  // Static adhkar and Friday reminder — intentional curated content.
  // Replace with backend-driven content when the journey/content API is live.
  static const _fridayTitle = 'Read Surah Al-Kahf';
  static const _fridayBody = 'A light for the day and the path ahead.';
  static const _morningAdhkar = [
    {'title': 'Morning remembrance', 'arabic': 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ', 'source': 'Muslim', 'repeat': 'Once'},
    {'title': 'Morning protection', 'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ', 'source': 'Muslim', 'repeat': 'Three times'},
  ];
  static const _eveningAdhkar = [
    {'title': 'Evening remembrance', 'arabic': 'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ', 'source': 'Muslim', 'repeat': 'Once'},
    {'title': 'Evening protection', 'arabic': 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ', 'source': 'Abu Dawud', 'repeat': 'Three times'},
  ];
  static const _prayerSchedule = [
    {'name': 'Dhuhr', 'time': '12:15'},
    {'name': 'Asr', 'time': '15:45'},
    {'name': 'Maghrib', 'time': '18:45'},
  ];

  // Static content — intentional curated verses/reminders.
  // Rotated by day-of-month. Replace with backend-driven source when ready.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final now = DateTime.now();
    _isFriday = now.weekday == DateTime.friday;

    await Future.delayed(const Duration(milliseconds: 300));

    // Try to load backend-driven rhythm content if available.
    try {
      final remote = await ContentService.instance.fetchRhythmOfTheDay();
      if (remote != null) {
        if (!mounted) return;
        setState(() {
          _title = remote['title']?.toString();
          _body = remote['body']?.toString();
          _arabic = remote['arabic']?.toString();
          _source = remote['source']?.toString();
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    final timeOfDay = _getTimeOfDay(now);

    if (_isFriday) {
      setState(() {
        _title = _fridayTitle;
        _body = _fridayBody;
        _loading = false;
      });
    } else if (timeOfDay == _TimeOfDay.morning) {
      final item = _morningAdhkar.first;
      setState(() {
        _title = item['title'];
        _arabic = item['arabic'];
        _source = item['source'];
        _loading = false;
      });
    } else if (timeOfDay == _TimeOfDay.afterAsr) {
      final item = _eveningAdhkar.first;
      setState(() {
        _title = item['title'];
        _arabic = item['arabic'];
        _source = item['source'];
        _loading = false;
      });
    } else {
      final next = _getNextSalah(now);
      final schedule = _prayerSchedule.map((p) => '${p['name']} — ${p['time']}').join('\n');
      setState(() {
        _title = 'Next: $next';
        _body = schedule;
        _loading = false;
      });
    }
  }

  String _getNextSalah(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    final dhuhr = _dhuhr.hour * 60 + _dhuhr.minute;
    final asr = _asr.hour * 60 + _asr.minute;
    if (minutes < dhuhr) return 'Dhuhr';
    if (minutes < asr) return 'Asr';
    return 'Maghrib';
  }

  _TimeOfDay _getTimeOfDay(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    final dhuhr = _dhuhr.hour * 60 + _dhuhr.minute;
    final asr = _asr.hour * 60 + _asr.minute;
    if (minutes < dhuhr) return _TimeOfDay.morning;
    if (minutes < asr) return _TimeOfDay.dhuhrAsr;
    return _TimeOfDay.afterAsr;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MizanMotion.normal,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      child: _loading
          ? _Surface(
              key: const ValueKey('rhythm-loading'),
              child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))),
            )
          : _buildContent(key: const ValueKey('rhythm-loaded')),
    );
  }

  Widget _buildContent({required Key key}) {
    final isFriday = _isFriday;
    final icon = isFriday ? Icons.menu_book_outlined : Icons.wb_sunny_outlined;
    final accent = isFriday ? kSage : kBronze;

    return FadeScaleTransition(
      key: key,
      beginScale: 0.97,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        child: _Surface(
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isFriday ? 'Today\'s light' : 'Rhythm of the day', style: const TextStyle(color: kInk, fontSize: 10.5, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_title ?? '', style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
                  if (_arabic != null && _arabic!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _ArabicText(_arabic!, fontSize: 18),
                  ],
                  if (_body != null && _body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: kInk.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600)),
                  ],
                  if (_source != null && _source!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_source!, style: TextStyle(color: kInk.withValues(alpha: 0.55), fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: kBronze, size: 18),
          ]),
        ),
      ),
    );
  }
}

enum _TimeOfDay { morning, dhuhrAsr, afterAsr }

class _LastReadCard extends StatefulWidget {
  const _LastReadCard();

  @override
  State<_LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<_LastReadCard> {
  String? _bookTitle;
  String? _chapterTitle;
  bool _loadingTitles = false;

  @override
  void didUpdateWidget(covariant _LastReadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveTitles();
  }

  Future<void> _resolveTitles() async {
    final progress = await BackendApi.instance.getLastReadingProgress();
    if (!mounted || progress == null) return;
    final bookId = progress['book_id'] as int? ?? 0;
    final chapterNumber = progress['chapter_number'] as int? ?? 1;
    if (_bookTitle != null && _chapterTitle != null) return;
    setState(() => _loadingTitles = true);
    try {
      final book = await BackendApi.instance.getBook(bookId);
      final chapters = await BackendApi.instance.getBookChapters(bookId);
      final chapter = chapters.firstWhere(
        (c) => c.chapterNumber == chapterNumber,
        orElse: () => chapters.isNotEmpty ? chapters.first : BookChapterRead(id: 0, bookId: bookId, chapterNumber: chapterNumber, title: 'Chapter $chapterNumber'),
      );
      if (!mounted) return;
      setState(() {
        _bookTitle = book.title;
        _chapterTitle = chapter.title;
        _loadingTitles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTitles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: BackendApi.instance.getLastReadingProgress(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _Surface(
            key: const ValueKey('lastread-loading'),
            child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))),
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
                  child: Row(children: [
                    const Icon(Icons.menu_book_outlined, color: kSage),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start your first reading', style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Open the journey to explore', style: TextStyle(color: kInk.withValues(alpha: 0.65), fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: kBronze),
                  ]),
                ),
              ),
            );
          } else {
            final bookId = progress['book_id'] as int? ?? 0;
            final chapter = progress['chapter_number'] as int? ?? 1;
            final bookTitle = _bookTitle ?? 'Book $bookId';
            final chapterTitle = _chapterTitle ?? 'Chapter $chapter';
            if (_bookTitle == null && _chapterTitle == null && !_loadingTitles) {
              _resolveTitles();
            }
            child = FadeScaleTransition(
              key: const ValueKey('lastread-progress'),
              beginScale: 0.97,
              child: InkWell(
                onTap: () => context.push('/journey'),
                child: _Surface(
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bookmark_rounded, color: kSage, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Continue reading', style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('$bookTitle, $chapterTitle', style: TextStyle(color: kInk.withValues(alpha: 0.65), fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: kBronze, size: 18),
                  ]),
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
  static const _verses = [
    {'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ', 'translation': 'Allah — there is no god except Him, the Ever-Living, the Sustainer of all. Neither drowsiness nor sleep overtakes Him. To Him belongs whatever is in the heavens and whatever is on the earth.', 'source': 'Quran 2:255'},
    {'arabic': 'شَهِدَ اللَّهُ أَنَّهُ لَا إِلَٰهَ إِلَّا هُوَ وَالْمَلَائِكَةُ وَأُولُو الْعِلْمِ قَائِمًا بِالْقِسْطِ ۚ لَا إِلَٰهَ إِلَّا هُوَ الْعَزِيزُ الْحَكِيمُ', 'translation': 'Allah bears witness that there is no god except Him, as do the angels and those of knowledge, maintaining justice. There is no god except Him, the Almighty, the All-Wise.', 'source': 'Quran 3:18'},
    {'arabic': 'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ الَّذِي خَلَقَ الْمَوْتَ وَالْحَيَاةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا', 'translation': 'Blessed is the One in whose hand is all authority, and He has power over all things, who created death and life to test you as to which of you is best in deeds.', 'source': 'Quran 67:1-2'},
    {'arabic': 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا', 'translation': 'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins.', 'source': 'Quran 39:53'},
    {'arabic': 'هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ ۖ عَالِمُ الْغَيْبِ وَالشَّهَادَةِ ۖ هُوَ الرَّحْمَٰنُ الرَّحِيمُ هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْمَلِكُ الْقُدُّوسُ السَّلَامُ', 'translation': 'He is Allah, the One besides whom there is no god, the Knower of the unseen and the seen. He is the Most Gracious, the Most Merciful. He is Allah, the King, the Holy, the Source of Peace.', 'source': 'Quran 59:22-23'},
  ];
  static const _prompts = [
    'What is a blessing you enjoyed today that you often take for granted? How can you express gratitude for it?',
    'When did you feel most present today? What made that moment feel meaningful?',
    'Who made a positive difference in your day, even in a small way? How can you acknowledge them?',
    'What is one thing you can let go of before tomorrow? How will that free your heart?',
    'What small act of goodness brought you peace today? How can you repeat it tomorrow?',
  ];
  @override
  Widget build(BuildContext context) {
    final verse = _verses[DateTime.now().day % _verses.length];
    final prompt = _prompts[DateTime.now().day % _prompts.length];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeading('Today\'s reflection'),
      const SizedBox(height: 12),
      FadeScaleTransition(
        beginScale: 0.97,
        child: _Surface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book_rounded, color: kBronze, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(verse['source']!, style: TextStyle(color: kInk.withValues(alpha: 0.75), fontSize: 12.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 14),
            _ArabicText(verse['arabic']!),
            const SizedBox(height: 10),
            Text(verse['translation']!, style: TextStyle(color: kInk.withValues(alpha: 0.85), fontSize: 15, height: 1.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
SizedBox(
	               width: double.infinity,
	               child: Consumer(
	                 builder: (context, ref, _) => FilledButton.icon(
	                   onPressed: () => _showVerseReflection(context, verse, prompt, ref),
	                   icon: const Icon(Icons.edit_outlined, size: 18),
	                   label: const Text('Reflect on this verse'),
	                   style: FilledButton.styleFrom(backgroundColor: kBronze, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
	                 ),
	               ),
	             ),
          ]),
        ),
      ),
    ]);
  }
}

Future<void> _showVerseReflection(BuildContext context, Map<String, String> verse, String prompt, WidgetRef ref) async {
  final controller = TextEditingController();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    builder: (sheetContext) => _VerseReflectionSheet(
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
          content: Row(children: [Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 18), const SizedBox(width: 10), Text('Your reflection was saved to your journey.', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))]),
      ),
    );
  }
}

class _VerseReflectionSheet extends StatefulWidget {
  const _VerseReflectionSheet({required this.verse, required this.prompt, required this.controller});

  final Map<String, String> verse;
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
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
      final queueItem = OfflineQueueItem(
        id: localId,
        actionType: ActionType.createReflection,
        payload: {
          'title': widget.verse['source']!,
          'body': '${widget.verse['translation']}\n\n${widget.prompt}\n\n$body',
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Reflect on ${widget.verse['source']}', style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 12),
          _ArabicText(widget.verse['arabic']!),
          const SizedBox(height: 10),
          Text(widget.verse['translation']!, style: TextStyle(color: kInk.withValues(alpha: 0.85), fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(14)),
            child: Text(widget.prompt, style: const TextStyle(color: kInk, fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.controller,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(hintText: 'What does this verse invite you to carry today?'),
            enabled: !_saving,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: kDanger, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBronze, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: _saving ? null : _save,
            child: _saving
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
              : const Text('Save to my journey'),
          ),
        ]),
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
          style: TextStyle(color: kInk, fontSize: fontSize, height: 1.9, fontFamily: 'Georgia'),
        ),
      );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = Theme.of(context).colorScheme.surface;
    final border = Theme.of(context).dividerColor;
    final shadowColor = brightness == Brightness.light ? Colors.black.withValues(alpha: 0.03) : Colors.black12;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}
