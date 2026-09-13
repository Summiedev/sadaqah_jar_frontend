import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';

class PrototypeSkeleton extends StatelessWidget {
  const PrototypeSkeleton({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class SkeletonLine extends StatefulWidget {
  const SkeletonLine({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, _) => Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: reduceMotion ? colors.accentSoft : null,
              gradient:
                  reduceMotion
                      ? null
                      : LinearGradient(
                        begin: Alignment(-1 + _controller.value * 2, 0),
                        end: Alignment(_controller.value * 2, 0),
                        colors: [
                          colors.accentSoft,
                          colors.surfaceElevated,
                          colors.accentSoft,
                        ],
                      ),
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(MizanRadii.card),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: child,
    );
  }
}
