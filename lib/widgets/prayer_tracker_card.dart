import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/prayer_countdown_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/theme_extensions.dart';

class PrayerTrackerCard extends StatefulWidget {
  const PrayerTrackerCard({super.key});

  @override
  State<PrayerTrackerCard> createState() => _PrayerTrackerCardState();
}

class _PrayerTrackerCardState extends State<PrayerTrackerCard> {
  late DateTime _today;
  late String _storageKey;
  Set<String> _completed = {};
  List<PrayerTime> _times = kPrayerTimesFallback;

  static const _prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _storageKey =
        'prayer_completion_${_today.year}-${_today.month}-${_today.day}';
    _load();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final times = await PrayerCountdownService.instance.getTimingsForDate(
      DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _times = times);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _completed = list.toSet());
  }

  /// Determines if a prayer's time has arrived for today.
  ///
  /// A prayer is available to mark once the local time has reached the prayer
  /// time. This respects the Islamic daily cycle:
  /// - Fajr becomes available at dawn
  /// - Dhuhr at noon
  /// - Asr in the afternoon
  /// - Maghrib at sunset
  /// - Isha at night
  ///
  /// Fajr is special: it is available from the start of the Islamic day (which
  /// starts the previous evening at Maghrib), so Fajr is always available.
  bool _isAvailable(String prayerName, PrayerTime time, DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;
    final prayerMinutes = time.hour * 60 + time.minute;

    // Fajr is available from the start of the Islamic day (previous Maghrib,
    // which is effectively after Isha time the night before). Practically,
    // Fajr is always available if we're past Isha or it's before Fajr time
    // because the Islamic day started in the evening.
    if (prayerName == 'Fajr') {
      // Get Isha time to determine the start of the Islamic day.
      final isha = _times.firstWhere(
        (t) => t.name == 'Isha',
        orElse: () => kPrayerTimesFallback[4],
      );
      final ishaMinutes = isha.hour * 60 + isha.minute;
      // If we're before Fajr but after Isha (previous day's Isha passed),
      // Fajr is already available (Islamic day started at Maghrib).
      return nowMinutes >= prayerMinutes || nowMinutes >= ishaMinutes;
    }

    // Regular prayers: available once prayer time is reached.
    return nowMinutes >= prayerMinutes;
  }

  Future<void> _toggle(String name) async {
    // Only allow toggling if the prayer time has arrived.
    final time = _times.firstWhere(
      (t) => t.name == name,
      orElse: () => kPrayerTimesFallback[_prayerOrder.indexOf(name)],
    );
    if (!_isAvailable(name, time, DateTime.now())) {
      HapticFeedback.vibrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text('$name prayer time has not arrived yet.'),
          ),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final changed = Set<String>.from(_completed);
    if (changed.contains(name)) {
      changed.remove(name);
    } else {
      changed.add(name);
      HapticFeedback.lightImpact();
    }
    await prefs.setStringList(_storageKey, changed.toList());
    if (!mounted) return;
    setState(() => _completed = changed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final times = _times;
    final completedCount = _completed.length;
    final totalCount = times.length;

    // Auto-detect day rollover: if the date changed while the widget stayed
    // alive, reset the storage key and state.
    if (now.year != _today.year ||
        now.month != _today.month ||
        now.day != _today.day) {
      _today = DateTime(now.year, now.month, now.day);
      _storageKey =
          'prayer_completion_${_today.year}-${_today.month}-${_today.day}';
      _completed = <String>{};
      // Don't call setState during build; schedule it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
        _load();
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Today\'s Salah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FutureBuilder<int>(
                  future: PrayerCountdownService.instance
                      .minutesUntilNextPrayer(now),
                  builder: (c, s) {
                    final minutes = s.data ?? 0;
                    final countdown = PrayerCountdownService.instance
                        .formatCountdown(minutes);
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next in $countdown',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$completedCount/$totalCount',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children:
                times.map((p) {
                  final done = _completed.contains(p.name);
                  final available = _isAvailable(p.name, p, now);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PrayerPill(
                        name: p.name,
                        done: done,
                        available: available,
                        onTap: () => _toggle(p.name),
                        onLongPress: available ? () => _showOptions(p) : null,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _showOptions(PrayerTime p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${p.name} details'),
                subtitle: Text('Time: ${_formatTime(p)}'),
              ),
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Undo completion'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _undo(p.name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Add reflection'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(PrayerTime p) {
    final hour12 = p.hour % 12 == 0 ? 12 : p.hour % 12;
    final period = p.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _undo(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final changed = Set<String>.from(_completed);
    changed.remove(name);
    await prefs.setStringList(_storageKey, changed.toList());
    if (!mounted) return;
    setState(() => _completed = changed);
  }
}

class _PrayerPill extends StatelessWidget {
  const _PrayerPill({
    required this.name,
    required this.done,
    required this.available,
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final bool done;
  final bool available;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Semi-transparent when prayer time hasn't arrived yet.
    final opacity = available ? 1.0 : 0.45;

    return Semantics(
      button: true,
      enabled: available,
      label: available ? '$name prayer' : '$name prayer - not yet available',
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: available ? onTap : null,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
               color: done ? colors.primary : colors.surface,
               borderRadius: BorderRadius.circular(MizanRadii.control),
               border: Border.all(
                 color: done ? colors.primary : colors.borderSubtle,
               ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                   color: done ? colors.onPrimary : colors.primary,
                  size: 18,
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                     color: done ? colors.onPrimary : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
