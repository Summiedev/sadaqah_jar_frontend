import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';
import 'journey_search_screen.dart';
import 'journey_search_data.dart';
import 'morning_adhkar_screen.dart';
import 'evening_adhkar_screen.dart';
import 'after_salah_adhkar_screen.dart';
import 'sleep_adhkar_screen.dart';
import 'travel_adhkar_screen.dart';
import 'book_reader_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['Reflection', 'Adhkar', 'Reading', 'Saved', 'History'];
  late final TabController _tabsController;
  final _adhkarTabKey = GlobalKey<_AdhkarTabState>();

  @override
  void initState() {
    super.initState();
    _tabsController = TabController(length: _tabs.length, vsync: this);
    JourneySearchIndex.build();
  }

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? kScaffoldDark : kIvory,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            toolbarHeight: 64,
            elevation: 0,
            backgroundColor: dark ? kSurfaceDark : kClayLight,
            foregroundColor: dark ? kInkDark : kInk,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 64,
            collapsedHeight: 64,
            title: const Text('Journey',
                style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                tooltip: 'Search Journey',
                icon: const Icon(Icons.search_rounded),
                onPressed: () async {
                  JourneySearchIndex.build();
                  final result = await Navigator.of(context).push<JourneySearchResult>(
                    MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
                  );
                  if (result != null && mounted) {
                    _tabsController.animateTo(1);
                    _adhkarTabKey.currentState?.selectCategory(result.category);
                  }
                },
              ),
              IconButton(
                tooltip: 'Saved items',
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => _tabsController.animateTo(3),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
              delegate: _PinnedHeader(
              child: ColoredBox(
                color: dark ? kSurfaceDark : kClayLight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _JourneySegments(controller: _tabsController, labels: _tabs),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
            controller: _tabsController,
            children: [_ReflectionsTab(), _AdhkarTab(key: _adhkarTabKey), _ReadingTab(), _SavedTab(), _HistorialTab()],
          ),
      ),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.child});
  final Widget child;
  @override double get minExtent => 62;
  @override double get maxExtent => 62;
  @override Widget build(BuildContext context, double offset, bool overlaps) => child;
  @override bool shouldRebuild(covariant _PinnedHeader oldDelegate) => false;
}

class _JourneySegments extends StatelessWidget {
  const _JourneySegments({required this.controller, required this.labels});
  final TabController controller;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        height: 46,
        decoration: BoxDecoration(color: dark ? kElevatedDark : kSoftBronze, borderRadius: BorderRadius.circular(16), border: Border.all(color: dark ? kLineDark : kLine)),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: dark ? kSurfaceDark : kPaper, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: dark ? Colors.black12 : Colors.black.withValues(alpha: 0.07), blurRadius: 5, offset: Offset(0, 2))]),
          labelColor: dark ? kInkDark : kInk,
          unselectedLabelColor: dark ? kMutedDark : kMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: labels.map((label) => Tab(height: 38, text: label)).toList(),
        ),
      );
  }
}

class _ReflectionsTab extends StatefulWidget {
  const _ReflectionsTab();
  @override
  State<_ReflectionsTab> createState() => _ReflectionsTabState();
}

class _ReflectionsTabState extends State<_ReflectionsTab> {
  List<JourneyReflection> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final page = await BackendApi.instance.getReflections();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze)));
    }
    if (_error != null && _items.isEmpty) {
      return Center(child: Column(children: [
        const Icon(Icons.wifi_off_rounded, size: 36, color: kBronze),
        const SizedBox(height: 16),
        Text('Could not load reflections', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
      ]));
    }
    if (_items.isEmpty) {
      return Stack(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 40, 20, 100), child: Center(child: Text('No reflections yet. Write your first one and see it appear here.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 14)))),
        Positioned(right: 20, bottom: 24, child: _ComposeButton(onTap: () => _composeReflection(context))),
      ]);
    }
    final grouped = <String, List<JourneyReflection>>{};
    for (final item in _items) {
      final label = _labelFor(DateTime.tryParse(item.createdAt));
      grouped.putIfAbsent(label, () => []).add(item);
    }
    final order = grouped.keys.toList();
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
        for (final day in order) _ReflectionSection(day, grouped[day]!),
      ]),
      Positioned(right: 20, bottom: 24, child: _ComposeButton(onTap: () => _composeReflection(context))),
    ]);
  }

  String _labelFor(DateTime? date) {
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }
}

class _Reflection {
  const _Reflection(this.mood, this.title, this.body, this.date, this.isPrivate);
  final String mood, title, body;
  final DateTime? date;
  final bool isPrivate;
}

class _ReflectionSection extends StatelessWidget {
  const _ReflectionSection(this.title, this.entries);
  final String title;
  final List<JourneyReflection> entries;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 6, bottom: 12), child: _SectionLabel(title)),
        ...entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _ReflectionTile(entry: _Reflection(e.mood, e.title, e.body, DateTime.tryParse(e.createdAt), e.isPrivate)))),
      ]);
  }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: kBronze)),
        const SizedBox(width: 12), const Expanded(child: Divider(color: kLine, height: 1)),
      ]);
}

class _ReflectionTile extends StatelessWidget {
  const _ReflectionTile({required this.entry});
  final _Reflection entry;
  @override
  Widget build(BuildContext context) => Material(
        color: kPaper,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openReader(context, _ReaderData(entry.title, entry.body, entry.mood, _date(entry.date))),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                 _Pill(entry.mood, color: kSoftBronze, textColor: kBronze), const Spacer(),
                if (entry.isPrivate) const Icon(Icons.lock_outline_rounded, size: 15, color: kMuted),
                const SizedBox(width: 7), Text(_date(entry.date), style: const TextStyle(fontSize: 12, color: kMuted)),
              ]),
              const SizedBox(height: 12),
              Text(entry.title, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),               Text(entry.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, height: 1.5)),
            ]),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.color, required this.textColor, this.onTap, this.selected});
  final String text;
  final Color color, textColor;
  final VoidCallback? onTap;
  final bool? selected;
  @override Widget build(BuildContext context) {
    final effectiveColor = selected == true ? color.withValues(alpha: 0.25) : color;
    final child = Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: effectiveColor, borderRadius: BorderRadius.circular(99)), child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700)));
    if (onTap != null) {
      return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(99), child: child));
    }
    return child;
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FloatingActionButton(
        backgroundColor: kBronze,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        tooltip: 'Write reflection',
        onPressed: onTap,
        child: const Icon(Icons.edit_outlined),
      );
}

class _AdhkarTab extends StatefulWidget { const _AdhkarTab({super.key}); @override State<_AdhkarTab> createState() => _AdhkarTabState(); }
class _AdhkarTabState extends State<_AdhkarTab> {
  static const categories = ['Morning', 'Evening', 'After Salah', 'Sleep', 'Travel', 'Protection', 'Gratitude', 'Forgiveness'];
  int selected = 0; final Set<int> saved = {}; final Map<int, int> counts = {};
  static const _selectedKey = 'mizan.journey.adhkar.selected';
  static const _savedKey = 'mizan.journey.adhkar.saved';
  static const _countsKey = 'mizan.journey.adhkar.counts';

  @override
  void initState() { super.initState(); _restore(); }

  void selectCategory(String category) {
    final index = categories.indexOf(category);
    if (index != -1 && index != selected) {
      setState(() => selected = index);
      _persist();
    }
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      selected = (prefs.getInt(_selectedKey) ?? 0).clamp(0, categories.length - 1).toInt();
      saved.addAll(prefs.getStringList(_savedKey)?.map(int.tryParse).whereType<int>() ?? const []);
      for (final value in prefs.getStringList(_countsKey) ?? const []) {
        final parts = value.split(':');
        if (parts.length == 2) { final key = int.tryParse(parts[0]); final count = int.tryParse(parts[1]); if (key != null && count != null) counts[key] = count; }
      }
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_selectedKey, selected),
      prefs.setStringList(_savedKey, saved.map((value) => '$value').toList()),
      prefs.setStringList(_countsKey, counts.entries.map((entry) => '${entry.key}:${entry.value}').toList()),
    ]);
  }
  @override Widget build(BuildContext context) {
    final item = _adhkar[categories[selected]]!;
    final isMorning = categories[selected] == 'Morning';
    final isEvening = categories[selected] == 'Evening';
    final isAfterSalah = categories[selected] == 'After Salah';
    final isSleep = categories[selected] == 'Sleep';
    final isTravel = categories[selected] == 'Travel';
    return Column(children: [
      SizedBox(height: 56, child: ListView.separated(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4), scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, index) => ChoiceChip(label: Text(categories[index]), selected: selected == index, onSelected: (_) { setState(() => selected = index); _persist(); }, selectedColor: kSoftBronze, backgroundColor: kPaper, side: BorderSide(color: selected == index ? kBronze : kLine))),
      ),
      Expanded(child: isMorning ? const MorningAdhkarList() : isEvening ? const EveningAdhkarList() : isAfterSalah ? const AfterSalahAdhkarList() : isSleep ? const SleepAdhkarList() : isTravel ? const TravelAdhkarList() : ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [
        _DhikrTile(item: item, saved: saved.contains(selected), count: counts[selected] ?? 0, onSave: () { setState(() => saved.contains(selected) ? saved.remove(selected) : saved.add(selected)); _persist(); }, onCount: () { setState(() => counts[selected] = (counts[selected] ?? 0) + 1); _persist(); }),
      ])),
    ]);
  }
}

class _Dhikr { const _Dhikr(this.arabic, this.transliteration, this.translation, this.reference); final String arabic, transliteration, translation, reference; }
const _adhkar = <String, _Dhikr>{
  'Morning': _Dhikr('\u0623\u064e\u0635\u0652\u0628\u064e\u062d\u0652\u0646\u064e\u0627 \u0648\u064e\u0623\u064e\u0635\u0652\u0628\u064e\u062d\u064e \u0627\u0644\u0652\u0645\u064f\u0644\u0652\u0643\u064f \u0644\u0650\u0644\u064e\u0651\u0647\u0650', 'Asbahna wa asbahal-mulku lillah', 'We have reached the morning, and the dominion belongs to Allah.', 'Muslim'),
  'Evening': _Dhikr('\u0623\u064e\u0645\u0652\u0633\u064e\u064a\u0652\u0646\u064e\u0627 \u0648\u064e\u0623\u064e\u0645\u0652\u0633\u064e\u0649', 'Amsayna wa amsal-mulku lillah', 'We have reached the evening, and the dominion belongs to Allah.', 'Muslim'),
  'After Salah': _Dhikr('\u0623\u064e\u0633\u0652\u062a\u064e\u063a\u0652\u0641\u0650\u0631\u064f \u0627\u0644\u0644\u064e\u0651\u0647\u064e', 'Astaghfirullah', 'I seek forgiveness of Allah.', 'Sunnah'),
  'Sleep': _Dhikr('\u0628\u0650\u0627\u0633\u0652\u0645\u0650\u0643\u064e \u0627\u0644\u0644\u064e\u0651\u0647\u064f\u0645\u064e\u0651', 'Bismika Allahumma amutu wa ahya', 'In Your name, O Allah, I die and I live.', 'Al-Bukhari'),
  'Travel': _Dhikr('\u0633\u064f\u0628\u0652\u062d\u064e\u0627\u0646\u064e \u0627\u0644\u064e\u0651\u0630\u0650\u064a \u0633\u064e\u062e\u064e\u0651\u0631\u064e \u0644\u064e\u0646\u064e\u0627', 'Subhanalladhi sakhkhara lana hadha', 'Glory be to the One who has subjected this to us.', 'Quran 43:13'),
  'Protection': _Dhikr('\u0623\u064e\u0639\u064f\u0648\u0630\u064f \u0628\u0650\u0643\u064e\u0644\u0650\u0645\u064e\u0627\u062a\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650', 'Audhu bikalimatillahit-tammati', 'I seek refuge in the perfect words of Allah.', 'Muslim'),
  'Gratitude': _Dhikr('\u0627\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f \u0644\u0650\u0644\u064e\u0651\u0647\u0650', 'Alhamdulillah', 'All praise is due to Allah.', 'Muslim'),
  'Forgiveness': _Dhikr('\u0623\u064e\u0633\u0652\u062a\u064e\u063a\u0652\u0641\u0650\u0631\u064f \u0627\u0644\u0644\u064e\u0651\u0647\u064e', 'Astaghfirullah', 'I seek forgiveness from Allah.', 'Muslim'),
};

class _DhikrTile extends StatelessWidget {
  const _DhikrTile({required this.item, required this.saved, required this.count, required this.onSave, required this.onCount});
  final _Dhikr item; final bool saved; final int count; final VoidCallback onSave, onCount;
  @override Widget build(BuildContext context) => Material(color: kPaper, borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(item.arabic, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(color: kInk, fontSize: 26, height: 1.7))), IconButton(onPressed: onSave, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: kBronze))]),
    const SizedBox(height: 10), Text(item.transliteration, style: const TextStyle(color: kBronze, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 16)), const SizedBox(height: 6), Text(item.translation, style: const TextStyle(color: kMuted, height: 1.5)), const SizedBox(height: 14),
    Row(children: [Text(item.reference, style: const TextStyle(color: kMuted, fontSize: 11.5, fontStyle: FontStyle.italic)), const Spacer(), IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback is coming soon.'))), icon: const Icon(Icons.volume_up_outlined, color: kBronze)), _Counter(value: count, onTap: onCount)]),
  ])));
}
class _Counter extends StatelessWidget { const _Counter({required this.value, required this.onTap}); final int value; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(99), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: value > 0 ? kSoftSage : kSoftBronze, borderRadius: BorderRadius.circular(99)), child: Text('$value', style: const TextStyle(color: kBronze, fontWeight: FontWeight.w700)))); }

class _ReadingTab extends StatelessWidget {
  const _ReadingTab();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookRead>>(
      future: BackendApi.instance.getBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBronze));
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: kBronze),
            const SizedBox(height: 16),
            const Text('Could not load library', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: () => (context as Element).reassemble(), icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
          ]));
        }
        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: kSoftBronze, shape: BoxShape.circle, border: Border.all(color: kLine)),
              child: const Icon(Icons.menu_book_outlined, size: 32, color: kBronze),
            ),
            const SizedBox(height: 18),
            const Text('No books available yet', style: TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            const Text('New books will appear here as they are added.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final book = books[index];
            return _ReadingTile(book: book);
          },
        );
      },
    );
  }
}
class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.book});
  final BookRead book;
  @override
  Widget build(BuildContext context) => Material(
        color: kPaper,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openReader(
            context,
            book,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: kSoftSage, borderRadius: BorderRadius.circular(8)),
                  child: Text(book.category.toUpperCase(), style: const TextStyle(color: kSage, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
                const SizedBox(height: 14),
                Text(
                  book.title,
                  style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(book.author, style: const TextStyle(color: kBronze, fontFamily: 'Georgia', fontSize: 14, fontStyle: FontStyle.italic)),
                if (book.description != null && book.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(book.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, height: 1.5)),
                ],
                const SizedBox(height: 14),
                Text(
                  '${book.chapterCount ?? 0} chapters \u00b7 ${book.totalReadingTime ?? 0} min read',
                  style: const TextStyle(color: kMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SavedTab extends StatefulWidget {
  const _SavedTab();

  @override
  State<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<_SavedTab> {
  late Future<List<JourneyAdhkarFavorite>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getAdhkarFavorites();
  }

  void _retry() {
    setState(() {
      _future = BackendApi.instance.getAdhkarFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JourneyAdhkarFavorite>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze)));
        }
        if (snapshot.hasError) {
          return Center(child: Column(children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: kBronze),
            const SizedBox(height: 16),
            Text('Could not load saved items', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
          ]));
        }
        final favorites = snapshot.data ?? const [];
        if (favorites.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 40, 20, 32),
            child: Center(child: Text('No saved items yet. Explore adhkar and reflections to build your collection.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 14))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final fav = favorites[index];
            return ListTile(
              tileColor: kPaper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Adhkar #${fav.adhkarId}', style: const TextStyle(color: kInk, fontWeight: FontWeight.w700)),
            );
          },
        );
      },
    );
  }
}

class _HistorialTab extends StatefulWidget {
  const _HistorialTab();

  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab> {
  late Future<JourneyReflectionPage> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getReflections();
  }

  void _retry() {
    setState(() {
      _future = BackendApi.instance.getReflections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JourneyReflectionPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze)));
        }
        if (snapshot.hasError) {
          return Center(child: Column(children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: kBronze),
            const SizedBox(height: 16),
            Text('Could not load history', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
          ]));
        }
        final page = snapshot.data;
        final items = page?.items ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Center(child: Text('No history yet. Your journey begins with the first step.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 14))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final refl = items[index];
            return _TimelineItem(
              Icons.edit_note_outlined,
              '${refl.mood}: ${refl.title}',
            );
          },
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget { const _TimelineItem(this.icon, this.text); final IconData icon; final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 33, height: 33, decoration: BoxDecoration(color: kSoftBronze, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: kBronze)), const SizedBox(width: 14), Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(text, style: const TextStyle(color: kMuted, height: 1.5))) )])); }

class _ReaderData { const _ReaderData(this.title, this.body, this.kicker, this.meta); final String title, body, kicker, meta; }
void _openReader(BuildContext context, dynamic data) {
  if (data is BookRead) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookReaderScreen(book: data)));
  } else if (data is _ReaderData) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ReaderPage(data: data)));
  }
}
class _ReaderPage extends StatelessWidget { const _ReaderPage({required this.data}); final _ReaderData data; @override Widget build(BuildContext context) => Scaffold(backgroundColor: kPaper, appBar: AppBar(backgroundColor: kPaper, surfaceTintColor: Colors.transparent, leading: BackButton(color: kInk), actions: const [Icon(Icons.bookmark_border_rounded, color: kBronze), SizedBox(width: 16)]), body: ListView(padding: const EdgeInsets.fromLTRB(30, 24, 30, 44), children: [Text(data.kicker.toUpperCase(), style: const TextStyle(color: kBronze, letterSpacing: 1.8, fontWeight: FontWeight.w700, fontSize: 11)), const SizedBox(height: 16), Text(data.title, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 32, height: 1.18, fontWeight: FontWeight.w700)), const SizedBox(height: 11), Text(data.meta, style: const TextStyle(color: kMuted, fontStyle: FontStyle.italic)), const SizedBox(height: 28), const Divider(color: kLine), const SizedBox(height: 26), Text(data.body, style: const TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 19, height: 1.8))])); }
void _composeReflection(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => const _ComposeSheet(),
  );
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _mood;
  bool _shareWithFamily = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty || _mood == null) return;
    setState(() => _saving = true);
    try {
      await BackendApi.instance.createReflection(
        title: title,
        body: body,
        mood: _mood!,
        isPrivate: !_shareWithFamily,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write reflection', style: TextStyle(color: kInk, fontFamily: 'Georgia', fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'A title for this moment')),
          const SizedBox(height: 14),
          TextField(controller: _bodyController, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'What is on your heart?', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('How are you feeling?', style: TextStyle(color: kInk, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: _Pill('Grateful', color: kSoftSage, textColor: kSage, selected: _mood == 'Grateful', onTap: () => setState(() => _mood = 'Grateful'))), const SizedBox(width: 8), Expanded(child: _Pill('Peaceful', color: kSoftBronze, textColor: kBronze, selected: _mood == 'Peaceful', onTap: () => setState(() => _mood = 'Peaceful'))), const SizedBox(width: 8), Expanded(child: _Pill('Hopeful', color: kClayLight, textColor: kBronzeLight, selected: _mood == 'Hopeful', onTap: () => setState(() => _mood = 'Hopeful')))]),
          const SizedBox(height: 16),
          Row(children: [Text('Share with family', style: TextStyle(color: kInk, fontSize: 13, fontWeight: FontWeight.w700)), const Spacer(), Switch(value: _shareWithFamily, onChanged: (v) => setState(() => _shareWithFamily = v))]),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: kBronze),
              child: _saving ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary)) : const Text('Save privately'),
            ),
          ),
        ],
      ),
    );
  }
}
String _date(DateTime? value) { if (value == null) return ''; const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return '${value.day} ${months[value.month - 1]} ${value.year}'; }
