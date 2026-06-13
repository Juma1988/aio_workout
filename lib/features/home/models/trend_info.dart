import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TrendInfo {
  final double changeKg;
  final String period;
  final bool isValid;

  const TrendInfo({
    required this.changeKg,
    required this.period,
  }) : isValid = true;

  const TrendInfo.none()
      : changeKg = 0,
        period = '',
        isValid = false;

  bool get isLoss => changeKg < 0;
  bool get isGain => changeKg > 0;
  bool get isFlat => changeKg == 0;

  String get displayText {
    if (isFlat) return '\u00B10.0 kg $period';
    final abs = changeKg.abs().toStringAsFixed(1);
    final prefix = isLoss ? '-' : '+';
    return '$prefix$abs kg $period';
  }

  Color color(BuildContext context) {
    if (isFlat) return AppTheme.textTertiary(context);
    return isLoss ? AppTheme.achievementGreen : AppTheme.stepsOrange;
  }

  IconData get icon {
    if (isFlat) return Icons.remove_rounded;
    return isLoss ? Icons.trending_down : Icons.trending_up;
  }
}
