import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_extensions.dart';
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
    final colors = context.colors;
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
                _WidgetChip('Salah', colors: colors),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.borderSubtle),
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
                          style: TextStyle(
                            color: colors.textPrimary,
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
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.explore_outlined,
                    color: colors.iconSecondary,
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.colors.scrim.withValues(alpha: 0.16),
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
    final colors = context.colors;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colors.accent, size: 18),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _WidgetChip extends StatelessWidget {
  const _WidgetChip(this.text, {required this.colors});

  final String text;
  final MizanColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
