import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'daily_verses.dart';

class LockScreenRectangular extends StatelessWidget {
  const LockScreenRectangular({super.key, this.verse});

  final DailyVerse? verse;

  @override
  Widget build(BuildContext context) {
    final v = verse ?? todaysVerse();
    final label =
        v.source.startsWith('Quran') ? 'QURAN LIGHT' : 'GENTLE REMINDER';
    return Semantics(
      label: 'Daily reminder: ${v.text}. ${v.source}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(17),
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFFF0D8B8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _SourceChip(v.source)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                v.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
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
  const _SourceChip(this.source);

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: kBronze.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kBronze.withValues(alpha: 0.32)),
      ),
      child: Text(
        source,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFF0D8B8),
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
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.87);
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Semantics(
      label: 'Daily reminder: ${v.shortText}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 14, color: kBronze),
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
