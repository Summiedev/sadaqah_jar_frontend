import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../home/add_act_screen.dart';
import '../../services/backend_api.dart';

enum ReflectionActionKind { give, read, dua, forgive }

class ReflectionActionSuggestion {
  const ReflectionActionSuggestion({
    required this.kind,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.icon,
  });

  final ReflectionActionKind kind;
  final String title;
  final String body;
  final String actionLabel;
  final IconData icon;
}

ReflectionActionSuggestion suggestionForReflection(JourneyReflection reflection) {
  final text = '${reflection.title} ${reflection.body} ${reflection.mood}'.toLowerCase();
  if (text.contains(RegExp(r'give|charity|sadaqah|generous|help'))) {
    return const ReflectionActionSuggestion(
      kind: ReflectionActionKind.give,
      title: 'A small giving step',
      body: 'Could this thought become one quiet act of generosity today?',
      actionLabel: 'Choose an act',
      icon: Icons.volunteer_activism_outlined,
    );
  }
  if (text.contains(RegExp(r'quran|ayah|read|recite|verse'))) {
    return const ReflectionActionSuggestion(
      kind: ReflectionActionKind.read,
      title: 'Stay with the meaning',
      body: 'A few more verses may help this reflection settle gently.',
      actionLabel: 'Open Qur\'an',
      icon: Icons.menu_book_outlined,
    );
  }
  if (text.contains(RegExp(r'forgive|anger|hurt|resent|let go'))) {
    return const ReflectionActionSuggestion(
      kind: ReflectionActionKind.forgive,
      title: 'Make room for release',
      body: 'Consider one gentle step toward forgiveness, at your own pace.',
      actionLabel: 'Carry this intention',
      icon: Icons.spa_outlined,
    );
  }
  return const ReflectionActionSuggestion(
    kind: ReflectionActionKind.dua,
    title: 'Turn it into a dua',
    body: 'You can hold this thought in a quiet prayer before moving on.',
    actionLabel: 'Open adhkar',
    icon: Icons.auto_awesome_outlined,
  );
}

Future<void> showReflectionActionSuggestion(
  BuildContext context,
  JourneyReflection reflection,
) async {
  final suggestion = suggestionForReflection(reflection);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surfaceElevated,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(suggestion.icon, color: sheetContext.colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    color: sheetContext.colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            suggestion.body,
            style: TextStyle(color: sheetContext.colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                switch (suggestion.kind) {
                  case ReflectionActionKind.give:
                    if (context.mounted) await AddActScreen.show(context);
                    break;
                  case ReflectionActionKind.read:
                    if (context.mounted) context.push('/journey?tab=quran');
                    break;
                  case ReflectionActionKind.dua:
                    if (context.mounted) context.push('/journey/adhkar/morning');
                    break;
                  case ReflectionActionKind.forgive:
                    break;
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(suggestion.actionLabel),
            ),
          ),
        ],
      ),
    ),
  );
}
