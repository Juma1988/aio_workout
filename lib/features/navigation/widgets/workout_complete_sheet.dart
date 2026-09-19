import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet shown after workout completion (no new achievements).
class WorkoutCompleteSheet extends StatelessWidget {
  final String focus;
  final int exerciseCount;
  final int durationSeconds;
  final int currentWeek;

  const WorkoutCompleteSheet({
    super.key,
    required this.focus,
    required this.exerciseCount,
    required this.durationSeconds,
    required this.currentWeek,
  });

  static Future<void> show(
    BuildContext context, {
    required String focus,
    required int exerciseCount,
    required int durationSeconds,
    required int currentWeek,
  }) {
    HapticFeedback.heavyImpact();
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WorkoutCompleteSheet(
        focus: focus,
        exerciseCount: exerciseCount,
        durationSeconds: durationSeconds,
        currentWeek: currentWeek,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.achievementGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppTheme.achievementGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.celebration_workoutComplete,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            focus,
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: '$exerciseCount',
                label: l10n.home_exercises,
              ),
              _StatItem(
                value: '${durationSeconds ~/ 60}${l10n.home_min}',
                label: l10n.home_duration,
              ),
              _StatItem(
                value: 'W$currentWeek',
                label: l10n.home_completed,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.home_letsGo),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
