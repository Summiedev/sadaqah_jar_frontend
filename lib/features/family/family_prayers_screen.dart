import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/refresh_helper.dart';
import '../../services/backend_api.dart';
import '../../widgets/mizan_async_state.dart';
import 'family_models.dart';
import 'family_theme.dart';
import '../../core/theme/theme_extensions.dart';

class PrayerRequestsScreen extends StatefulWidget {
  const PrayerRequestsScreen({required this.id, super.key});

  final String id;

  @override
  State<PrayerRequestsScreen> createState() => _PrayerRequestsScreenState();
}

class _PRequest {
  const _PRequest(
    this.author,
    this.accent,
    this.text,
    this.time, {
    this.id,
    this.ameen = 0,
    this.ease = 0,
    this.accept = 0,
    this.commentCount = 0,
  });
  final String? id;
  final String author;
  final Color accent;
  final String text;
  final String time;
  final int ameen;
  final int ease;
  final int accept;
  final int commentCount;

  _PRequest copyWith({
    String? id,
    String? author,
    Color? accent,
    String? text,
    String? time,
    int? ameen,
    int? ease,
    int? accept,
    int? commentCount,
  }) {
    return _PRequest(
      author ?? this.author,
      accent ?? this.accent,
      text ?? this.text,
      time ?? this.time,
      id: id ?? this.id,
      ameen: ameen ?? this.ameen,
      ease: ease ?? this.ease,
      accept: accept ?? this.accept,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class _PrayerRequestsScreenState extends State<PrayerRequestsScreen> {
  FamilyJar? _jar;
  final List<_PRequest> _requests = [];
  final TextEditingController _c = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _loadInFlight = false;
  final Set<int> _responding = <int>{};
  AutoRefreshController? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _loadPrayers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _c.dispose();
    _autoRefresh?.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // H6: use lifecycle-aware single-flight refresh instead of a raw
    // 30-second Timer.periodic that could overlap with WebSocket events,
    // resume refreshes, and mutation refreshes.
    _autoRefresh?.dispose();
    _autoRefresh = AutoRefreshController(
      interval: const Duration(seconds: 30),
      onRefresh: () async {
        if (!mounted) return;
        await _loadPrayers();
      },
    )..start();
  }

  Future<void> _loadPrayers() async {
    if (!mounted || _loadInFlight) return;
    _loadInFlight = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      if (!mounted) return;
      setState(() {
        _error = 'This family could not be found.';
        _loading = false;
      });
      _loadInFlight = false;
      return;
    }
    try {
      final prayers = await BackendApi.instance.getFamilyPrayers(familyId);
      if (!mounted) return;
      setState(() {
        _requests.clear();
        _requests.addAll(
          prayers.map((p) {
            final counts =
                p['response_counts'] != null
                    ? Map<String, int>.from(p['response_counts'] as Map)
                    : const <String, int>{};
            return _PRequest(
              p['author_name']?.toString() ?? 'Family member',
              context.colors.primary,
              p['text']?.toString() ?? '',
              'just now',
              id: p['id']?.toString(),
              ameen: counts['ameen'] ?? 0,
              ease: counts['grant_ease'] ?? 0,
              accept: counts['accept'] ?? 0,
              commentCount:
                  ((p['comment_counts'] as Map?)?['total'] as num?)?.toInt() ??
                  0,
            );
          }),
        );
        _loading = false;
      });
      _loadInFlight = false;
    } catch (e) {
      if (!mounted) return;
      // Do NOT fall back to fabricated data. Surface the real error and keep
      // whatever real data we already had loaded (if any).
      setState(() {
        _error =
            e is BackendApiException
                ? e.message
                : 'Could not load prayer requests.';
        _loading = false;
      });
      _loadInFlight = false;
    }
  }

  Future<void> _add() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() {
        _requests.insert(0, _PRequest('You', context.colors.primary, text, 'now'));
        _c.clear();
      });
      return;
    }
    try {
      final result = await BackendApi.instance.createFamilyPrayer(
        familyId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _requests.insert(
          0,
          _PRequest(
            'You',
            context.colors.primary,
            text,
            'just now',
            id: result['id']?.toString(),
          ),
        );
        _c.clear();
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _respond(int index, String type) async {
    final request = _requests[index];
    final familyId = int.tryParse(widget.id);
    final prayerId = int.tryParse(request.id ?? '');
    if (familyId == null || prayerId == null) {
      setState(() {
        final current = _requests[index];
        final newAmeen = type == 'ameen' ? current.ameen + 1 : current.ameen;
        final newEase = type == 'grant_ease' ? current.ease + 1 : current.ease;
        final newAccept =
            type == 'accept' ? current.accept + 1 : current.accept;
        _requests[index] = current.copyWith(
          ameen: newAmeen,
          ease: newEase,
          accept: newAccept,
        );
      });
      return;
    }
    if (_responding.contains(prayerId)) return;
    _responding.add(prayerId);
    try {
      final result = await BackendApi.instance.respondToFamilyPrayer(
        familyId,
        prayerId,
        type,
      );
      if (!mounted) return;
      final counts =
          result['response_counts'] != null
              ? Map<String, int>.from(result['response_counts'] as Map)
              : <String, int>{};
      setState(() {
        _requests[index] = _requests[index].copyWith(
          ameen: counts['ameen'] ?? _requests[index].ameen,
          ease: counts['grant_ease'] ?? _requests[index].ease,
          accept: counts['accept'] ?? _requests[index].accept,
        );
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: context.colors.error),
      );
    } finally {
      _responding.remove(prayerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ScreenHeader(
                title: 'Prayer Requests',
                subtitle: jar == null ? null : 'Hold one another in du\'a',
              ),
            ),
            Expanded(child: _buildBody()),
            _PComposeBar(controller: _c, onSend: _add),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _requests.isEmpty) {
      return const MizanLoadingState(label: 'Loading prayer requests...');
    }
    if (_error != null && _requests.isEmpty) {
      return MizanErrorState(
        title: 'Could not load prayer requests',
        message: _error!,
        onRetry: _loadPrayers,
      );
    }
    if (_requests.isEmpty) {
      return const MizanEmptyState(
        title: 'No prayer requests',
        message:
            'Support one another through du\'a. Share a request and let your family hold you close.',
        icon: Icons.favorite_border_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => _RequestCard(
            key: ValueKey(_requests[index].id ?? index),
            r: _requests[index],
            onRespond: (type) => _respond(index, type),
            onReplies: () => _openReplies(index),
          ),
    );
  }

  Future<void> _openReplies(int index) async {
    final request = _requests[index];
    final familyId = int.tryParse(widget.id);
    final prayerId = int.tryParse(request.id ?? '');
    if (familyId == null || prayerId == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      builder:
          (_) => _PrayerRepliesSheet(familyId: familyId, prayerId: prayerId),
    );
    if (mounted) _loadPrayers();
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.r,
    required this.onRespond,
    required this.onReplies,
    super.key,
  });

  final _PRequest r;
  final ValueChanged<String> onRespond;
  final VoidCallback onReplies;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final colors = context.colors;
    return SoftCard(
      color: colors.surfaceElevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.accent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.author,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      r.time,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.favorite_border_outlined,
                size: 16,
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResponseChip(
                label: 'Ameen',
                active: r.ameen > 0,
                count: r.ameen,
                onTap: () => widget.onRespond('ameen'),
              ),
              _ResponseChip(
                label: 'May Allah grant ease',
                active: r.ease > 0,
                count: r.ease,
                onTap: () => widget.onRespond('grant_ease'),
              ),
              _ResponseChip(
                label: 'May Allah accept',
                active: r.accept > 0,
                count: r.accept,
                onTap: () => widget.onRespond('accept'),
              ),
              _ResponseChip(
                label: 'Write a dua',
                active: false,
                count: r.commentCount,
                onTap: widget.onReplies,
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: widget.onReplies,
            child: Text(
              r.commentCount == 0
                  ? 'Be the first to write a personal dua'
                  : 'View ${r.commentCount} written dua${r.commentCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerRepliesSheet extends StatefulWidget {
  const _PrayerRepliesSheet({required this.familyId, required this.prayerId});
  final int familyId;
  final int prayerId;

  @override
  State<_PrayerRepliesSheet> createState() => _PrayerRepliesSheetState();
}

class _PrayerRepliesSheetState extends State<_PrayerRepliesSheet> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _replies = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final replies = await BackendApi.instance.getPrayerComments(
        widget.familyId,
        widget.prayerId,
      );
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load written duas. Try again.';
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final reply = await BackendApi.instance.createPrayerComment(
        widget.familyId,
        widget.prayerId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _replies = [reply, ..._replies];
        _controller.clear();
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send your dua. It is still in the text box.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteReply(Map<String, dynamic> reply) async {
    final commentId = int.tryParse(reply['id']?.toString() ?? '');
    if (commentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete this dua?'),
            content: const Text(
              'Your written dua will be removed from this prayer request.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BackendApi.instance.deletePrayerComment(
        widget.familyId,
        widget.prayerId,
        commentId,
      );
      if (mounted)
        setState(
          () =>
              _replies =
                  _replies
                      .where(
                        (item) =>
                            item['id']?.toString() != commentId.toString(),
                      )
                      .toList(),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is BackendApiException
                  ? error.message
                  : 'Could not delete this dua.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Written duas',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add a personal prayer beyond the quick responses.',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 14),
            if (_loading)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
              )
            else if (_error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            else if (_replies.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _replies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final reply = _replies[index];
                    return SoftCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply['author_name']?.toString() ??
                                      'Family member',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reply['text']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete written dua',
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colors.iconSecondary,
                            ),
                            onPressed: () => _deleteReply(reply),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No written duas yet.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write an extensive dua…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _saving ? null : _send,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.send_rounded),
                label: const Text('Send dua'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseChip extends StatefulWidget {
  const _ResponseChip({
    required this.label,
    required this.active,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  State<_ResponseChip> createState() => _ResponseChipState();
}

class _ResponseChipState extends State<_ResponseChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _a = Tween<double>(
    begin: 1,
    end: 0.92,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  bool _tapped = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active || _tapped;
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${widget.label}, ${widget.count} responses',
      child: ScaleTransition(
        scale: _a,
        child: Material(
          color:
              active
                  ? colors.primary.withValues(alpha: 0.12)
                  : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTapDown: (_) => _c.forward(),
            onTapUp: (_) => _c.reverse(),
            onTapCancel: () => _c.reverse(),
            onTap: () {
              setState(() => _tapped = true);
              widget.onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? colors.primary : colors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: active ? colors.primary : colors.textSecondary,
                    ),
                  ),
                  if (active) const SizedBox(width: 6),
                  if (active)
                    Icon(Icons.check, size: 12, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PComposeBar extends StatelessWidget {
  const _PComposeBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.inputBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Request a private du\'a…',
                  hintStyle: TextStyle(
                    color: colors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: colors.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSend,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.send_outlined,
                  size: 18,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
