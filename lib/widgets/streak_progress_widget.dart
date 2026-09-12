import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/act_store.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_extensions.dart';

class StreakProgressRectangular extends ConsumerWidget {
  const StreakProgressRectangular({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final colors = context.colors;
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
                  style: TextStyle(
                    color: colors.textPrimary,
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
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _WidgetChip('Week', colors: colors),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.borderSubtle),
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
                              backgroundColor: colors.border,
                              valueColor: AlwaysStoppedAnimation(colors.accent),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$totalStars of ${totalStars + remaining} acts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.accent,
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
    final colors = context.colors;
    final days = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final completed = min(streak, days.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'This week',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$completed/${days.length}',
              style: TextStyle(
                color: colors.accent,
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
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.only(left: isFirst ? 0 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
      decoration: BoxDecoration(
        color: done ? colors.accentSoft : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? colors.accent : colors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_rounded : Icons.remove_rounded,
            color: done ? colors.primary : colors.iconSecondary,
            size: 14,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: done ? colors.primary : colors.textSecondary,
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
    final colors = context.colors;
    final streak = store.currentStreak ?? 0;
    final progress = store.progress;
    final totalStars = store.totalStars;

    return CustomPaint(
      size: const Size(120, 120),
      painter: _CircularPainter(
        streak: streak,
        progress: progress,
        totalStars: totalStars,
        onSurface: colors.textPrimary,
        accent: colors.accent,
      ),
      child: Center(
        child: Text(
          streak > 0 ? '$streak' : '${(progress * 100).round()}%',
          style: TextStyle(
            color: colors.textPrimary,
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
    required this.accent,
  });

  final int streak;
  final double progress;
  final int totalStars;
  final Color onSurface;
  final Color accent;

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
          ..color = accent
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
        old.onSurface != onSurface ||
        old.accent != accent;
  }
}

class StreakProgressInline extends ConsumerWidget {
  const StreakProgressInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final colors = context.colors;
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
            color: colors.iconSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _inlineText(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
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
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.scrim.withValues(alpha: 0.16),
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
