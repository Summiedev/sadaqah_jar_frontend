import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../core/theme/theme_extensions.dart';

/// The shared framed surface for repeatable Mizan content.
///
/// It deliberately has no fixed height so journal, Qur'an and Islamic text
/// can grow naturally in every text scale and theme.
class MizanSurface extends StatelessWidget {
  const MizanSurface({
    required this.child,
    this.padding = MizanSpacing.card,
    this.color,
    this.borderColor,
    this.radius = MizanRadii.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? colors.borderSubtle),
        boxShadow:
            isDark
                ? const []
                : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.09),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
      ),
      child: child,
    );

    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: surface,
        ),
      ),
    );
  }
}
