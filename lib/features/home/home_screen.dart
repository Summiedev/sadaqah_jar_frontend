import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'add_act_screen.dart';
import '../../core/mode_provider.dart';

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
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  toolbarHeight: 64,
                  collapsedHeight: 64,
                  expandedHeight: 64,
                  backgroundColor: kClayLight,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Sanctuary'),
                   actions: [const _NotifIcon(), const SizedBox(width: 10), const _StreakPill(), const SizedBox(width: 14)],
                ),
                 SliverPadding(
                   padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                   sliver: SliverList.list(children: [
                     const CardEntrance(index: 0, child: _HomeHeader()),
                     const SizedBox(height: 20),
                     CardEntrance(index: 1, child: _JarHero(totalActs: acts.totalStars, progress: acts.progress, onAdd: () => AddActScreen.show(context), remainingActs: acts.remainingActs)),
                     const SizedBox(height: 16),
                     CardEntrance(index: 2, child: _AddTodayCard(onTap: () => AddActScreen.show(context))),
                     const SizedBox(height: 16),
                     CardEntrance(index: 3, child: _RhythmOfTheDayCard(onTap: () => context.push('/journey'))),
                     const SizedBox(height: 16),
                     const CardEntrance(index: 4, child: _VerifiedDonationsCard()),
                     const SizedBox(height: 20),
                     const CardEntrance(index: 5, child: _TodaysGentleActs()),
                     const SizedBox(height: 16),
                     const CardEntrance(index: 6, child: _LastReadCard()),
                     const SizedBox(height: 16),
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
        return Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(display, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 23, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Small goodness, beautifully kept.', style: TextStyle(color: kMuted, fontSize: 13)),
          ])),
        ]);
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

    if (streak == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kClayPale,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kLine),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.2, color: kBronze)),
          const SizedBox(width: 8),
        ]),
      );
    }

    return AnimatedSwitcher(
      key: ValueKey('streak-$streak'),
      duration: MizanMotion.normal,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      child: Container(
        key: ValueKey('streak-$streak'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kClayPale,
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
              boxShadow: const [BoxShadow(color: Color(0x26FF8C00), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: kDanger, size: 18),
          ),
          const SizedBox(width: 8),
          AnimatedNumber(value: streak, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _JarHero extends ConsumerWidget {
  const _JarHero({required this.totalActs, required this.progress, required this.onAdd, required this.remainingActs});
  final int totalActs;
  final double progress;
  final VoidCallback onAdd;
  final int remainingActs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actStoreProvider);
    final goalTitle = acts.goalTitle;
    return AnimatedSwitcher(
      key: ValueKey('jar-$totalActs-$progress'),
      duration: MizanMotion.slow,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      child: Container(
        key: ValueKey('jar-$totalActs-$progress'),
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(goalTitle != null ? goalTitle.toUpperCase() : 'MY SADAQAH JAR', style: const TextStyle(color: kBronzeLight, fontSize: 10.5, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('${(progress * 100).round()}% filled', style: const TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 27, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            AnimatedNumber(value: totalActs, style: const TextStyle(color: kMutedLight, fontSize: 13)),
            const SizedBox(height: 18),
            SmoothProgress(value: progress, height: 7, color: kBronzeLight, backgroundColor: kInk),
            const SizedBox(height: 8),
            Text('$remainingActs more acts to reach your intention', style: const TextStyle(color: kClayLight, fontSize: 11.5)),
          ])),
          const SizedBox(width: 8),
          ExcludeSemantics(child: SizedBox(width: 110, height: 166, child: FamilyJarView(fill: progress, size: 108, glow: .9))),
        ]),
      ),
    );
  }
}

class _AddTodayCard extends StatelessWidget {
  const _AddTodayCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FadeScaleTransition(
    beginScale: 0.97,
    child: Material(
      color: kWhite,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kLine),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: const Row(children: [
            CircleAvatar(radius: 24, backgroundColor: Color(0xFFE8DCCF), child: Icon(Icons.add_rounded, color: kBronze, size: 28)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add sadaqah for today', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('A gift, dhikr, a kindness, a prayer - it all counts.', style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
            ])),
            Icon(Icons.arrow_forward_rounded, color: kBronze),
          ]),
        ),
      ),
    ),
  );
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
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: const Row(children: [
            CircleAvatar(radius: 24, backgroundColor: Color(0xFFE8DCCF), child: Icon(Icons.volunteer_activism_outlined, color: kBronze, size: 26)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Verified Donations', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Discover and support trusted causes.', style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
            ])),
            Icon(Icons.arrow_forward_rounded, color: kBronze),
          ]),
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget { const _SectionHeading(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, color: kInk, fontWeight: FontWeight.w700)); }

class _TodaysGentleActs extends StatelessWidget {
  const _TodaysGentleActs();

  /// Longer Quranic verses and reminders for daily reflection
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
    return _Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E3D4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_outlined, color: kBronze, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'A gentle reminder',
              style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        _ArabicText(item['arabic']!),
        const SizedBox(height: 14),
        Text(
          item['translation']!,
          style: const TextStyle(color: kInk, fontSize: 15, height: 1.6, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x1A8B6842),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '✨ ${item['reminder']!}',
            style: const TextStyle(color: kBronzeDark, fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item['source']!,
          style: const TextStyle(color: kMutedLight, fontSize: 11.5, fontStyle: FontStyle.italic),
        ),
      ]),
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

  static const _dhuhr = TimeOfDay(hour: 12, minute: 15);
  static const _asr = TimeOfDay(hour: 15, minute: 45);

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
    if (_loading) {
      return _Surface(
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))),
      );
    }

    final isFriday = _isFriday;
    final icon = isFriday ? Icons.menu_book_outlined : Icons.wb_sunny_outlined;
    final accent = isFriday ? kSage : kBronze;

    return FadeScaleTransition(
      beginScale: 0.97,
      child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: _Surface(
            child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isFriday ? 'Today\'s light' : 'Rhythm of the day', style: TextStyle(color: kInk, fontSize: 10.5, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_title ?? '', style: TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
          if (_arabic != null && _arabic!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ArabicText(_arabic!, fontSize: 18),
          ],
          if (_body != null && _body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4)),
          ],
          if (_source != null && _source!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_source!, style: const TextStyle(color: kMutedLight, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ])),
        Icon(Icons.arrow_forward_rounded, color: kBronze, size: 18),
      ]),
    ),
  ),
);
  }
}

enum _TimeOfDay { morning, dhuhrAsr, afterAsr }

class _LastReadCard extends StatelessWidget {
  const _LastReadCard();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: BackendApi.instance.getLastReadingProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Surface(child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))));
        }
        final progress = snapshot.data;
        if (progress == null) {
          return FadeScaleTransition(
            beginScale: 0.97,
            child: InkWell(
              onTap: () => context.push('/journey'),
              child: const _Surface(child: Row(children: [Icon(Icons.menu_book_outlined, color: kSage), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Start your first reading', style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('Open the journey to explore', style: TextStyle(color: kMuted, fontSize: 12.5))])), Icon(Icons.arrow_forward_rounded, color: kBronze)])),
            ),
          );
        }
        final bookId = progress['book_id'] as int? ?? 0;
        final chapter = progress['chapter_number'] as int? ?? 1;
        return FadeScaleTransition(
          beginScale: 0.97,
          child: InkWell(
            onTap: () => context.push('/journey'),
            child: _Surface(
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.bookmark_rounded, color: kSage, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Continue reading', style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Book $bookId, Chapter $chapter', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                ])),
                Icon(Icons.arrow_forward_rounded, color: kMuted, size: 18),
              ]),
            ),
          ),
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
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book_rounded, color: kBronze, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(verse['source']!, style: const TextStyle(color: kMuted, fontSize: 12.5, fontStyle: FontStyle.italic))),
            ]),
            const SizedBox(height: 16),
            _ArabicText(verse['arabic']!),
            const SizedBox(height: 12),
            Text(verse['translation']!, style: const TextStyle(color: kInk, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showVerseReflection(context, verse, prompt),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Reflect on this verse'),
                style: FilledButton.styleFrom(backgroundColor: kBronze, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

Future<void> _showVerseReflection(BuildContext context, Map<String, String> verse, String prompt) async {
  final controller = TextEditingController();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    builder: (sheetContext) => SlideUpFade(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Reflect on ${verse['source']}', style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 12),
            _ArabicText(verse['arabic']!),
            const SizedBox(height: 10),
            Text(verse['translation']!, style: const TextStyle(color: kInk, fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(14)),
              child: Text(prompt, style: const TextStyle(color: kInk, fontSize: 14.5, height: 1.5)),
            ),
            const SizedBox(height: 14),
            TextField(controller: controller, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'What does this verse invite you to carry today?')),
            const SizedBox(height: 14),
              FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kBronze, padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () async {
                final body = controller.text.trim();
                if (body.isEmpty) return;
                final navigator = Navigator.of(context);
                await BackendApi.instance.createReflection(
                  title: verse['source']!,
                  body: '${verse['translation']}\n\n$prompt\n\n$body',
                  mood: 'Reflective',
                );
                if (context.mounted) navigator.pop(true);
              },
              child: const Text('Save to my journey'),
            ),
          ]),
        ),
      ),
    ),
  );
  controller.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 10), Text('Your reflection was saved to your journey.')]),
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

class _Surface extends StatelessWidget { const _Surface({required this.child}); final Widget child; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(22), border: Border.all(color: kLine), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))]), child: child); }
