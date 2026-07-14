import 'dart:async';

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  const OnboardingScreen({super.key, required this.onGetStarted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Duration _autoSwipeInterval = Duration(seconds: 4);

  late final PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      eyebrow: 'Sadaqah, softly',
      titlePrefix: 'Make small ',
      titleAccent: 'acts feel alive',
      titleSuffix: '',
      body: 'Track one gentle good deed at a time and let your progress gather naturally, without pressure.',
      metric: 'One deed',
      metricLabel: 'starts the flow',
      chips: ['Smile', 'Help quietly', 'Give a little'],
      gradient: [Color(0xFF5C4B39), Color(0xFF916844), Color(0xFFD7BE92)],
      accent: Color(0xFFF4E6C8),
      orb: Color(0xFFE7B77B),
      icon: Icons.spa_outlined,
    ),
    _OnboardingPageData(
      eyebrow: 'Gentle momentum',
      titlePrefix: 'Build a ',
      titleAccent: 'calm streak',
      titleSuffix: '',
      body: 'Keep your rhythm with tiny check-ins, kind reminders, and a clearer sense of what you have already done.',
      metric: 'Daily',
      metricLabel: 'consistency grows quietly',
      chips: ['Check in', 'Repeat', 'Breathe'],
      gradient: [Color(0xFF4E5F4D), Color(0xFF728261), Color(0xFFD8D0A5)],
      accent: Color(0xFFF0F6E8),
      orb: Color(0xFFA8C68C),
      icon: Icons.timeline_outlined,
    ),
    _OnboardingPageData(
      eyebrow: 'Togetherness',
      titlePrefix: 'Grow ',
      titleAccent: 'with your people',
      titleSuffix: '',
      body: 'Invite family and friends into the same flow, celebrate the wins, and keep the jar feeling shared.',
      metric: 'Shared',
      metricLabel: 'progress feels warmer',
      chips: ['Invite', 'Celebrate', 'Support'],
      gradient: [Color(0xFF4B4C63), Color(0xFF72819D), Color(0xFFD7D6E7)],
      accent: Color(0xFFF5F6FF),
      orb: Color(0xFFA9B8E8),
      icon: Icons.groups_2_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSwipe();
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(_autoSwipeInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _pages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubicEmphasized,
      );
    });
  }

  void _goToNext() {
    if (_currentPage == _pages.length - 1) {
      widget.onGetStarted();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final scale = (width / 390).clamp(0.9, 1.08);
    double s(double value) => value * scale;

    final current = _pages[_currentPage];
    final heroHeight = (height * 0.58).clamp(400.0, 520.0);

    return Scaffold(
      backgroundColor: current.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: current.gradient,
            stops: const [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -s(90),
              left: -s(60),
              child: _GlowDot(color: current.orb.withValues(alpha: 0.22), size: s(220)),
            ),
            Positioned(
              top: s(90),
              right: -s(80),
              child: _GlowDot(color: current.accent.withValues(alpha: 0.12), size: s(250)),
            ),
            Positioned(
              bottom: -s(110),
              left: -s(40),
              child: _GlowDot(color: Colors.black.withValues(alpha: 0.10), size: s(200)),
            ),
            Positioned(
              top: s(42),
              right: -s(14),
              child: Opacity(
                opacity: 0.23,
                child: Image.asset(
                  'lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 53.png',
                  width: s(86),
                  height: s(86),
                ),
              ),
            ),
            Positioned(
              bottom: s(96),
              left: -s(18),
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 58.png',
                  width: s(112),
                  height: s(112),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + media.viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _BrandPill(scale: scale, color: current.accent),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onGetStarted,
                          style: TextButton.styleFrom(
                            foregroundColor: current.accent.withValues(alpha: 0.95),
                            padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(6)),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: s(15),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(16)),
                    SizedBox(
                      height: heroHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                          _startAutoSwipe();
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          final active = index == _currentPage;
                          return AnimatedScale(
                            scale: active ? 1.0 : 0.965,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: s(6)),
                              child: _OnboardingCard(page: page, scale: scale),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: s(24)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Column(
                        key: ValueKey<int>(_currentPage),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: current.titlePrefix,
                                  style: TextStyle(
                                    color: const Color(0xFFF8F3EA),
                                    fontSize: s(31),
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                TextSpan(
                                  text: current.titleAccent,
                                  style: TextStyle(
                                    color: current.accent,
                                    fontSize: s(31),
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                TextSpan(
                                  text: current.titleSuffix,
                                  style: TextStyle(
                                    color: const Color(0xFFF8F3EA),
                                    fontSize: s(31),
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: s(14)),
                          Text(
                            current.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: s(16.2),
                              height: 1.48,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(22)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = index == _currentPage;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                            );
                            _startAutoSwipe();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: s(5)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: isActive ? s(20) : s(7),
                              height: s(7),
                              decoration: BoxDecoration(
                                color: isActive ? current.accent : Colors.white.withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: current.accent.withValues(alpha: 0.32),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: s(22)),
                    SizedBox(
                      width: double.infinity,
                      height: s(56),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(s(18)),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF201A16).withValues(alpha: 0.92),
                              const Color(0xFF4A382B).withValues(alpha: 0.92),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(18)),
                            ),
                          ),
                          onPressed: _goToNext,
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Get started' : 'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: s(16.5),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: s(12)),
                    Text(
                      'By continuing you can settle into the flow at your own pace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: s(12.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.scale, required this.color});

  final double scale;
  final Color color;

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(10)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_outlined, size: s(16), color: color),
          SizedBox(width: s(8)),
          Text(
            'Mizan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: s(13.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.page, required this.scale});

  final _OnboardingPageData page;
  final double scale;

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(s(34)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -s(54),
              left: -s(32),
              child: _SoftOrb(color: page.orb.withValues(alpha: 0.28), size: s(180)),
            ),
            Positioned(
              top: s(18),
              right: -s(20),
              child: _SoftOrb(color: page.accent.withValues(alpha: 0.12), size: s(140)),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _FlowPainter(accent: page.accent),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(20), s(20), s(20), s(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(7)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Text(
                          page.eyebrow,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: s(11.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(page.icon, color: page.accent.withValues(alpha: 0.92), size: s(22)),
                    ],
                  ),
                  SizedBox(height: s(18)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: page.titlePrefix,
                                style: TextStyle(
                                  color: const Color(0xFFFBF7F0),
                                  fontSize: s(25),
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: page.titleAccent,
                                style: TextStyle(
                                  color: page.accent,
                                  fontSize: s(25),
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: page.titleSuffix,
                                style: TextStyle(
                                  color: const Color(0xFFFBF7F0),
                                  fontSize: s(25),
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: s(12)),
                        Text(
                          page.body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: s(14.6),
                            height: 1.48,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: s(18)),
                        Expanded(
                          child: Center(
                            child: _SceneIllustration(page: page, scale: scale),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(8)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(s(14)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(s(22)),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                page.metric,
                                style: TextStyle(
                                  color: page.accent,
                                  fontSize: s(18),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: s(2)),
                              Text(
                                page.metricLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.74),
                                  fontSize: s(12.5),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ...page.chips.map(
                            (chip) => Padding(
                              padding: EdgeInsets.only(bottom: s(8)),
                              child: _FlowChip(label: chip, scale: scale, color: page.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _SceneIllustration extends StatelessWidget {
  const _SceneIllustration({required this.page, required this.scale});

  final _OnboardingPageData page;
  final double scale;

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1.48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: s(2),
              top: s(20),
              child: _FloatingNode(
                label: page.chips[0],
                color: page.accent.withValues(alpha: 0.94),
                scale: scale,
              ),
            ),
            Positioned(
              right: s(4),
              top: s(12),
              child: _FloatingNode(
                label: page.chips[1],
                color: Colors.white.withValues(alpha: 0.88),
                scale: scale,
              ),
            ),
            Positioned(
              left: s(26),
              bottom: s(10),
              child: _FloatingNode(
                label: page.chips[2],
                color: page.accent.withValues(alpha: 0.96),
                scale: scale,
              ),
            ),
            Container(
              width: s(190),
              height: s(190),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    page.accent.withValues(alpha: 0.34),
                    page.orb.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: s(154),
              height: s(154),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.2),
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: s(116),
              height: s(116),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    page.accent.withValues(alpha: 0.18),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.accent.withValues(alpha: 0.24),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(page.icon, color: Colors.white, size: s(40)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNode extends StatelessWidget {
  const _FloatingNode({required this.label, required this.color, required this.scale});

  final String label;
  final Color color;
  final double scale;

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: s(11.5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.label, required this.scale, required this.color});

  final String label;
  final double scale;
  final Color color;

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(7)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: s(11.2),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2
      ..color = accent.withValues(alpha: 0.10);

    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.78)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.66,
        size.width * 0.32,
        size.height * 0.54,
        size.width * 0.44,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.56,
        size.width * 0.64,
        size.height * 0.72,
        size.width * 0.80,
        size.height * 0.64,
      );
    canvas.drawPath(path, paint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.20),
      size.shortestSide * 0.14,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowPainter oldDelegate) => oldDelegate.accent != accent;
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.36, spreadRadius: size * 0.04),
        ],
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.38, spreadRadius: size * 0.04),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.titlePrefix,
    required this.titleAccent,
    required this.titleSuffix,
    required this.body,
    required this.metric,
    required this.metricLabel,
    required this.chips,
    required this.gradient,
    required this.accent,
    required this.orb,
    required this.icon,
  });

  final String eyebrow;
  final String titlePrefix;
  final String titleAccent;
  final String titleSuffix;
  final String body;
  final String metric;
  final String metricLabel;
  final List<String> chips;
  final List<Color> gradient;
  final Color accent;
  final Color orb;
  final IconData icon;

  Color get background => gradient.last;
}
