import 'package:home_widget/home_widget.dart';

import '../core/act_store.dart';

class StreakProgressWidgetService {
  StreakProgressWidgetService._();

  static final StreakProgressWidgetService instance = StreakProgressWidgetService._();

  static const _widgetName = 'MizanStreakProgress';
  static const _androidWidget = 'MizanStreakProgressWidget';
  static const _iosWidget = 'MizanStreakProgressWidget';

  Future<void> update(ActStore store) async {
    final streak = store.currentStreak ?? 0;
    final progress = store.progress;
    final totalStars = store.totalStars;
    final remaining = store.remainingActs;

    try {
      await HomeWidget.saveWidgetData<int>('streak_count', streak);
      await HomeWidget.saveWidgetData<int>('goal_progress_pct', (progress * 100).round());
      await HomeWidget.saveWidgetData<int>('total_stars', totalStars);
      await HomeWidget.saveWidgetData<int>('remaining_acts', remaining);
      await HomeWidget.saveWidgetData<String>('updated_at', DateTime.now().toIso8601String());

      await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: _iosWidget,
        androidName: _androidWidget,
      );
    } catch (_) {
      // Best-effort.
    }
  }
}
