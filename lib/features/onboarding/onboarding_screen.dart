import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _step = 0;

  final int _pages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _pages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic);
    } else {
      context.push('/mode');
    }
  }

  void _skip() {
    context.push('/mode');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'M I Z A N',
                    style: TextStyle(fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w700, fontFamily: 'serif', color: Color(0xFF4E3629)),
                  ),
                  Row(
                    children: List.generate(_pages, (index) {
                      final active = index == _step;
                      return GestureDetector(
                        onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 6),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF8B6842) : const Color(0xFFE8DCCF),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (value) => setState(() => _step = value),
                  children: [
                    _Page(
                      visual: const _WelcomeVisual(),
                      title: 'Every small act\ncarries weight.',
                      subtitle: 'Mizan is a quiet companion for your daily charity, remembrance, and reflection â€” made for sincerity, not streaks.',
                    ),
                    _Page(
                      visual: const _JarVisual(),
                      title: 'Small acts, slowly\nfilling the jar.',
                      subtitle: 'Like water gathering drop by drop, consistency leaves a lasting light. There is no rush, only return.',
                    ),
                    _Page(
                      visual: const _ModesVisual(),
                      title: 'Choose how you\nwish to begin.',
                      subtitle: 'Personal for your own path. Family to grow together. Or both â€” solitude and togetherness in one.',
                    ),
                    _Page(
                      visual: const _CommunityVisual(),
                      title: 'You are not\nalone.',
                      subtitle: 'Reflection, adhkar, prayer, family, and growth â€” walk gently, surrounded by what matters.',
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4E3629),
                        foregroundColor: const Color(0xFFFAF6F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      child: Text(_step == _pages - 1 ? 'Begin Your Journey' : 'Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _step < _pages - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Visibility(
                      visible: _step < _pages - 1,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0x994E3629),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        child: const Text('Skip introduction'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.visual, required this.title, required this.subtitle});

  final Widget visual;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          SizedBox(height: 240, child: Center(child: visual)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF2F241E), height: 1.28, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w400, color: Color(0xCC4E3629)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PAGE 1 â€” WELCOME
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WelcomeVisual extends StatefulWidget {
  const _WelcomeVisual();

  @override
  State<_WelcomeVisual> createState() => _WelcomeVisualState();
}

class _WelcomeVisualState extends State<_WelcomeVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _scale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  late final Animation<double> _rise = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _rise.value),
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF8B6842).withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFF6ECDF), Color(0xFFEBD9C6)]),
                  ),
                ),
                const Icon(Icons.balance_outlined, size: 64, color: Color(0xFF8B6842)),
                Positioned(
                  bottom: 30,
                  child: Container(
                    width: 26,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB38964),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(6)),
                      boxShadow: [BoxShadow(color: const Color(0xFF8B6842).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PAGE 2 â€” THE JAR (animated fill)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _JarVisual extends StatefulWidget {
  const _JarVisual();

  @override
  State<_JarVisual> createState() => _JarVisualState();
}

class _JarVisualState extends State<_JarVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final Animation<double> _fill = Tween<double>(begin: 0.05, end: 0.82).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, _) => CustomPaint(
        size: const Size(190, 220),
        painter: _JarPainter(fill: _fill.value),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter({required this.fill});
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(cx - w * 0.28, h * 0.16)
      ..quadraticBezierTo(cx - w * 0.40, h * 0.24, cx - w * 0.36, h * 0.5)
      ..lineTo(cx - w * 0.32, h * 0.84)
      ..quadraticBezierTo(cx - w * 0.28, h * 0.96, cx, h * 0.96)
      ..quadraticBezierTo(cx + w * 0.28, h * 0.96, cx + w * 0.32, h * 0.84)
      ..lineTo(cx + w * 0.36, h * 0.5)
      ..quadraticBezierTo(cx + w * 0.40, h * 0.24, cx + w * 0.28, h * 0.16)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE8D8C7));
    canvas.drawPath(body, Paint()..style = PaintingStyle.stroke..color = const Color(0xFFD6BEA8)..strokeWidth = 2);
    canvas.save();
    canvas.clipPath(body);
    final top = h * 0.2 + (h * 0.74) * (1 - fill);
    final light = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB38964), Color(0xFF8B6842)],
      ).createShader(Rect.fromLTWH(0, top, w, h - top));
    canvas.drawRect(Rect.fromLTWH(0, top, w, h), light);
    final rng = math.Random(3);
    final speck = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 16; i++) {
      final yy = top + rng.nextDouble() * (h - top);
      final xx = cx + (rng.nextDouble() - 0.5) * w * 0.5;
      canvas.drawCircle(Offset(xx, yy), (0.6 + rng.nextDouble() * 1.6), speck);
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.14), width: w * 0.5, height: h * 0.08), const Radius.circular(8)),
      Paint()..color = const Color(0xFFC9B09A),
    );
  }

  @override
  bool shouldRepaint(covariant _JarPainter old) => old.fill != fill;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PAGE 3 â€” MODES (introductory)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ModesVisual extends StatelessWidget {
  const _ModesVisual();

  static const List<(IconData, String, String)> _modes = [
    (Icons.person_outline_rounded, 'Personal', 'Your private journey of remembrance.'),
    (Icons.groups_outlined, 'Family', 'Grow in goodness, together.'),
    (Icons.auto_awesome_outlined, 'Both', 'Solitude and togetherness in one.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in _modes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6DBCF)),
                boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: const Color(0xFFF1E1CF), borderRadius: BorderRadius.circular(14)),
                    child: Icon(m.$1, size: 22, color: const Color(0xFF8B6842)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                        const SizedBox(height: 3),
                        Text(m.$3, style: const TextStyle(fontSize: 12, color: Color(0xFF9A8A7A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PAGE 4 â€” COMMUNITY
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CommunityVisual extends StatelessWidget {
  const _CommunityVisual();

  static const List<(IconData, String)> _items = [
    (Icons.menu_book_outlined, 'Reflection'),
    (Icons.favorite_border_outlined, 'Adhkar'),
    (Icons.volunteer_activism_outlined, 'Prayer'),
    (Icons.groups_outlined, 'Family'),
    (Icons.trending_up_outlined, 'Growth'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _items.map((it) {
        return Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6DBCF)),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(it.$1, size: 28, color: const Color(0xFF8B6842)),
              const SizedBox(height: 10),
              Text(it.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4E3629))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
