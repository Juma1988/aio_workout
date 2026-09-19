import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/clock.dart';
import '../../../data/weight_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../models/trend_info.dart';
import '../painters/weight_spark_painter.dart';
import 'metric_card_frame.dart';
import 'metric_header.dart';

class WeightTrendCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? goalKg;
  final TrendInfo trend;
  final Animation<double> chartAnimation;
  final bool reduceMotion;
  final VoidCallback? onTap;
  final Clock clock;

  const WeightTrendCard({
    super.key,
    required this.entries,
    this.goalKg,
    required this.trend,
    required this.chartAnimation,
    required this.reduceMotion,
    this.onTap,
    required this.clock,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final purple = AppTheme.weightPurple;
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    final currentWeight = sorted.isNotEmpty ? sorted.last.weightKg : 0.0;
    final hasGoal = goalKg != null && goalKg! > 0;
    final goalProgress = hasGoal && currentWeight > 0
        ? (currentWeight / goalKg!).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Weight tracker, ${currentWeight.toStringAsFixed(1)} kilograms',
      child: MetricCardFrame(
        accentColor: purple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricHeader(
              icon: Icons.monitor_weight_outlined,
              title: l10n.home_weight,
              iconColor: purple,
              trailing: trend.isValid
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trend.icon, size: 16, color: trend.color(context)),
                        const SizedBox(width: 4),
                        Text(
                          trend.displayText,
                          style: TextStyle(
                            color: trend.color(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: kMetricBodyHeight,
              width: double.infinity,
              child: sorted.isEmpty
                  ? _buildWeightEmpty(context)
                  : GestureDetector(
                      onTap: onTap,
                      child: AnimatedBuilder(
                        animation: chartAnimation,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(double.infinity, kMetricBodyHeight),
                            painter: WeightSparkPainter(
                              entries: sorted,
                              lineColor: purple,
                              animationValue: reduceMotion
                                  ? 1.0
                                  : chartAnimation.value,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 16,
              child: sorted.isEmpty
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: currentWeight),
                          duration: AppTheme.kAnimMedium,
                          curve: AppTheme.kEaseOut,
                          builder: (context, animated, _) {
                            return Text(
                              '${animated.toStringAsFixed(1)} ${l10n.home_kg}',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        if (hasGoal) ...[
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: goalProgress.clamp(0.0, 1.0),
                                backgroundColor: AppTheme.subtleFill(context),
                                color: purple,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(goalProgress * 100).round()}%',
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _lastLoggedText(sorted, l10n),
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastLoggedText(List<WeightEntry> sorted, AppLocalizations l10n) {
    if (sorted.isEmpty) return '';
    final last = sorted.last.date;
    final diff = clock.now().difference(last);
    if (diff.inDays == 0) return l10n.home_loggedToday;
    if (diff.inDays == 1) return l10n.home_loggedYesterday;
    return l10n.home_loggedDaysAgo(diff.inDays);
  }

  Widget _buildWeightEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 36,
              color: AppTheme.textDisabled(context),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.home_logWeight,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.home_tapToRecord,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
