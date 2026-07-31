import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// MIZAN · FAMILY — DESIGN TOKENS
// Warm ivory, paper textures, walnut / clay / bronze / muted olive.
// All tokens are aliases of the canonical app_theme.dart values.
// ─────────────────────────────────────────────────────────────

const Color fIvory = kIvory;
const Color fPaper = kPaper;
const Color fSurface = kSurface;
const Color fWalnut = kInk;
const Color fWalnutLight = Color(0xFF3C2F26);
const Color fBronze = kBronze;
const Color fBronzeDark = kBronzeDark;
const Color fBronzeLight = kBronzeLight;
const Color fClay = kClay;
const Color fClayLight = kClayLight;
const Color fClayPale = kClayPale;
const Color fOlive = kOlive;
const Color fOliveSoft = kOliveSoft;
const Color fStone = kMuted;
const Color fStoneLight = kMutedLight;
const Color fStonePale = kStonePale;
const Color fWhite = kWhite;
const Color fShadow = Color(0x0D000000);
const Color fShadowWarm = Color(0x1A8B6842);

const EdgeInsets fScreenPad = EdgeInsets.fromLTRB(20, 10, 20, 20);
const double fRadius = 24;

const TextStyle fSerif = TextStyle(fontFamily: 'Georgia', color: fWalnut);

// ─────────────────────────────────────────────────────────────
// SOFT CARD
// ─────────────────────────────────────────────────────────────

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.color = fWhite,
    this.borderColor = fClay,
    this.radius = fRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: fShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AVATAR (initials, warm accents, gentle contribution ring)
// ─────────────────────────────────────────────────────────────

class MizanAvatar extends StatelessWidget {
  const MizanAvatar({
    required this.name,
    this.accent = fBronze,
    this.size = 52,
    this.contributed = false,
    this.showRing = true,
    super.key,
  });

  final String name;
  final Color accent;
  final double size;
  final bool contributed;
  final bool showRing;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ring = contributed && showRing ? fOlive : fClay;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: ring, width: contributed && showRing ? 2 : 1.2),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROGRESS TRACK (matte clay track, warm bronze fill, no neon)
// ─────────────────────────────────────────────────────────────

class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    required this.value,
    this.height = 8,
    this.color = fBronze,
    super.key,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fClay,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: v,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN HEADER (editorial back + title + optional action)
// ─────────────────────────────────────────────────────────────

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_ios_new,
            onTap: onBack ?? () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: fWalnut,
                    fontFamily: 'Georgia',
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11, color: fStoneLight, letterSpacing: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fClay),
          ),
          child: Icon(icon, size: 16, color: fWalnutLight),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUTTONS (soft compress on press, restrained spring)
// ─────────────────────────────────────────────────────────────

class MizanButton extends StatefulWidget {
  const MizanButton({required this.label, required this.onTap, super.key, this.fullWidth = true});

  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  State<MizanButton> createState() => _MizanButtonState();
}

class _MizanButtonState extends State<MizanButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  late final Animation<double> _a = Tween<double>(begin: 1, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _a,
      child: Semantics(
        button: true,
        label: widget.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            onTapDown: (_) => _c.forward(),
            onTapUp: (_) => _c.reverse(),
            onTapCancel: () => _c.reverse(),
            child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: fBronze,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: fShadowWarm, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fWhite, letterSpacing: 0.3),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class MizanOutlineButton extends StatefulWidget {
  const MizanOutlineButton({required this.label, required this.onTap, super.key, this.fullWidth = true});

  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  State<MizanOutlineButton> createState() => _MizanOutlineButtonState();
}

class _MizanOutlineButtonState extends State<MizanOutlineButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  late final Animation<double> _a = Tween<double>(begin: 1, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _a,
      child: Semantics(
        button: true,
        label: widget.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            onTapDown: (_) => _c.forward(),
            onTapUp: (_) => _c.reverse(),
            onTapCancel: () => _c.reverse(),
            child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: fWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: fClay),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fStone, letterSpacing: 0.3),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, letterSpacing: 2.4, fontWeight: FontWeight.w700, color: fStonePale),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAPER BACKGROUND HELPER
// ─────────────────────────────────────────────────────────────

class PaperBackground extends StatelessWidget {
  const PaperBackground({required this.child, super.key, this.color = fIvory});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SoftGrainPainter())),
          child,
        ],
      ),
    );
  }
}

class _SoftGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fWalnut.withValues(alpha: 0.012)..style = PaintingStyle.fill;
    final random = math.Random(7);
    for (int i = 0; i < 160; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final s = random.nextDouble() * 2 + 0.5;
      canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// FAMILY JAR PAINTER — ceramic jar filled with warm LIGHT
// (never coins, never money — generosity is light)
// ─────────────────────────────────────────────────────────────

class FamilyJarView extends StatefulWidget {
  const FamilyJarView({required this.fill, super.key, this.size = 200, this.glow = 0.0});

  final double fill;
  final double size;
  final double glow;

  @override
  State<FamilyJarView> createState() => _FamilyJarViewState();
}

class _FamilyJarViewState extends State<FamilyJarView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late Animation<double> _fill = Tween<double>(begin: 0, end: widget.fill).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

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
  void didUpdateWidget(covariant FamilyJarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fill == widget.fill) return;
    _fill = Tween<double>(begin: oldWidget.fill, end: widget.fill.clamp(0.0, 1.0)).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 1.22,
          child: CustomPaint(
            painter: _FamilyJarPainter(
              fill: _fill.value,
              glow: widget.glow + (_c.isAnimating ? (1 - _c.value) * .35 : 0),
            ),
          ),
        );
      },
    );
  }
}

class _FamilyJarPainter extends CustomPainter {
  _FamilyJarPainter({required this.fill, required this.glow});

  final double fill;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 200; // scale factor

    // Gentle ambient glow behind jar
    if (glow > 0) {
      final gp = Paint()
        ..shader = RadialGradient(
          colors: [
            fBronzeLight.withValues(alpha: glow * 0.16),
            fBronzeLight.withValues(alpha: glow * 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy + 10 * s), radius: 130 * s));
      canvas.drawCircle(Offset(cx, cy + 10 * s), 130 * s, gp);
    }

    // Jar body path
    final jarPath = Path()
      ..moveTo(cx - 40 * s, cy - 78 * s)
      ..quadraticBezierTo(cx - 50 * s, cy - 72 * s, cx - 55 * s, cy - 58 * s)
      ..quadraticBezierTo(cx - 60 * s, cy - 38 * s, cx - 58 * s, cy - 18 * s)
      ..lineTo(cx - 55 * s, cy + 42 * s)
      ..quadraticBezierTo(cx - 50 * s, cy + 72 * s, cx - 30 * s, cy + 78 * s)
      ..lineTo(cx + 30 * s, cy + 78 * s)
      ..quadraticBezierTo(cx + 50 * s, cy + 72 * s, cx + 55 * s, cy + 42 * s)
      ..lineTo(cx + 58 * s, cy - 18 * s)
      ..quadraticBezierTo(cx + 60 * s, cy - 38 * s, cx + 55 * s, cy - 58 * s)
      ..quadraticBezierTo(cx + 50 * s, cy - 72 * s, cx + 40 * s, cy - 78 * s)
      ..close();

    // Matte clay body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFE8D8C7), Color(0xFFD9C4AF), Color(0xFFC9B09A)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(cx - 60 * s, cy - 80 * s, 120 * s, 160 * s));
    canvas.drawPath(jarPath, bodyPaint);

    // Light inside the jar — rises with `fill`
    if (fill > 0.001) {
      canvas.save();
      canvas.clipPath(jarPath);
      final innerTop = cy - 60 * s;
      final innerBottom = cy + 74 * s;
      final lightH = (innerBottom - innerTop) * fill.clamp(0.0, 1.0);
      final lightTop = innerBottom - lightH;
      final lightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fBronzeLight.withValues(alpha: 0.05),
            fBronzeLight.withValues(alpha: 0.28),
            fBronze.withValues(alpha: 0.42),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTRB(cx - 60 * s, lightTop, cx + 60 * s, innerBottom));
      canvas.drawRect(Rect.fromLTRB(cx - 60 * s, lightTop, cx + 60 * s, innerBottom), lightPaint);

      // Floating specks of light within the glow
      final speck = Paint()..color = fBronzeLight.withValues(alpha: 0.5);
      final rng = math.Random(11);
      for (int i = 0; i < 14; i++) {
        final t = rng.nextDouble();
        final yy = innerBottom - t * lightH;
        final xx = cx + (rng.nextDouble() - 0.5) * 92 * s;
        final r = (0.6 + rng.nextDouble() * 1.8) * s;
        canvas.drawCircle(Offset(xx, yy), r, speck);
      }
      canvas.restore();

      // Soft halo at the surface of the light
      final surfacePaint = Paint()
        ..shader = RadialGradient(
          colors: [fBronzeLight.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, lightTop), radius: 46 * s));
      canvas.drawCircle(Offset(cx, lightTop), 46 * s, surfacePaint);
    }

    // Rim
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFD4BFA8), Color(0xFFC4AD94), Color(0xFFB89E84)],
      ).createShader(Rect.fromLTWH(cx - 42 * s, cy - 86 * s, 84 * s, 16 * s));
    canvas.drawPath(
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 80 * s), width: 84 * s, height: 14 * s),
          Radius.circular(7 * s),
        )),
      rimPaint,
    );

    // Inner opening (dark)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 80 * s), width: 60 * s, height: 10 * s),
      Paint()..color = const Color(0xFF8B7A6A),
    );

    // Decorative bands
    final band = Paint()
      ..color = fBronzeLight.withValues(alpha: 0.18)
      ..strokeWidth = 1.5 * s
      ..style = PaintingStyle.stroke;
    final top = Path()
      ..moveTo(cx - 48 * s, cy - 12 * s)
      ..quadraticBezierTo(cx, cy - 7 * s, cx + 48 * s, cy - 12 * s);
    canvas.drawPath(top, band);
    final bot = Path()
      ..moveTo(cx - 45 * s, cy + 46 * s)
      ..quadraticBezierTo(cx, cy + 51 * s, cx + 45 * s, cy + 46 * s);
    canvas.drawPath(bot, band);

    // Side shine
    final shine = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fWhite.withValues(alpha: 0.18), fWhite.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(cx - 50 * s, cy - 70 * s, 30 * s, 100 * s));
    canvas.drawPath(
      Path()
        ..moveTo(cx - 45 * s, cy - 65 * s)
        ..quadraticBezierTo(cx - 40 * s, cy - 30 * s, cx - 42 * s, cy + 10 * s)
        ..quadraticBezierTo(cx - 38 * s, cy + 20 * s, cx - 35 * s, cy + 30 * s)
        ..lineTo(cx - 30 * s, cy + 30 * s)
        ..quadraticBezierTo(cx - 33 * s, cy + 10 * s, cx - 35 * s, cy - 30 * s)
        ..quadraticBezierTo(cx - 38 * s, cy - 60 * s, cx - 45 * s, cy - 65 * s)
        ..close(),
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _FamilyJarPainter old) => old.fill != fill || old.glow != glow;
}
