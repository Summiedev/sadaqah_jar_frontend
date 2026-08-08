import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../services/prayer_countdown_service.dart';

class NextPrayerWidgetService {
  NextPrayerWidgetService._();

  static final NextPrayerWidgetService instance = NextPrayerWidgetService._();

  static const _widgetName = 'MizanNextPrayer';
  static const _androidWidget = 'MizanNextPrayerWidget';
  static const _iosWidget = 'MizanNextPrayerWidget';

  Timer? _timer;

  Future<void> start() async {
    await update();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => update());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> update() async {
    final now = DateTime.now();
    final prayer = await PrayerCountdownService.instance.nextPrayer(now);
    final minutes = await PrayerCountdownService.instance
        .minutesUntilNextPrayer(now);
    final name = prayer?.name ?? 'Prayer';
    final prompt =
        minutes <= 5 ? 'Time to pause and pray' : 'Prepare with presence';
    final inline = minutes <= 0 ? 'Salah now' : 'Next: $name';

    try {
      await HomeWidget.saveWidgetData<String>('prayer_name', name);
      await HomeWidget.saveWidgetData<String>('prayer_countdown', prompt);
      await HomeWidget.saveWidgetData<String>('prayer_inline', inline);
      await HomeWidget.saveWidgetData<String>(
        'updated_at',
        now.toIso8601String(),
      );

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
