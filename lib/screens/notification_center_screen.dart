import 'package:flutter/material.dart';

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
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPage();
  }

  @override
  void dispose() {
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
      _notifyUnreadCount();
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
    final unread = _items.where((n) => !n.isRead).length;
    widget.onUnreadCountChanged?.call(unread);
  }

  Future<void> _markRead(int notificationId, int index) async {
    try {
      await BackendApi.instance.markNotificationRead(notificationId);
      if (!mounted) return;
      setState(() {
        _items[index] = NotificationItem(
          id: _items[index].id,
          title: _items[index].title,
          message: _items[index].message,
          isRead: true,
          createdAt: _items[index].createdAt,
        );
      });
      _notifyUnreadCount();
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
            title: _items[i].title,
            message: _items[i].message,
            isRead: true,
            createdAt: _items[i].createdAt,
          );
        }
      });
      _notifyUnreadCount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $error')),
      );
    }
  }

  void _archive(int index) {
    final item = _items[index];
    setState(() => _items.removeAt(index));
    _notifyUnreadCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Notification archived'), action: SnackBarAction(label: 'Undo', onPressed: () {
        if (mounted) setState(() => _items.insert(index.clamp(0, _items.length).toInt(), item));
      })),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;
    final unreadCount = _items.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFF2EBDD),
        surfaceTintColor: Colors.transparent,
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
          child: _initialLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _items.isEmpty
                  ? _StateMessage(message: 'Failed to load notifications.', detail: _error!, onRetry: _retry)
                  : _items.isEmpty
                      ? const _StateMessage(
                          message: 'No notifications yet.',
                          detail: 'Gentle updates from your family space and reminders will appear here.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(s(16)),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFE8D7C1), Color(0xFFF7F3ED)],
                                ),
                                borderRadius: BorderRadius.circular(s(20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_total notification${_total == 1 ? '' : 's'}',
                                    style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: const Color(0xFF2F251E)),
                                  ),
                                  SizedBox(height: s(4)),
                                  Text(
                                    unreadCount == 0
                                        ? 'You are all caught up.'
                                        : '$unreadCount unread update${unreadCount == 1 ? '' : 's'} waiting.',
                                    style: TextStyle(fontSize: s(12.8), color: const Color(0xFF6A5E52)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(12)),
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
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
                                  return Dismissible(
                                    key: ValueKey(notification.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: s(22)),
                                      decoration: BoxDecoration(color: const Color(0xFF8B6842), borderRadius: BorderRadius.circular(s(16))),
                                      child: const Icon(Icons.archive_outlined, color: Colors.white),
                                    ),
                                    onDismissed: (_) => _archive(index),
                                    child: _NotificationCard(
                                      scale: scale,
                                      notification: notification,
                                      onTap: notification.isRead ? null : () => _markRead(notification.id, index),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_error != null) ...[
                              SizedBox(height: s(8)),
                              TextButton(onPressed: _retry, child: const Text('Retry loading more')),
                            ],
                          ],
                        ),
        ),
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
    return Material(
      color: notification.isRead ? const Color(0xFFF7F3ED) : const Color(0xFFE9DCCF),
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
                  color: presentation.$2.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Icon(presentation.$1, color: presentation.$2, size: s(20)),
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
                              color: const Color(0xFF2F2A28),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: s(8),
                            height: s(8),
                            decoration: const BoxDecoration(color: Color(0xFFB07B3E), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    SizedBox(height: s(4)),
                    Text(notification.message, style: TextStyle(fontSize: s(13), color: const Color(0xFF5A4D43), height: 1.35)),
                    if (notification.createdAt != null) ...[
                      SizedBox(height: s(8)),
                      Text(_formatDate(notification.createdAt!), style: TextStyle(fontSize: s(11.2), color: const Color(0xFF7A6D60))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _presentationFor(NotificationItem item) {
    final text = '${item.title} ${item.message}'.toLowerCase();
    if (text.contains('prayer') || text.contains('salah')) return (Icons.mosque_outlined, const Color(0xFF58705C));
    if (text.contains('family') || text.contains('invite')) return (Icons.groups_outlined, const Color(0xFF8B6842));
    if (text.contains('goal')) return (Icons.flag_outlined, const Color(0xFFB06B45));
    if (text.contains('reflection')) return (Icons.menu_book_outlined, const Color(0xFF687EA5));
    if (text.contains('achievement') || text.contains('streak')) return (Icons.auto_awesome_outlined, const Color(0xFF9A6A3A));
    return (Icons.notifications_none_outlined, const Color(0xFF76695E));
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
  const _StateMessage({required this.message, required this.detail, this.onRetry});

  final String message;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
