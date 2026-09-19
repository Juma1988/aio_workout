import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../hydration/hydration_history_screen.dart';
import 'metric_card_frame.dart';
import 'metric_header.dart';
import 'progress_ring.dart';

class HydrationMetricCard extends StatelessWidget {
  final double liters;
  final double goal;
  final int mlPerClick;
  final ValueChanged<double>? onChanged;

  const HydrationMetricCard({
    super.key,
    required this.liters,
    required this.goal,
    required this.mlPerClick,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveGoal = goal <= 0 ? 2.5 : goal;
    final progress = (liters / effectiveGoal).clamp(0.0, 1.0);
    final color = AppTheme.hydrationBlue;
    final addLiters = mlPerClick / 1000.0;

    return Semantics(
      label:
          '${l10n.home_hydration}, ${liters.toStringAsFixed(2)} ${l10n.home_liters}',
      child: MetricCardFrame(
        accentColor: color,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final next = (liters + addLiters).clamp(0.0, effectiveGoal * 3);
            onChanged?.call(next);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HydrationHistoryScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricHeader(
                icon: Icons.water_drop_rounded,
                title: l10n.home_hydration,
                iconColor: color,
                trailing: Text(
                  '${liters.toStringAsFixed(2)} / ${effectiveGoal.toStringAsFixed(1)}',
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
                            tween: Tween(begin: 0, end: liters),
                            duration: AppTheme.kAnimMedium,
                            curve: AppTheme.kEaseOut,
                            builder: (context, value, _) {
                              return Text(
                                '${value.toStringAsFixed(2)} ${l10n.home_liters}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -0.5,
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
                      bottomLabel: l10n.home_hydration,
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
