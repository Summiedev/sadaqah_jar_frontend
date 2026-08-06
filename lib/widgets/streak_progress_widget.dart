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
    final progress = store.progress;
    final totalStars = store.totalStars;
    final remaining = store.remainingActs;

    if (streak > 0) {
      return _ModeA(streak: streak, totalStars: totalStars, remaining: remaining);
    }
    return _ModeB(progress: progress, goalTitle: store.goalTitle, totalStars: totalStars, remaining: remaining);
  }
}

class _ModeA extends StatelessWidget {
  const _ModeA({required this.streak, required this.totalStars, required this.remaining});

  final int streak;
  final int totalStars;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final dots = _buildDots(context, streak);
    return Container(
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
            child: Icon(Icons.local_fire_department_rounded, color: kBronze, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('$streak', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Georgia')),
                    const SizedBox(width: 4),
                    Text('day streak', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: dots),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDots(BuildContext context, int streak) {
    final maxDots = 7;
    final active = streak > maxDots ? maxDots : streak;
    final dots = <Widget>[];
    for (var i = 0; i < maxDots; i++) {
      final isActive = i < active;
      dots.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isActive ? kBronze : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }
    if (streak > maxDots) {
      dots.add(
        Text('+${streak - maxDots}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    return dots;
  }
}

class _ModeB extends StatelessWidget {
  const _ModeB({required this.progress, required this.goalTitle, required this.totalStars, required this.remaining});

  final double progress;
  final String? goalTitle;
  final int totalStars;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(Icons.track_changes_rounded, color: kBronze, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalStars of ${totalStars + remaining}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(kBronze),
                  ),
                ),
              ],
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87), fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
        ),
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  _CircularPainter({required this.streak, required this.progress, required this.totalStars, required this.onSurface});

  final int streak;
  final double progress;
  final int totalStars;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final strokeWidth = 6.0;

    final track = Paint()
      ..color = onSurface.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arc = Paint()
      ..color = onSurface.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, track);

    final sweep = streak > 0 ? min(streak / 30.0, 1.0) : progress.clamp(0.0, 1.0);
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
    return old.streak != streak || old.progress != progress || old.onSurface != onSurface;
  }
}

class StreakProgressInline extends ConsumerWidget {
  const StreakProgressInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(actStoreProvider);
    final streak = store.currentStreak ?? 0;

    final label = streak > 0 ? '$streak day streak' : '${store.totalStars} this month';

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(streak > 0 ? Icons.local_fire_department_rounded : Icons.track_changes_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
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

