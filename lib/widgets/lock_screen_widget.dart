import 'package:flutter/material.dart';

import 'daily_verses.dart';

class LockScreenRectangular extends StatelessWidget {
  const LockScreenRectangular({super.key, this.verse});

  final DailyVerse? verse;

  @override
  Widget build(BuildContext context) {
    final v = verse ?? todaysVerse();
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87);
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.88;

    return Semantics(
      label: 'Daily reminder: ${v.text}. ${v.source}',
      child: Container(
        width: maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 16, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              v.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LockScreenInline extends StatelessWidget {
  const LockScreenInline({super.key, this.verse});

  final DailyVerse? verse;

  @override
  Widget build(BuildContext context) {
    final v = verse ?? todaysVerse();
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87);
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Semantics(
      label: 'Daily reminder: ${v.shortText}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 14, color: textColor),
          const SizedBox(width: 6),
          SizedBox(
            width: maxWidth,
            child: Text(
              _inlineText(v.shortText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
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
    if (result.length < text.length) return '$result\u2026';
    return result;
  }
}
