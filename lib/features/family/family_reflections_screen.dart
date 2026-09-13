import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import '../../widgets/mizan_async_state.dart';
import 'family_models.dart';
import 'family_theme.dart';

class FamilyReflectionsScreen extends StatefulWidget {
  const FamilyReflectionsScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilyReflectionsScreen> createState() =>
      _FamilyReflectionsScreenState();
}

class _FReflection {
  const _FReflection(
    this.author,
    this.authorAccent,
    this.text,
    this.time, {
    this.id,
    this.encouragement = const {},
    this.commentCount = 0,
  });
  final String? id;
  final String author;
  final Color authorAccent;
  final String text;
  final String time;
  final Map<String, int> encouragement;
  final int commentCount;

  _FReflection copyWith({
    String? id,
    String? author,
    Color? authorAccent,
    String? text,
    String? time,
    Map<String, int>? encouragement,
    int? commentCount,
  }) {
    return _FReflection(
      author ?? this.author,
      authorAccent ?? this.authorAccent,
      text ?? this.text,
      time ?? this.time,
      id: id ?? this.id,
      encouragement: encouragement ?? this.encouragement,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class _FamilyReflectionsScreenState extends State<FamilyReflectionsScreen> {
  FamilyJar? _jar;
  final List<_FReflection> _reflections = [];
  final TextEditingController _c = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _loadReflections();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Loads reflections from the backend.
  ///
  /// [showSpinner] controls whether the full-screen loading state is shown.
  /// It is only used for the very first load; subsequent syncs (after a
  /// create/update or a pull-to-refresh) update silently to avoid flicker.
  Future<void> _loadReflections({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      if (!mounted) return;
      setState(() {
        _error = 'This family could not be found.';
        _loading = false;
      });
      return;
    }
    try {
      final reflections = await BackendApi.instance.getFamilyReflections(
        familyId,
      );
      if (!mounted) return;
      setState(() {
        _reflections.clear();
        _reflections.addAll(
          reflections.map(
            (r) => _FReflection(
              'You',
              context.colors.primary,
              r['text']?.toString() ?? '',
              'just now',
              id: r['id']?.toString(),
              encouragement:
                  r['encouragement_counts'] != null
                      ? Map<String, int>.from(r['encouragement_counts'] as Map)
                      : const {},
              commentCount:
                  (((r['comment_counts'] as Map?)?['total']) as num?)
                      ?.toInt() ??
                  0,
            ),
          ),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Do NOT fall back to fabricated data. Surface the real error and keep
      // whatever real data we already had loaded (if any).
      setState(() {
        _error =
            e is BackendApiException
                ? e.message
                : 'Could not load reflections.';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() {
        _reflections.insert(
          0,
          _FReflection('You', context.colors.primary, text, 'now'),
        );
        _c.clear();
      });
      return;
    }
    try {
      final result = await BackendApi.instance.createFamilyReflection(
        familyId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _reflections.insert(
          0,
          _FReflection(
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

  Future<void> _edit(int index) async {
    final reflection = _reflections[index];
    final controller = TextEditingController(text: reflection.text);
    final newText = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.colors.surfaceElevated,
            title: Text(
              'Edit reflection',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontFamily: 'Georgia',
              ),
            ),
            content: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 1,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: context.colors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Update your reflection…',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (newText == null || newText.isEmpty || newText == reflection.text)
      return;

    final familyId = int.tryParse(widget.id);
    final reflectionId = int.tryParse(reflection.id ?? '');
    if (familyId == null || reflectionId == null) {
      setState(() {
        _reflections[index] = reflection.copyWith(text: newText);
      });
      return;
    }
    try {
      final result = await BackendApi.instance.updateFamilyReflection(
        familyId,
        reflectionId,
        text: newText,
      );
      if (!mounted) return;
      setState(() {
        _reflections[index] = reflection.copyWith(
          text: result['text']?.toString() ?? newText,
        );
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _encourage(int index, String type) async {
    final reflection = _reflections[index];
    final familyId = int.tryParse(widget.id);
    final reflectionId = int.tryParse(reflection.id ?? '');
    if (familyId == null || reflectionId == null) {
      setState(() {
        final updated = Map<String, int>.from(reflection.encouragement);
        updated[type] = (updated[type] ?? 0) + 1;
        _reflections[index] = reflection.copyWith(encouragement: updated);
      });
      return;
    }
    try {
      final result = await BackendApi.instance.encourageFamilyReflection(
        familyId,
        reflectionId,
        type,
      );
      if (!mounted) return;
      final counts =
          result['encouragement_counts'] != null
              ? Map<String, int>.from(result['encouragement_counts'] as Map)
              : <String, int>{};
      setState(() {
        _reflections[index] = reflection.copyWith(encouragement: counts);
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _openComments(int index) async {
    final familyId = int.tryParse(widget.id);
    final reflectionId = int.tryParse(_reflections[index].id ?? '');
    if (familyId == null || reflectionId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      builder:
          (_) => _FamilyReflectionCommentsSheet(
            familyId: familyId,
            reflectionId: reflectionId,
            text: _reflections[index].text,
          ),
    );
    if (mounted) _loadReflections(showSpinner: false);
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
                title: 'Reflections',
                subtitle:
                    jar == null ? null : 'A quiet journal for ${jar.name}',
              ),
            ),
            Expanded(child: _buildBody()),
            _FComposeBar(controller: _c, onSend: _add),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _reflections.isEmpty) {
      return const MizanLoadingState(label: 'Loading reflections...');
    }
    if (_error != null && _reflections.isEmpty) {
      return MizanErrorState(
        title: 'Could not load reflections',
        message: _error!,
        onRetry: _loadReflections,
      );
    }
    if (_reflections.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadReflections(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 64),
            MizanEmptyState(
              title: 'No reflections yet',
              message:
                  'Share your first reflection with your family. No replies, only quiet encouragement.',
              icon: Icons.menu_book_outlined,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadReflections(showSpinner: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: _buildJournalBoard(),
      ),
    );
  }

  List<Widget> _buildJournalBoard() {
    final board = <Widget>[];
    for (var index = 0; index < _reflections.length;) {
      final cardIndex = index;
      final current = _reflections[index];
      final currentCard = _ReflectionCard(
        r: current,
        onPick: (k) => _encourage(cardIndex, k),
        onEdit: () => _edit(cardIndex),
        onComments: () => _openComments(cardIndex),
      );
      if (current.text.length > 180 || index == _reflections.length - 1) {
        board.add(currentCard);
        board.add(const SizedBox(height: 12));
        index++;
        continue;
      }
      final next = _reflections[index + 1];
      if (next.text.length > 180) {
        board.add(currentCard);
        board.add(const SizedBox(height: 12));
        index++;
        continue;
      }
      final left = index;
      final right = index + 1;
      board.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ReflectionCard(
                r: _reflections[left],
                onPick: (k) => _encourage(left, k),
                onEdit: () => _edit(left),
                onComments: () => _openComments(left),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReflectionCard(
                r: _reflections[right],
                onPick: (k) => _encourage(right, k),
                onEdit: () => _edit(right),
                onComments: () => _openComments(right),
              ),
            ),
          ],
        ),
      );
      board.add(const SizedBox(height: 12));
      index += 2;
    }
    return board;
  }
}

const List<String> _encourageOptions = <String>[
  'barakallahu_feek',
  'may_allah_accept',
];

String _encourageLabel(String value) =>
    value == 'barakallahu_feek' ? 'Barakallahu feek' : 'May Allah accept it';

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({
    required this.r,
    required this.onPick,
    required this.onComments,
    this.onEdit,
  });

  final _FReflection r;
  final ValueChanged<String> onPick;
  final VoidCallback onComments;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.authorAccent, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.author,
                      style: TextStyle(
                        fontSize: 13.5,
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
              if (onEdit != null)
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: colors.iconSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit reflection',
                  onPressed: onEdit,
                ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            '"${r.text}"',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),
          Text(
            'Offer gentle encouragement',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _encourageOptions.map((k) {
                  final count = r.encouragement[k] ?? 0;
                  return Semantics(
                    button: true,
                    label: '${_encourageLabel(k)}, $count encouragements',
                    child: Material(
                      color:
                          count > 0
                              ? r.authorAccent.withValues(alpha: 0.12)
                              : colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onPick(k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  count > 0
                                      ? r.authorAccent
                                      : colors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _encourageLabel(k),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        count > 0
                                            ? r.authorAccent
                                            : colors.textSecondary,
                                  ),
                                ),
                              ),
                              if (count > 0) ...<Widget>[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: r.authorAccent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onComments,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${r.commentCount} comments',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
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

class _FComposeBar extends StatelessWidget {
  const _FComposeBar({required this.controller, required this.onSend});

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
                  hintText: 'Share a quiet reflection…',
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

class _FamilyReflectionCommentsSheet extends StatefulWidget {
  const _FamilyReflectionCommentsSheet({
    required this.familyId,
    required this.reflectionId,
    required this.text,
  });
  final int familyId;
  final int reflectionId;
  final String text;

  @override
  State<_FamilyReflectionCommentsSheet> createState() =>
      _FamilyReflectionCommentsSheetState();
}

class _FamilyReflectionCommentsSheetState
    extends State<_FamilyReflectionCommentsSheet> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _comments = const [];
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
      final comments = await BackendApi.instance.getFamilyReflectionComments(
        widget.familyId,
        widget.reflectionId,
      );
      if (mounted)
        setState(() {
          _comments = comments;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load comments.';
        });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final comment = await BackendApi.instance.createFamilyReflectionComment(
        widget.familyId,
        widget.reflectionId,
        text: text,
      );
      if (mounted)
        setState(() {
          _comments = [..._comments, comment];
          _controller.clear();
          _saving = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _error =
              error is BackendApiException
                  ? error.message
                  : 'Could not add comment.';
        });
    }
  }

  Future<void> _delete(int id) async {
    try {
      await BackendApi.instance.deleteFamilyReflectionComment(
        widget.familyId,
        widget.reflectionId,
        id,
      );
      if (mounted)
        setState(
          () =>
              _comments =
                  _comments
                      .where(
                        (comment) => comment['id']?.toString() != id.toString(),
                      )
                      .toList(),
        );
    } catch (error) {
      if (mounted)
        setState(
          () =>
              _error =
                  error is BackendApiException
                      ? error.message
                      : 'Could not delete comment.',
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
              'Comments',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.text,
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Georgia',
                fontSize: 17,
                height: 1.55,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No comments yet. Be the first to respond.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final comment = _comments[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['author_name']?.toString() ??
                                      'Family member',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['text']?.toString() ?? '',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                () => _delete(
                                  int.tryParse(
                                        comment['id']?.toString() ?? '',
                                      ) ??
                                      0,
                                ),
                            tooltip: 'Delete comment',
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Write a comment',
                suffixIcon: IconButton(
                  onPressed: _saving ? null : _send,
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
