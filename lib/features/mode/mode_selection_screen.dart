import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(modeProvider);
  }

  void _continue() {
    ref.read(modeProvider.notifier).setMode(_selected);
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final modes = [kModePersonal, kModeFamily, kModeBoth];
    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              _Header(selected: _selected),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: modes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final mode = modes[i];
                    return _ModeCard(
                      meta: kModeMeta[mode]!,
                      selected: _selected == mode,
                      onTap: () => setState(() => _selected = mode),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _EnterButton(onTap: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'M I Z A N',
              style: TextStyle(fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w700, fontFamily: 'serif', color: kInk),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'How would you like\nto begin?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk, height: 1.25, letterSpacing: -0.4),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose what fits today. You can change it later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.55, color: Color(0xCC4E3629)),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.meta, required this.selected, required this.onTap});

  final ModeMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = meta.accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? accent : kClayLight, width: selected ? 1.8 : 1),
        boxShadow: [
          BoxShadow(
            color: selected ? accent.withValues(alpha: 0.16) : const Color(0x11000000),
            blurRadius: selected ? 22 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(meta.icon, size: 28, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                      const SizedBox(height: 4),
                      Text(meta.tagline, style: const TextStyle(fontSize: 12.5, height: 1.45, color: kMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(color: accent, width: 1.6),
                  ),
                  child: selected ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: kInk,
          foregroundColor: kPaper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        child: const Text('Enter Mizan'),
      ),
    );
  }
}
