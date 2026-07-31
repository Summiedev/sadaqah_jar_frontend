import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/theme/app_theme.dart';

import '../services/backend_api.dart';

class LiveJarPanel extends StatefulWidget {
  const LiveJarPanel({super.key, this.compact = false});

  final bool compact;

  @override
  State<LiveJarPanel> createState() => _LiveJarPanelState();
}

enum ConnectionStatus { connecting, live, offline, disconnected, updated }

class _LiveJarPanelState extends State<LiveJarPanel> {
  JarStats? _jar;
  bool _loading = true;
  ConnectionStatus _status = ConnectionStatus.connecting;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int? _userId;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _maxReconnectDelay = 30000;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = await BackendApi.instance.getCurrentUserId();
    final token = await BackendApi.instance.getToken();
    final jar = await BackendApi.instance.getJar();

    if (!mounted) return;
    setState(() {
      _userId = userId;
      _jar = jar;
      _loading = false;
      _status = userId == null || token == null || token.isEmpty ? ConnectionStatus.offline : ConnectionStatus.live;
    });

    if (userId == null || token == null || token.isEmpty) {
      return;
    }

    await _connect(userId, token);
  }

  Future<void> _connect(int userId, String token) async {
    _reconnectTimer?.cancel();
    try {
      final uri = BackendApi.instance.userWebSocketUri(userId, token);
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleEvent,
        onError: (_) {
          if (mounted) setState(() => _status = ConnectionStatus.disconnected);
          _scheduleReconnect(userId, token);
        },
        onDone: () {
          if (mounted) setState(() => _status = ConnectionStatus.disconnected);
          _scheduleReconnect(userId, token);
        },
      );
      if (mounted) setState(() { _status = ConnectionStatus.live; _reconnectAttempts = 0; });
    } catch (_) {
      if (mounted) setState(() => _status = ConnectionStatus.disconnected);
      _scheduleReconnect(userId, token);
    }
  }

  void _scheduleReconnect(int userId, String token) {
    _reconnectTimer?.cancel();
    final delay = (_reconnectAttempts == 0)
        ? const Duration(seconds: 1)
        : Duration(milliseconds: (1000 * (1 << _reconnectAttempts)).clamp(1000, _maxReconnectDelay));
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () {
      if (mounted && _userId != null) _connect(userId, token);
    });
  }

  void _handleEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;
      if (decoded is Map<String, dynamic>) {
        final currentStars = (decoded['current_stars'] as num?)?.toInt();
        final capacity = (decoded['capacity'] as num?)?.toInt();
        if (currentStars != null || capacity != null) {
          setState(() {
            _jar = JarStats(
              currentStars: currentStars ?? _jar?.currentStars ?? 0,
              capacity: capacity ?? _jar?.capacity ?? 33,
              completedAt: decoded['completed_at']?.toString() ?? _jar?.completedAt,
            );
            _status = ConnectionStatus.updated;
          });
        }
      }
    } catch (_) {
      // Ignore malformed websocket payloads and keep the last known state.
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;
    final jar = _jar;
    final current = jar?.currentStars ?? 0;
    final capacity = jar?.capacity ?? 33;
    final progress = capacity == 0 ? 0.0 : current / capacity;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = widget.compact || constraints.maxWidth < 340;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compactLayout ? s(12) : s(16)),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(compactLayout ? s(14) : s(20)),
          ),
          child: _loading
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: s(10),
                      runSpacing: s(10),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: constraints.maxWidth - 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Personal Mizan',
                                style: TextStyle(
                                  fontSize: compactLayout ? s(16) : s(18),
                                  fontWeight: FontWeight.w800,
                                  color: kInk,
                                ),
                              ),
                              SizedBox(height: s(4)),
                              Text(
                                _userId == null ? 'Sign in to connect live updates' : 'Live balance updates are connected',
                                style: TextStyle(fontSize: s(12), color: kMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(6)),
                          decoration: BoxDecoration(
                            color: kClayLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _status.name,
                            style: TextStyle(fontSize: s(11), color: kBronzeDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(14)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: s(compactLayout ? 8 : 12),
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: kClayLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(kBronzeDark),
                      ),
                    ),
                    SizedBox(height: s(10)),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: s(6),
                      spacing: s(10),
                      children: [
                        Text('$current / $capacity stars', style: TextStyle(fontSize: s(14), color: kMuted)),
                        Text('${(progress * 100).round()}%', style: TextStyle(fontSize: s(14), color: kMuted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (jar?.completedAt != null) ...[
                      SizedBox(height: s(8)),
                      Text('Jar completed', style: TextStyle(color: Colors.green.shade700, fontSize: s(13))),
                    ],
                  ],
                ),
        );
      },
    );
  }
}