import 'dart:async';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api.dart';
import 'location_service.dart';
import 'notification_type.dart';

/// Background handler for Firebase messages. This runs in the background
/// isolate and persists the payload so the app can route to it when opened.
/// Keep this minimal: avoid UI-only plugins here.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final data = message.data;
    final payload = data.isNotEmpty ? data.entries.map((e) => '${e.key}=${e.value}').join('&') : '';
    if (payload.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_payload', payload);
    }
  } catch (_) {}
}

/// Opt-in push setup. Call only from an explicit reminder-enable action.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _deviceIdKey = 'push_device_id';
  bool _configured = false;
  final StreamController<RemoteMessage> _foregroundController = StreamController<RemoteMessage>.broadcast();

  /// Stream of messages received while the app is foregrounded. UI can
  /// subscribe to present an in-app banner/toast.
  Stream<RemoteMessage> get onForegroundMessage => _foregroundController.stream;

  Future<bool> enableForReminders() async {
    if (kIsWeb) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized && settings.authorizationStatus != AuthorizationStatus.provisional) return false;
    await _configureForegroundNotifications();
    await _registerCurrentToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _registerCurrentToken());
    return true;
  }

  Future<void> _configureForegroundNotifications() async {
    if (_configured) return;
    try {
      // Ask the OS to present system notifications while app is foregrounded
      // where supported (iOS). On Android the OS won't auto-display
      // notification payloads when the app is foregrounded, so we expose an
      // in-app stream for UI banners.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      // Foreground messages: broadcast to UI for an in-app banner/toast.
      FirebaseMessaging.onMessage.listen((message) {
        _foregroundController.add(message);
      });

      // When the user taps a system notification from the tray, Firebase
      // delivers it here. Persist the data for later routing via
      // `pending_notification_payload` so the existing startup logic can
      // route once the app is resumed.
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        try {
          final data = message.data;
          if (data.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_notification_payload', data.entries.map((e) => '${e.key}=${e.value}').join('&'));
          }
        } catch (_) {}
      });
    } catch (e) {
      // Firebase may not be initialized in some environments.
    }
    _configured = true;
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final preferences = await SharedPreferences.getInstance();
    var deviceId = preferences.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      await preferences.setString(_deviceIdKey, deviceId);
    }
    // Attempt to include device timezone and last-known coordinates so the
    // backend can respect user timezone and saved location when scheduling
    // or filtering notifications (e.g., prayer times).
    String? tzName;
    try {
      tzName = DateTime.now().timeZoneName;
    } catch (_) {
      tzName = null;
    }
    Map<String, double>? coords;
    try {
      coords = await LocationService.instance.getStoredPosition();
    } catch (_) {
      coords = null;
    }
    await BackendApi.instance.registerPushToken(deviceId: deviceId, platform: _platformName(), pushToken: token, timeZone: tzName, coords: coords);
  }

  String _platformName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'web',
  };
}
