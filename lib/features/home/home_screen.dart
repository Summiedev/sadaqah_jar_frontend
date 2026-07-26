import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import '../../core/theme/app_theme.dart';
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
                    const _HomeHeader(),
                    const SizedBox(height: 22),
                     _JarHero(totalActs: acts.totalStars, progress: acts.progress, onAdd: () => AddActScreen.show(context), remainingActs: acts.remainingActs),
                    const SizedBox(height: 24),
                     _AddTodayCard(onTap: () => AddActScreen.show(context)),
                    const SizedBox(height: 24),
                     _TodaysGentleActs(),
                    const SizedBox(height: 30),
                     _LastReadCard(),
                    const SizedBox(height: 30),
                     _TodaysReflection(),
                    const SizedBox(height: 30),
                     _RhythmOfTheDayCard(onTap: () => context.push('/journey')),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: BackendApi.instance.getUserProfile(),
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

class _StreakPill extends StatelessWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakInfo>(
      future: BackendApi.instance.getStreak(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        final streak = snapshot.data?.currentStreak ?? 0;
        return Container(
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
            Text('$streak', style: const TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
        );
      },
    );
  }
}

class _JarHero extends StatelessWidget {
  const _JarHero({required this.totalActs, required this.progress, required this.onAdd, required this.remainingActs});
  final int totalActs;
  final double progress;
  final VoidCallback onAdd;
  final int remainingActs;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MY SADAQAH JAR', style: TextStyle(color: kBronzeLight, fontSize: 10.5, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('${(progress * 100).round()}% filled', style: const TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 27, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('$totalActs acts of goodness this month', style: const TextStyle(color: kMutedLight, fontSize: 13)),
            const SizedBox(height: 18),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 7, color: kBronzeLight, backgroundColor: kInk)),
            const SizedBox(height: 8),
            Text('$remainingActs more acts to reach your intention', style: const TextStyle(color: kClayLight, fontSize: 11.5)),
          ])),
          const SizedBox(width: 8),
          ExcludeSemantics(child: SizedBox(width: 110, height: 166, child: FamilyJarView(fill: progress, size: 108, glow: .9))),
        ]),
      );
}

class _AddTodayCard extends StatelessWidget {
  const _AddTodayCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: kPaper,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: kLine)),
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
      );
}

class _SectionHeading extends StatelessWidget { const _SectionHeading(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, color: kInk, fontWeight: FontWeight.w700)); }

class _TodaysGentleActs extends StatelessWidget {
  const _TodaysGentleActs();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: BackendApi.instance.getTodaysGentleActs(limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Surface(child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _Surface(child: Padding(
            padding: EdgeInsets.all(18),
            child: Text('Pick a gentle act today.', style: TextStyle(color: kMuted, fontSize: 14)),
          ));
        }
        final acts = snapshot.data!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHeading('Today\'s gentle acts'),
          const SizedBox(height: 12),
          ...acts.map((act) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Surface(
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.volunteer_activism_outlined, color: kBronze, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(act['title']?.toString() ?? '', style: const TextStyle(color: kInk, fontWeight: FontWeight.w700, fontSize: 14.5))),
              ]),
            ),
          )),
        ]);
      },
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
    {'title': 'Morning remembrance', 'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', 'source': 'Muslim', 'repeat': 'Once'},
    {'title': 'Ayat al-Kursi', 'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ', 'source': 'Quran 2:255', 'repeat': 'Once'},
  ];
  static const _eveningAdhkar = [
    {'title': 'Evening remembrance', 'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', 'source': 'Muslim', 'repeat': 'Once'},
    {'title': 'Ayat al-Kursi', 'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ', 'source': 'Quran 2:255', 'repeat': 'Once'},
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

    return InkWell(
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
            Text(_arabic!, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(color: kInk, fontSize: 18, height: 1.6)),
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
          return InkWell(
            onTap: () => context.push('/journey'),
            child: const _Surface(child: Row(children: [Icon(Icons.menu_book_outlined, color: kSage), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Start your first reading', style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('Open the journey to explore', style: TextStyle(color: kMuted, fontSize: 12.5))])), Icon(Icons.arrow_forward_rounded, color: kBronze)])),
          );
        }
        final bookId = progress['book_id'] as int? ?? 0;
        final chapter = progress['chapter_number'] as int? ?? 1;
        return InkWell(
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
        );
      },
    );
  }
}

class _TodaysReflection extends StatelessWidget {
  const _TodaysReflection();
  static const _verses = [
    {'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', 'translation': 'In the name of Allah, the Most Gracious, the Most Merciful.', 'source': 'Quran 1:1'},
    {'arabic': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'translation': 'Indeed, with hardship comes ease.', 'source': 'Quran 94:6'},
    {'arabic': 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ', 'translation': 'Allah is the Light of the heavens and the earth.', 'source': 'Quran 24:35'},
    {'arabic': 'وَأَنَّ اللَّهَ مَعَ الصَّابِرِينَ', 'translation': 'And Allah is with the patient.', 'source': 'Quran 2:153'},
    {'arabic': 'فَاذْكُرُونِي أَذْكُرْكُمْ', 'translation': 'So remember Me; I will remember you.', 'source': 'Quran 2:152'},
  ];
  @override
  Widget build(BuildContext context) {
    final verse = _verses[DateTime.now().day % _verses.length];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeading('Today\'s reflection'),
      const SizedBox(height: 12),
      _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book_rounded, color: kBronze, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(verse['source']!, style: const TextStyle(color: kMuted, fontSize: 12.5, fontStyle: FontStyle.italic))),
          ]),
          const SizedBox(height: 16),
          Text(verse['arabic']!, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(color: kInk, fontSize: 20, height: 1.8, fontFamily: 'Georgia')),
          const SizedBox(height: 12),
          Text(verse['translation']!, style: const TextStyle(color: kInk, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/journey'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Reflect'),
            style: FilledButton.styleFrom(backgroundColor: kBronze, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
          ),
        ]),
      ),
    ]);
  }
}

class _Surface extends StatelessWidget { const _Surface({required this.child}); final Widget child; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kPaper, borderRadius: BorderRadius.circular(22), border: Border.all(color: kLine)), child: child); }
