import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17120E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF231A14), Color(0xFF3B2D23), Color(0xFF1A1410)],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: _GlowDot(color: const Color(0xFFB88957).withValues(alpha: 0.38), size: 220),
            ),
            Positioned(
              top: 110,
              right: -80,
              child: _GlowDot(color: const Color(0xFF7E8F5A).withValues(alpha: 0.28), size: 200),
            ),
            Positioned(
              bottom: 120,
              left: -60,
              child: _GlowDot(color: const Color(0xFF8A6A52).withValues(alpha: 0.30), size: 180),
            ),
            Positioned(
              top: 40,
              left: 22,
              child: Opacity(
                opacity: 0.34,
                child: Image.asset('lib/assets/images/plants three.png', width: 86, height: 86),
              ),
            ),
            Positioned(
              top: 110,
              right: 10,
              child: Opacity(
                opacity: 0.28,
                child: Image.asset('lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 53(1).png', width: 104, height: 104),
              ),
            ),
            Positioned(
              left: -22,
              bottom: 160,
              child: Opacity(
                opacity: 0.26,
                child: Image.asset('lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 58.png', width: 120, height: 120),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 740;
                    return Column(
                      children: [
                        const Spacer(),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.94, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Transform.scale(scale: value, child: child),
                          child: Column(
                            children: [
                              Container(
                                width: compact ? 170 : 190,
                                height: compact ? 170 : 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFF0E4C9).withValues(alpha: 0.26),
                                      const Color(0xFFB98A5B).withValues(alpha: 0.06),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.58, 1.0],
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: compact ? 146 : 162,
                                      height: compact ? 146 : 162,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFE8D9B8).withValues(alpha: 0.18), width: 1.4),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x5A000000), blurRadius: 36, offset: Offset(0, 18)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: compact ? 112 : 122,
                                      height: compact ? 112 : 122,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E1712).withValues(alpha: 0.86),
                                        border: Border.all(color: const Color(0xFFD5B483).withValues(alpha: 0.32), width: 1.5),
                                      ),
                                      child: const Icon(Icons.volunteer_activism_outlined, size: 54, color: Color(0xFFF2E7C8)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: compact ? 20 : 28),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'Mizan',
                                  style: TextStyle(
                                    color: Color(0xFFF3EFD9),
                                    fontSize: 58,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'A calm space for sadaqah, streaks, and family jars.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFE5D5BF).withValues(alpha: 0.82),
                                  fontSize: compact ? 15 : 16,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF251C16).withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE5C99B).withValues(alpha: 0.18)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x44000000), blurRadius: 30, offset: Offset(0, 16)),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: const [
                                  _FeatureChip(icon: Icons.favorite_border, label: 'Good deeds'),
                                  _FeatureChip(icon: Icons.groups_outlined, label: 'Family jars'),
                                  _FeatureChip(icon: Icons.auto_graph_outlined, label: 'Daily streaks'),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: 180,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: const LinearProgressIndicator(
                                    minHeight: 6,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2B879)),
                                    backgroundColor: Color(0x33251C16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Loading your jar...',
                                style: TextStyle(
                                  color: const Color(0xFFE8D7B8).withValues(alpha: 0.82),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'From a smile to a star, every act counts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFC8B8A3).withValues(alpha: 0.88),
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.4, spreadRadius: size * 0.04)],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6C6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D0A3).withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFE9D4AA)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFF1E6CC), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}