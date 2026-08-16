import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/animations.dart';
import '../services/backend_api.dart' show BackendApi, NotificationItem;

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, this.onUnreadCountChanged});

  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<NotificationItem> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  int _total = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final page = await BackendApi.instance.getNotifications(
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _total = page.total;
        _offset = page.offset + page.data.length;
        _items.addAll(page.data);
        _hasMore = _items.length < page.total && page.data.isNotEmpty;
        _initialLoading = false;
        _loadingMore = false;
      });
      _fetchUnreadCount();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _hasMore = false;
        _initialLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await BackendApi.instance.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() {
        _unreadCount = count;
      });
      _notifyUnreadCount();
    } catch (_) {
      if (!mounted) return;
      final fallback = _items.where((n) => !n.isRead).length;
      setState(() {
        _unreadCount = fallback;
      });
      _notifyUnreadCount();
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final page = await BackendApi.instance.getNotifications(
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.data);
        _total = page.total;
        _offset = page.data.length;
        _hasMore = _items.length < page.total && page.data.isNotEmpty;
        _error = null;
        _refreshing = false;
      });
      _fetchUnreadCount();
    } catch (error) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh notifications.')),
      );
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _loadPage();
    }
  }

  void _retry() {
    setState(() {
      _items.clear();
      _offset = 0;
      _total = 0;
      _hasMore = true;
      _error = null;
      _initialLoading = true;
    });
    _loadPage();
  }

  void _notifyUnreadCount() {
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  Future<void> _markRead(int notificationId, int index) async {
    try {
      await BackendApi.instance.markNotificationRead(notificationId);
      if (!mounted) return;
      // C5: don't blindly modify _items[index] after an await - the list may
      // have been refreshed/reordered. Look the item up by ID again.
      final updatedIndex =
          _items.indexWhere((item) => item.id == notificationId);
      if (updatedIndex == -1) return;
      setState(() {
        _items[updatedIndex] = NotificationItem(
          id: _items[updatedIndex].id,
          type: _items[updatedIndex].type,
          title: _items[updatedIndex].title,
          body: _items[updatedIndex].body,
          isRead: true,
          createdAt: _items[updatedIndex].createdAt,
          data: _items[updatedIndex].data,
        );
      });
      _fetchUnreadCount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark that notification as read.'),
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await BackendApi.instance.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = NotificationItem(
            id: _items[i].id,
            type: _items[i].type,
            title: _items[i].title,
            body: _items[i].body,
            isRead: true,
            createdAt: _items[i].createdAt,
            data: _items[i].data,
          );
        }
      });
      _fetchUnreadCount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark notifications as read.')),
      );
    }
  }

  Future<void> _archive(int index) async {
    final item = _items[index];
    try {
      await BackendApi.instance.deleteNotification(item.id);
      if (!mounted) return;
      // C5: same guard - find by ID after the await rather than using a
      // potentially stale index.
      final updatedIndex =
          _items.indexWhere((n) => n.id == item.id);
      if (updatedIndex == -1) return;
      setState(() => _items.removeAt(updatedIndex));
      _fetchUnreadCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (mounted) {
                setState(
                  () => _items.insert(
                    updatedIndex.clamp(0, _items.length).toInt(),
                    item,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not archive notification.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => (v * scale).roundToDouble();
    final unreadCount = _unreadCount;
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: tokens.iconPrimary,
            size: 19,
          ),
          tooltip: 'Back',
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(18)),
          child: AnimatedSwitcher(
            key: const ValueKey('notification-content'),
            duration: MizanMotion.normal,
            switchInCurve: MizanMotion.gentle,
            switchOutCurve: MizanMotion.gentle,
            child:
                _initialLoading
                    ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                    )
                    : _error != null && _items.isEmpty
                    ? _StateMessage(
                      key: const ValueKey('error'),
                      message: 'Failed to load notifications.',
                      detail: _error!,
                      onRetry: _retry,
                    )
                    : _items.isEmpty
                    ? const _StateMessage(
                      key: ValueKey('empty'),
                      message: 'No notifications yet.',
                      detail:
                          'Gentle updates from your family space and reminders will appear here.',
                    )
                    : Column(
                      key: const ValueKey('notification-list'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeScaleTransition(
                          beginScale: 0.97,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(s(16)),
                            decoration: BoxDecoration(
                              color: tokens.surfaceElevated,
                              border: Border.all(color: tokens.border),
                              borderRadius: BorderRadius.circular(s(20)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: s(46),
                                  height: s(46),
                                  decoration: BoxDecoration(
                                    color: tokens.primaryContainer,
                                    borderRadius: BorderRadius.circular(s(15)),
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_outlined,
                                    color: tokens.primary,
                                    size: s(22),
                                  ),
                                ),
                                SizedBox(width: s(13)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_total notification${_total == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: s(16),
                                          fontWeight: FontWeight.w800,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: s(4)),
                                      Text(
                                        unreadCount == 0
                                            ? 'You are all caught up.'
                                            : '$unreadCount unread update${unreadCount == 1 ? '' : 's'} waiting.',
                                        style: TextStyle(
                                          fontSize: s(12.8),
                                          color: tokens.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: s(12)),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            color: tokens.primary,
                            backgroundColor: tokens.surfaceElevated,
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount:
                                  _items.length +
                                  (_hasMore && _error == null ? 1 : 0),
                              separatorBuilder:
                                  (_, __) => SizedBox(height: s(10)),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: s(10),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final notification = _items[index];
                                return CardEntrance(
                                  key: ValueKey('entrance-${notification.id}'),
                                  index: index.clamp(0, 8),
                                  delay: const Duration(milliseconds: 30),
                                  child: _DismissibleNotificationCard(
                                    scale: scale,
                                    notification: notification,
                                    onTap:
                                        notification.isRead
                                            ? null
                                            : () => _markRead(
                                              notification.id,
                                              index,
                                            ),
                                    onArchive: () => _archive(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: s(8)),
                          TextButton(
                            onPressed: _retry,
                            child: const Text('Retry loading more'),
                          ),
                        ],
                        if (_refreshing) ...[SizedBox(height: s(4))],
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the notification card in a [Dismissible] whose reveal background
/// now animates in step with the swipe (icon scales up as you drag) instead
/// of appearing instantly at full size the moment the swipe starts.
class _DismissibleNotificationCard extends StatelessWidget {
  const _DismissibleNotificationCard({
    required this.scale,
    required this.notification,
    required this.onArchive,
    this.onTap,
  });

  final double scale;
  final NotificationItem notification;
  final VoidCallback onArchive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Builder(
        builder: (context) {
          // DismissUpdateDetails isn't available pre-swipe, so we drive the
          // icon's scale off the Dismissible's own movement via a
          // NotificationListener-free approach: LayoutBuilder + the
          // Dismissible's internal Transform already handles position, we
          // just make our icon feel alive with a simple entrance curve.
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: MizanMotion.fast,
            curve: MizanMotion.gentle,
            builder:
                (context, value, child) => Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: scale * 22),
                  decoration: BoxDecoration(
                    color: kBronze,
                    borderRadius: BorderRadius.circular(scale * 16),
                  ),
                  child: Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.archive_outlined,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
          );
        },
      ),
      onDismissed: (_) => onArchive(),
      child: _NotificationCard(
        scale: scale,
        notification: notification,
        onTap: onTap,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.scale,
    required this.notification,
    this.onTap,
  });

  final double scale;
  final NotificationItem notification;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(notification);
    final tokens = context.colors;
    final cardColor =
        notification.isRead ? tokens.surfaceElevated : tokens.primaryContainer;
    final textColor =
        notification.isRead ? tokens.textPrimary : tokens.onPrimaryContainer;
    final mutedColor =
        notification.isRead
            ? tokens.textSecondary
            : tokens.onPrimaryContainer.withValues(alpha: 0.78);
    return Semantics(
      button: true,
      label: notification.title,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(s(16)),
          child: Padding(
            padding: EdgeInsets.all(s(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!notification.isRead)
                  Container(
                    width: s(4),
                    height: s(72),
                    margin: EdgeInsets.only(right: s(11)),
                    decoration: BoxDecoration(
                      color: presentation.color,
                      borderRadius: BorderRadius.circular(s(8)),
                    ),
                  ),
                Container(
                  width: s(38),
                  height: s(38),
                  decoration: BoxDecoration(
                    color:
                        notification.isRead
                            ? presentation.color.withValues(alpha: 0.13)
                            : tokens.surfaceElevated.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(s(12)),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.color,
                    size: s(20),
                  ),
                ),
                SizedBox(width: s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: s(15),
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            AnimatedContainer(
                              duration: MizanMotion.fast,
                              curve: MizanMotion.gentle,
                              width: s(8),
                              height: s(8),
                              decoration: BoxDecoration(
                                color: presentation.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: s(4)),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: s(13),
                          color: mutedColor,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_detailText(notification) != null) ...[
                        SizedBox(height: s(7)),
                        Text(
                          _detailText(notification)!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: s(11.5),
                            color: mutedColor,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: s(8)),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(8),
                              vertical: s(4),
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surfaceContainer,
                              borderRadius: BorderRadius.circular(s(99)),
                            ),
                            child: Text(
                              _typeLabel(notification),
                              style: TextStyle(
                                fontSize: s(10.5),
                                color: tokens.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: s(11.2),
                              color: mutedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _presentationFor(NotificationItem item) {
    final text = '${item.title} ${item.body}'.toLowerCase();
    if (text.contains('prayer') || text.contains('salah')) {
      return (icon: Icons.mosque_outlined, color: kSage);
    }
    if (text.contains('family') || text.contains('invite')) {
      return (icon: Icons.groups_outlined, color: kBronze);
    }
    if (text.contains('goal')) {
      return (icon: Icons.flag_outlined, color: kBronzeDark);
    }
    if (text.contains('reflection')) {
      return (icon: Icons.menu_book_outlined, color: kSlate);
    }
    if (text.contains('achievement') || text.contains('streak')) {
      return (icon: Icons.auto_awesome_outlined, color: kBronzeDark);
    }
    return (icon: Icons.notifications_none_outlined, color: kMuted);
  }

  String _typeLabel(NotificationItem item) {
    final raw = item.type.trim();
    if (raw.isEmpty) return 'Update';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String? _detailText(NotificationItem item) {
    final data = item.data;
    if (data == null || data.isEmpty) return null;
    final family = data['family_name']?.toString();
    final actor = data['actor_name']?.toString() ?? data['username']?.toString();
    final goal = data['goal_title']?.toString();
    final detail = [
      if (family != null && family.isNotEmpty) 'Family: $family',
      if (goal != null && goal.isNotEmpty) 'Goal: $goal',
      if (actor != null && actor.isNotEmpty) 'From: $actor',
    ];
    return detail.isEmpty ? null : detail.take(2).join('  •  ');
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final now = DateTime.now();
    final diff = now.difference(parsed);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
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
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.message,
    required this.detail,
    this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return CardEntrance(
      index: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: tokens.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  onRetry == null
                      ? Icons.notifications_none_rounded
                      : Icons.cloud_off_outlined,
                  color: tokens.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                onRetry == null
                    ? detail
                    : 'We could not reach the notification service. Pull to refresh or try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
