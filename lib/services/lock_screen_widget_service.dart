import 'package:home_widget/home_widget.dart';

import '../widgets/daily_verses.dart';

class LockScreenWidgetService {
  LockScreenWidgetService._();

  static final LockScreenWidgetService instance = LockScreenWidgetService._();

  static const _widgetName = 'MizanDailyReminder';
  static const _androidWidget = 'MizanLockScreenWidget';
  static const _iosWidget = 'MizanLockScreenWidget';

  Future<void> updateWidget({bool force = false}) async {
    final verse = todaysVerse();
    final now = DateTime.now();

    try {
      await HomeWidget.saveWidgetData<String>('daily_text', verse.text);
      await HomeWidget.saveWidgetData<String>('daily_source', verse.source);
      await HomeWidget.saveWidgetData<String>('daily_short', verse.shortText);
      await HomeWidget.saveWidgetData<String>('updated_at', now.toIso8601String());

      final shouldRefresh = await _shouldRefresh(now);
      if (force || shouldRefresh) {
        await HomeWidget.updateWidget(
          name: _widgetName,
          iOSName: _iosWidget,
          androidName: _androidWidget,
        );
      }
    } catch (_) {
      // Widget update is best-effort; failures should not crash the app.
    }
  }

  Future<bool> _shouldRefresh(DateTime now) async {
    final stored = await HomeWidget.getWidgetData<String>('last_refresh_date');
    if (stored == null) return true;
    final lastDate = DateTime.tryParse(stored);
    if (lastDate == null) return true;
    return !_isSameDay(lastDate, now);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> markRefreshed(DateTime now) async {
    try {
      await HomeWidget.saveWidgetData<String>('last_refresh_date', now.toIso8601String());
    } catch (_) {
      // Ignore persistence errors for refresh tracking.
    }
  }

  Future<void> scheduleDailyRefresh() async {
    await updateWidget(force: true);
    await markRefreshed(DateTime.now());
  }

  Future<void> initialize() async {
    await updateWidget(force: true);
  }
}
