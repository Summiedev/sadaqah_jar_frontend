import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../widgets/daily_verses.dart';

class LockScreenWidgetService {
  LockScreenWidgetService._();

  static final LockScreenWidgetService instance = LockScreenWidgetService._();

  static const _widgetName = 'MizanDailyReminder';
  static const _androidWidget = 'MizanLockScreenWidget';
  static const _iosWidget = 'MizanLockScreenWidget';

  Timer? _timer;

  Future<void> start() async {
    await updateWidget(force: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => updateWidget());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> updateWidget({bool force = false}) async {
    final now = DateTime.now();
    final rotation =
        await HomeWidget.getWidgetData<int>(
          'rhythm_rotation',
          defaultValue: 0,
        ) ??
        0;
    final verse = verseForTimeSlot(now, rotation: rotation);
    final contextLine = _contextLine(now);

    try {
      await HomeWidget.saveWidgetData<String>('daily_text', verse.text);
      await HomeWidget.saveWidgetData<String>('daily_source', verse.source);
      await HomeWidget.saveWidgetData<String>('daily_short', verse.shortText);
      await HomeWidget.saveWidgetData<String>('daily_context', contextLine);
      await HomeWidget.saveWidgetData<String>(
        'updated_at',
        now.toIso8601String(),
      );

      final shouldRefresh = await _shouldRefresh(now);
      if (force || shouldRefresh) {
        await HomeWidget.updateWidget(
          name: _widgetName,
          iOSName: _iosWidget,
          androidName: _androidWidget,
        );
        await markRefreshed(now);
      }
    } catch (_) {
      // Widget update is best-effort; failures should not crash the app.
    }
  }

  /// Rotates the reminder while keeping it in the current time-aware pool.
  /// This is called by the refresh action rendered inside the Android widget.
  Future<void> refreshFromWidget() async {
    final current =
        await HomeWidget.getWidgetData<int>(
          'rhythm_rotation',
          defaultValue: 0,
        ) ??
        0;
    await HomeWidget.saveWidgetData<int>(
      'rhythm_rotation',
      (current + 1) % kDailyVerses.length,
    );
    await updateWidget(force: true);
  }

  Future<bool> _shouldRefresh(DateTime now) async {
    final stored = await HomeWidget.getWidgetData<String>('last_refresh_date');
    if (stored == null) return true;
    final lastDate = DateTime.tryParse(stored);
    if (lastDate == null) return true;
    return !_isSameDay(lastDate, now) || _slot(lastDate) != _slot(now);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _slot(DateTime now) {
    if (now.hour < 11) return 0;
    if (now.hour < 16) return 1;
    if (now.hour < 21) return 2;
    return 3;
  }

  String _contextLine(DateTime now) {
    if (now.weekday == DateTime.friday && now.hour >= 9 && now.hour < 17) {
      return 'Friday light';
    }
    if (now.hour < 4) return 'Night light';
    if (now.hour < 11) return 'Morning light';
    if (now.hour < 16) return 'Midday light';
    if (now.hour < 21) return 'Evening light';
    return 'Night light';
  }

  Future<void> markRefreshed(DateTime now) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'last_refresh_date',
        now.toIso8601String(),
      );
    } catch (_) {
      // Ignore persistence errors for refresh tracking.
    }
  }

  Future<void> scheduleDailyRefresh() async {
    await updateWidget(force: true);
    await markRefreshed(DateTime.now());
  }

  Future<void> initialize() async {
    await start();
  }
}
