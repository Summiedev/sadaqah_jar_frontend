import 'package:flutter/material.dart';

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

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width, required this.height, this.radius = 12});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE2D5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: child,
    );
  }
}
