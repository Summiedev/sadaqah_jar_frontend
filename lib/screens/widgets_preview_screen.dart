import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/act_store.dart';
import '../core/theme/theme_extensions.dart';
import '../services/lock_screen_widget_service.dart';
import '../services/next_prayer_widget_service.dart';
import '../services/streak_progress_widget_service.dart';
import '../widgets/lock_screen_widget.dart';
import '../widgets/next_prayer_widget.dart';
import '../widgets/streak_progress_widget.dart';

class WidgetsPreviewScreen extends ConsumerStatefulWidget {
  const WidgetsPreviewScreen({super.key});

  @override
  ConsumerState<WidgetsPreviewScreen> createState() =>
      _WidgetsPreviewScreenState();
}

class _WidgetChoice {
  const _WidgetChoice({
    required this.name,
    required this.description,
    required this.widgetName,
    required this.providerName,
    required this.preview,
  });

  final String name;
  final String description;
  final String widgetName;
  final String providerName;
  final Widget Function() preview;
}

class _WidgetsPreviewScreenState extends ConsumerState<WidgetsPreviewScreen> {
  static final _choices = <_WidgetChoice>[
    _WidgetChoice(
      name: 'Daily reminder',
      description: 'A time-aware Quran verse or gentle reminder.',
      widgetName: 'MizanDailyReminder',
      providerName: 'MizanLockScreenWidget',
      preview: () => const LockScreenRectangular(),
    ),
    _WidgetChoice(
      name: 'Next Salah',
      description: 'See the next prayer and a quiet countdown.',
      widgetName: 'MizanNextPrayer',
      providerName: 'MizanNextPrayerWidget',
      preview: () => const NextPrayerRectangular(),
    ),
    _WidgetChoice(
      name: 'Progress',
      description: 'Your current streak or personal goal progress.',
      widgetName: 'MizanStreakProgress',
      providerName: 'MizanStreakProgressWidget',
      preview: () => const StreakProgressRectangular(),
    ),
  ];

  int _selected = 0;
  bool _adding = false;

  Future<void> _addToHomeScreen() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        _showMessage(
          'Mizan home-screen widgets are currently available on Android.',
        );
        return;
      }

      final choice = _choices[_selected];
      switch (_selected) {
        case 0:
          await LockScreenWidgetService.instance.updateWidget(force: true);
          break;
        case 1:
          await NextPrayerWidgetService.instance.update();
          break;
        case 2:
          await StreakProgressWidgetService.instance.update(
            ref.read(actStoreProvider),
          );
          break;
      }

      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) {
        _showMessage(
          'On your home screen, touch and hold an empty space, choose Widgets, then select Mizan and this widget.',
        );
        return;
      }

      await HomeWidget.requestPinWidget(
        name: choice.widgetName,
        androidName: 'com.summie.mizan.${choice.providerName}',
      );
    } catch (_) {
      _showMessage(
        'Could not open the widget add flow. Try from your home-screen widget picker.',
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final choice = _choices[_selected];
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Mizan widgets'),
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: 'Choose a widget'),
              items: [
                for (var index = 0; index < _choices.length; index++)
                  DropdownMenuItem(
                    value: index,
                    child: Text(_choices[index].name),
                  ),
              ],
              onChanged:
                  _adding
                      ? null
                      : (value) {
                        if (value != null) setState(() => _selected = value);
                      },
            ),
            const SizedBox(height: 8),
            Text(
              choice.description,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wifi_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const Spacer(),
                      Text(
                        TimeOfDay.now().format(context),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  choice.preview(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _adding ? null : _addToHomeScreen,
              icon:
                  _adding
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_to_home_screen_rounded),
              label: Text(_adding ? 'Opening launcher…' : 'Add to Home Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
