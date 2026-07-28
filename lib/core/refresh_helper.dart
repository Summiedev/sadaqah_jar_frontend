import 'dart:async';
import 'package:flutter/material.dart';

class AutoRefreshController {
  final Duration interval;
  final VoidCallback onRefresh;
  Timer? _timer;
  bool _disposed = false;
  bool _paused = false;

  AutoRefreshController({
    this.interval = const Duration(seconds: 30),
    required this.onRefresh,
  });

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      if (!_paused && !_disposed) {
        onRefresh();
      }
    });
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
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
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
}