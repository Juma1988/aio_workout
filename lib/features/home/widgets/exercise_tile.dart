import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/exercise.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onPlay;
  final VoidCallback onInfo;

  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.isDone,
    required this.onToggle,
    required this.onPlay,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final setsReps = exercise.getRecommendedDisplay();
    final green = AppTheme.achievementGreen;

    return Semantics(
      label: '${exercise.name}, ${isDone ? "completed" : "not completed"}',
      child: AnimatedContainer(
        duration: AppTheme.kAnimFast,
        curve: AppTheme.kEaseOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone
              ? green.withValues(alpha: 0.06)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? green.withValues(alpha: 0.2)
                : AppTheme.subtleFill(context, 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Semantics(
              label: isDone ? 'Mark as incomplete' : 'Mark as complete',
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedContainer(
                    duration: AppTheme.kAnimFast,
                    curve: AppTheme.kEaseOutBack,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDone
                            ? green
                            : AppTheme.subtleFill(context, 0.30),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: isDone
                          ? green.withValues(alpha: 0.15)
                          : null,
                    ),
                    child: isDone
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.5, end: 1.0),
                            duration: AppTheme.kAnimFast,
                            curve: Curves.easeOutBack,
                            builder: (context, scale, _) => Transform.scale(
                              scale: scale,
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: green,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (setsReps.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      setsReps,
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: isDone
                      ? '${exercise.name} completed'
                      : 'Start exercise ${exercise.name}',
                  child: InkWell(
                    onTap: isDone ? null : onPlay,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: AppTheme.kAnimFast,
                      curve: AppTheme.kEaseOut,
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone
                            ? green.withValues(alpha: 0.12)
                            : AppTheme.subtleFill(context, 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.play_arrow_rounded,
                        size: 22,
                        color: isDone
                            ? green
                            : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  label: 'Show exercise info for ${exercise.name}',
                  child: InkWell(
                    onTap: onInfo,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.subtleFill(context, 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
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
