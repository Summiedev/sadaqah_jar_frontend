import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/mode_provider.dart';
import '../../core/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  int _step = 0;
  int _mode = kModeBoth;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < 2) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await ref.read(modeProvider.notifier).setMode(_mode);
    await ref.read(sessionProvider).completeOnboarding();
    if (mounted) context.go('/auth');
  }

  Future<void> _skip() async {
    await ref.read(modeProvider.notifier).setMode(_mode);
    await ref.read(sessionProvider).completeOnboarding();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 8),
              child: Row(
                children: [
                  _BrandMark(colors: colors),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _step = value),
                children: [
                  _WelcomePage(colors: colors),
                  _RhythmPage(colors: colors),
                  _SpacePage(
                    colors: colors,
                    selected: _mode,
                    onSelect: (value) => setState(() => _mode = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Row(
                children: [
                  _ProgressDots(step: _step, colors: colors),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      _step == 2
                          ? Icons.arrow_forward_rounded
                          : Icons.north_east_rounded,
                      size: 18,
                    ),
                    label: Text(_step == 2 ? 'Begin' : 'Next'),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SvgPicture.asset('lib/assets/images/mizan_logo.svg'),
      ),
      const SizedBox(width: 9),
      Text(
        'MIZAN',
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.1,
        ),
      ),
    ],
  );
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step, required this.colors});
  final int step;
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: index == step ? 24 : 7,
        height: 7,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: index == step ? colors.primary : colors.border,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => _PageLayout(
    colors: colors,
    eyebrow: 'WELCOME TO MIZAN',
    title: 'A quieter space\nfor what matters.',
    body:
        'Keep your good intentions close, one small practice at a time.',
    visual: _WelcomeVisual(colors: colors),
  );
}

class _RhythmPage extends StatelessWidget {
  const _RhythmPage({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => _PageLayout(
    colors: colors,
    eyebrow: 'YOUR DAILY RHYTHM',
    title: 'Small steps\nbecome a practice.',
    body:
        'Reflect, read, pray, and give in a way that feels steady, private, and human.',
    visual: _RhythmVisual(colors: colors),
  );
}

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.colors,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
  });

  final MizanColors colors;
  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        visual,
        const SizedBox(height: 28),
        Text(
          eyebrow,
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          body,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _WelcomeVisual extends StatelessWidget {
  const _WelcomeVisual({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: colors.borderSubtle),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 24,
          top: 20,
          child: Icon(Icons.nights_stay_rounded, size: 82, color: colors.primary),
        ),
        Positioned(
          left: 24,
          bottom: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mizan',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_awesome, color: colors.primary, size: 18),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RhythmVisual extends StatelessWidget {
  const _RhythmVisual({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: colors.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'A GENTLE CHECK-IN',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _RhythmItem(icon: Icons.menu_book_rounded, label: 'Read', colors: colors),
            _RhythmLine(colors: colors),
            _RhythmItem(icon: Icons.edit_note_rounded, label: 'Reflect', colors: colors),
            _RhythmLine(colors: colors),
            _RhythmItem(icon: Icons.volunteer_activism_rounded, label: 'Give', colors: colors),
          ],
        ),
      ],
    ),
  );
}

class _RhythmItem extends StatelessWidget {
  const _RhythmItem({required this.icon, required this.label, required this.colors});
  final IconData icon;
  final String label;
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _RhythmLine extends StatelessWidget {
  const _RhythmLine({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    child: Divider(color: colors.border, thickness: 1.5),
  );
}

class _SpacePage extends StatelessWidget {
  const _SpacePage({required this.colors, required this.selected, required this.onSelect});
  final MizanColors colors;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAKE IT YOURS',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'How will you\nuse Mizan?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Choose a starting point. You can change this later.',
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
        _Choice(
          title: 'Just me',
          body: 'A private daily practice',
          icon: Icons.person_outline_rounded,
          value: kModePersonal,
          selected: selected,
          colors: colors,
          onSelect: onSelect,
        ),
        _Choice(
          title: 'With family',
          body: 'A shared space to grow together',
          icon: Icons.people_outline_rounded,
          value: kModeFamily,
          selected: selected,
          colors: colors,
          onSelect: onSelect,
        ),
        _Choice(
          title: 'Both',
          body: 'Keep a personal and family space',
          icon: Icons.layers_outlined,
          value: kModeBoth,
          selected: selected,
          colors: colors,
          onSelect: onSelect,
        ),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.body,
    required this.icon,
    required this.value,
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  final String title;
  final String body;
  final IconData icon;
  final int value;
  final int selected;
  final MizanColors colors;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: active ? colors.primaryContainer : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? colors.primary : colors.borderSubtle,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? colors.primary : colors.iconSecondary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(body, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Icon(
                active ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: active ? colors.primary : colors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
