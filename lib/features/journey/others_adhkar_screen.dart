import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import 'others_adhkar_data.dart';

class OthersAdhkarList extends ConsumerStatefulWidget {
  const OthersAdhkarList({super.key});

  @override
  ConsumerState<OthersAdhkarList> createState() => _OthersAdhkarListState();
}

class _OthersAdhkarListState extends ConsumerState<OthersAdhkarList> {
  final Map<int, int> _counts = {};
  bool _showTranslation = true;
  bool _showTransliteration = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToggleChip(
                  label: 'Translation',
                  icon: Icons.translate_rounded,
                  active: _showTranslation,
                  onTap:
                      () =>
                          setState(() => _showTranslation = !_showTranslation),
                ),
                const SizedBox(width: 10),
                _ToggleChip(
                  label: 'Transliteration',
                  icon: Icons.menu_book_rounded,
                  active: _showTransliteration,
                  onTap:
                      () => setState(
                        () => _showTransliteration = !_showTransliteration,
                      ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            physics: const BouncingScrollPhysics(),
            itemCount: OtherAdhkarData.duas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final dua = OtherAdhkarData.duas[index];
              final count = _counts[dua.id] ?? 0;
              final tokens = context.colors;

              return Material(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dua.commonName != null &&
                          dua.commonName!.isNotEmpty) ...[
                        Text(
                          dua.commonName!,
                          style: const TextStyle(
                            color: kBronze,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          dua.arabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 24,
                            height: 1.7,
                          ),
                        ),
                      ),
                      if (_showTransliteration) ...[
                        const SizedBox(height: 10),
                        Text(
                          dua.transliteration,
                          style: const TextStyle(
                            color: kBronzeLight,
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (_showTranslation) ...[
                        const SizedBox(height: 6),
                        Text(
                          dua.translation,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            height: 1.55,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                      if (dua.notes != null && dua.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: kBronze,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dua.notes!,
                                style: const TextStyle(
                                  color: kBronze,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        dua.source,
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  (MediaQuery.sizeOf(context).width - 120)
                                      .clamp(120.0, 420.0)
                                      .toDouble(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.primaryContainer,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                dua.repetition,
                                softWrap: true,
                                style: const TextStyle(
                                  color: kBronze,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (count > 0)
                            _Counter(
                              value: count,
                              onTap:
                                  () => setState(
                                    () => _counts[dua.id] = count + 1,
                                  ),
                            )
                          else
                            IconButton(
                              onPressed:
                                  () => setState(() => _counts[dua.id] = 1),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: kBronze,
                              ),
                              tooltip: 'Start counting',
                            ),
                          IconButton(
                            onPressed:
                                () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Audio playback is coming soon.',
                                        ),
                                      ),
                                    ),
                            icon: const Icon(
                              Icons.volume_up_outlined,
                              color: kBronze,
                            ),
                            tooltip: 'Play audio',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kBronze : kIvory,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Theme.of(context).colorScheme.onPrimary : kBronze,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? Theme.of(context).colorScheme.onPrimary : kBronze,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.onTap});
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value > 0 ? kSoftSage : kIvory,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$value',
          style: const TextStyle(color: kBronze, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
