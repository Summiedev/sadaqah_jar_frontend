import 'dart:math';

import 'package:flutter/material.dart';

class AuthChoiceScreen extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final VoidCallback onForgotPassword;
  final VoidCallback onPrivacy;
  const AuthChoiceScreen({
    super.key,
    required this.onGoogle,
    required this.onEmail,
    required this.onForgotPassword,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final scale = (width / 390).clamp(0.92, 1.08);
    double s(double v) => v * scale;
    final heroSize = (width * 0.74).clamp(250.0, 330.0);

    return Scaffold(
      backgroundColor: const Color(0xFF191410),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1712), Color(0xFF433225), Color(0xFF14100D)],
            stops: [0.0, 0.56, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -70,
              child: _GlowDot(color: const Color(0xFFB88957).withValues(alpha: 0.30), size: 200),
            ),
            Positioned(
              top: 120,
              right: -90,
              child: _GlowDot(color: const Color(0xFF7C8A59).withValues(alpha: 0.24), size: 220),
            ),
            Positioned(
              bottom: -90,
              left: -50,
              child: _GlowDot(color: const Color(0xFF8C6C54).withValues(alpha: 0.24), size: 190),
            ),
            Positioned(
              top: 52,
              right: 14,
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  'lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 53.png',
                  width: s(86),
                  height: s(86),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: 164,
              child: Opacity(
                opacity: 0.24,
                child: Image.asset(
                  'lib/assets/images/plant, leaves, leaf, branch, plants, nature, green, 58.png',
                  width: s(116),
                  height: s(116),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + media.viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF1E6CC),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: SizedBox(
                        width: heroSize,
                        height: heroSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: heroSize,
                              height: heroSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFF0E3C5).withValues(alpha: 0.22),
                                    const Color(0xFFAA7440).withValues(alpha: 0.06),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: Size(heroSize, heroSize),
                              painter: _DashedRingPainter(
                                ringColor: const Color(0xFF8D7A65),
                                accentColor: const Color(0xFFC4864A),
                              ),
                            ),
                            Container(
                              width: heroSize * 0.74,
                              height: heroSize * 0.74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDDD9DE).withValues(alpha: 0.16),
                              ),
                            ),
                            Container(
                              width: heroSize * 0.58,
                              height: heroSize * 0.58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE7E3E8).withValues(alpha: 0.12),
                              ),
                            ),
                            _GoodActsCluster(scale: scale),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Do ',
                            style: TextStyle(
                              color: const Color(0xFFF7F0E2),
                              fontSize: s(28),
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'more sadaqah',
                            style: TextStyle(
                              color: const Color(0xFFD6A05C),
                              fontSize: s(28),
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Login or create an account to track acts, build streaks, and grow your family jar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFE6D6C0).withValues(alpha: 0.84),
                        fontSize: 15.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F1E7).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE6D6BE).withValues(alpha: 0.95)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x2A000000), blurRadius: 28, offset: Offset(0, 16)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Choose how you want to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF3F352E),
                              fontSize: s(20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF171513),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onGoogle,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF67A2FF)),
                                  SizedBox(width: 8),
                                  Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9A734F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onEmail,
                              child: const Text(
                                'Continue with Email',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: onForgotPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF5F7C43),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onPrivacy,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'By continuing, you agree to our ',
                                    style: TextStyle(
                                      color: const Color(0xFF867567),
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: const Color(0xFF716659),
                                      decoration: TextDecoration.underline,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: TextStyle(
                                      color: const Color(0xFF867567),
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: const Color(0xFF716659),
                                      decoration: TextDecoration.underline,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.ringColor, required this.accentColor});

  final Color ringColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;

    const totalBars = 92;
    for (var i = 0; i < totalBars; i++) {
      final angle = (i / totalBars) * 2 * pi;
      final isAccent = i > 45 && i < 64;
      paint.color = isAccent ? accentColor : ringColor;

      final inner = Offset(
        center.dx + (radius - 8) * cos(angle),
        center.dy + (radius - 8) * sin(angle),
      );
      final outer = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor || oldDelegate.accentColor != accentColor;
  }
}

class _GoodActsCluster extends StatelessWidget {
  const _GoodActsCluster({required this.scale});

  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFFEDE7E0).withValues(alpha: 0.74);

    return SizedBox(
      width: s(170),
      height: s(170),
      child: Stack(
        children: [
          Positioned(
            top: s(12),
            left: s(72),
            child: Icon(Icons.cloud_outlined, size: s(18), color: textColor),
          ),
          Positioned(
            top: s(35),
            left: s(40),
            child: Text(
              'Smile at\nsomeone',
              style: TextStyle(color: textColor, fontSize: s(7), height: 1.1),
            ),
          ),
          Positioned(
            top: s(72),
            left: s(22),
            child: Text(
              'Say\nBismillah',
              style: TextStyle(color: textColor, fontSize: s(7), height: 1.1),
            ),
          ),
          Positioned(
            top: s(85),
            left: s(92),
            child: Text(
              'Remove harm\nfrom the path',
              style: TextStyle(color: textColor, fontSize: s(7), height: 1.1),
            ),
          ),
          Positioned(
            top: s(115),
            left: s(96),
            child: Row(
              children: [
                Text(
                  'Say: La ilaha\nilla Allah',
                  style: TextStyle(color: textColor, fontSize: s(7), height: 1.1),
                ),
                SizedBox(width: s(2)),
                Icon(Icons.edit, size: s(10), color: textColor),
              ],
            ),
          ),
          Positioned(
            top: s(112),
            left: s(20),
            child: Icon(Icons.rotate_left, size: s(30), color: textColor),
          ),
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
