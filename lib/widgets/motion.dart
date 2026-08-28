import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Small, reusable motion primitives. All movement switches off when the
/// platform asks for reduced motion.
bool motionEnabled(BuildContext context) =>
    !MediaQuery.of(context).disableAnimations &&
    !MediaQuery.of(context).accessibleNavigation;

class PressableSpring extends StatefulWidget {
  const PressableSpring({
    super.key,
    required this.child,
    this.onTap,
    this.scale = .975,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;
  @override
  State<PressableSpring> createState() => _PressableSpringState();
}

class _PressableSpringState extends State<PressableSpring> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = motionEnabled(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: enabled && _pressed ? widget.scale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 220),
        curve: _pressed ? Curves.easeOut : Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class FocusGlow extends StatefulWidget {
  const FocusGlow({super.key, required this.child, this.radius = 16});
  final Widget child;
  final double radius;
  @override
  State<FocusGlow> createState() => _FocusGlowState();
}

class _FocusGlowState extends State<FocusGlow> {
  final FocusNode _node = FocusNode();
  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    onFocusChange: (_) => setState(() {}),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow:
            _node.hasFocus && motionEnabled(context)
                ? [
                  BoxShadow(
                    color: kBronze.withValues(alpha: 0.2),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
                : [],
      ),
      child: widget.child,
    ),
  );
}
