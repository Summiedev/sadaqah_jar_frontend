import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_extensions.dart';
import '../services/connectivity_service.dart';
import '../services/offline_action_queue.dart';

class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  static const _displayDuration = Duration(seconds: 4);

  Timer? _poller;
  Timer? _hideTimer;
  int _pending = 0;
  bool _visible = false;
  bool? _lastOnline;
  int? _lastObservedPending;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final count = await ref.read(offlineQueueProvider).getPendingCount();
      if (!mounted) return;
      final online = ref.read(isOnlineProvider);
      final stateChanged =
          _lastOnline != online || _lastObservedPending != count;
      final changed = count != _pending;
      if (changed) setState(() => _pending = count);
      _lastOnline = online;
      _lastObservedPending = count;

      // Show an offline state even when the queue is empty. Queue changes are
      // shown briefly; the banner is not a permanent part of the layout.
      if (stateChanged) _showBriefly();
    } catch (_) {}
  }

  void _showBriefly() {
    if (!mounted) return;
    _hideTimer?.cancel();
    if (!_visible) setState(() => _visible = true);
    _hideTimer = Timer(_displayDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider);
    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (previous != null && previous != next) _showBriefly();
    });
    final show = _visible && (!online || _pending > 0);
    final message = !online
        ? _pending == 0
            ? "You're offline. Saved changes will sync automatically."
            : 'You\'re offline. $_pending saved change${_pending == 1 ? '' : 's'} will sync automatically.'
        : '$_pending saved change${_pending == 1 ? '' : 's'} waiting to sync.';
    final colors = context.colors;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child:
          show
              ? Container(
                key: ValueKey(message),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
                color: colors.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      online ? Icons.sync_rounded : Icons.cloud_off_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
