import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../core/act_store.dart';
import '../../services/offline_action_queue.dart';
import '../../services/queue_sync_service.dart';

class AddActScreen extends ConsumerStatefulWidget {
  const AddActScreen({this.familyId, super.key});
  final int? familyId;

  @override
  ConsumerState<AddActScreen> createState() => _AddActScreenState();

  static Future<bool> show(BuildContext context, {int? familyId}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActScreen(familyId: familyId),
    );
    return result ?? false;
  }
}

class _AddActScreenState extends ConsumerState<AddActScreen> {
  String? _selected;
  final _note = TextEditingController();
  bool _saved = false;
  bool _saving = false;
  String? _error;

  static const _acts = [
    ('Money', Icons.volunteer_activism_outlined),
    ('Food', Icons.restaurant_outlined),
    ('Kindness', Icons.favorite_outline_rounded),
    ('Dhikr', Icons.brightness_5_outlined),
    ('Prayer', Icons.self_improvement_outlined),
    ('Remove harm', Icons.clean_hands_outlined),
    ('Smile', Icons.sentiment_satisfied_alt_rounded),
    ('Time', Icons.schedule_outlined),
    ('Other', Icons.edit_note_outlined),
  ];

  static const _allSuggestions = [
    'Picked up something harmful from the ground today',
    'Helped a blind man cross the road',
    'Gave water to someone who was thirsty',
    'Smiled at someone who was having a hard day',
    'Shared my meal with a neighbor',
    'Prayed for someone who was sick',
    'Removed a thorn from the middle of the road',
    'Gave charity without telling anyone',
    'Helped my parents with housework',
    'Said Alhamdulillah 33 times today',
    'Visited someone who was feeling alone',
    'Forgave someone who wronged me',
    'Taught someone something useful today',
    'Fed a stray animal',
    'Stopped myself from saying something harmful',
    'Gave someone good advice',
    'Spent time with an elderly person',
    'Helped carry someone\'s heavy burden',
    'Shared useful knowledge with a friend',
    'Made someone laugh when they were down',
  ];

  late final List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    // A user can record an act without forcing it into an inaccurate
    // category. Existing categories remain available, while Other is the
    // neutral default and the note field carries the user's own wording.
    _selected = 'Other';
    _pickRandomSuggestions();
  }

  void _pickRandomSuggestions() {
    final shuffled = List<String>.from(_allSuggestions)..shuffle();
    _suggestions = shuffled.take(2).toList();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _error = null;
    });

    final type = _selected!;
    final note = _note.text.trim();

    final localId =
        'local_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
    final payload = <String, dynamic>{'type': type, 'note': note};
    if (widget.familyId != null) {
      payload['family_id'] = widget.familyId!;
    }

    final queueItem = OfflineQueueItem(
      id: localId,
      actionType:
          widget.familyId != null
              ? ActionType.addFamilyAct
              : ActionType.addJarStar,
      payload: payload,
      createdAt: DateTime.now(),
    );

    // Offline-first: the act counts locally the instant it's added, whether the
    // device is online or not. We do NOT block the user on the network. The act
    // is then handed to a durable queue that syncs to the server in the
    // background and retries on its own. A network/server failure must never
    // lose the act or surface a scary error - from the user's side, adding to
    // their jar always succeeds.
    try {
      if (widget.familyId == null) {
        // Try the fast path: add remotely. If it fails (offline or server),
        // fall back to offline-first behaviour by recording locally and
        // enqueuing for background sync so the UI never blocks.
        try {
          await ref
              .read(actStoreProvider)
              .addRemote(type: type, note: note, requestId: localId);
        } catch (_) {
          await ref.read(actStoreProvider).add(type: type, note: note);
          // Best-effort sync - never surface errors to the user.
          try {
            await QueueSyncService.instance.enqueueAndSync(queueItem);
          } catch (_) {}
        }
      } else {
        // Best-effort sync - never surface errors to the user.
        try {
          await QueueSyncService.instance.enqueueAndSync(queueItem);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
    } catch (_) {
      // The act still counts locally - show success regardless of sync state.
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _saved
        ? const _Success()
        : FadeScaleTransition(
          beginScale: 0.95,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.5,
            maxChildSize: 0.88,
            expand: false,
            builder: (context, scrollController) {
              return Material(
                color: Colors.transparent,
                child: Container(
                  key: const ValueKey('add-sheet'),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kClay,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            16,
                            20,
                            18 + MediaQuery.paddingOf(context).bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add today\'s sadaqah',
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 24,
                                            color: kInk,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Every sincere act belongs in your jar.',
                                          style: TextStyle(
                                            color: kMuted,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    tooltip: 'Close',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: kInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const _GentleReminder(),
                              const SizedBox(height: 22),
                              _SectionHeader(title: 'WHAT DID YOU SHARE?'),
                              const SizedBox(height: 12),
                              _ActGrid(
                                acts: _acts,
                                selected: _selected,
                                onSelect:
                                    (value) =>
                                        setState(() => _selected = value),
                              ),
                              const SizedBox(height: 22),
                              _SectionHeader(title: 'INSPIRED?'),
                              const SizedBox(height: 10),
                              ..._suggestions.map(
                                (item) => _SuggestionCard(
                                  text: item,
                                  onTap: () => _onSuggestion(item),
                                ),
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: () {
                                  GoRouter.of(context).push('/charities');
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kSoftBronze,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: kLine),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite_border_rounded,
                                        color: kBronze,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Give to verified causes',
                                          style: TextStyle(
                                            color: kInk,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: kMuted,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _SectionHeader(title: 'A SMALL NOTE (OPTIONAL)'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _note,
                                maxLines: 2,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Example: Said Alhamdulillah 33 times',
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                key: const ValueKey('preview-line'),
                                duration: MizanMotion.fast,
                                switchInCurve: MizanMotion.gentle,
                                switchOutCurve: MizanMotion.gentle,
                                child: _PreviewLine(selected: _selected),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: kDanger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      (_selected == null || _saving)
                                          ? null
                                          : _save,
                                  icon:
                                      _saving
                                          ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.add_circle_outline_rounded,
                                          ),
                                  label: Text(
                                    _saving ? 'Saving...' : 'Add to my jar',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  void _onSuggestion(String value) {
    setState(() {
      _selected = switch (value) {
        'Prayed for someone who was sick' => 'Prayer',
        'Removed a thorn from the middle of the road' => 'Remove harm',
        'Helped my parents with housework' => 'Kindness',
        'Made someone laugh when they were down' => 'Kindness',
        'Gave charity without telling anyone' => 'Money',
        _ => 'Other',
      };
      if (_note.text.trim().isEmpty) _note.text = value;
    });
  }
}

class _ActGrid extends StatelessWidget {
  const _ActGrid({
    required this.acts,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, IconData)> acts;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              acts
                  .map(
                    (act) => SizedBox(
                      width: itemWidth,
                      child: _ActChoice(
                        label: act.$1,
                        icon: act.$2,
                        selected: selected == act.$1,
                        onTap: () => onSelect(act.$1),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: kBronze,
        fontSize: 10.5,
        letterSpacing: 1.3,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GentleReminder extends StatelessWidget {
  const _GentleReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: kBronze, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dhikr counts too: tahlil, tahmid, tasbih, a smile, a du\'a, or removing something harmful from the road.',
              style: TextStyle(color: kInk, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      key: const ValueKey('preview-line'),
      duration: MizanMotion.fast,
      switchInCurve: MizanMotion.gentle,
      switchOutCurve: MizanMotion.gentle,
      child: AnimatedContainer(
        key: ValueKey(selected),
        duration: MizanMotion.fast,
        curve: MizanMotion.gentle,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kClayPale,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected == null
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: kBronze,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected == null
                    ? 'Choose one act to place it in your jar.'
                    : '$selected will be added to today\'s jar.',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActChoice extends StatelessWidget {
  const _ActChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Act choice: $label',
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: MizanMotion.fast,
          curve: MizanMotion.gentle,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? kClayLight : kPaper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kBronze : kLine,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? kBronze : kMuted),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? kInk : kMuted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: MizanMotion.fast,
          curve: MizanMotion.gentle,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kSoftBronze,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: kBronze,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              Icon(Icons.add_rounded, color: kMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) {
    return DialogFadeScale(
      child: Container(
        key: const ValueKey('success-sheet'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
        decoration: const BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessCheck(size: 56, color: kSage),
            const SizedBox(height: 18),
            const Text(
              'Added to your jar',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                color: kInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'May this small act return to you as ease and goodness.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, height: 1.45),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_rounded,
                  size: 16,
                  color: kBronze.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saved locally - will sync when online',
                  style: TextStyle(
                    color: kMuted.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Back to my jar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
