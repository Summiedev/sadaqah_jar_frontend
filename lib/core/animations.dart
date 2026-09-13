import 'package:flutter/material.dart';
import 'theme/theme_extensions.dart';

/// Canonical motion tokens for Mizan.
class MizanMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 340);
  static const Duration page = Duration(milliseconds: 280);

  static const Curve gentle = Curves.easeOutCubic;
  static const Curve gentleIn = Curves.easeInOutCubic;
  static const Curve quick = Curves.fastOutSlowIn;
  static const Curve soft = Curves.easeOutQuart;

  static bool enabled(BuildContext context) =>
      !MediaQuery.of(context).disableAnimations &&
      !MediaQuery.of(context).accessibleNavigation;
}

class FadeScaleTransition extends StatelessWidget {
  const FadeScaleTransition({
    super.key,
    required this.child,
    this.duration = MizanMotion.normal,
    this.curve = MizanMotion.gentle,
    this.beginScale = 0.98,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    if (!MizanMotion.enabled(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginScale, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, scale, child) {
        final opacity = ((scale - beginScale) / (1 - beginScale)).clamp(
          0.0,
          1.0,
        );
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

/// Staggers a card's fade+rise entrance based on [index], without ever
/// leaving it stuck below full opacity.
///
/// Implementation note: the delay must EXTEND the timeline, not eat into a
/// fixed-length animation. A previous version computed
/// `adjusted = (value - delayFactor).clamp(0, 1)` inside a single fixed
/// `MizanMotion.slow` duration - since `value` only ever reaches 1.0 at the
/// end of that same fixed window, higher-index cards could never actually
/// reach full opacity (their ceiling was `1 - delayFactor`, which shrinks
/// further for every subsequent index). This version runs the
/// TweenAnimationBuilder over `delay + animation` and only starts easing in
/// opacity once the delay portion has elapsed, so every card - regardless
/// of index - reaches opacity 1.0, just later.
class CardEntrance extends StatelessWidget {
  const CardEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 40),
  });

  final Widget child;
  final int index;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (!MizanMotion.enabled(context)) return child;

    final delayMs = index * delay.inMilliseconds;
    final animMs = MizanMotion.slow.inMilliseconds;
    final totalMs = delayMs + animMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Timeline covers delay + animation, so later cards simply start
      // later - they still reach full opacity, just after a pause.
      duration: Duration(milliseconds: totalMs),
      curve: Curves.linear,
      builder: (context, timelineValue, child) {
        final elapsedMs = timelineValue * totalMs;
        final localProgress = ((elapsedMs - delayMs) / animMs).clamp(0.0, 1.0);
        final adjusted = MizanMotion.gentle.transform(localProgress);
        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - adjusted)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.duration = MizanMotion.normal,
    this.style,
  });

  final int value;
  final Duration duration;
  final TextStyle? style;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: MizanMotion.gentle));
    _previous = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previous = oldWidget.value;
      _animation = IntTween(begin: _previous, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: MizanMotion.gentle),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) => Text('${_animation.value}', style: widget.style),
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _shimmer = Tween<double>(
    begin: -2,
    end: 2,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  bool _isRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate = MizanMotion.enabled(context);
    if (shouldAnimate && !_isRunning) {
      _controller.repeat();
      _isRunning = true;
    } else if (!shouldAnimate && _isRunning) {
      _controller.stop();
      _isRunning = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final colors = context.colors;
        if (!MizanMotion.enabled(context)) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              color: colors.surfaceContainerHigh,
            ),
          );
        }
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_shimmer.value - 1, 0),
              end: Alignment(_shimmer.value, 0),
              colors: [
                colors.surfaceContainerHigh,
                colors.surfaceElevated,
                colors.surfaceContainerHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 56, this.color, this.onComplete});

  final double size;
  final Color? color;
  final VoidCallback? onComplete;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MizanMotion.slow,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.5,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: MizanMotion.soft));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.success;
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: color,
              size: widget.size * 0.5,
            ),
          ),
        );
      },
    );
  }
}

class SmoothProgress extends StatelessWidget {
  const SmoothProgress({
    super.key,
    required this.value,
    this.height = 7,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
      duration: MizanMotion.slow,
      curve: MizanMotion.gentle,
      builder: (context, animatedValue, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius ?? BorderRadius.circular(height),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                color: color ?? theme.colorScheme.primary,
                borderRadius: borderRadius ?? BorderRadius.circular(height),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DialogFadeScale extends StatelessWidget {
  const DialogFadeScale({
    super.key,
    required this.child,
    this.duration = MizanMotion.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (!MizanMotion.enabled(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: duration,
      curve: MizanMotion.gentle,
      builder: (context, scale, child) {
        final opacity = ((scale - 0.92) / (1 - 0.92)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

class SlideUpFade extends StatelessWidget {
  const SlideUpFade({
    super.key,
    required this.child,
    this.duration = MizanMotion.normal,
    this.offset = 0.08,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (!MizanMotion.enabled(context)) return child;
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: Offset(0, offset), end: Offset.zero),
      duration: duration,
      curve: MizanMotion.gentle,
      builder: (context, value, child) {
        final opacity = (1 - (value.dy / offset)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: value, child: child),
        );
      },
      child: child,
    );
  }
}
