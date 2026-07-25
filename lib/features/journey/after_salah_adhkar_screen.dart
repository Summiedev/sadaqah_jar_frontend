import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'after_salah_adhkar_data.dart';

class AfterSalahAdhkarList extends ConsumerStatefulWidget {
  const AfterSalahAdhkarList({super.key});

  @override
  ConsumerState<AfterSalahAdhkarList> createState() => _AfterSalahAdhkarListState();
}

class _AfterSalahAdhkarListState extends ConsumerState<AfterSalahAdhkarList> {
  final Map<int, int> _counts = {};
  bool _showTranslation = true;
  bool _showTransliteration = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              _ToggleChip(
                label: 'Translation',
                icon: Icons.translate_rounded,
                active: _showTranslation,
                onTap: () => setState(() => _showTranslation = !_showTranslation),
              ),
              const SizedBox(width: 10),
              _ToggleChip(
                label: 'Transliteration',
                icon: Icons.menu_book_rounded,
                active: _showTransliteration,
                onTap: () => setState(() => _showTransliteration = !_showTransliteration),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            physics: const BouncingScrollPhysics(),
            itemCount: AfterSalahAdhkarData.duas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final dua = AfterSalahAdhkarData.duas[index];
              final count = _counts[dua.id] ?? 0;
              final hasArabic = dua.arabic.isNotEmpty;
              final hasTranslation = _showTranslation && dua.translation.isNotEmpty;
              final hasTransliteration = _showTransliteration && dua.transliteration.isNotEmpty;

              return Material(
                color: const Color(0xFFFFFBF6),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dua.commonName != null && dua.commonName!.isNotEmpty) ...[
                        Text(
                          dua.commonName!,
                          style: const TextStyle(color: Color(0xFF8B6842), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (hasArabic)
                        Text(
                          dua.arabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Color(0xFF30241E), fontSize: 24, height: 1.7),
                        ),
                      if (hasTransliteration) ...[
                        const SizedBox(height: 10),
                        Text(dua.transliteration, style: const TextStyle(color: Color(0xFF92704B), fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 15, height: 1.5)),
                      ],
                      if (hasTranslation) ...[
                        const SizedBox(height: 6),
                        Text(dua.translation, style: const TextStyle(color: Color(0xFF756457), height: 1.55, fontSize: 14.5)),
                      ],
                      if (dua.notes != null && dua.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF8B6842)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(dua.notes!, style: const TextStyle(color: Color(0xFF8B6842), fontSize: 12.5, height: 1.45))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        dua.source,
                        style: const TextStyle(color: Color(0xFF8F7B6B), fontSize: 11, fontStyle: FontStyle.italic, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(99)),
                            child: Text(dua.repetition, style: const TextStyle(color: Color(0xFF8B6842), fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          if (count > 0)
                            _Counter(value: count, onTap: () => setState(() => _counts[dua.id] = count + 1))
                          else
                            IconButton(
                              onPressed: () => setState(() => _counts[dua.id] = 1),
                              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8B6842)),
                              tooltip: 'Start counting',
                            ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback is coming soon.')));
                            },
                            icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF8B6842)),
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
  const _ToggleChip({required this.label, required this.icon, required this.active, required this.onTap});
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
          color: active ? const Color(0xFF8B6842) : const Color(0xFFF0E3D4),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF8B6842)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF8B6842),
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
          color: value > 0 ? const Color(0xFFDCE7D8) : const Color(0xFFF0E3D4),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$value',
          style: const TextStyle(color: Color(0xFF8B6842), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
