import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Widget buildStaggeredSection({
  required AnimationController controller,
  required int index,
  required Widget child,
  bool reduceMotion = false,
}) {
  if (reduceMotion) return child;

  final double start = (index * 0.115).clamp(0.0, 0.7);
  final Animation<double> curved = CurvedAnimation(
    parent: controller,
    curve: Interval(
      start,
      (start + 0.38).clamp(0.0, 1.0),
      curve: AppTheme.kEaseOut,
    ),
  );

  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.09),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
