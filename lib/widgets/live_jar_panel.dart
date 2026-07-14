import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/backend_api.dart';

class LiveJarPanel extends StatefulWidget {
  const LiveJarPanel({super.key, this.compact = false});

  final bool compact;

  @override
  State<LiveJarPanel> createState() => _LiveJarPanelState();
}

class _LiveJarPanelState extends State<LiveJarPanel> {
  JarStats? _jar;
  bool _loading = true;
  String _status = 'Connecting';
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int? _userId;

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
      _status = userId == null || token == null ? 'Offline' : 'Live';
    });

    if (userId == null || token == null || token.isEmpty) {
      return;
    }

    try {
      final uri = BackendApi.instance.userWebSocketUri(userId, token);
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleEvent,
        onError: (_) {
          if (mounted) {
            setState(() {
              _status = 'Disconnected';
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _status = 'Disconnected';
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'Disconnected';
        });
      }
    }
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
            _status = 'Updated';
          });
        }
      }
    } catch (_) {
      // Ignore malformed websocket payloads and keep the last known state.
    }
  }

  @override
  void dispose() {
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
            color: const Color(0xFFF8F4EA),
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
                                  color: const Color(0xFF3B3327),
                                ),
                              ),
                              SizedBox(height: s(4)),
                              Text(
                                _userId == null ? 'Sign in to connect live updates' : 'Live balance updates are connected',
                                style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3D5C7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(fontSize: s(11), color: const Color(0xFF7A5B3E), fontWeight: FontWeight.w700),
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
                        backgroundColor: const Color(0xFFE5D6C3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B734F)),
                      ),
                    ),
                    SizedBox(height: s(10)),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: s(6),
                      spacing: s(10),
                      children: [
                        Text('$current / $capacity stars', style: TextStyle(fontSize: s(14), color: const Color(0xFF5A4D43))),
                        Text('${(progress * 100).round()}%', style: TextStyle(fontSize: s(14), color: const Color(0xFF5A4D43), fontWeight: FontWeight.w600)),
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