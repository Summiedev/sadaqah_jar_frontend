import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './animations.dart';

CustomTransitionPage<dynamic> mizanPage({
  required Widget child,
  String? name,
  Object? extra,
}) {
  return CustomTransitionPage<dynamic>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!MizanMotion.enabled(context)) return child;
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final scale = Tween<double>(begin: 0.985, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: ScaleTransition(scale: scale, child: child)));
    },
    transitionDuration: MizanMotion.page,
  );
}

CustomTransitionPage<dynamic> mizanDialogPage({
  required Widget child,
  String? name,
  Object? extra,
}) {
  return CustomTransitionPage<dynamic>(
    fullscreenDialog: true,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!MizanMotion.enabled(context)) return child;
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = Tween<double>(begin: 0.96, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
    },
    transitionDuration: MizanMotion.normal,
  );
}
