import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderService {
  LocalReminderService._();
  static final instance = LocalReminderService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static const _fridayId = 1001;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> scheduleDailyAt(int id, String title, String body, TimeOfDay time) async {
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    var when = scheduled;
    if (scheduled.isBefore(now)) {
      when = scheduled.add(const Duration(days: 1));
    }
    await _local.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(android: AndroidNotificationDetails('reminders', 'Reminders')),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async => await _local.cancel(id);

  Future<void> enableFridayReminder(bool enable, {required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      await scheduleDailyAt(_fridayId, 'Friday reminder', 'A gentle Friday reminder', TimeOfDay(hour: hour, minute: minute));
      await prefs.setBool('reminder_friday_enabled', true);
      await prefs.setString('reminder_friday_time', '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } else {
      await cancel(_fridayId);
      await prefs.remove('reminder_friday_enabled');
      await prefs.remove('reminder_friday_time');
    }
  }
}
