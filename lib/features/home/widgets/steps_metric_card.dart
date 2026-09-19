import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../steps/step_history_screen.dart';
import 'metric_card_frame.dart';
import 'metric_header.dart';
import 'progress_ring.dart';

class StepsMetricCard extends StatelessWidget {
  final int steps;
  final int stepsGoal;
  final int stepsPerClick;
  final ValueChanged<int>? onStepsChanged;

  const StepsMetricCard({
    super.key,
    required this.steps,
    required this.stepsGoal,
    required this.stepsPerClick,
    this.onStepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = stepsGoal <= 0 ? 10000 : stepsGoal;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final color = AppTheme.stepsOrange;

    return Semantics(
      label: '${l10n.home_steps}, $steps',
      child: MetricCardFrame(
        accentColor: color,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onStepsChanged?.call(steps + stepsPerClick);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StepHistoryScreen()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricHeader(
                icon: Icons.directions_walk_rounded,
                title: l10n.home_steps,
                iconColor: color,
                trailing: Text(
                  '$steps / $goal',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: steps.toDouble()),
                            duration: AppTheme.kAnimMedium,
                            curve: AppTheme.kEaseOut,
                            builder: (context, value, _) {
                              return Text(
                                '${value.round()}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.subtleFill(context),
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: l10n.home_steps,
                      color: color,
                      size: 76,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.home_tapToAdd,
                style: TextStyle(
                  color: AppTheme.textDisabled(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
