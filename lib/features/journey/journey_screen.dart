import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/backend_api.dart';
import '../../services/offline_action_queue.dart';
import '../../services/queue_sync_service.dart';
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
import 'quran/quran_data.dart';
import 'reflection_action_suggestion.dart';
import '../../widgets/mizan_async_state.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({
    super.key,
    this.initialTab = 0,
    this.initialQuranSurahId,
    this.initialQuranPage,
  });

  final int initialTab;
  final int? initialQuranSurahId;
  final int? initialQuranPage;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

int _localReflectionId(String requestId) {
  var hash = 0;
  for (final unit in requestId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return -(hash == 0 ? 1 : hash);
}

Future<List<JourneyReflection>> _pendingReflections() async {
  final items = await OfflineActionQueue.instance.getUnfinished(
    actionType: ActionType.createReflection,
  );
  return [
    for (final item in items)
      if ((item.payload['body']?.toString().trim().isNotEmpty ?? false))
        JourneyReflection(
          id: _localReflectionId(item.id),
          title: item.payload['title']?.toString() ?? 'A note from today',
          body: item.payload['body']!.toString(),
          mood: item.payload['mood']?.toString() ?? 'Reflective',
          isPrivate: item.payload['is_private'] as bool? ?? false,
          createdAt: item.createdAt.toIso8601String(),
          date: item.createdAt.toIso8601String(),
          localRequestId: item.id,
        ),
  ];
}

Future<List<JourneyHistoryItem>> _pendingJourneyHistory() async {
  final items = await OfflineActionQueue.instance.getUnfinished();
  return [
    for (final item in items)
      if (item.actionType != ActionType.createReflection)
        JourneyHistoryItem(
          id: 'local:${item.id}',
          kind:
              item.actionType == ActionType.addFamilyAct ? 'family' : 'sadaqah',
          title:
              item.actionType == ActionType.addFamilyAct
                  ? 'Family activity saved'
                  : 'Sadaqah recorded',
          description: _pendingHistoryDescription(item),
          occurredAt: item.createdAt.toIso8601String(),
          metadata: const {'pending_sync': true},
        ),
  ];
}

String _pendingHistoryDescription(OfflineQueueItem item) {
  final type = item.payload['type']?.toString().trim();
  final note = item.payload['note']?.toString().trim();
  final details = [
    if (type != null && type.isNotEmpty) type.replaceAll('_', ' '),
    if (note != null && note.isNotEmpty) note,
  ];
  return details.isEmpty
      ? 'Saved on this device and waiting to sync.'
      : '${details.join(' - ')}. Saved on this device and waiting to sync.';
}

String? _historyDayKey(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
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
    final tabIndex = widget.initialTab.clamp(0, _tabs.length - 1);
    _tabsController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: tabIndex,
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
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder:
            (context, _) => [
              SliverAppBar(
                pinned: true,
                floating: false,
                toolbarHeight: 58,
                elevation: dark ? 0 : 6,
                shadowColor: colors.scrim.withValues(alpha: dark ? 0 : 0.14),
                scrolledUnderElevation: dark ? 0 : 6,
                backgroundColor: colors.surface,
                foregroundColor: colors.textPrimary,
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
                      color: colors.surface,
                      boxShadow:
                          dark
                              ? null
                              : [
                                BoxShadow(
                                  color: colors.scrim.withValues(alpha: 0.12),
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
            QuranTab(
              initialSurahId: widget.initialQuranSurahId,
              initialPage: widget.initialQuranPage,
            ),
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
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(MizanRadii.card),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(MizanRadii.control),
          boxShadow: [
            BoxShadow(
              color: colors.scrim.withValues(alpha: dark ? 0.08 : 0.07),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
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
  final Set<int> _selectedIds = <int>{};
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    reflectionRevision.addListener(_onReflectionRevision);
    _load();
  }

  @override
  void dispose() {
    reflectionRevision.removeListener(_onReflectionRevision);
    super.dispose();
  }

  void _onReflectionRevision() {
    if (mounted && !_deleting) _load(showSpinner: false);
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) setState(() => _loading = true);
    JourneyReflectionPage? page;
    Object? remoteError;
    try {
      page = await BackendApi.instance.getReflections();
    } catch (error) {
      remoteError = error;
    }
    try {
      final pending = await _pendingReflections();
      final remote = page?.items ?? const <JourneyReflection>[];
      final merged = [
        ...pending,
        ...remote.where(
          (item) =>
              !pending.any(
                (local) =>
                    local.title == item.title &&
                    local.body == item.body &&
                    local.mood == item.mood,
              ),
        ),
      ];
      if (!mounted) return;
      setState(() {
        _items = merged;
        _loading = false;
        _error =
            remoteError == null
                ? null
                : backendErrorMessage(
                  remoteError,
                  fallback:
                      'We could not reach your journal. Please try again.',
                );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = backendErrorMessage(
          remoteError ?? error,
          fallback: 'We could not reach your journal. Please try again.',
        );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(showReflectionActionSuggestion(context, reflection));
      }
    });
  }

  void _toggleSelection(JourneyReflection reflection) {
    if (_deleting) return;
    setState(() {
      if (!_selectedIds.add(reflection.id)) {
        _selectedIds.remove(reflection.id);
      }
    });
  }

  void _openReflection(JourneyReflection reflection) {
    if (_selectionMode) {
      _toggleSelection(reflection);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReflectionDetailPage(reflection: reflection),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_deleting || _selectedIds.isEmpty) return;
    final selected =
        _items.where((item) => _selectedIds.contains(item.id)).toList();
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              selected.length == 1 ? 'Delete note?' : 'Delete notes?',
            ),
            content: Text(
              selected.length == 1
                  ? 'This note will be removed from your Journey.'
                  : 'These ${selected.length} notes will be removed from your Journey.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final deletedIds = <int>{};
    Object? firstError;
    for (final reflection in selected) {
      try {
        if (reflection.localRequestId != null) {
          await OfflineActionQueue.instance.remove(reflection.localRequestId!);
        } else {
          await BackendApi.instance.deleteReflection(reflection.id);
        }
        deletedIds.add(reflection.id);
      } catch (error) {
        firstError ??= error;
      }
    }

    if (!mounted) return;
    setState(() {
      _items = _items.where((item) => !deletedIds.contains(item.id)).toList();
      _selectedIds.removeAll(deletedIds);
      _deleting = false;
    });
    if (firstError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${deletedIds.length} deleted. ${backendErrorMessage(firstError, fallback: 'Some notes could not be deleted and remain selected.')}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${deletedIds.length} note${deletedIds.length == 1 ? '' : 's'} deleted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loading) {
      return const MizanLoadingState(label: 'Loading your reflections...');
    }
    if (_error != null && _items.isEmpty) {
      return MizanErrorState(
        title: 'Your notes are taking a moment',
        message: _error!,
        onRetry: _load,
        icon: Icons.menu_book_outlined,
      );
    }
    if (_items.isEmpty) {
      return Stack(
        children: [
          const MizanEmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'A quiet place for your notes',
            message:
                'Write what you noticed, learned, or want to carry with you.',
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
        RefreshIndicator(
          onRefresh: () => _load(showSpinner: false),
          color: colors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              if (_selectionMode)
                _ReflectionSelectionToolbar(
                  count: _selectedIds.length,
                  deleting: _deleting,
                  onCancel: () => setState(_selectedIds.clear),
                  onDelete: _deleteSelected,
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_items.length} note${_items.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _load(showSpinner: false),
                    tooltip: 'Refresh notes',
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: colors.iconSecondary,
                    ),
                  ),
                ],
              ),
              for (final day in order)
                _ReflectionSection(
                  day,
                  grouped[day]!,
                  selectedIds: _selectedIds,
                  selectionMode: _selectionMode,
                  onTap: _openReflection,
                  onLongPress: _toggleSelection,
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child:
              _selectionMode
                  ? const SizedBox.shrink()
                  : _ComposeButton(onTap: () => _composeAndInsert(context)),
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
    this.mood,
    this.title,
    this.body,
    this.date,
    this.isPrivate,
  );
  final String mood, title, body;
  final DateTime? date;
  final bool isPrivate;
}

class _ReflectionSection extends StatelessWidget {
  const _ReflectionSection(
    this.title,
    this.entries, {
    required this.selectedIds,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });
  final String title;
  final List<JourneyReflection> entries;
  final Set<int> selectedIds;
  final bool selectionMode;
  final ValueChanged<JourneyReflection> onTap;
  final ValueChanged<JourneyReflection> onLongPress;
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
            reflection: e,
            selected: selectedIds.contains(e.id),
            selectionMode: selectionMode,
            onTap: () => onTap(e),
            onLongPress: () => onLongPress(e),
            entry: _Reflection(
              e.mood,
              e.title,
              e.body,
              DateTime.tryParse(e.createdAt),
              e.isPrivate,
            ),
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colors.borderSubtle, height: 1)),
      ],
    );
  }
}

class _ReflectionTile extends StatelessWidget {
  const _ReflectionTile({
    required this.entry,
    required this.reflection,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });
  final _Reflection entry;
  final JourneyReflection reflection;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(MizanRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(MizanRadii.card),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 82,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.mood.isEmpty ? 'Note' : entry.mood,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (entry.isPrivate)
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: colors.iconSecondary,
                          ),
                        const SizedBox(width: 7),
                        Text(
                          _date(entry.date),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      entry.title.isEmpty ? 'Untitled note' : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selectionMode
                    ? (selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded)
                    : Icons.chevron_right_rounded,
                color: selected ? colors.primary : colors.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionSelectionToolbar extends StatelessWidget {
  const _ReflectionSelectionToolbar({
    required this.count,
    required this.deleting,
    required this.onCancel,
    required this.onDelete,
  });

  final int count;
  final bool deleting;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(MizanRadii.card),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Cancel selection',
              onPressed: deleting ? null : onCancel,
              icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
            ),
            Expanded(
              child: Text(
                '$count selected',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Delete selected notes',
              onPressed: deleting ? null : onDelete,
              icon:
                  deleting
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.error,
                        ),
                      )
                      : Icon(Icons.delete_outline_rounded, color: colors.error),
            ),
          ],
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
    final colors = context.colors;
    final isSelected = selected == true;
    final effectiveColor = isSelected ? color : colors.surfaceContainer;
    final effectiveTextColor = isSelected ? textColor : colors.textSecondary;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isSelected ? textColor.withValues(alpha: 0.35) : colors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: effectiveTextColor,
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FloatingActionButton(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      tooltip: 'Write reflection',
      onPressed: onTap,
      child: const Icon(Icons.edit_outlined),
    );
  }
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
    'Protection',
    'Gratitude',
    'Forgiveness',
    // Keep this new category at the end so persisted category indexes for
    // existing users continue to point to the same adhkar section.
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
    final colors = context.colors;
    final item = _adhkar[categories[selected]];
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
                  selectedColor: colors.primaryContainer,
                  backgroundColor: colors.surfaceElevated,
                  side: BorderSide(
                    color: selected == index ? colors.primary : colors.border,
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
                      _DhikrTile(
                        item: item!,
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
                                counts[selected] = (counts[selected] ?? 0) + 1,
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
    final colors = context.colors;
    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(MizanRadii.card),
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
                      color: colors.textPrimary,
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
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.transliteration,
              style: TextStyle(
                color: colors.primary,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.translation,
              style: TextStyle(color: colors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  item.reference,
                  style: TextStyle(
                    color: colors.textSecondary,
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
                  icon: Icon(Icons.volume_up_outlined, color: colors.primary),
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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value > 0 ? colors.successContainer : colors.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$value',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
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
  late Future<List<BookRead>> _booksFuture;
  Map<String, dynamic>? _lastProgress;

  @override
  void initState() {
    super.initState();
    _reloadBooks();
    _loadLastProgress();
  }

  Future<void> _loadLastProgress() async {
    final progress = await BackendApi.instance.getLastReadingProgress();
    if (mounted) setState(() => _lastProgress = progress);
  }

  void _reloadBooks() {
    _booksFuture = BackendApi.instance.getBooks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookRead>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MizanLoadingState(label: 'Loading your library...');
        }
        if (snapshot.hasError) {
          return MizanErrorState(
            title: 'Could not load library',
            message:
                'Your books could not be loaded. Please check your connection and try again.',
            onRetry: () => setState(_reloadBooks),
          );
        }
        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return const MizanEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No books available yet',
            message: 'New books will appear here as they are added.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final book = books[index];
            final isContinue =
                _lastProgress?['book_id']?.toString() == book.id.toString();
            return _ReadingTile(
              book: book,
              isContinue: isContinue,
              chapter:
                  isContinue
                      ? (_lastProgress?['chapter_number'] as num?)?.toInt()
                      : null,
            );
          },
        );
      },
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.book,
    this.isContinue = false,
    this.chapter,
  });
  final BookRead book;
  final bool isContinue;
  final int? chapter;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(MizanRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(MizanRadii.card),
        onTap: () => _openReader(context, book),
        child: Padding(
          padding: MizanSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isContinue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Continue reading${chapter == null ? '' : ' - Chapter $chapter'}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  book.category.toUpperCase(),
                  style: TextStyle(
                    color: colors.success,
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
                  color: colors.textPrimary,
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: TextStyle(
                  color: colors.primary,
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
                  style: TextStyle(color: colors.textSecondary, height: 1.5),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                '${book.chapterCount ?? 0} chapters \u00b7 ${book.totalReadingTime ?? 0} min read',
                style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
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
    final colors = context.colors;
    return FutureBuilder<List<JourneyAdhkarFavorite>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MizanLoadingState(label: 'Loading saved items...');
        }
        if (snapshot.hasError) {
          return MizanErrorState(
            title: 'Could not load saved items',
            message: 'Your saved items could not be loaded. Please try again.',
            onRetry: _retry,
          );
        }
        final favorites = snapshot.data ?? const [];
        if (favorites.isEmpty) {
          return const MizanEmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved items yet',
            message: 'Explore adhkar and reflections to build your collection.',
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
              tileColor: colors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Adhkar #${fav.adhkarId}',
                style: TextStyle(
                  color: colors.textPrimary,
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
  late Future<_HistoryLoad> _future;
  StreamSubscription<DateTime>? _readingActivitySubscription;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
    reflectionRevision.addListener(_onHistoryChanged);
    offlineQueueRevision.addListener(_onHistoryChanged);
    _readingActivitySubscription = QuranRepository.instance.readingActivity
        .listen((_) => _reload());
  }

  @override
  void dispose() {
    reflectionRevision.removeListener(_onHistoryChanged);
    offlineQueueRevision.removeListener(_onHistoryChanged);
    _readingActivitySubscription?.cancel();
    super.dispose();
  }

  void _onHistoryChanged() => _reload();

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _loadHistory());
  }

  Future<void> _refresh() async {
    final future = _loadHistory();
    if (mounted) setState(() => _future = future);
    await future;
  }

  Future<_HistoryLoad> _loadHistory() async {
    List<DateTime> readingDays = const [];
    List<JourneyReflection> reflections = const [];
    List<JourneyHistoryItem> historyItems = const [];
    List<JourneyHistoryItem> pendingItems = const [];
    final loadErrors = <Object>[];
    try {
      readingDays = await QuranRepository.instance.readingDays();
    } catch (error) {
      loadErrors.add(error);
    }
    try {
      final pending = await _pendingReflections();
      final remote = (await BackendApi.instance.getReflections()).items;
      reflections = [
        ...pending,
        ...remote.where(
          (item) =>
              !pending.any(
                (local) =>
                    local.title == item.title &&
                    local.body == item.body &&
                    local.mood == item.mood,
              ),
        ),
      ];
    } catch (error) {
      try {
        reflections = await _pendingReflections();
      } catch (_) {}
      loadErrors.add(error);
    }
    try {
      historyItems = (await BackendApi.instance.getJourneyHistory()).items;
    } catch (error) {
      // Keep local history usable while an older server is being upgraded.
      loadErrors.add(error);
    }
    try {
      pendingItems = await _pendingJourneyHistory();
    } catch (error) {
      loadErrors.add(error);
    }
    return _HistoryLoad(
      reflections: reflections,
      readingDays: readingDays,
      historyItems: historyItems,
      pendingItems: pendingItems,
      errors: loadErrors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FutureBuilder<_HistoryLoad>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MizanLoadingState(label: 'Loading your history...');
        }
        final loaded = snapshot.data;
        if (snapshot.hasError || loaded == null) {
          return MizanErrorState(
            title: 'Could not load history',
            message: 'Your history could not be loaded. Please try again.',
            onRetry: _reload,
          );
        }
        final reflectionIds = {
          for (final reflection in loaded.reflections)
            if (reflection.id > 0) reflection.id,
        };
        final localReadingDays = {
          for (final day in loaded.readingDays) _historyDayKey(day),
        };
        final events = <_HistoryEvent>[
          for (final reflection in loaded.reflections)
            _HistoryEvent(
              date:
                  DateTime.tryParse(
                    reflection.date ?? reflection.createdAt,
                  )?.toLocal(),
              reflection: reflection,
            ),
          for (final day in loaded.readingDays) _HistoryEvent(date: day),
          for (final item in loaded.pendingItems)
            _HistoryEvent(
              date: DateTime.tryParse(item.occurredAt)?.toLocal(),
              history: item,
            ),
          for (final item in loaded.historyItems)
            if (!(item.kind == 'reflection' &&
                    item.referenceId != null &&
                    reflectionIds.contains(item.referenceId)) &&
                !(item.kind == 'quran' &&
                    localReadingDays.contains(
                      _historyDayKey(DateTime.tryParse(item.occurredAt)),
                    )))
              _HistoryEvent(
                date: DateTime.tryParse(item.occurredAt)?.toLocal(),
                history: item,
              ),
        ]..sort((a, b) {
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return b.date!.compareTo(a.date!);
        });
        if (events.isEmpty && loaded.errors.isNotEmpty) {
          return MizanErrorState(
            title: 'Could not load history',
            message: backendErrorMessage(
              loaded.errors.first,
              fallback: 'Your history could not be loaded. Please try again.',
            ),
            onRetry: _reload,
          );
        }
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: colors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 420,
                  child: MizanEmptyState(
                    icon: Icons.history_rounded,
                    title: 'Your journey starts here',
                    message:
                        'Your reflections, Quran reading, Salah, Adhkar, Sadaqah, goals and family activity will appear here.',
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          color: colors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: events.length + 1 + (loaded.errors.isNotEmpty ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                final noteCount = loaded.reflections.length;
                final readingCount = loaded.readingDays.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_outlined, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${events.length} activit${events.length == 1 ? 'y' : 'ies'} | '
                          '$noteCount reflection${noteCount == 1 ? '' : 's'} | '
                          '$readingCount Quran day${readingCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh history',
                        onPressed: _reload,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: colors.iconSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (loaded.errors.isNotEmpty && index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.warningContainer,
                      borderRadius: BorderRadius.circular(MizanRadii.card),
                      border: Border.all(
                        color: colors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync_problem_rounded,
                          color: colors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Some activity could not be refreshed. Pull down to try again.',
                            style: TextStyle(
                              color: colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final eventIndex = index - 1 - (loaded.errors.isNotEmpty ? 1 : 0);
              final event = events[eventIndex];
              if (event.reflection case final reflection?) {
                return _HistoryTimelineItem(
                  reflection: reflection,
                  isLast: eventIndex == events.length - 1,
                );
              }
              if (event.history case final item?) {
                return _HistoryActivityTimelineItem(
                  item: item,
                  isLast: eventIndex == events.length - 1,
                );
              }
              return _QuranReadingHistoryItem(
                date: event.date,
                isLast: eventIndex == events.length - 1,
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryLoad {
  const _HistoryLoad({
    required this.reflections,
    required this.readingDays,
    required this.historyItems,
    required this.pendingItems,
    this.errors = const [],
  });

  final List<JourneyReflection> reflections;
  final List<DateTime> readingDays;
  final List<JourneyHistoryItem> historyItems;
  final List<JourneyHistoryItem> pendingItems;
  final List<Object> errors;
}

class _HistoryEvent {
  const _HistoryEvent({this.date, this.reflection, this.history});

  final DateTime? date;
  final JourneyReflection? reflection;
  final JourneyHistoryItem? history;
}

class _HistoryActivityTimelineItem extends StatelessWidget {
  const _HistoryActivityTimelineItem({
    required this.item,
    required this.isLast,
  });

  final JourneyHistoryItem item;
  final bool isLast;

  IconData get _icon => switch (item.kind) {
    'sadaqah' => Icons.volunteer_activism_outlined,
    'prayer' => Icons.mosque_outlined,
    'adhkar' => Icons.spa_outlined,
    'book' => Icons.auto_stories_outlined,
    'quran' => Icons.menu_book_rounded,
    'goal' => Icons.flag_outlined,
    'family' => Icons.people_outline_rounded,
    'activity' => Icons.check_circle_outline,
    _ => Icons.history_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = DateTime.tryParse(item.occurredAt)?.toLocal();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 19),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(MizanRadii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _historyDateLabel(date),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.description?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 5),
                            Text(
                              item.description!,
                              style: TextStyle(
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (item.metadata['pending_sync'] == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Waiting to sync',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranReadingHistoryItem extends StatelessWidget {
  const _QuranReadingHistoryItem({required this.date, required this.isLast});

  final DateTime? date;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 19),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(MizanRadii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.menu_book_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _historyDateLabel(date),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Quran reading',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'A day spent with the Mushaf.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  const _HistoryTimelineItem({required this.reflection, required this.isLast});

  final JourneyReflection reflection;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date =
        DateTime.tryParse(reflection.date ?? reflection.createdAt)?.toLocal();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 19),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(MizanRadii.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(MizanRadii.card),
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  _ReflectionDetailPage(reflection: reflection),
                        ),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _historyDateLabel(date),
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (reflection.mood.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  reflection.mood,
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reflection.title.trim().isEmpty
                              ? 'Untitled reflection'
                              : reflection.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (reflection.body.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            reflection.body,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              reflection.isPrivate
                                  ? Icons.lock_outline_rounded
                                  : Icons.people_outline_rounded,
                              size: 15,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reflection.isPrivate
                                  ? 'Private journal'
                                  : 'Shared with your journey',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Read note',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _historyDateLabel(DateTime? date) {
  if (date == null) return 'Date not recorded';
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: colors.iconPrimary),
        actions: [
          Icon(Icons.bookmark_border_rounded, color: colors.primary),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 44),
        children: [
          Text(
            data.kicker.toUpperCase(),
            style: TextStyle(
              color: colors.primary,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: TextStyle(
              color: colors.textPrimary,
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
              color: colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 28),
          Divider(color: colors.divider),
          const SizedBox(height: 26),
          Text(
            data.body,
            style: TextStyle(
              color: colors.textPrimary,
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

Future<JourneyReflection?> _composeReflection(BuildContext context) {
  return showModalBottomSheet<JourneyReflection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
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
  String? _prompt;
  bool _shareWithFamily = false;
  bool _saving = false;

  bool get _hasUnsavedChanges =>
      _titleController.text.trim().isNotEmpty ||
      _bodyController.text.trim().isNotEmpty ||
      _mood != null ||
      _shareWithFamily;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final resolvedTitle = title.isEmpty ? 'A note from today' : title;
      final resolvedMood = _mood ?? 'Reflective';
      final requestId = 'reflection_${DateTime.now().microsecondsSinceEpoch}';
      final local = JourneyReflection(
        id: _localReflectionId(requestId),
        title: resolvedTitle,
        body: body,
        mood: resolvedMood,
        isPrivate: !_shareWithFamily,
        createdAt: DateTime.now().toIso8601String(),
        date: DateTime.now().toIso8601String(),
      );
      // Persist first. The queue performs a best-effort remote sync without
      // keeping this sheet mounted or making the user wait on the network.
      await QueueSyncService.instance.enqueueAndSync(
        OfflineQueueItem(
          id: requestId,
          actionType: ActionType.createReflection,
          payload: {
            'title': resolvedTitle,
            'body': body,
            'mood': resolvedMood,
            'is_private': !_shareWithFamily,
            'request_id': requestId,
          },
          createdAt: DateTime.now(),
        ),
      );
      final reflection = local;
      if (mounted) Navigator.pop(context, reflection);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your note has not been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final today = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.now());
    final bodyHint = switch (_prompt) {
      'What stayed with me?' =>
        'Write about the thought, verse, or moment that stayed with you...',
      'What am I grateful for?' =>
        'Name one thing you received, noticed, or want to thank Allah for...',
      'What needs care?' =>
        'Give this feeling or intention a little room on the page...',
      'A quiet intention' =>
        'Write one small intention you would like to carry forward...',
      _ => 'Write freely. This page is yours...',
    };
    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      color: colors.onPrimaryContainer,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRIVATE JOURNAL',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A page for today',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontFamily: 'Georgia',
                            fontSize: 25,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          today,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : _handleBack,
                    tooltip: 'Close',
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.iconSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'What is present for you today?',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final prompt in [
                    'What stayed with me?',
                    'What am I grateful for?',
                    'What needs care?',
                    'A quiet intention',
                  ])
                    _Pill(
                      prompt,
                      color: colors.primaryContainer,
                      textColor: colors.onPrimaryContainer,
                      selected: _prompt == prompt,
                      onTap:
                          () => setState(
                            () => _prompt = _prompt == prompt ? null : prompt,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Give this page a title',
                        hintStyle: TextStyle(color: colors.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: colors.divider),
                    TextField(
                      controller: _bodyController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      textAlignVertical: TextAlignVertical.top,
                      minLines: 8,
                      maxLines: 16,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText: bodyHint,
                        hintStyle: TextStyle(
                          color: colors.textMuted,
                          height: 1.6,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              Text(
                'How does this page feel?',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mood in [
                    'Grateful',
                    'Peaceful',
                    'Hopeful',
                    'Tender',
                  ])
                    _Pill(
                      mood,
                      color: colors.primaryContainer,
                      textColor: colors.onPrimaryContainer,
                      selected: _mood == mood,
                      onTap:
                          () => setState(
                            () => _mood = _mood == mood ? null : mood,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _shareWithFamily
                          ? Icons.people_alt_outlined
                          : Icons.lock_outline_rounded,
                      color: colors.iconSecondary,
                      size: 21,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _shareWithFamily
                                ? 'Visible to your family'
                                : 'Private journal entry',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _shareWithFamily
                                ? 'Your family can read this reflection.'
                                : 'Only you can read this reflection.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _shareWithFamily,
                      onChanged:
                          (value) => setState(() => _shareWithFamily = value),
                      activeThumbColor: colors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 19),
                  label: Text(
                    _saving ? 'Keeping your note...' : 'Keep this note',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

class _ReflectionDetailPage extends StatefulWidget {
  const _ReflectionDetailPage({required this.reflection});
  final JourneyReflection reflection;
  @override
  State<_ReflectionDetailPage> createState() => _ReflectionDetailPageState();
}

class _ReflectionDetailPageState extends State<_ReflectionDetailPage> {
  late final _titleController = TextEditingController(
    text: widget.reflection.title,
  );
  late final _bodyController = TextEditingController(
    text: widget.reflection.body,
  );
  bool _editing = false;
  bool _saving = false;

  bool get _hasUnsavedChanges =>
      _editing &&
      (_titleController.text.trim() != widget.reflection.title.trim() ||
          _bodyController.text.trim() != widget.reflection.body.trim());

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await BackendApi.instance.updateReflection(
        widget.reflection.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
        _titleController.text = updated.title;
        _bodyController.text = updated.body;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reflection saved')));
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your reflection has not been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(_editing ? 'Edit reflection' : 'Reflection'),
          leading: IconButton(
            onPressed: _handleBack,
            icon: Icon(Icons.arrow_back_rounded, color: colors.iconPrimary),
            tooltip: 'Back',
          ),
          actions: [
            if (_editing) ...[
              TextButton(
                onPressed:
                    _saving
                        ? null
                        : () => setState(() {
                          _editing = false;
                          _titleController.text = widget.reflection.title;
                          _bodyController.text = widget.reflection.body;
                        }),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ] else
              IconButton(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit reflection',
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              32 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reflection.mood,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _editing
                    ? TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    )
                    : Text(
                      _titleController.text,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                const SizedBox(height: 12),
                Text(
                  _date(
                    DateTime.tryParse(
                      widget.reflection.date ?? widget.reflection.createdAt,
                    ),
                  ),
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 28),
                _editing
                    ? TextField(
                      controller: _bodyController,
                      onChanged: (_) => setState(() {}),
                      autofocus: true,
                      minLines: 12,
                      maxLines: null,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write freely...',
                        hintStyle: TextStyle(color: colors.textMuted),
                        border: InputBorder.none,
                      ),
                    )
                    : Text(
                      _bodyController.text,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Georgia',
                        fontSize: 19,
                        height: 1.8,
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
