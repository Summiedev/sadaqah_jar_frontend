import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Main entrance - plays once, then explicitly stops so its ticker goes
  // fully idle instead of lingering at value == 1.0.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Ambient loop - shimmer + pulse. Cheap, isolated, runs forever.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onEntranceStatus);
    _controller.forward();
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Entrance is done - stop the controller so it fully idles (no ticker
      // registered, no per-frame callbacks) rather than just sitting at 1.0.
      _controller.stop();
      _controller.removeStatusListener(_onEntranceStatus);
    }
  }

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
  );
  late final Animation<double> _rise = Tween<double>(begin: 24, end: 0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.05, 0.7, curve: Curves.easeOutCubic)),
  );

  // Diamond ring draw-in (0 -> full sweep).
  late final Animation<double> _ringSweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
  );

  // Center dot pop.
  late final Animation<double> _dotPop = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.8, curve: Curves.elasticOut),
  );

  // Top accent line grows from center.
  late final Animation<double> _lineGrow = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
  );

  // Arabic subtitle + tagline, arriving last.
  late final Animation<double> _subtitleFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.7, 0.95, curve: Curves.easeOut),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
  );

  static const _letters = ['M', 'I', 'Z', 'A', 'N'];

  @override
  void dispose() {
    _controller.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = kBronzeLight;
    final foreground = kClayLight;
    return Scaffold(
      // The splash is a branded loading surface, not an app page. Preserve
      // the original dark-brown background in both light and dark mode.
      backgroundColor: kScaffoldDark,
      body: Stack(
        children: [
          // Elegant top accent line - grows from the center outward.
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 70),
              child: AnimatedBuilder(
                animation: _lineGrow,
                builder: (context, _) => SizedBox(
                  width: 48,
                  height: 1.2,
                  child: Center(
                    child: FractionallySizedBox(
                            widthFactor: Curves.easeOut.transform(_lineGrow.value),
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: foreground.withValues(alpha: 0.15)),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Main brand contents
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final floatOffset = math.sin(_controller.value * math.pi) * 2;
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _rise.value + floatOffset),
                    child: Transform.scale(scale: _scale.value, child: child),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo box - rings draw themselves in, dot pops, ambient glow loops.
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(44),
                            border: Border.all(color: foreground.withValues(alpha: 0.07), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(44),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.9,
                                      colors: [kSurfaceDark, kScaffoldDark],
                                    ),
                                  ),
                                ),
                                // Ambient rotating sheen behind the diamond - isolated repaint.
                                RepaintBoundary(
                                  child: AnimatedBuilder(
                                    animation: _ambient,
                                    builder: (context, _) => Transform.rotate(
                                      angle: _ambient.value * 2 * math.pi,
                                      child: Container(
                                              decoration: BoxDecoration(
                                                gradient: SweepGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    accent.withValues(alpha: 0.08),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Diamond rings - drawn in with a sweep, not just faded.
                        AnimatedBuilder(
                          animation: _ringSweep,
                          builder: (context, _) => CustomPaint(
                            size: const Size(96, 96),
                            painter: _DiamondRingsPainter(progress: _ringSweep.value, color: foreground),
                          ),
                        ),
                        // Center gold dot - elastic pop, then a gentle ambient pulse.
                        AnimatedBuilder(
                          animation: Listenable.merge([_dotPop, _ambient]),
                          builder: (context, _) {
                            final pulse = 1 + (math.sin(_ambient.value * 2 * math.pi) * 0.12);
                            final glow = 0.5 + (math.sin(_ambient.value * 2 * math.pi) * 0.3);
                                return Transform.scale(
                              scale: _dotPop.value.clamp(0.0, 1.0) * pulse,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.5 * glow),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 38),

                  // Brand name - letters stagger in individually, with a shimmer sweep once settled.
                  _ShimmerWordmark(controller: _controller, ambient: _ambient, letters: _letters, foreground: foreground, shimmer: kPaper),
                  const SizedBox(height: 12),

                  // Arabic subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'ميزان',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      color: foreground.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom tagline - arrives last, gentle rise-fade.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: FadeTransition(
                opacity: _taglineFade,
                child: AnimatedBuilder(
                  animation: _taglineFade,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, (1 - _taglineFade.value) * 8),
                    child: child,
                  ),
                  child: Text(
                    'THE BEAUTY OF CONSTANCY',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 4.5,
                      color: foreground.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the two concentric rotated-square rings with a stroke that sweeps
/// in from 0 to full, instead of appearing all at once.
class _DiamondRingsPainter extends CustomPainter {
  _DiamondRingsPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);

    _drawSweptSquare(canvas, halfSize: 36, alpha: 0.8, strokeWidth: 1.5);
    _drawSweptSquare(canvas, halfSize: 26, alpha: 0.4, strokeWidth: 1.0);

    canvas.restore();
  }

  void _drawSweptSquare(Canvas canvas, {required double halfSize, required double alpha, required double strokeWidth}) {
    final rect = Rect.fromLTWH(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
    final path = Path()..addRect(rect);
    final metrics = path.computeMetrics().first;
    final extractLength = metrics.length * progress.clamp(0.0, 1.0);
    final drawn = metrics.extractPath(0, extractLength);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondRingsPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

/// "M I Z A N" with each letter staggering in on its own delay, plus a soft
/// diagonal shimmer sweep across the settled text - driven by the ambient
/// loop so it repeats gently without restarting the whole entrance.
class _ShimmerWordmark extends StatelessWidget {
  const _ShimmerWordmark({required this.controller, required this.ambient, required this.letters, required this.foreground, required this.shimmer});
  final AnimationController controller;
  final AnimationController ambient;
  final List<String> letters;
  final Color foreground;
  final Color shimmer;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, ambient]),
        builder: (context, _) {
          // Base wordmark, letters staggered in during the entrance.
          final row = Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(letters.length, (i) {
              final start = 0.35 + (i * 0.06);
              final end = (start + 0.35).clamp(0.0, 1.0);
              final t = CurvedAnimation(
                parent: controller,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              ).value;
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 10),
                  child: Text(
                    i == letters.length - 1 ? letters[i] : '${letters[i]} ',
                    style: TextStyle(
                      fontSize: 34,
                      letterSpacing: 14,
                      fontWeight: FontWeight.w400,
                      color: foreground,
                      fontFamily: 'serif',
                      height: 1.1,
                    ),
                  ),
                ),
              );
            }),
          );

          // Once the entrance has mostly finished, layer a slow shimmer sweep.
          if (controller.value < 0.85) return row;

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final sweep = ambient.value;
              return LinearGradient(
                begin: Alignment(-1.5 + sweep * 3, 0),
                end: Alignment(-0.5 + sweep * 3, 0),
                colors: [foreground, shimmer, foreground],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(bounds);
            },
            child: row,
          );
        },
      ),
    );
  }
}
