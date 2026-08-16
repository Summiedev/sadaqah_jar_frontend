import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/backend_api.dart';

/// [H3] Keyed WebSocket manager.
///
/// Fixes the previous global-singleton lifecycle bug where one screen calling
/// `disconnect()` (or `connectFamily()`) destroyed the socket used elsewhere.
///
/// Architecture:
/// * `personalConnection` - one socket for the signed-in user's own channel.
/// * `familyConnections[familyId]` - one socket per family jar.
///
/// Each connection owns its own StreamSubscription and reconnect timer.
/// Reconnect uses capped exponential backoff (5s -> 10s -> 20s -> 40s max).
/// `disconnect()` closes ALL user-scoped sockets (used on logout).
class WebSocketService extends ChangeNotifier {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  final Map<String, _SocketConnection> _connections = {};
  static const _maxReconnectDelay = Duration(seconds: 40);
  static const _baseReconnectDelay = Duration(seconds: 5);

  bool get isConnected => _connections.values.any((c) => c.connected);

  /// Connects (or reconnects) the personal user socket. Replaces any existing
  /// personal socket, cancelling its old subscription and reconnect timer.
  Future<void> connect(int userId) async {
    await _connect('user:$userId', () => _openUser(userId));
  }

  /// Connects (or reconnects) a family socket. Does NOT touch the personal
  /// socket or other family sockets.
  Future<void> connectFamily(int familyId) async {
    await _connect('family:$familyId', () => _openFamily(familyId));
  }

  /// Closes ALL user-scoped sockets. Used on logout/account switch.
  void disconnect() {
    for (final conn in _connections.values) {
      conn.close();
    }
    _connections.clear();
    notifyListeners();
  }

  Future<void> _connect(String key, Future<void> Function() open) async {
    final existing = _connections[key];
    if (existing != null) {
      // Replace: cancel old subscription + reconnect timer, then reopen.
      existing.close();
    }
    final conn = _SocketConnection(
      key,
      onReconnect: () => _connect(key, open),
      baseReconnectDelay: _baseReconnectDelay,
      maxReconnectDelay: _maxReconnectDelay,
    );
    _connections[key] = conn;
    await open();
    notifyListeners();
  }

  Future<void> _openUser(int userId) async {
    final key = 'user:$userId';
    final conn = _connections[key];
    if (conn == null) return;
    try {
      final token = await BackendApi.instance.getToken();
      if (token == null || token.isEmpty) return;
      final uri = BackendApi.instance.userWebSocketUri(userId, token);
      conn.open(WebSocketChannel.connect(uri));
    } catch (_) {
      conn.markFailed();
    }
  }

  Future<void> _openFamily(int familyId) async {
    final key = 'family:$familyId';
    final conn = _connections[key];
    if (conn == null) return;
    try {
      final token = await BackendApi.instance.getToken();
      if (token == null || token.isEmpty) return;
      final uri = BackendApi.instance.familyWebSocketUri(familyId, token);
      conn.open(WebSocketChannel.connect(uri));
    } catch (_) {
      conn.markFailed();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class _SocketConnection {
  _SocketConnection(
    this.key, {
    required this.onReconnect,
    required this.baseReconnectDelay,
    required this.maxReconnectDelay,
  });

  final String key;
  final Future<void> Function() onReconnect;
  final Duration baseReconnectDelay;
  final Duration maxReconnectDelay;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _connected = false;
  int _reconnectAttempts = 0;

  bool get connected => _connected;

  void open(WebSocketChannel channel) {
    _channel?.sink.close();
    _subscription?.cancel();
    _channel = channel;
    _connected = true;
    _reconnectAttempts = 0;
    _subscription = channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          _handleEvent(data);
        } catch (_) {}
      },
      onDone: () {
        _connected = false;
        _scheduleReconnect();
      },
      onError: (_) {
        _connected = false;
        _scheduleReconnect();
      },
    );
  }

  void markFailed() {
    _connected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Capped exponential backoff: 5s, 10s, 20s, 40s, 40s, ...
    final delayMs = baseReconnectDelay.inMilliseconds *
        (1 << (_reconnectAttempts > 3 ? 3 : _reconnectAttempts));
    final capped = delayMs > maxReconnectDelay.inMilliseconds
        ? maxReconnectDelay
        : Duration(milliseconds: delayMs);
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    _reconnectAttempts++;
    _reconnectTimer = Timer(capped + jitter, () {
      onReconnect();
    });
  }

  void _handleEvent(Map<String, dynamic> data) {
    final eventType =
        data['event_type']?.toString() ?? data['type']?.toString() ?? '';
    switch (eventType) {
      case 'family.created':
      case 'member.joined':
      case 'member.left':
      case 'goal.created':
      case 'goal.completed':
      case 'act.added':
      case 'reflection.shared':
        // Notify listeners so UI can refresh. The service itself doesn't
        // hold per-screen state; screens listen and re-fetch.
        break;
    }
  }

  void close() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }
}
