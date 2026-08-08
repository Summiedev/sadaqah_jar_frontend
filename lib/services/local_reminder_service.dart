import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderService {
  LocalReminderService._();
  static final instance = LocalReminderService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const _fridayId = 1001;
  static const _channelId = 'mizan_reminders';
  static const _channelName = 'Mizan reminders';
  static const _channelDescription =
      'Prayer, adhkar, family, and journey reminders from Mizan.';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_notification_payload', payload);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android =
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
    final ios = await _local
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _local.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  Future<void> scheduleDailyAt(
    int id,
    String title,
    String body,
    TimeOfDay time,
  ) async {
    await initialize();
    final now = DateTime.now();
    final scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    var when = scheduled;
    if (scheduled.isBefore(now)) {
      when = scheduled.add(const Duration(days: 1));
    }
    await _local.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async => await _local.cancel(id);

  Future<void> scheduleWeeklyAt(
    int id,
    String title,
    String body, {
    required int weekday,
    required TimeOfDay time,
  }) async {
    await initialize();
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    while (when.weekday != weekday || !when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _local.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> enableFridayReminder(
    bool enable, {
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      final allowed = await requestPermission();
      if (!allowed) {
        throw StateError('Notification permission is required for reminders.');
      }
      await scheduleWeeklyAt(
        _fridayId,
        'Friday reminder',
        'A gentle Friday reminder',
        weekday: DateTime.friday,
        time: TimeOfDay(hour: hour, minute: minute),
      );
      await prefs.setBool('reminder_friday_enabled', true);
      await prefs.setString(
        'reminder_friday_time',
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    } else {
      await cancel(_fridayId);
      await prefs.remove('reminder_friday_enabled');
      await prefs.remove('reminder_friday_time');
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
