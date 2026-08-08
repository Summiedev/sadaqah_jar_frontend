import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/act_store.dart';
import '../core/theme/app_theme.dart';

class StreakProgressRectangular extends ConsumerWidget {
  const StreakProgressRectangular({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final streak = store.currentStreak ?? 0;
    final progress = store.progress.clamp(0.0, 1.0).toDouble();
    final totalStars = store.totalStars;
    final remaining = store.remainingActs;

    return Semantics(
      label:
          streak > 0
              ? '$streak day streak'
              : '${(progress * 100).round()} percent goal progress',
      child: _WidgetPreviewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  streak > 0 ? '$streak' : '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Georgia',
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streak > 0 ? 'day streak' : 'monthly progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _WidgetChip('Week'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child:
                  streak > 0
                      ? _WeekDots(streak: streak)
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFF0D8B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$totalStars of ${totalStars + remaining} acts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF0D8B8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
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

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final days = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final completed = min(streak, days.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'This week',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$completed/${days.length}',
              style: const TextStyle(
                color: Color(0xFFF0D8B8),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: _WeekCell(
                  label: days[i],
                  done: i < completed,
                  isFirst: i == 0,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    required this.label,
    required this.done,
    required this.isFirst,
  });

  final String label;
  final bool done;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: isFirst ? 0 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
      decoration: BoxDecoration(
        color:
            done
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? Colors.white : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_rounded : Icons.remove_rounded,
            color: done ? const Color(0xFF0A3B34) : Colors.white54,
            size: 14,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: done ? const Color(0xFF0A3B34) : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreakProgressCircular extends ConsumerWidget {
  const StreakProgressCircular({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final streak = store.currentStreak ?? 0;
    final progress = store.progress;
    final totalStars = store.totalStars;

    return CustomPaint(
      size: const Size(120, 120),
      painter: _CircularPainter(
        streak: streak,
        progress: progress,
        totalStars: totalStars,
        onSurface: Theme.of(context).colorScheme.onSurface,
      ),
      child: Center(
        child: Text(
          streak > 0 ? '$streak' : '${(progress * 100).round()}%',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.87),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  _CircularPainter({
    required this.streak,
    required this.progress,
    required this.totalStars,
    required this.onSurface,
  });

  final int streak;
  final double progress;
  final int totalStars;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final strokeWidth = 6.0;

    final track =
        Paint()
          ..color = onSurface.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final arc =
        Paint()
          ..color = kBronze
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, track);

    final sweep =
        streak > 0
            ? min(streak / 30.0, 1.0)
            : progress.clamp(0.0, 1.0).toDouble();
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -pi / 2,
        2 * pi * sweep,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularPainter old) {
    return old.streak != streak ||
        old.progress != progress ||
        old.onSurface != onSurface;
  }
}

class StreakProgressInline extends ConsumerWidget {
  const StreakProgressInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final streak = store.currentStreak ?? 0;
    final label =
        streak > 0 ? '$streak day streak' : '${store.totalStars} this month';

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak > 0
                ? Icons.local_fire_department_rounded
                : Icons.track_changes_rounded,
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
