import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_extensions.dart';
import 'daily_verses.dart';

class LockScreenRectangular extends StatelessWidget {
  const LockScreenRectangular({super.key, this.verse});

  final DailyVerse? verse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final v = verse ?? todaysVerse();
    final label =
        v.source.startsWith('Quran') ? 'QURAN LIGHT' : 'GENTLE REMINDER';
    return Semantics(
      label: 'Daily reminder: ${v.text}. ${v.source}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(17),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: colors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _SourceChip(v.source, colors: colors)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Text(
                v.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip(this.source, {required this.colors});

  final String source;
  final MizanColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        source,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.accent,
          fontSize: 10.5,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w800,
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
    final colors = context.colors;
    final textColor = colors.textPrimary;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Semantics(
      label: 'Daily reminder: ${v.shortText}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 14, color: colors.accent),
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
