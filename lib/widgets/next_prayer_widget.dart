import 'dart:async';

import 'package:flutter/material.dart';

import '../services/prayer_countdown_service.dart';
import '../core/theme/app_theme.dart';

class NextPrayerRectangular extends StatefulWidget {
  const NextPrayerRectangular({super.key});

  @override
  State<NextPrayerRectangular> createState() => _NextPrayerRectangularState();
}

class _NextPrayerRectangularState extends State<NextPrayerRectangular> {
  late final Timer _timer;
  int _minutes = 0;
  String _prayer = '';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _update() async {
    final now = DateTime.now();
    final prayer = await PrayerCountdownService.instance.nextPrayer(now);
    final minutes = await PrayerCountdownService.instance.minutesUntilNextPrayer(now);
    if (mounted) {
      setState(() {
        _prayer = prayer?.name ?? '';
        _minutes = minutes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$_prayer in $_minutes minutes',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light ? kClay : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kBronze.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.mosque_outlined, color: kBronze, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _prayer,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'in $_minutes min',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NextPrayerInline extends StatelessWidget {
  const NextPrayerInline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: PrayerCountdownService.instance.minutesUntilNextPrayer(DateTime.now()),
      builder: (context, snap) {
        final minutes = snap.data ?? 0;
        final label = 'in $minutes min';
        return Semantics(
          label: label,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mosque_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                _inlineText(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Georgia'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _inlineText(String text) {
    if (text.length <= 30) return text;
    final words = text.split(' ');
    final buffer = StringBuffer();
    for (final word in words) {
      if ((buffer.length + word.length + 1) > 30) break;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    final result = buffer.toString().trim();
    if (result.length < text.length) return '$result…';
    return result;
  }
}
