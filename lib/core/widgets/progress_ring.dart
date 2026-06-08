import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final double progress;
  final String centerLabel;
  final String bottomLabel;
  final Color color;
  final double size;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    required this.bottomLabel,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 4;
    final stroke = size > 48 ? 4.5 : 3.8;
    final centerFont = size > 48 ? 12.0 : 10.0;
    final bottomFont = size > 48 ? 9.0 : 8.0;

    return Semantics(
      label: '$centerLabel complete',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: innerSize,
              height: innerSize,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                duration: AppTheme.kAnimProgress,
                curve: AppTheme.kEaseOut,
                builder: (context, animatedProgress, _) {
                  return CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: stroke,
                    backgroundColor: AppTheme.subtleFill(context),
                    color: color,
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: centerFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bottomLabel,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: bottomFont,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
