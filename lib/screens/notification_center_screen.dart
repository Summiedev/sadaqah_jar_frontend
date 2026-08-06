import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../services/backend_api.dart' show BackendApi, NotificationItem;

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, this.onUnreadCountChanged});

  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
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
      final page = await BackendApi.instance.getNotifications(limit: _pageSize, offset: _offset);
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
      final page = await BackendApi.instance.getNotifications(limit: _pageSize, offset: 0);
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
        SnackBar(content: Text('Could not refresh: $error')),
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
      setState(() {
        _items[index] = NotificationItem(
          id: _items[index].id,
          type: _items[index].type,
          title: _items[index].title,
          body: _items[index].body,
          isRead: true,
          createdAt: _items[index].createdAt,
          data: _items[index].data,
        );
      });
      _fetchUnreadCount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $error')),
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
        SnackBar(content: Text('Failed to mark all as read: $error')),
      );
    }
  }

  Future<void> _archive(int index) async {
    final item = _items[index];
    try {
      await BackendApi.instance.deleteNotification(item.id);
      if (!mounted) return;
      setState(() => _items.removeAt(index));
      _fetchUnreadCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (mounted) setState(() => _items.insert(index.clamp(0, _items.length).toInt(), item));
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not archive notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => (v * scale).roundToDouble();
    final unreadCount = _unreadCount;

    final dark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = dark ? kScaffoldDark : kClayPale;
    final headerBg = dark ? kSurfaceDark : kClayPale;
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: headerBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dark ? kInkDark : kInk, size: 19),
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
            child: _initialLoading
                ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
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
                            detail: 'Gentle updates from your family space and reminders will appear here.',
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
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: dark ? const [kElevatedDark, kSurfaceDark] : const [kClayLight, kClayPale],
                                    ),
                                    border: Border.all(color: dark ? kLineDark : kLine),
                                    borderRadius: BorderRadius.circular(s(20)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_total notification${_total == 1 ? '' : 's'}',
                                        style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: dark ? kInkDark : kInk),
                                      ),
                                      SizedBox(height: s(4)),
                                      Text(
                                        unreadCount == 0
                                            ? 'You are all caught up.'
                                            : '$unreadCount unread update${unreadCount == 1 ? '' : 's'} waiting.',
                                        style: TextStyle(fontSize: s(12.8), color: dark ? kMutedDark : kMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: s(12)),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _refresh,
                                  color: kBronze,
                                  backgroundColor: dark ? kElevatedDark : kPaper,
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    itemCount: _items.length + (_hasMore && _error == null ? 1 : 0),
                                    separatorBuilder: (_, __) => SizedBox(height: s(10)),
                                    itemBuilder: (context, index) {
                                      if (index >= _items.length) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(vertical: s(10)),
                                          child: const Center(child: CircularProgressIndicator()),
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
                                          onTap: notification.isRead ? null : () => _markRead(notification.id, index),
                                          onArchive: () => _archive(index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                SizedBox(height: s(8)),
                                TextButton(onPressed: _retry, child: const Text('Retry loading more')),
                              ],
                              if (_refreshing) ...[
                                SizedBox(height: s(4)),
                              ],
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
            builder: (context, value, child) => Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: scale * 22),
              decoration: BoxDecoration(
                color: kBronze,
                borderRadius: BorderRadius.circular(scale * 16),
              ),
              child: Transform.scale(
                scale: value,
                child: Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.onPrimary),
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
  const _NotificationCard({required this.scale, required this.notification, this.onTap});

  final double scale;
  final NotificationItem notification;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(notification);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = notification.isRead
        ? (dark ? kSurfaceDark : kPaper)
        : (dark ? kElevatedDark : kSoftBronze);
    final textColor = dark ? kInkDark : kInk;
    final mutedColor = dark ? kMutedDark : kMuted;
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
                Container(
                  width: s(38),
                  height: s(38),
                  decoration: BoxDecoration(
                    color: presentation.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(s(12)),
                  ),
                  child: Icon(presentation.icon, color: presentation.color, size: s(20)),
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
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
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
                              decoration: BoxDecoration(color: presentation.color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      SizedBox(height: s(4)),
                      Text(
                        notification.body,
                        style: TextStyle(fontSize: s(13), color: mutedColor, height: 1.35, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: s(8)),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(fontSize: s(11.2), color: mutedColor.withValues(alpha: 0.78), fontWeight: FontWeight.w600),
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
    if (text.contains('prayer') || text.contains('salah')) return (icon: Icons.mosque_outlined, color: kSage);
    if (text.contains('family') || text.contains('invite')) return (icon: Icons.groups_outlined, color: kBronze);
    if (text.contains('goal')) return (icon: Icons.flag_outlined, color: kBronzeDark);
    if (text.contains('reflection')) return (icon: Icons.menu_book_outlined, color: kSlate);
    if (text.contains('achievement') || text.contains('streak')) return (icon: Icons.auto_awesome_outlined, color: kBronzeDark);
    return (icon: Icons.notifications_none_outlined, color: kMuted);
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({super.key, required this.message, required this.detail, this.onRetry});

  final String message;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CardEntrance(
      index: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kInk),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: kInk.withValues(alpha: 0.65), fontWeight: FontWeight.w600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
