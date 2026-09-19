import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'metric_card_frame.dart';
import 'metric_header.dart';

class ThisWeekCard extends StatelessWidget {
  final List<double> barHeights;
  final int totalExercises;
  final Animation<double> barAnimation;
  final List<CurvedAnimation?> barCurves;
  final bool reduceMotion;

  const ThisWeekCard({
    super.key,
    required this.barHeights,
    required this.totalExercises,
    required this.barAnimation,
    required this.barCurves,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = [
      l10n.weekday_monday_abbr,
      l10n.weekday_tuesday_abbr,
      l10n.weekday_wednesday_abbr,
      l10n.weekday_thursday_abbr,
      l10n.weekday_friday_abbr,
      l10n.weekday_saturday_abbr,
      l10n.weekday_sunday_abbr,
    ];
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: '${l10n.home_thisWeek} activity chart',
      child: MetricCardFrame(
        accentColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricHeader(
              icon: Icons.bar_chart_rounded,
              title: l10n.home_thisWeek,
              iconColor: color,
              trailing: Text(
                '$totalExercises ${l10n.home_exercises}',
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: barAnimation,
                builder: (context, _) {
                  final barAnims = List.generate(7, (i) {
                    final curve = barCurves[i];
                    final anim = curve != null
                        ? Tween<double>(begin: 0.0, end: barHeights[i]).animate(curve)
                        : AlwaysStoppedAnimation<double>(barHeights[i]);
                    return anim;
                  });

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = barAnims[i].value;
                      final isActive = h > 0.05;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Percentage label above active bars
                          SizedBox(
                            height: 16,
                            child: isActive
                                ? Text(
                                    '${(h * 100).round()}%',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            label: '${days[i]}: ${(h * 100).round()}% activity',
                            child: Container(
                              width: 30,
                              height: (kMetricBodyHeight - 30) * h,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? color
                                    : AppTheme.subtleFill(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days
                    .map(
                      (d) => SizedBox(
                        width: 30,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
