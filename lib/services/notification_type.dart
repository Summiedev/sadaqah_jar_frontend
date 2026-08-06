import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/theme/app_theme.dart';

enum NotificationType {
  sadaqahAct('sadaqah_act'),
  reflection('reflection'),
  familyActivity('family_activity'),
  goalProgress('goal_progress'),
  invitation('invitation'),
  prayerRequest('prayer_request'),
  streak('streak'),
  friday('friday'),
  adhkar('adhkar'),
  monthlyReview('monthly_review'),
  achievement('achievement'),
  readingProgress('reading_progress'),
  general('general');

  const NotificationType(this.name);
  final String name;
}

NotificationType notificationTypeFromName(String? name) {
  if (name == null) return NotificationType.general;
  return NotificationType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => NotificationType.general,
  );
}

NotificationType notificationTypeFromData(Map<String, dynamic> data) {
  return notificationTypeFromName(data['notification_type'] as String?);
}

String notificationTypeLabel(NotificationType type) {
  return switch (type) {
    NotificationType.sadaqahAct => 'Sadaqah',
    NotificationType.reflection => 'Reflection',
    NotificationType.familyActivity => 'Family',
    NotificationType.goalProgress => 'Goals',
    NotificationType.invitation => 'Invitation',
    NotificationType.prayerRequest => 'Prayer',
    NotificationType.streak => 'Streak',
    NotificationType.friday => 'Jumu\'ah',
    NotificationType.adhkar => 'Adhkar',
    NotificationType.monthlyReview => 'Review',
    NotificationType.achievement => 'Achievement',
    NotificationType.readingProgress => 'Reading',
    NotificationType.general => 'Mizan',
  };
}

class NotificationStyle {
  final Color accentColor;
  final String channelId;
  final String channelName;
  final String channelDescription;

  const NotificationStyle({
    required this.accentColor,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  });
}

const Map<NotificationType, NotificationStyle> kNotificationStyles = {
  NotificationType.sadaqahAct: NotificationStyle(
    accentColor: kBronze,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.reflection: NotificationStyle(
    accentColor: kSage,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.familyActivity: NotificationStyle(
    accentColor: kClay,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.goalProgress: NotificationStyle(
    accentColor: kBronzeLight,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.invitation: NotificationStyle(
    accentColor: kOlive,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.prayerRequest: NotificationStyle(
    accentColor: kSage,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.streak: NotificationStyle(
    accentColor: kBronzeDark,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.friday: NotificationStyle(
    accentColor: kSage,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.adhkar: NotificationStyle(
    accentColor: kBronze,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.monthlyReview: NotificationStyle(
    accentColor: kMuted,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.achievement: NotificationStyle(
    accentColor: kBronzeLight,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.readingProgress: NotificationStyle(
    accentColor: kSlate,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
  NotificationType.general: NotificationStyle(
    accentColor: kBronze,
    channelId: 'reminders',
    channelName: 'Reminders',
    channelDescription: 'Prayer and adhkar reminders',
  ),
};

NotificationStyle notificationStyle(NotificationType type) {
  return kNotificationStyles[type] ?? kNotificationStyles[NotificationType.general]!;
}

AndroidNotificationDetails androidNotificationDetails(NotificationType type) {
  final style = notificationStyle(type);
  return AndroidNotificationDetails(
    style.channelId,
    style.channelName,
    channelDescription: style.channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    color: style.accentColor,
    styleInformation: BigTextStyleInformation(
      '',
      contentTitle: '',
      summaryText: '',
    ),
  );
}

DarwinNotificationDetails darwinNotificationDetails(NotificationType type) {
  return DarwinNotificationDetails(
    subtitle: notificationTypeLabel(type),
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: type.name,
  );
}