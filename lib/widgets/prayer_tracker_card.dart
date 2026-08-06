import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/prayer_countdown_service.dart';
import '../core/theme/app_theme.dart';

class PrayerTrackerCard extends StatefulWidget {
  const PrayerTrackerCard({super.key});

  @override
  State<PrayerTrackerCard> createState() => _PrayerTrackerCardState();
}

class _PrayerTrackerCardState extends State<PrayerTrackerCard> {
  late DateTime _today;
  late String _storageKey;
  Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _storageKey = 'prayer_completion_${_today.year}-${_today.month}-${_today.day}';
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? <String>[];
    setState(() => _completed = list.toSet());
  }

  Future<void> _toggle(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final changed = Set<String>.from(_completed);
    if (changed.contains(name)) {
      changed.remove(name);
    } else {
      changed.add(name);
      HapticFeedback.lightImpact();
    }
    await prefs.setStringList(_storageKey, changed.toList());
    setState(() => _completed = changed);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrayerTime>>(
      future: PrayerCountdownService.instance.getTimingsForDate(DateTime.now()),
      builder: (context, snap) {
        final times = snap.data ?? kPrayerTimesFallback;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLine),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Today\'s Salah', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, fontSize: 16)),
              Row(children: [
                FutureBuilder<int>(
                  future: PrayerCountdownService.instance.minutesUntilNextPrayer(DateTime.now()),
                  builder: (c, s) {
                    final minutes = s.data ?? 0;
                    final countdown = PrayerCountdownService.instance.formatCountdown(minutes);
                    final next = (snap.data ?? times).firstWhere((_) => true, orElse: () => times.first);
                    return Row(children: [if (next != null) Text('${next.name} • $countdown', style: TextStyle(color: kMuted, fontSize: 13)), const SizedBox(width: 8), Text('${_completed.length}/${times.length}', style: TextStyle(color: kBronze, fontWeight: FontWeight.w700))]);
                  },
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: times.map((p) {
              final done = _completed.contains(p.name);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _toggle(p.name),
                    onLongPress: () => _showOptions(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: done ? kBronze : kClayPale,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: done ? kBronzeDark : kLine),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? kWhite : kBronze, size: 18),
                        const SizedBox(height: 6),
                        Text(p.name, style: TextStyle(color: done ? kWhite : kInk, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList()),
          ]),
        );
      },
    );
  }

  void _showOptions(PrayerTime p) {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text('${p.name} details'), subtitle: Text('Time: ${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}')),
        ListTile(leading: const Icon(Icons.edit), title: const Text('Edit completion time'), onTap: () => Navigator.of(ctx).pop()),
        ListTile(leading: const Icon(Icons.undo), title: const Text('Undo completion'), onTap: () async { Navigator.of(ctx).pop(); await _undo(p.name); }),
        ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Add reflection'), onTap: () => Navigator.of(ctx).pop()),
      ]));
    });
  }

  Future<void> _undo(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final changed = Set<String>.from(_completed);
    changed.remove(name);
    await prefs.setStringList(_storageKey, changed.toList());
    setState(() => _completed = changed);
  }
}
