import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/animations.dart';
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
    visual: const _OnboardingIllustration(
      asset: 'lib/assets/images/onboarding_prayer_scene.png',
      semanticLabel: 'A quiet prayer space at dawn',
    ),
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
    visual: const _OnboardingIllustration(
      asset: 'lib/assets/images/onboarding_quran_scene.png',
      semanticLabel: 'A person reading the Quran at home',
    ),
  );
}

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.colors,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
    this.supportingContent,
  });

  final MizanColors colors;
  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;
  final Widget? supportingContent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 600;
      final hasChoices = supportingContent != null;
      final artworkHeight =
          (constraints.maxHeight * (hasChoices ? 0.34 : 0.46))
              .clamp(hasChoices ? 168.0 : 218.0, hasChoices ? 224.0 : 312.0)
              .toDouble();
      final horizontalPadding = compact ? 20.0 : 26.0;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                (constraints.maxHeight - 18)
                    .clamp(0, double.infinity)
                    .toDouble(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: artworkHeight,
                child: ColoredBox(
                  color: colors.surfaceContainerHigh,
                  child: FadeScaleTransition(
                    key: ValueKey(eyebrow),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8,
                      ),
                      child: visual,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: compact ? 14 : 22),
                    SlideUpFade(
                      child: Text(
                        eyebrow,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SlideUpFade(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontFamily: 'Georgia',
                          fontSize: compact ? 30 : 34,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: SlideUpFade(
                        child: Text(
                          body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                    if (supportingContent != null) ...[
                      SizedBox(height: compact ? 14 : 20),
                      supportingContent!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.asset,
    required this.semanticLabel,
  });

  final String asset;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Image.asset(
      asset,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
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
  Widget build(BuildContext context) => _PageLayout(
    colors: colors,
    eyebrow: 'MAKE IT YOURS',
    title: 'Begin where\nyou are.',
    body: 'Choose the space that fits today. You can change it anytime.',
    visual: const _OnboardingIllustration(
      asset: 'lib/assets/images/onboarding_family_scene.png',
      semanticLabel: 'A family sharing a quiet moment at home',
    ),
    supportingContent: Column(
      children: [
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
