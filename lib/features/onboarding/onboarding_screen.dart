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
                  Semantics(
                    label: 'Onboarding step ${_step + 1} of 3',
                    child: _ProgressDots(step: _step, colors: colors),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(132, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: Icon(
                      _step == 2
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(_step == 2 ? 'Start gently' : 'Continue'),
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
    title: 'Make room\nfor what matters.',
    body: 'A private place for the small acts you want to keep close.',
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
    title: 'Keep the rhythm\ngentle.',
    body:
        'Read a page. Make a prayer. Give what you can. Come back without guilt.',
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
        FadeScaleTransition(child: visual),
        const SizedBox(height: 28),
        SlideUpFade(
          child: Text(
            eyebrow,
            style: TextStyle(
              color: colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SlideUpFade(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'Georgia',
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SlideUpFade(
          child: Text(
            body,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: 226,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.18),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            left: -8,
            bottom: -2,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                colors.primary.withValues(alpha: 0.75),
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'lib/assets/images/plants one.png',
                width: 104,
                height: 104,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 24,
            child: Row(
              children: [
                Icon(
                  Icons.nights_stay_outlined,
                  color: colors.primary,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  'A place to return to',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Center(child: _OpenBookIllustration()),
          Positioned(
            left: 24,
            bottom: 18,
            child: Text(
              'One small act at a time',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpenBookIllustration extends StatelessWidget {
  const _OpenBookIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 190,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: -0.06,
              child: _BookPage(
                colors: colors,
                left: true,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: 0.06,
              child: _BookPage(
                colors: colors,
                left: false,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 92,
            color: colors.primary.withValues(alpha: 0.48),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.balance_rounded,
              color: colors.onPrimary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPage extends StatelessWidget {
  const _BookPage({required this.colors, required this.left});

  final MizanColors colors;
  final bool left;

  @override
  Widget build(BuildContext context) => Container(
    width: 88,
    height: 106,
    decoration: BoxDecoration(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(left ? 8 : 3),
        bottomLeft: Radius.circular(left ? 8 : 3),
        topRight: Radius.circular(left ? 3 : 8),
        bottomRight: Radius.circular(left ? 3 : 8),
      ),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(left ? 14 : 10, 26, left ? 10 : 14, 14),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              height: 2,
              width: double.infinity,
              color: colors.borderSubtle,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RhythmVisual extends StatelessWidget {
  const _RhythmVisual({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 226,
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
    decoration: BoxDecoration(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A GENTLE CHECK-IN',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _RhythmItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Read a page',
                  detail: 'A little time with the Quran',
                  colors: colors,
                ),
              ),
              _RhythmLine(colors: colors),
              Expanded(
                child: _RhythmItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Make space to reflect',
                  detail: 'Keep what you learn close',
                  colors: colors,
                ),
              ),
              _RhythmLine(colors: colors),
              Expanded(
                child: _RhythmItem(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Let a small act count',
                  detail: 'Give, even when it is simple',
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RhythmItem extends StatelessWidget {
  const _RhythmItem({
    required this.icon,
    required this.label,
    required this.detail,
    required this.colors,
  });
  final IconData icon;
  final String label;
  final String detail;
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.primary, size: 22),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RhythmLine extends StatelessWidget {
  const _RhythmLine({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 19),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 14,
        child: VerticalDivider(color: colors.border, thickness: 1.5, width: 1),
      ),
    ),
  );
}

class _SpacePage extends StatelessWidget {
  const _SpacePage({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });
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
        _SpaceVisual(colors: colors),
        const SizedBox(height: 24),
        Text(
          'Begin where\nyou are.',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'Georgia',
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Choose the space that fits today. You can change it anytime.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
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

class _SpaceVisual extends StatelessWidget {
  const _SpaceVisual({required this.colors});
  final MizanColors colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 112,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.borderSubtle),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.balance_rounded, color: colors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'A practice shaped around your life, not another thing to keep up with.',
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'Georgia',
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
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
              Icon(
                icon,
                color: active ? colors.primary : colors.iconSecondary,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
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
