import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/family_theme.dart' show FamilyJarView;
import '../../core/act_store.dart';
import 'add_act_screen.dart';
import '../../core/mode_provider.dart';

const _ink = Color(0xFF30261F);
const _muted = Color(0xFF76695E);
const _bronze = Color(0xFF8B6842);
const _sage = Color(0xFF58705C);
const _paper = Color(0xFFFFFCF8);
const _line = Color(0xFFE8DDD1);

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
            colors: [Color(0xFFF8F2E9), Color(0xFFF2E8DB), Color(0xFFF9F4ED)],
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
                  backgroundColor: const Color(0xFFE8DCC8),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Sanctuary'),
                  actions: [const _NotifIcon(), const SizedBox(width: 10), _StreakPill(streak: 7 + acts.today), const SizedBox(width: 14)],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                  sliver: SliverList.list(children: [
                    const _HomeHeader(),
                    const SizedBox(height: 22),
                     _JarHero(totalActs: 12 + acts.total, progress: acts.progress, onAdd: () => AddActScreen.show(context)),
                    const SizedBox(height: 24),
                     _AddTodayCard(onTap: () => AddActScreen.show(context)),
                    const SizedBox(height: 24),
                     const _SadaqahIdeas(),
                     const SizedBox(height: 14),
                     _CharityQuickLink(onTap: () => context.push('/charities')),
                     const SizedBox(height: 30),
                     const _SectionHeading('Continue reading'),
                     const SizedBox(height: 12),
                     const _ReadingCard(),
                     const SizedBox(height: 30),
                     const _RhythmOfTheDayCard(),
                     const SizedBox(height: 30),
                     const _SectionHeading('Recent adhkar'),
                    const SizedBox(height: 12),
                    const _AdhkarRow(),
                    const SizedBox(height: 30),
                    const _ReminderCard(),
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
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assalamu alaikum, Amina', style: TextStyle(color: _ink, fontFamily: 'Georgia', fontSize: 23, fontWeight: FontWeight.w700)),
          SizedBox(height: 5),
          Text('Small goodness, beautifully kept.', style: TextStyle(color: _muted, fontSize: 13)),
        ])),
      ]);
}

class _NotifIcon extends StatelessWidget {
  const _NotifIcon();
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.notifications_none_outlined, color: _ink),
        tooltip: 'Notifications',
        onPressed: () => context.push('/notifications'),
      );
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0C0),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x26FF8C00), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD4541A), size: 18),
          ),
          const SizedBox(width: 8),
          Text('$streak', style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      );
}

class _JarHero extends StatelessWidget {
  const _JarHero({required this.totalActs, required this.progress, required this.onAdd});
  final int totalActs;
  final double progress;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MY SADAQAH JAR', style: TextStyle(color: Color(0xFFE6C99F), fontSize: 10.5, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('${(progress * 100).round()}% filled', style: const TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 27, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('$totalActs acts of goodness this month', style: const TextStyle(color: Color(0xFFD8CABE), fontSize: 13)),
            const SizedBox(height: 18),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 7, color: const Color(0xFFE5B877), backgroundColor: const Color(0xFF59483D))),
            const SizedBox(height: 8),
            const Text('8 more acts to reach your intention', style: TextStyle(color: Color(0xFFE1D5CA), fontSize: 11.5)),
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
        color: _paper,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
            child: const Row(children: [
              CircleAvatar(radius: 24, backgroundColor: Color(0xFFE8DCCF), child: Icon(Icons.add_rounded, color: _bronze, size: 28)),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add sadaqah for today', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('A gift, dhikr, a kindness, a prayer - it all counts.', style: TextStyle(color: _muted, fontSize: 12.5, height: 1.35)),
              ])),
              Icon(Icons.arrow_forward_rounded, color: _bronze),
            ]),
          ),
        ),
      );
}

class _SadaqahIdeas extends StatelessWidget {
  const _SadaqahIdeas();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        _SectionHeading('Little sadaqah reminders'),
        SizedBox(height: 12),
        Row(children: [
          Expanded(child: _IdeaTile(icon: Icons.brightness_5_outlined, title: 'Tahlil', body: 'La ilaha illallah')),
          SizedBox(width: 10),
          Expanded(child: _IdeaTile(icon: Icons.wb_sunny_outlined, title: 'Tahmid', body: 'Alhamdulillah')),
        ]),
        SizedBox(height: 10),
        Row(children: [
          Expanded(child: _IdeaTile(icon: Icons.clean_hands_outlined, title: 'Clear harm', body: 'Move it from the road')),
          SizedBox(width: 10),
          Expanded(child: _IdeaTile(icon: Icons.sentiment_satisfied_alt_rounded, title: 'Smile', body: 'A quiet gift')),
        ]),
      ]);
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _bronze, size: 23),
          const SizedBox(height: 12),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12, height: 1.4)),
        ]),
      );
}

class _SectionHeading extends StatelessWidget { const _SectionHeading(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Georgia', fontSize: 21, color: _ink, fontWeight: FontWeight.w700)); }

class _ReadingCard extends StatelessWidget { const _ReadingCard(); @override Widget build(BuildContext context) => const _Surface(child: Row(children: [Icon(Icons.menu_book_outlined, color: _sage), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('On patience', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('A quiet reflection - 2 minutes left', style: TextStyle(color: _muted, fontSize: 12.5))])), Icon(Icons.arrow_forward_rounded, color: _bronze)])); }

class _RhythmOfTheDayCard extends StatefulWidget {
  const _RhythmOfTheDayCard();

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
      return const _Surface(
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B6842)))),
      );
    }

    final isFriday = _isFriday;
    final icon = isFriday ? Icons.menu_book_outlined : Icons.wb_sunny_outlined;
    final accent = isFriday ? const Color(0xFF58705C) : const Color(0xFF8B6842);

    return _Surface(
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isFriday ? 'Today\'s light' : 'Rhythm of the day', style: TextStyle(color: _ink, fontSize: 10.5, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_title ?? '', style: TextStyle(color: _ink, fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
          if (_arabic != null && _arabic!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_arabic!, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF30261F), fontSize: 18, height: 1.6)),
          ],
          if (_body != null && _body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF76695E), fontSize: 12.5, height: 1.4)),
          ],
          if (_source != null && _source!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_source!, style: const TextStyle(color: Color(0xFF8F7B6B), fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ])),
        Icon(Icons.arrow_forward_rounded, color: const Color(0xFF8B6842), size: 18),
      ]),
    );
  }
}

enum _TimeOfDay { morning, dhuhrAsr, afterAsr }

class _AdhkarRow extends StatelessWidget { const _AdhkarRow(); @override Widget build(BuildContext context) => const Row(children: [Expanded(child: _Dhikr('SubhanAllah', '33')), SizedBox(width: 10), Expanded(child: _Dhikr('Alhamdulillah', '33')), SizedBox(width: 10), Expanded(child: _Dhikr('Allahu Akbar', '34'))]); }
class _Dhikr extends StatelessWidget { const _Dhikr(this.label, this.count); final String label, count; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6), decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)), child: Column(children: [Text(count, style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, color: _bronze, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted))])); }
class _ReminderCard extends StatelessWidget { const _ReminderCard(); @override Widget build(BuildContext context) => const _Surface(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_outlined, color: _bronze), SizedBox(width: 12), Expanded(child: Text('Kindness is never lost. Let it be quiet, let it be steady.', style: TextStyle(fontFamily: 'Georgia', fontSize: 16, height: 1.4, color: _ink)))])); }
class _Surface extends StatelessWidget { const _Surface({required this.child}); final Widget child; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)), child: child); }
class _CharityQuickLink extends StatelessWidget {
  const _CharityQuickLink({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E3D4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.volunteer_activism_outlined, color: _bronze, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Give to verified causes', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 3),
                Text('Trusted places to donate externally', style: TextStyle(color: _muted, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: _muted, size: 20),
        ],
      ),
    ),
  );
}
