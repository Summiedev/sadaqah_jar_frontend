import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backend_api.dart';
import '../../core/mode_provider.dart';
import '../../core/animations.dart';
import '../../core/theme/theme_extensions.dart';
import 'family_models.dart';
import 'family_theme.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  List<Map<String, dynamic>> _families = const [];
  bool _loading = true;
  String? _error;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  /// Loads the family list from the backend.
  ///
  /// [showSpinner] shows the full-screen loader - only used for the first load.
  /// Syncs triggered after a create/join or by pull-to-refresh run silently so
  /// the list doesn't flicker or flash a loading indicator.
  Future<void> _loadFamilies({bool showSpinner = true}) async {
    if (!mounted) return;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final families = await BackendApi.instance.getFamilies();
      if (!mounted) return;
      cacheFamiliesFromApi(families);
      setState(() {
        _families = families;
        _loading = false;
      });
      _loadPendingInvitations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = backendErrorMessage(
          e,
          fallback: 'Could not load your family hubs. Please try again.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _loadPendingInvitations() async {
    try {
      final invitations = await BackendApi.instance.getPendingInvitations();
      if (!mounted) return;
      setState(() {
        _pendingCount = invitations.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingCount = 0;
      });
    }
  }

  Future<void> _confirmDiscardDialog(
    BuildContext dialogContext, {
    required String message,
  }) async {
    final discard = await showDialog<bool>(
      context: dialogContext,
      builder:
          (confirmContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(confirmContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }

  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => PopScope(
                  canPop: nameController.text.trim().isEmpty,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && nameController.text.trim().isNotEmpty) {
                      unawaited(
                        _confirmDiscardDialog(
                          ctx,
                          message: 'The family name has not been saved.',
                        ),
                      );
                    }
                  },
                  child: DialogFadeScale(
                    child: AlertDialog(
                      backgroundColor: ctx.colors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: Text(
                        'Create a family jar',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ctx.colors.textPrimary,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start a shared space for your family.',
                            style: TextStyle(
                              color: ctx.colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Family name',
                              hintText: 'e.g. The Ahmad Family',
                              filled: true,
                              fillColor: ctx.colors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: ctx.colors.inputBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: ctx.colors.textSecondary),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            Navigator.pop(ctx, name);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: ctx.colors.primary,
                            foregroundColor: ctx.colors.onPrimary,
                          ),
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );

    if (result == null || !mounted) return;
    try {
      final response = await BackendApi.instance.createFamilyJar(name: result);
      if (!mounted) return;
      setState(() {
        _families = [response, ..._families];
        _loading = false;
        _error = null;
      });
      final inviteCode = response['invite_code'] as String? ?? '';

      await showDialog(
        context: context,
        builder:
            (ctx) => DialogFadeScale(
              child: AlertDialog(
                backgroundColor: ctx.colors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Text(
                  'Family jar created!',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ctx.colors.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share this code with your family members:',
                      style: TextStyle(
                        color: ctx.colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: ctx.colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ctx.colors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              inviteCode,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ctx.colors.textPrimary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: inviteCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(
                                    bottom: 80,
                                    left: 16,
                                    right: 16,
                                  ),
                                  content: const Text('Invite code copied!'),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy_rounded,
                              color: ctx.colors.primary,
                            ),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: ctx.colors.primary,
                      foregroundColor: ctx.colors.onPrimary,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
      );
      // Silent reconciliation so the optimistic card is replaced with the
      // authoritative server record (no spinner, no flicker).
      await _loadFamilies(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          content: Text('Could not create jar: $e'),
        ),
      );
    }
  }

  Future<void> _joinFamily() async {
    final codeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => DialogFadeScale(
            child: AlertDialog(
              backgroundColor: ctx.colors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                'Join a family jar',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ctx.colors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the invite code shared with you.',
                    style: TextStyle(
                      color: ctx.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'e.g. MIZAN-ABC-123',
                      filled: true,
                      fillColor: ctx.colors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ctx.colors.inputBorder),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ctx.colors.textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final code = codeController.text.trim();
                    if (code.isEmpty) return;
                    Navigator.pop(ctx, code);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ctx.colors.primary,
                    foregroundColor: ctx.colors.onPrimary,
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
    );

    if (result == null || !mounted) return;
    try {
      await BackendApi.instance.joinFamilyJar(inviteCode: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          content: const Text('Joined family jar!'),
        ),
      );
      // Silent sync so the joined jar appears without a jarring reload spinner.
      _loadFamilies(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          content: Text(
            backendErrorMessage(
              e,
              fallback: 'Could not join the family. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
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
          child: RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () => _loadFamilies(showSpinner: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  toolbarHeight: 64,
                  collapsedHeight: 64,
                  expandedHeight: 64,
                  backgroundColor: tokens.background,
                  foregroundColor: tokens.textPrimary,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Family'),
                  actions: [
                    PopupMenuButton<String>(
                      tooltip: 'Create or join a family',
                      icon: Icon(Icons.add_rounded, color: tokens.iconPrimary),
                      onSelected: (value) {
                        if (value == 'create') _createFamily();
                        if (value == 'join') _joinFamily();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'create',
                          child: Text('Create family'),
                        ),
                        PopupMenuItem(
                          value: 'join',
                          child: Text('Join with code'),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        onPressed: () => context.push('/family/invitations'),
                        tooltip: 'Invitations',
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.borderSubtle),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.person_add_outlined,
                                  size: 18,
                                  color: tokens.primary,
                                ),
                              ),
                              if (_pendingCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: tokens.error,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_pendingCount',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    key: const ValueKey('family-content'),
                    duration: MizanMotion.normal,
                    switchInCurve: MizanMotion.gentle,
                    switchOutCurve: MizanMotion.gentle,
                    child: _buildBody(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return SizedBox(
        key: ValueKey('loading'),
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }
    if (_error != null) {
      return _ErrorState(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: _loadFamilies,
      );
    }
    if (_families.isEmpty) {
      return Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          children: [
            if (_pendingCount > 0) ...[
              _PendingInvitesBanner(count: _pendingCount),
              const SizedBox(height: 12),
            ],
            _EmptyFamily(onJoin: _joinFamily, onCreate: _createFamily),
          ],
        ),
      );
    }
    return Padding(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children:
            [
              if (_pendingCount > 0) ...[
                _PendingInvitesBanner(count: _pendingCount),
                const SizedBox(height: 12),
              ],
              ..._families.map(
                (jar) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _JarCard(jar: jar),
                ),
              ),
            ],
      ),
    );
  }
}

class _PendingInvitesBanner extends StatelessWidget {
  const _PendingInvitesBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => context.push('/family/invitations'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count pending invitation${count == 1 ? '' : 's'}',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: colors.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.errorContainer,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.error.withValues(alpha: 0.4)),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: tokens.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load families',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({required this.jar});

  final Map<String, dynamic> jar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final name = jar['name']?.toString() ?? 'Family';
    final memberCount = (jar['member_count'] as num?)?.toInt() ?? 0;
    final goals = (jar['goals'] as List?) ?? const [];
    final firstGoal =
        goals.isNotEmpty && goals.first is Map
            ? Map<String, dynamic>.from(goals.first as Map)
            : const <String, dynamic>{};
    final actsDone = _asInt(
      jar['acts_done'],
      fallback: _asInt(firstGoal['acts_done'], fallback: 0),
    );
    final actsTarget = _asInt(
      jar['acts_target'],
      fallback: _asInt(firstGoal['acts_target'], fallback: 0),
    );
    final rawProgress = _asDouble(
      jar['progress'],
      fallback:
          actsTarget > 0
              ? actsDone / actsTarget
              : _asDouble(firstGoal['progress'], fallback: 0),
    );
    final progress = rawProgress.clamp(0.0, 1.0).toDouble();
    final daysRemaining =
        _asNullableInt(jar['days_remaining']) ?? _daysLeftThisMonth();
    final goalLabel =
        (jar['goal_label'] ??
                firstGoal['title'] ??
                (actsTarget > 0 ? 'Monthly goal' : 'No active goal'))
            .toString();
    return CardEntrance(
      index: 0,
      child: Semantics(
        button: true,
        label:
            'Open $name, $memberCount members, ${(progress * 100).round()} percent complete',
        child: SoftCard(
          onTap: () => context.push('/family/jar/${jar['id']}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tokens.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 28,
                        color: tokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$memberCount members',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$goalLabel · ${(progress * 100).round()}%',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$daysRemaining days left',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SmoothProgress(value: progress),
            ],
          ),
        ),
      ),
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _daysLeftThisMonth() {
    final now = DateTime.now();
    final nextMonth =
        now.month == 12
            ? DateTime(now.year + 1)
            : DateTime(now.year, now.month + 1);
    return nextMonth
        .difference(DateTime(now.year, now.month, now.day))
        .inDays
        .clamp(0, 31);
  }
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily({super.key, required this.onJoin, required this.onCreate});

  final VoidCallback onJoin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (MizanMotion.enabled(context))
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MizanMotion.slow,
              curve: MizanMotion.gentle,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 6 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Icon(
                  Icons.groups_outlined,
                  size: 40,
                  color: colors.primary,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'No family yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a jar or join one with an invite code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Join with code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MizanButton(label: 'Create a jar', onTap: onCreate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
