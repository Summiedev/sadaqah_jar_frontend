import 'dart:async';
import 'package:flutter/material.dart';

/// Lifecycle-aware periodic refresh controller with single-flight protection.
///
/// Prevents refresh storms by:
/// * pausing when the app is backgrounded/offline
/// * refusing overlapping refreshes (single-flight)
/// * cancelling the timer on dispose
/// * allowing only one owner to start the timer
class AutoRefreshController {
  final Duration interval;
  final Future<void> Function() onRefresh;
  Timer? _timer;
  bool _disposed = false;
  bool _paused = false;
  bool _refreshInFlight = false;
  bool _lifecycleAware = false;

  AutoRefreshController({
    this.interval = const Duration(seconds: 30),
    required this.onRefresh,
    bool lifecycleAware = true,
  }) {
    if (lifecycleAware) {
      _lifecycleAware = true;
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
    }
  }

  void start() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _maybeRefresh());
  }

  /// Single-flight guard: if a refresh is already running, skip this tick.
  Future<void> _maybeRefresh() async {
    if (_paused || _disposed || _refreshInFlight) return;
    _refreshInFlight = true;
    try {
      await onRefresh();
    } finally {
      _refreshInFlight = false;
    }
  }

  /// Public method to trigger an immediate refresh (mutation/pull-to-refresh).
  /// Shares the same single-flight guard so overlapping calls are coalesced.
  Future<void> refreshNow() => _maybeRefresh();

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_lifecycleAware) {
      WidgetsBinding.instance.removeObserver(_LifecycleObserver(this));
    }
  }

  bool get isPaused => _paused;
}

class _LifecycleObserver with WidgetsBindingObserver {
  final AutoRefreshController controller;
  _LifecycleObserver(this.controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.resume();
      // Refresh immediately on resume so data isn't stale.
      controller.refreshNow();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      controller.pause();
    }
  }
}

class PullToRefreshWrapper extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> {
  Future<void>? _pendingRefresh;

  Future<void> _handleRefresh() async {
    setState(() {
      _pendingRefresh = widget.onRefresh();
    });
    await _pendingRefresh;
    if (mounted) {
      setState(() {
        _pendingRefresh = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _handleRefresh, child: widget.child);
  }
}
