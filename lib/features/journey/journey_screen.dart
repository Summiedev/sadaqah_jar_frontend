import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/backend_api.dart';
import 'journey_search_screen.dart';
import 'journey_search_data.dart';
import 'morning_adhkar_screen.dart';
import 'evening_adhkar_screen.dart';
import 'after_salah_adhkar_screen.dart';
import 'sleep_adhkar_screen.dart';
import 'travel_adhkar_screen.dart';
import 'others_adhkar_screen.dart';
import 'book_reader_screen.dart';
import 'quran/quran_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({
    super.key,
    this.initialTab = 0,
    this.initialQuranSurahId,
  });

  final int initialTab;
  final int? initialQuranSurahId;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    'Reflection',
    'Adhkar',
    'Quran',
    'Reading',
    'Saved',
    'History',
  ];
  late final TabController _tabsController;
  final _adhkarTabKey = GlobalKey<_AdhkarTabState>();

  @override
  void initState() {
    super.initState();
    _tabsController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabs.length - 1).toInt(),
    );
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
        headerSliverBuilder:
            (context, _) => [
              SliverAppBar(
                pinned: true,
                floating: false,
                toolbarHeight: 58,
                elevation: dark ? 0 : 6,
                shadowColor: Colors.black.withValues(alpha: dark ? 0 : 0.14),
                scrolledUnderElevation: dark ? 0 : 6,
                backgroundColor: dark ? kSurfaceDark : kClayLight,
                foregroundColor: dark ? kInkDark : kInk,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 58,
                collapsedHeight: 58,
                title: const Text(
                  'Journey',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Search Journey',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () async {
                      JourneySearchIndex.build();
                      final result = await Navigator.of(
                        context,
                      ).push<JourneySearchResult>(
                        MaterialPageRoute(
                          builder: (_) => const JourneySearchScreen(),
                        ),
                      );
                      if (result != null && mounted) {
                        _tabsController.animateTo(1);
                        _adhkarTabKey.currentState?.selectCategory(
                          result.category,
                        );
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? kSurfaceDark : kClayLight,
                      boxShadow:
                          dark
                              ? null
                              : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                      child: _JourneySegments(
                        controller: _tabsController,
                        labels: _tabs,
                      ),
                    ),
                  ),
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabsController,
          children: [
            _ReflectionsTab(),
            _AdhkarTab(key: _adhkarTabKey),
            QuranTab(initialSurahId: widget.initialQuranSurahId),
            _ReadingTab(),
            _SavedTab(),
            _HistorialTab(),
          ],
        ),
      ),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.child});
  final Widget child;
  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;
  @override
  Widget build(BuildContext context, double offset, bool overlaps) => child;
  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) => false;
}

class _JourneySegments extends StatelessWidget {
  const _JourneySegments({required this.controller, required this.labels});
  final TabController controller;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: dark ? kElevatedDark : kSoftBronze,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? kLineDark : kLine),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: dark ? kSurfaceDark : kPaper,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  dark ? Colors.black12 : Colors.black.withValues(alpha: 0.07),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: dark ? kInkDark : kInk,
        unselectedLabelColor: dark ? kMutedDark : kMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: labels.map((label) => Tab(height: 34, text: label)).toList(),
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

  Future<void> _composeAndInsert(BuildContext context) async {
    final reflection = await _composeReflection(context);
    if (!mounted || reflection == null) return;
    setState(() {
      _items = [
        reflection,
        ..._items.where((item) => item.id != reflection.id),
      ];
      _error = null;
    });
  }

  Future<void> _editReflection(
    BuildContext context,
    JourneyReflection item,
  ) async {
    final reflection = await _composeReflection(context, initial: item);
    if (!mounted || reflection == null) return;
    setState(() {
      _items =
          _items
              .map((entry) => entry.id == reflection.id ? reflection : entry)
              .toList();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: kBronze),
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return _JourneyStateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load reflections',
        body: _friendlyJourneyError(_error),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: const [
              _JourneyStatePanel(
                icon: Icons.edit_note_outlined,
                title: 'No reflections yet',
                body:
                    'Write what is on your heart and your reflections will gather here.',
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 24,
            child: _ComposeButton(onTap: () => _composeAndInsert(context)),
          ),
        ],
      );
    }
    final grouped = <String, List<JourneyReflection>>{};
    for (final item in _items) {
      final label = _labelFor(DateTime.tryParse(item.createdAt));
      grouped.putIfAbsent(label, () => []).add(item);
    }
    final order = grouped.keys.toList();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            for (final day in order)
              _ReflectionSection(
                day,
                grouped[day]!,
                onEdit: (item) => _editReflection(context, item),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: _ComposeButton(onTap: () => _composeAndInsert(context)),
        ),
      ],
    );
  }

  String _labelFor(DateTime? date) {
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final diff =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }
}

class _Reflection {
  const _Reflection(
    this.id,
    this.mood,
    this.title,
    this.body,
    this.date,
    this.isPrivate,
  );
  final int id;
  final String mood, title, body;
  final DateTime? date;
  final bool isPrivate;
}

class _ReflectionSection extends StatelessWidget {
  const _ReflectionSection(this.title, this.entries, {required this.onEdit});
  final String title;
  final List<JourneyReflection> entries;
  final ValueChanged<JourneyReflection> onEdit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        child: _SectionLabel(title),
      ),
      ...entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ReflectionTile(
            entry: _Reflection(
              e.id,
              e.mood,
              e.title,
              e.body,
              DateTime.tryParse(e.createdAt),
              e.isPrivate,
            ),
            onEdit: () => onEdit(e),
          ),
        ),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w700,
          color: kBronze,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: kLine, height: 1)),
    ],
  );
}

class _ReflectionTile extends StatelessWidget {
  const _ReflectionTile({required this.entry, required this.onEdit});
  final _Reflection entry;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      color: tokens.surfaceElevated,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap:
            () => _openReader(
              context,
              _ReaderData(
                entry.title,
                entry.body,
                entry.mood,
                _date(entry.date),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Pill(
                    entry.mood,
                    color: tokens.primaryContainer,
                    textColor: tokens.primary,
                  ),
                  const Spacer(),
                  if (entry.isPrivate)
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: tokens.iconSecondary,
                    ),
                  const SizedBox(width: 7),
                  Text(
                    _date(entry.date),
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit reflection',
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: tokens.iconSecondary,
                      size: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.title,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
    this.text, {
    required this.color,
    required this.textColor,
    this.onTap,
    this.selected,
  });
  final String text;
  final Color color, textColor;
  final VoidCallback? onTap;
  final bool? selected;
  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        selected == true ? color.withValues(alpha: 0.25) : color;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: child,
        ),
      );
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

class _AdhkarTab extends StatefulWidget {
  const _AdhkarTab({super.key});
  @override
  State<_AdhkarTab> createState() => _AdhkarTabState();
}

class _AdhkarTabState extends State<_AdhkarTab> {
  static const categories = [
    'Morning',
    'Evening',
    'After Salah',
    'Sleep',
    'Travel',
    'Others',
  ];
  int selected = 0;
  final Set<int> saved = {};
  final Map<int, int> counts = {};
  static const _selectedKey = 'mizan.journey.adhkar.selected';
  static const _savedKey = 'mizan.journey.adhkar.saved';
  static const _countsKey = 'mizan.journey.adhkar.counts';

  @override
  void initState() {
    super.initState();
    _restore();
  }

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
      selected =
          (prefs.getInt(_selectedKey) ?? 0)
              .clamp(0, categories.length - 1)
              .toInt();
      saved.addAll(
        prefs.getStringList(_savedKey)?.map(int.tryParse).whereType<int>() ??
            const [],
      );
      for (final value in prefs.getStringList(_countsKey) ?? const []) {
        final parts = value.split(':');
        if (parts.length == 2) {
          final key = int.tryParse(parts[0]);
          final count = int.tryParse(parts[1]);
          if (key != null && count != null) counts[key] = count;
        }
      }
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_selectedKey, selected),
      prefs.setStringList(_savedKey, saved.map((value) => '$value').toList()),
      prefs.setStringList(
        _countsKey,
        counts.entries.map((entry) => '${entry.key}:${entry.value}').toList(),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final item = _adhkar[categories[selected]];
    final tokens = context.colors;
    final isMorning = categories[selected] == 'Morning';
    final isEvening = categories[selected] == 'Evening';
    final isAfterSalah = categories[selected] == 'After Salah';
    final isSleep = categories[selected] == 'Sleep';
    final isTravel = categories[selected] == 'Travel';
    final isOthers = categories[selected] == 'Others';
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder:
                (_, index) => ChoiceChip(
                  label: Text(categories[index]),
                  selected: selected == index,
                  onSelected: (_) {
                    setState(() => selected = index);
                    _persist();
                  },
                  selectedColor: tokens.primaryContainer,
                  backgroundColor: tokens.surfaceElevated,
                  labelStyle: TextStyle(
                    color:
                        selected == index
                            ? tokens.onPrimaryContainer
                            : tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color:
                        selected == index
                            ? tokens.primary
                            : tokens.borderSubtle,
                  ),
                ),
          ),
        ),
        Expanded(
          child:
              isMorning
                  ? const MorningAdhkarList()
                  : isEvening
                  ? const EveningAdhkarList()
                  : isAfterSalah
                  ? const AfterSalahAdhkarList()
                  : isSleep
                  ? const SleepAdhkarList()
                  : isTravel
                  ? const TravelAdhkarList()
                  : isOthers
                  ? const OthersAdhkarList()
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    children: [
                      if (item != null)
                        _DhikrTile(
                          item: item,
                          saved: saved.contains(selected),
                          count: counts[selected] ?? 0,
                          onSave: () {
                            setState(
                              () =>
                                  saved.contains(selected)
                                      ? saved.remove(selected)
                                      : saved.add(selected),
                            );
                            _persist();
                          },
                          onCount: () {
                            setState(
                              () =>
                                  counts[selected] =
                                      (counts[selected] ?? 0) + 1,
                            );
                            _persist();
                          },
                        ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _Dhikr {
  const _Dhikr(
    this.arabic,
    this.transliteration,
    this.translation,
    this.reference,
  );
  final String arabic, transliteration, translation, reference;
}

const _adhkar = <String, _Dhikr>{
  'Morning': _Dhikr(
    '\u0623\u064e\u0635\u0652\u0628\u064e\u062d\u0652\u0646\u064e\u0627 \u0648\u064e\u0623\u064e\u0635\u0652\u0628\u064e\u062d\u064e \u0627\u0644\u0652\u0645\u064f\u0644\u0652\u0643\u064f \u0644\u0650\u0644\u064e\u0651\u0647\u0650',
    'Asbahna wa asbahal-mulku lillah',
    'We have reached the morning, and the dominion belongs to Allah.',
    'Muslim',
  ),
  'Evening': _Dhikr(
    '\u0623\u064e\u0645\u0652\u0633\u064e\u064a\u0652\u0646\u064e\u0627 \u0648\u064e\u0623\u064e\u0645\u0652\u0633\u064e\u0649',
    'Amsayna wa amsal-mulku lillah',
    'We have reached the evening, and the dominion belongs to Allah.',
    'Muslim',
  ),
  'After Salah': _Dhikr(
    '\u0623\u064e\u0633\u0652\u062a\u064e\u063a\u0652\u0641\u0650\u0631\u064f \u0627\u0644\u0644\u064e\u0651\u0647\u064e',
    'Astaghfirullah',
    'I seek forgiveness of Allah.',
    'Sunnah',
  ),
  'Sleep': _Dhikr(
    '\u0628\u0650\u0627\u0633\u0652\u0645\u0650\u0643\u064e \u0627\u0644\u0644\u064e\u0651\u0647\u064f\u0645\u064e\u0651',
    'Bismika Allahumma amutu wa ahya',
    'In Your name, O Allah, I die and I live.',
    'Al-Bukhari',
  ),
  'Travel': _Dhikr(
    '\u0633\u064f\u0628\u0652\u062d\u064e\u0627\u0646\u064e \u0627\u0644\u064e\u0651\u0630\u0650\u064a \u0633\u064e\u062e\u064e\u0651\u0631\u064e \u0644\u064e\u0646\u064e\u0627',
    'Subhanalladhi sakhkhara lana hadha',
    'Glory be to the One who has subjected this to us.',
    'Quran 43:13',
  ),
  'Protection': _Dhikr(
    '\u0623\u064e\u0639\u064f\u0648\u0630\u064f \u0628\u0650\u0643\u064e\u0644\u0650\u0645\u064e\u0627\u062a\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650',
    'Audhu bikalimatillahit-tammati',
    'I seek refuge in the perfect words of Allah.',
    'Muslim',
  ),
  'Gratitude': _Dhikr(
    '\u0627\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f \u0644\u0650\u0644\u064e\u0651\u0647\u0650',
    'Alhamdulillah',
    'All praise is due to Allah.',
    'Muslim',
  ),
  'Forgiveness': _Dhikr(
    '\u0623\u064e\u0633\u0652\u062a\u064e\u063a\u0652\u0641\u0650\u0631\u064f \u0627\u0644\u0644\u064e\u0651\u0647\u064e',
    'Astaghfirullah',
    'I seek forgiveness from Allah.',
    'Muslim',
  ),
};

class _DhikrTile extends StatelessWidget {
  const _DhikrTile({
    required this.item,
    required this.saved,
    required this.count,
    required this.onSave,
    required this.onCount,
  });
  final _Dhikr item;
  final bool saved;
  final int count;
  final VoidCallback onSave, onCount;
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      color: tokens.surfaceElevated,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 26,
                      height: 1.7,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSave,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: tokens.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.transliteration,
              style: TextStyle(
                color: tokens.primary,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.translation,
              style: TextStyle(color: tokens.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  item.reference,
                  style: TextStyle(
                    color: tokens.textMuted,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed:
                      () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Audio playback is coming soon.'),
                        ),
                      ),
                  icon: Icon(Icons.volume_up_outlined, color: tokens.primary),
                ),
                _Counter(value: count, onTap: onCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.onTap});
  final int value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              value > 0 ? tokens.secondaryContainer : tokens.primaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$value',
          style: TextStyle(color: tokens.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReadingTab extends StatefulWidget {
  const _ReadingTab();

  @override
  State<_ReadingTab> createState() => _ReadingTabState();
}

class _ReadingTabState extends State<_ReadingTab> {
  late Future<List<BookRead>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getBooks();
  }

  void _retry() {
    setState(() => _future = BackendApi.instance.getBooks());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookRead>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBronze));
        }
        if (snapshot.hasError) {
          return _JourneyStateMessage(
            icon: Icons.menu_book_outlined,
            title: 'Library is taking a moment',
            body: _friendlyJourneyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: _retry,
          );
        }
        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return const _JourneyStateMessage(
            icon: Icons.auto_stories_outlined,
            title: 'No books available yet',
            body:
                'When an admin publishes a readable book, it will appear here with a proper reader.',
          );
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
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      color: tokens.surfaceElevated,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openReader(context, book),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tokens.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  book.category.toUpperCase(),
                  style: TextStyle(
                    color: tokens.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                book.title,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: TextStyle(
                  color: tokens.primary,
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (book.description != null && book.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  book.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.textSecondary, height: 1.5),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                '${book.chapterCount ?? 0} chapters \u00b7 ${book.totalReadingTime ?? 0} min read',
                style: TextStyle(color: tokens.textMuted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final tokens = context.colors;
    return FutureBuilder<List<JourneyAdhkarFavorite>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: kBronze),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 36, color: kBronze),
                const SizedBox(height: 16),
                Text(
                  'Could not load saved items',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        final favorites = snapshot.data ?? const [];
        if (favorites.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            child: Center(
              child: Text(
                'No saved items yet. Explore adhkar and reflections to build your collection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary, fontSize: 14),
              ),
            ),
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
              tileColor: tokens.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: tokens.borderSubtle),
              ),
              title: Text(
                'Adhkar #${fav.adhkarId}',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: kBronze),
            ),
          );
        }
        if (snapshot.hasError) {
          return _JourneyStateMessage(
            icon: Icons.history_rounded,
            title: 'Could not load history',
            body: _friendlyJourneyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: _retry,
          );
        }
        final page = snapshot.data;
        final items = page?.items ?? const [];
        if (items.isEmpty) {
          return const _JourneyStateMessage(
            icon: Icons.history_toggle_off_rounded,
            title: 'No history yet',
            body:
                'Your saved reflections and reading moments will gather here as a gentle record.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _HistoryHeader(total: page?.total ?? items.length);
            }
            final refl = items[index - 1];
            return _HistoryCard(reflection: refl);
          },
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? kPaperDark : kPaper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? kLineDark : kLine),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dark ? kElevatedDark : kSoftBronze,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: dark ? kBronzeDarkMode : kBronze,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total journey moment${total == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: dark ? kInkDark : kInk,
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reflections you have written from Quran, hadith, and quiet daily moments.',
                  style: TextStyle(
                    color: dark ? kMutedDark : kMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.reflection});
  final JourneyReflection reflection;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final date = _date(DateTime.tryParse(reflection.createdAt));
    return Material(
      color: dark ? kPaperDark : kPaper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            () => _openReader(
              context,
              _ReaderData(
                reflection.title,
                reflection.body,
                reflection.mood,
                date,
              ),
            ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: dark ? kLineDark : kLine),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: dark ? kElevatedDark : kSoftSage,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: dark ? kBronzeDarkMode : kSage,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _Pill(
                            reflection.mood,
                            color: dark ? kElevatedDark : kSoftBronze,
                            textColor: dark ? kBronzeDarkMode : kBronze,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          date,
                          style: TextStyle(
                            color: dark ? kMutedDark : kMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      reflection.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark ? kInkDark : kInk,
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reflection.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark ? kMutedDark : kMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
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

class _JourneyStateMessage extends StatelessWidget {
  const _JourneyStateMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Center(
        child: _JourneyStatePanel(
          icon: icon,
          title: title,
          body: body,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}

class _JourneyStatePanel extends StatelessWidget {
  const _JourneyStatePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dark ? kPaperDark : kPaper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? kLineDark : kLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: dark ? kElevatedDark : kSoftBronze,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 31,
              color: dark ? kBronzeDarkMode : kBronze,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? kInkDark : kInk,
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? kMutedDark : kMuted,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String _friendlyJourneyError(Object? error) {
  if (error is BackendApiException) {
    if (error.statusCode >= 500) {
      return 'The library service is unavailable right now. Your app is fine, and you can try again shortly.';
    }
    return error.message;
  }
  final text = error?.toString() ?? '';
  if (text.contains('BackendApiException(500')) {
    return 'The library service is unavailable right now. Your app is fine, and you can try again shortly.';
  }
  if (text.toLowerCase().contains('socket') ||
      text.toLowerCase().contains('connection')) {
    return 'Check your connection and try again. Anything already saved on this device is still safe.';
  }
  return 'Something interrupted the request. Please try again.';
}

class _ReaderData {
  const _ReaderData(this.title, this.body, this.kicker, this.meta);
  final String title, body, kicker, meta;
}

void _openReader(BuildContext context, dynamic data) {
  if (data is BookRead) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookReaderScreen(book: data)));
  } else if (data is _ReaderData) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _ReaderPage(data: data)));
  }
}

class _ReaderPage extends StatelessWidget {
  const _ReaderPage({required this.data});
  final _ReaderData data;
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: tokens.iconPrimary),
        actions: [
          Icon(Icons.bookmark_border_rounded, color: tokens.primary),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 44),
        children: [
          Text(
            data.kicker.toUpperCase(),
            style: TextStyle(
              color: tokens.primary,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: TextStyle(
              color: tokens.textPrimary,
              fontFamily: 'Georgia',
              fontSize: 32,
              height: 1.18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            data.meta,
            style: TextStyle(
              color: tokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 28),
          Divider(color: tokens.divider),
          const SizedBox(height: 26),
          Text(
            data.body,
            style: TextStyle(
              color: tokens.textPrimary,
              fontFamily: 'Georgia',
              fontSize: 19,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

Future<JourneyReflection?> _composeReflection(
  BuildContext context, {
  JourneyReflection? initial,
}) {
  return showModalBottomSheet<JourneyReflection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _ComposeSheet(initial: initial),
  );
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({this.initial});

  final JourneyReflection? initial;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final _titleController = TextEditingController(
    text: widget.initial?.title ?? '',
  );
  late final _bodyController = TextEditingController(
    text: widget.initial?.body ?? '',
  );
  late String? _mood =
      widget.initial?.mood.isNotEmpty == true ? widget.initial!.mood : null;
  late bool _shareWithFamily = !(widget.initial?.isPrivate ?? true);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final mood = _mood ?? 'Reflection';
      final reflection =
          widget.initial == null
              ? await BackendApi.instance.createReflection(
                title: title,
                body: body,
                mood: mood,
                isPrivate: !_shareWithFamily,
              )
              : await BackendApi.instance.updateReflection(
                widget.initial!.id,
                title: title,
                body: body,
                mood: mood,
                isPrivate: !_shareWithFamily,
              );
      if (mounted) Navigator.pop(context, reflection);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your reflection. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: tokens.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.initial == null
                              ? 'Add reflection'
                              : 'Edit reflection',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontFamily: 'Georgia',
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Save the thought as it is. Mood is optional.',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'A title for this moment',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                hintText: 'What is on your heart?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mood, optional',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    'Grateful',
                    color: tokens.secondaryContainer,
                    textColor: tokens.secondary,
                    selected: _mood == 'Grateful',
                    onTap: () => setState(() => _mood = 'Grateful'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Pill(
                    'Peaceful',
                    color: tokens.primaryContainer,
                    textColor: tokens.primary,
                    selected: _mood == 'Peaceful',
                    onTap: () => setState(() => _mood = 'Peaceful'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Pill(
                    'Hopeful',
                    color: tokens.accentSoft,
                    textColor: tokens.accent,
                    selected: _mood == 'Hopeful',
                    onTap: () => setState(() => _mood = 'Hopeful'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: tokens.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Share with family',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _shareWithFamily,
                  onChanged: (v) => setState(() => _shareWithFamily = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: kBronze),
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
                        : Text(
                          widget.initial == null
                              ? 'Save reflection'
                              : 'Save changes',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime? value) {
  if (value == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
