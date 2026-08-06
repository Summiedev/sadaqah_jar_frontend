import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/backend_api.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _connected = false;
  int? _userId;
  int? _familyId;

  bool get isConnected => _connected;

  Future<void> connect(int userId) async {
    _userId = userId;
    _familyId = null;
    await _connectUser();
  }

  Future<void> connectFamily(int familyId) async {
    _familyId = familyId;
    _userId = null;
    await _connectFamily();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _reconnectTimer?.cancel();
    notifyListeners();
  }

  Future<void> _connectUser() async {
    _channel?.sink.close();
    _channel = null;

    try {
      final token = await BackendApi.instance.getToken();
      if (token == null || token.isEmpty) return;

      final uri = BackendApi.instance.userWebSocketUri(_userId!, token);
      _channel = WebSocketChannel.connect(uri);
      _connected = true;
      notifyListeners();
      _listen();
    } catch (_) {
      _connected = false;
      notifyListeners();
    }
  }

  Future<void> _connectFamily() async {
    _channel?.sink.close();
    _channel = null;

    try {
      final token = await BackendApi.instance.getToken();
      if (token == null || token.isEmpty) return;

      final uri = BackendApi.instance.familyWebSocketUri(_familyId!, token);
      _channel = WebSocketChannel.connect(uri);
      _connected = true;
      notifyListeners();
      _listen();
    } catch (_) {
      _connected = false;
      notifyListeners();
    }
  }

  void _listen() {
    _channel?.stream.listen((message) {
      try {
        final data = jsonDecode(message) as Map<String, dynamic>;
        _handleEvent(data);
      } catch (_) {}
    }, onDone: () {
      _connected = false;
      notifyListeners();
      _scheduleReconnect();
    }, onError: (_) {
      _connected = false;
      notifyListeners();
      _scheduleReconnect();
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_userId != null) {
        _connectUser();
      } else if (_familyId != null) {
        _connectFamily();
      }
    });
  }

  void _handleEvent(Map<String, dynamic> data) {
    final eventType = data['event_type']?.toString() ?? data['type']?.toString() ?? '';
    switch (eventType) {
      case 'family.created':
      case 'member.joined':
      case 'member.left':
      case 'goal.created':
      case 'goal.completed':
      case 'act.added':
      case 'reflection.shared':
        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}