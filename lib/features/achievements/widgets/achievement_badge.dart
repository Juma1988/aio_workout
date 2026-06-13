import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AchievementBadge extends StatelessWidget {
  final int count;
  final double size;

  const AchievementBadge({
    super.key,
    required this.count,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Semantics(
      label: '$count achievements unlocked',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.stepsOrange,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.cardColor(context),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
