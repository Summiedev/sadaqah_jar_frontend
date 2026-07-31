import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api.dart';

/// Opt-in push setup. Call only from an explicit reminder-enable action.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _deviceIdKey = 'push_device_id';
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _configured = false;

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
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: android, iOS: ios));
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        if (notification == null) return;
        await _local.show(notification.hashCode, notification.title, notification.body, const NotificationDetails(
          android: AndroidNotificationDetails('reminders', 'Reminders', channelDescription: 'Prayer and adhkar reminders', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ));
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
    await BackendApi.instance.registerPushToken(deviceId: deviceId, platform: _platformName(), pushToken: token);
  }

  String _platformName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'web',
  };
}
