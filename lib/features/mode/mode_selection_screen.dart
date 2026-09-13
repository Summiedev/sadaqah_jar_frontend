import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/mizan_surface.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() =>
      _ModeSelectionScreenState();
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
    final colors = context.colors;
    final modes = [kModePersonal, kModeFamily, kModeBoth];
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: MizanSpacing.screen,
          child: Column(
            children: [
              _Header(selected: _selected),
              const SizedBox(height: MizanSpacing.xxl),
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
              const SizedBox(height: MizanSpacing.lg),
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
    final colors = context.colors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'M I Z A N',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'How would you like\nto begin?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose what fits today. You can change it later.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final ModeMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (meta.id) {
      kModeFamily => colors.secondary,
      kModeBoth => colors.info,
      _ => colors.primary,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: MizanSurface(
        padding: const EdgeInsets.all(MizanSpacing.lg),
        color: selected ? accent.withValues(alpha: 0.08) : null,
        borderColor: selected ? accent : colors.borderSubtle,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(MizanRadii.control),
              ),
              child: Icon(meta.icon, size: 28, color: accent),
            ),
            const SizedBox(width: MizanSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MizanSpacing.xs),
                  Text(
                    meta.tagline,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MizanSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(color: accent, width: 1.6),
              ),
              child:
                  selected
                      ? Icon(Icons.check, size: 15, color: colors.onPrimary)
                      : null,
            ),
          ],
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
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        child: const Text('Enter Mizan'),
      ),
    );
  }
}
