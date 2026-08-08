import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/prayer_countdown_service.dart';

class NextPrayerRectangular extends StatefulWidget {
  const NextPrayerRectangular({super.key});

  @override
  State<NextPrayerRectangular> createState() => _NextPrayerRectangularState();
}

class _NextPrayerRectangularState extends State<NextPrayerRectangular> {
  late final Timer _timer;
  int _minutes = 0;
  String _prayer = 'Prayer';

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

  Future<void> _update() async {
    final now = DateTime.now();
    final prayer = await PrayerCountdownService.instance.nextPrayer(now);
    final minutes = await PrayerCountdownService.instance
        .minutesUntilNextPrayer(now);
    if (!mounted) return;
    setState(() {
      _prayer = prayer?.name ?? 'Prayer';
      _minutes = minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final supportText =
        _minutes <= 5 ? 'Time to pause and pray' : 'Prepare with presence';
    final label = 'Next prayer: $_prayer. $supportText';
    return Semantics(
      label: label,
      child: _WidgetPreviewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _WidgetIcon(icon: Icons.notifications_none_rounded),
                const SizedBox(width: 10),
                const Expanded(child: _Eyebrow('PRAYER RHYTHM')),
                const _WidgetChip('Salah'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _prayer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Georgia',
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          supportText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF0D8B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.explore_outlined,
                    color: Colors.white70,
                    size: 28,
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
    return FutureBuilder<String>(
      future: _nextPrayerName(),
      builder: (context, snap) {
        final prayer = snap.data ?? 'Prayer';
        final label = 'Next: $prayer';
        return Semantics(
          label: label,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _inlineText(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _nextPrayerName() async {
    final prayer = await PrayerCountdownService.instance.nextPrayer(
      DateTime.now(),
    );
    return prayer?.name ?? 'Prayer';
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
    if (result.length < text.length) return '$result...';
    return result;
  }
}

class _WidgetPreviewCard extends StatelessWidget {
  const _WidgetPreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06433B), Color(0xFF0B302B), Color(0xFF201A16)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WidgetIcon extends StatelessWidget {
  const _WidgetIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFFF0D8B8), size: 18),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _WidgetChip extends StatelessWidget {
  const _WidgetChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kBronze.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kBronze.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFF0D8B8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
