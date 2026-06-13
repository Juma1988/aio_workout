import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AchievementCountText extends StatelessWidget {
  final int unlocked;
  final int total;

  const AchievementCountText({
    super.key,
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$unlocked of $total achievements unlocked',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$unlocked',
            style: TextStyle(
              color: AppTheme.achievementGreen,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 2),
            child: Text(
              ' / $total',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'unlocked',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
