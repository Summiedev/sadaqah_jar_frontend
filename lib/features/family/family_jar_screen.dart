import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/refresh_helper.dart';
import '../../core/theme/app_theme.dart';
import '../home/add_act_screen.dart';
import 'family_theme.dart';
import '../../services/backend_api.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/websocket_service.dart';

class FamilyJarScreen extends StatefulWidget {
  const FamilyJarScreen({required this.id, super.key});
  final String id;

  @override
  State<FamilyJarScreen> createState() => _FamilyJarScreenState();
}

class _FamilyJarScreenState extends State<FamilyJarScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _family;
  bool _loading = true;
  bool _refreshing = false;
  bool _notFound = false;

  int _optimisticActsDone = 0;
  int? _lastKnownServerActsDone;

  AutoRefreshController? _autoRefresh;
  VoidCallback? _wsListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFamily();
    _startAutoRefresh();
    _connectWebSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefresh?.dispose();
    if (_wsListener != null) {
      WebSocketService.instance.removeListener(_wsListener!);
    }
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  void _connectWebSocket() {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    WebSocketService.instance.connectFamily(familyId);
    _wsListener = () {
      if (mounted) {
        _loadFamily(silent: true);
      }
    };
    WebSocketService.instance.addListener(_wsListener!);
  }

  // Lifecycle refresh is handled by AutoRefreshController's internal observer.
  // Keeping a manual handler here would cause a duplicate refresh on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op - AutoRefreshController handles lifecycle pausing/resuming.
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
        await _loadFamily(silent: true);
      },
    )..start();
  }

  bool _familyLoadInFlight = false;

  Future<void> _loadFamily({bool silent = false}) async {
    if (!mounted || _familyLoadInFlight) return;
    _familyLoadInFlight = true;
    if (!silent) {
      setState(() => _loading = true);
    } else {
      setState(() => _refreshing = true);
    }
    try {
      final familyId = int.tryParse(widget.id);
      if (familyId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _refreshing = false;
        });
        return;
      }
      final detail = await BackendApi.instance.getFamilyDetail(familyId);
      if (!mounted) return;
      final goals = (detail['goals'] as List?) ?? const [];
      final serverActsDone =
          goals.isNotEmpty
              ? (goals.first['acts_done'] as num?)?.toInt() ?? 0
              : 0;
      if (_lastKnownServerActsDone != null &&
          serverActsDone > _lastKnownServerActsDone! &&
          _optimisticActsDone > 0) {
        _optimisticActsDone = (_optimisticActsDone -
                (serverActsDone - _lastKnownServerActsDone!))
            .clamp(0, 1 << 30);
      }
      _lastKnownServerActsDone = serverActsDone;
      setState(() {
        _family = detail;
        _loading = false;
        _refreshing = false;
        _notFound = false;
      });
    } catch (e) {
      if (!mounted) return;
      final is404 = e is BackendApiException && e.statusCode == 404;
      setState(() {
        _loading = false;
        _refreshing = false;
        _notFound = is404;
      });
    } finally {
      _familyLoadInFlight = false;
    }
  }

  /// Optimistic-update + reconciliation pattern for adding a family act.
  ///
  /// 1. Immediately increment [_optimisticActsDone] so the UI shows the new
  ///    count before the network call resolves (optimistic).
  /// 2. Fire POST /family/{id}/add-act.
  /// 3. On success: leave the optimistic value in place; the next server
  ///    response will reconcile any drift.
  /// 4. On failure: roll back [_optimisticActsDone] to 0 and show a snackbar
  ///    with a retry action so the user can try again.
  /// 5. On [_loadFamily] (pull-to-refresh / retry): [_family] is replaced with
  ///    the server's authoritative value and [_optimisticActsDone] is reset
  ///    to 0, ensuring no permanent drift between local state and server.
  Future<void> _onAddAct() async {
    final familyIdStr = _family?['id']?.toString();
    if (familyIdStr == null) return;
    final parsedFamilyId = int.tryParse(familyIdStr);
    if (parsedFamilyId == null) return;

    final choice = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: context.colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetContext.colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'How would you like to add it?',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: context.colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Both choices grow the shared jar.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _ContributionOption(
                  icon: Icons.groups_outlined,
                  title: 'Share with family',
                  body: 'Your family can see this moment in the activity feed.',
                  onTap: () => Navigator.pop(sheetContext, 'family'),
                ),
                const SizedBox(height: 10),
                _ContributionOption(
                  icon: Icons.visibility_off_outlined,
                  title: 'Keep it private',
                  body: 'It counts toward the jar without showing who or what.',
                  onTap: () => Navigator.pop(sheetContext, 'private'),
                ),
              ],
            ),
          ),
    );
    if (choice == null || !mounted) return;

    final success = await AddActScreen.show(context, familyId: parsedFamilyId);
    if (!mounted) return;
    if (success) {
      // The add sheet owns the draft and only returns true after its Save
      // action completed. Do not change the family count when the user is
      // still choosing an act or dismisses the sheet.
      setState(() => _optimisticActsDone += 1);
      unawaited(_loadFamily(silent: true));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not add act. Please try again.'),
        backgroundColor: context.colors.error,
        action: SnackBarAction(label: 'Retry', onPressed: _onAddAct),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loading) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }
    if (_notFound) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 20),
              Text(
                'Family not found',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _loadFamily,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_family == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 20),
              Text(
                'Connection issue',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not reach the server. Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadFamily,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            if (_refreshing)
              LinearProgressIndicator(
                minHeight: 2,
                color: context.colors.primary,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: _JarBody(
                family: _family!,
                onAddAct: _onAddAct,
                optimisticActsDone: _optimisticActsDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JarBody extends StatelessWidget {
  const _JarBody({
    required this.family,
    required this.onAddAct,
    required this.optimisticActsDone,
  });
  final Map<String, dynamic> family;
  final VoidCallback onAddAct;
  final int optimisticActsDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = family['name']?.toString() ?? 'Family';
    final familyId = family['id'].toString();
    final members = (family['members'] as List?) ?? [];
    final goals = (family['goals'] as List?) ?? [];

    return SafeArea(
      child: Column(
        children: [
          _JarAppBar(name: name, familyId: familyId),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              labelColor: colors.textPrimary,
              unselectedLabelColor: colors.textMuted,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: [
                Tab(text: 'Home'),
                Tab(text: 'Activity'),
                Tab(text: 'Together'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _JarHome(
                  family: family,
                  goals: goals,
                  members: members,
                  onAddAct: onAddAct,
                  optimisticActsDone: optimisticActsDone,
                ),
                _Activity(family: family),
                _Together(family: family, members: members),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JarAppBar extends StatelessWidget {
  const _JarAppBar({required this.name, required this.familyId});
  final String name;
  final String familyId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back',
           icon: Icon(
             Icons.arrow_back_ios_new_rounded,
             color: context.colors.iconPrimary,
            size: 19,
          ),
        ),
        Expanded(
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
             style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
               color: context.colors.textPrimary,
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Family options',
           icon: Icon(
             Icons.more_horiz_rounded,
             color: context.colors.iconPrimary,
           ),
          onSelected: (value) {
            if (value == 'settings') {
              context.push('/family/settings/$familyId');
            }
            if (value == 'invite') {
              context.push('/family/invitations/$familyId');
            }
          },
          itemBuilder:
              (_) => const [
                PopupMenuItem(value: 'invite', child: Text('Invite family')),
                PopupMenuItem(value: 'settings', child: Text('Jar settings')),
              ],
        ),
      ],
    ),
  );
}

class _JarHome extends StatelessWidget {
  const _JarHome({
    required this.family,
    required this.goals,
    required this.members,
    required this.onAddAct,
    this.optimisticActsDone = 0,
  });
  final Map<String, dynamic> family;
  final List goals;
  final List members;
  final VoidCallback onAddAct;
  final int optimisticActsDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: [
      _GoalHero(goals: goals, optimisticActsDone: optimisticActsDone),
      const SizedBox(height: 12),
      _SharedIntentionSection(familyId: int.tryParse(family['id'].toString()) ?? 0),
      const SizedBox(height: 28),
      const _PendingSyncIndicator(),
      const SizedBox(height: 6),
      MizanButton(label: 'Add to our jar', onTap: onAddAct),
      const SizedBox(height: 10),
      Center(
        child: Text(
          'Share an act with the family, or let it count privately.',
           style: TextStyle(fontSize: 11.5, color: colors.textMuted),
        ),
      ),
      const SizedBox(height: 30),
      const _SectionTitle(title: 'Today, together'),
      const SizedBox(height: 12),
      _TodayCard(members: members),
      const SizedBox(height: 28),
      const _SectionTitle(title: 'Next milestone'),
      const SizedBox(height: 12),
      if (goals.isNotEmpty)
        _MilestoneCard(goal: goals.first, jarId: family['id'].toString()),
      const SizedBox(height: 28),
      const _SectionTitle(title: 'A little care'),
      const SizedBox(height: 12),
      _PrayerPreview(familyId: family['id'].toString()),
    ],
    );
  }
}

class _SharedIntentionSection extends StatefulWidget {
  const _SharedIntentionSection({required this.familyId});

  final int familyId;

  @override
  State<_SharedIntentionSection> createState() => _SharedIntentionSectionState();
}

class _SharedIntentionSectionState extends State<_SharedIntentionSection> {
  Map<String, dynamic>? _intention;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final intention = await BackendApi.instance.getFamilyIntention(widget.familyId);
      if (!mounted) return;
      setState(() {
        _intention = intention;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _setIntention() async {
    final title = TextEditingController(text: _intention?['title']?.toString());
    final prompt = TextEditingController(text: _intention?['prompt']?.toString());
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surfaceElevated,
        title: Text(
          'This week\'s intention',
          style: TextStyle(color: dialogContext.colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Shared intention'),
              ),
              TextField(
                controller: prompt,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'A gentle prompt (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = title.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop((value, prompt.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    title.dispose();
    prompt.dispose();
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final saved = await BackendApi.instance.saveFamilyIntention(
        widget.familyId,
        title: result.$1,
        prompt: result.$2,
      );
      if (!mounted) return;
      setState(() {
        _intention = saved;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendErrorMessage(
              error,
              fallback: 'Only a family admin can set the shared intention.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _contribute() async {
    final note = TextEditingController(
      text: _intention?['my_private_note']?.toString() ?? '',
    );
    var completed = _intention?['my_contribution_completed'] == true;
    final result = await showModalBottomSheet<(bool, String?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My private contribution',
                style: TextStyle(
                  color: sheetContext.colors.textPrimary,
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your note stays private. Only your completion joins the family count.',
                style: TextStyle(color: sheetContext.colors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: note,
                maxLines: 4,
                maxLength: 4000,
                decoration: const InputDecoration(
                  hintText: 'What will you carry into the week?',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: completed,
                onChanged: (value) => setSheetState(() => completed = value ?? false),
                title: const Text('I have made my contribution'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop((completed, note.text.trim())),
                  child: const Text('Save privately'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    note.dispose();
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final saved = await BackendApi.instance.saveFamilyIntentionContribution(
        widget.familyId,
        completed: result.$1,
        privateNote: result.$2,
      );
      if (!mounted) return;
      setState(() {
        _intention = saved;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendErrorMessage(
              error,
              fallback: 'Could not save your private contribution.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loading) {
      return const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()));
    }
    final intention = _intention;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: intention == null
          ? Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose one shared intention for this week.',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : _setIntention,
                  tooltip: 'Set shared intention',
                  icon: Icon(Icons.edit_outlined, color: colors.primary),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OUR SHARED INTENTION',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : _setIntention,
                      tooltip: 'Edit shared intention',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  intention['title']?.toString() ?? '',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((intention['prompt']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    intention['prompt'].toString(),
                    style: TextStyle(color: colors.textSecondary, height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${intention['contributor_count'] ?? 0} quiet contributions',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _saving ? null : _contribute,
                      icon: Icon(
                        intention['my_contribution_completed'] == true
                            ? Icons.check_circle_outline_rounded
                            : Icons.favorite_border_rounded,
                        size: 17,
                      ),
                      label: Text(
                        intention['my_contribution_completed'] == true
                            ? 'Contributed'
                            : 'Add mine',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.goals, this.optimisticActsDone = 0});
  final List goals;
  final int optimisticActsDone;

  @override
  Widget build(BuildContext context) {
    final actsTarget =
        goals.isEmpty ? 0 : (goals.first['acts_target'] as num?)?.toInt() ?? 0;
    final serverActsDone =
        goals.isEmpty ? 0 : (goals.first['acts_done'] as num?)?.toInt() ?? 0;
    final actsDone = serverActsDone + optimisticActsDone;
    final progress =
        actsTarget == 0 ? 0.0 : (actsDone / actsTarget).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final remaining = (actsTarget - actsDone).clamp(0, actsTarget);
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = context.colors;
        final compact = constraints.maxWidth < 340;
        final compactCopyWidth =
            constraints.maxWidth > 44
                ? constraints.maxWidth - 44
                : constraints.maxWidth;
        final jar = ExcludeSemantics(
          child: SizedBox(
            width: compact ? 78 : 96,
            height: compact ? 92 : 112,
            child: Center(
              child: FamilyJarView(
                fill: progress,
                size: compact ? 68 : 82,
                glow: .55,
              ),
            ),
          ),
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUR INTENTION',
              style: TextStyle(
                 color: colors.primary,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                     color: colors.textPrimary,
                    fontSize: compact ? 28 : 31,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? compactCopyWidth : 180,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$actsDone of $actsTarget acts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                           color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remaining left this month',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                           color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
             ProgressTrack(value: progress, height: 8, color: colors.primary),
            const SizedBox(height: 8),
            Row(
              children: [
                 Icon(Icons.group_outlined, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Growing together',
                    overflow: TextOverflow.ellipsis,
                     style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(17, 17, 14, 15),
          decoration: BoxDecoration(
             color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                 color: colors.scrim.withValues(alpha: 0.20),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: jar),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 4),
                      jar,
                    ],
                  ),
        );
      },
    );
  }
}

class _PendingSyncIndicator extends ConsumerWidget {
  const _PendingSyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Intentionally invisible - acts count locally the instant they're added,
    // and the durable queue syncs to the server silently in the background.
    // There's no user-facing "pending sync" state.
    return const SizedBox.shrink();
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.members});
  final List members;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final contributed =
        members
            .where((m) => (m['contributed_today'] as bool?) ?? false)
            .toList();
    final names = contributed.take(4).toList();
    final double avatarWidth =
        names.isEmpty ? 0.0 : 42 + (names.length - 1) * 28;
    return SoftCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (names.isNotEmpty)
                SizedBox(
                  height: 42,
                  width: avatarWidth,
                  child: Stack(
                    children: [
                      for (var i = 0; i < names.length; i++)
                        Positioned(
                          left: i * 28.toDouble(),
                          child: MizanAvatar(
                            name: names[i]['username']?.toString() ?? '?',
                            accent: context.colors.primary,
                            size: 42,
                            contributed: true,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${names.length} family members have added goodness today.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                     color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
           Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: colors.divider),
          ),
          Row(
            children: [
               Icon(Icons.auto_awesome_outlined, size: 17, color: colors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Family activities will appear here.',
                   style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
              ),
               Icon(Icons.arrow_forward_rounded, size: 17, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.goal, required this.jarId});
  final Map<String, dynamic> goal;
  final String jarId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
    onTap: () => context.push('/family/goals/$jarId'),
    padding: const EdgeInsets.all(17),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
             color: colors.primary.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(14),
          ),
           child: Icon(Icons.flag_outlined, color: colors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal['title']?.toString() ?? 'Goal',
                 style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                   color: colors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goal['acts_done'] ?? 0} of ${goal['acts_target'] ?? 0} acts',
                 style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
         Icon(Icons.arrow_forward_rounded, color: colors.primary),
      ],
    ),
    );
  }
}

class _PrayerPreview extends StatelessWidget {
  const _PrayerPreview({required this.familyId});
  final String familyId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
    color: colors.primaryContainer,
    borderColor: colors.borderSubtle,
    onTap: () => context.push('/family/prayers/$familyId'),
    padding: const EdgeInsets.all(17),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
             color: colors.surfaceElevated,
            shape: BoxShape.circle,
             border: Border.all(color: colors.borderSubtle),
          ),
           child: Icon(Icons.favorite_border_rounded, color: colors.primary),
        ),
        const SizedBox(width: 13),
         Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hold someone close in du\'a',
                 style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'Ask your family to remember someone in prayer.',
                 style: TextStyle(fontSize: 12.5, height: 1.35, color: colors.textSecondary),
              ),
            ],
          ),
        ),
         Icon(Icons.arrow_forward_rounded, color: colors.primary),
      ],
    ),
    );
  }
}

class _Activity extends StatefulWidget {
  const _Activity({required this.family});
  final Map<String, dynamic> family;

  @override
  State<_Activity> createState() => _ActivityState();
}

class _ActivityState extends State<_Activity> {
  List<Map<String, dynamic>> _activities = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activities =
        ((widget.family['activities'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    _load();
  }

  Future<void> _load() async {
    final familyId = (widget.family['id'] as num?)?.toInt();
    if (familyId == null) return;
    try {
      final activities = await BackendApi.instance.getFamilyActivity(familyId);
      if (!mounted) return;
      setState(() {
        _activities = activities;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the latest activity.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activities = _activities;
    if (_loading && activities.isEmpty) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (activities.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          Text(
            'Family activity',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 23,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Small moments that are growing your shared intention.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            TextButton(onPressed: _load, child: Text(_error!))
          else
            Center(
              child: Text(
                'No activity yet. Start by adding an act to your family jar.',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        Text(
          'Family activity',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 23,
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Small moments that are growing your shared intention.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 20),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < activities.length; i++)
                _ActivityRow(
                  activity: activities[i],
                  divider: i < activities.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.divider});
  final Map<String, dynamic> activity;
  final bool divider;

  static const _eventLabels = {
    'family.created': 'created a family jar',
    'member.joined': 'joined the family',
    'member.left': 'left the family',
    'goal.created': 'created a new goal',
    'goal.completed': 'completed a goal',
    'act.added': 'added an act to the jar',
    'reflection.shared': 'shared a reflection',
    'prayer.shared': 'shared a prayer request',
    'prayer_request.created': 'shared a prayer request',
    'prayer.responded': 'responded to a prayer',
    'prayer.commented': 'wrote a dua',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rawEvent = activity['event_type']?.toString() ?? 'activity';
    final eventType = _eventLabels[rawEvent] ?? rawEvent;
    final createdAt = activity['created_at']?.toString() ?? '';
    final day = createdAt.split('T').first;
    final actor = activity['actor_name']?.toString();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: colors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actor == null || actor.isEmpty
                          ? eventType
                          : '$actor $eventType',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (divider) Divider(height: 1, indent: 63, color: colors.divider),
      ],
    );
  }
}

class _Together extends StatelessWidget {
  const _Together({required this.family, required this.members});
  final Map<String, dynamic> family;
  final List members;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final familyId = family['id'].toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Together',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 23,
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Care for one another beyond the numbers.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 22),
        _CareLink(
          icon: Icons.favorite_border_rounded,
          title: 'Prayer requests',
          body: 'Ask your family to remember someone in du\'a.',
          onTap: () => context.push('/family/prayers/$familyId'),
        ),
        const SizedBox(height: 12),
        _CareLink(
          icon: Icons.menu_book_outlined,
          title: 'Shared reflections',
          body: 'A quiet place to share what is on your heart.',
          onTap: () => context.push('/family/reflections/$familyId'),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(title: 'Family members'),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No family members yet. Invite someone to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          )
        else
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < members.take(5).length; i++)
                  _MemberRow(
                    member: members[i],
                    divider: i < members.take(5).length - 1,
                  ),
                ListTile(
                  onTap: () => context.push('/family/invitations/$familyId'),
                  title: Text(
                    'Invite someone to the jar',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.add_circle_outline_rounded,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CareLink extends StatelessWidget {
  const _CareLink({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
    onTap: onTap,
    padding: const EdgeInsets.all(17),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, color: colors.primary),
      ],
    ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.divider});
  final Map<String, dynamic> member;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = member['username']?.toString() ?? 'Unknown';
    final role = member['role']?.toString() ?? 'Member';
    return Column(
      children: [
        ListTile(
          leading: MizanAvatar(
            name: name,
            accent: colors.primary,
            size: 40,
            contributed: member['contributed_today'] as bool? ?? false,
          ),
          title: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            role,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          trailing: Icon(Icons.person_outline_rounded, color: colors.iconSecondary),
        ),
        if (divider) Divider(height: 1, indent: 68, color: colors.divider),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 19,
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ContributionOption extends StatelessWidget {
  const _ContributionOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: colors.primary),
        ],
      ),
    );
  }
}
