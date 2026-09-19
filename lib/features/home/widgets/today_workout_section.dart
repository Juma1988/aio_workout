import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/workout_log.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/exercise_progress_dialog.dart';
import '../rest_timer.dart';
import 'exercise_info_sheet.dart';
import 'exercise_tile.dart';

class TodayWorkoutSection extends StatelessWidget {
  final int currentWeek;
  final int currentDay;
  final Set<String> completedUuids;
  final bool isTodayCompleted;
  final int restTimerSeconds;
  final String? restTimerExerciseUuid;
  final ValueChanged<String>? onExerciseToggled;
  final ValueChanged<String>? onExerciseCompleted;
  final VoidCallback? onFinishWorkout;
  final VoidCallback? onStartRestTimer;
  final VoidCallback? onDismissRestTimer;
  final Clock clock;
  final bool allExercisesDone;

  const TodayWorkoutSection({
    super.key,
    required this.currentWeek,
    required this.currentDay,
    required this.completedUuids,
    required this.isTodayCompleted,
    required this.restTimerSeconds,
    this.restTimerExerciseUuid,
    this.onExerciseToggled,
    this.onExerciseCompleted,
    this.onFinishWorkout,
    this.onStartRestTimer,
    this.onDismissRestTimer,
    required this.clock,
    required this.allExercisesDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = completedUuids.length;

    // ── Completed for today: show a done card instead of the exercise list ──
    if (isTodayCompleted) {
      final nextProgress = ProgramProgress(
        currentWeek: currentWeek,
        currentDay: currentDay,
      ).advance();
      final nextFocus = getLocalizedFocus(l10n, nextProgress.currentWeek, nextProgress.currentDay);

      return Semantics(
        label: '${l10n.home_todaysWorkout} complete',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.home_todaysWorkout,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.notif_done,
                    style: TextStyle(
                      color: AppTheme.achievementGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.achievementGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.achievementGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.achievementGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.home_workoutComplete,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.home_noExercises,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.subtleFill(context, 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${l10n.home_week} ${nextProgress.currentWeek} \u2014 ${l10n.home_day} ${nextProgress.currentDay} \u2014 $nextFocus',
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: l10n.home_todaysWorkout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.home_todaysWorkout,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Semantics(
                  label: isRestDay(currentDay)
                      ? (allExercisesDone ? '${l10n.home_restDay} complete' : l10n.home_restDay)
                      : '$completed of ${getTodayExercises(currentDay).length} ${l10n.home_exercises} ${l10n.home_completed}',
                  child: Text(
                    isRestDay(currentDay)
                        ? (allExercisesDone ? l10n.home_restDay : '0')
                        : '$completed/${getTodayExercises(currentDay).length}',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.home_week} $currentWeek \u2014 ${l10n.home_day} $currentDay \u2014 ${getLocalizedFocus(l10n, currentWeek, currentDay)}',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // ── Rest timer banner ──
          if (restTimerExerciseUuid != null && restTimerSeconds > 0)
            RestTimer(
              key: ValueKey('rest_$restTimerExerciseUuid'),
              seconds: restTimerSeconds,
              onComplete: () {
                onDismissRestTimer?.call();
              },
            ),

          ...List.generate(getTodayExercises(currentDay).length, (i) {
            final ex = getTodayExercises(currentDay)[i];
            final isDone = completedUuids.contains(ex.uuid);
            return Padding(
              padding: EdgeInsets.only(bottom: i < getTodayExercises(currentDay).length - 1 ? 8 : 0),
              child: ExerciseTile(
                exercise: ex,
                isDone: isDone,
                onToggle: () {
                  final uuid = ex.uuid;
                  onExerciseToggled?.call(uuid);
                  if (!isDone) {
                    onStartRestTimer?.call();
                  }
                },
                onPlay: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExerciseProgressDialog(
                        exercise: ex,
                        onComplete: () {
                          onExerciseCompleted?.call(ex.uuid);
                        },
                      ),
                    ),
                  );
                },
                onInfo: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => ExerciseInfoSheet(exercise: ex),
                  );
                },
              ),
            );
          }),

          // ── Finish Workout button (shows when all exercises are done) ──
          if (allExercisesDone) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onFinishWorkout,
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  l10n.home_completeWorkout,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
