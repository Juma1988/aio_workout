import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/exercise_localizer.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart';

class WorkoutPlanDialog extends StatefulWidget {
  const WorkoutPlanDialog({super.key});

  @override
  State<WorkoutPlanDialog> createState() => _WorkoutPlanDialogState();
}

class _WorkoutPlanDialogState extends State<WorkoutPlanDialog> {
  ProgramProgress _progress = const ProgramProgress();
  int _totalWorkouts = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = WorkoutStorageService();
    final progress = await service.loadProgramProgress();
    final sessions = await service.loadSessions();
    if (mounted) {
      setState(() {
        _progress = progress;
        _totalWorkouts = sessions.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dialog_workoutPlanTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildProgressCard(context),
        const SizedBox(height: 20),
        Text(
          l10n.dialog_12WeekProgram,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(12, (i) {
          final week = i + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _WeekPlanCard(
              week: week,
              isCurrentWeek: week == _progress.currentWeek,
              completedWorkouts: _completedWorkoutsInWeek(week),
            ),
          );
        }),
      ],
    );
  }

  int _completedWorkoutsInWeek(int week) {
    return 0;
  }

  Widget _buildProgressCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = _getPhase(l10n, _progress.currentWeek);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.route,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dialog_weekDayDisplay(_progress.currentWeek, _progress.currentDay),
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phase,
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_totalWorkouts',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      l10n.dialog_workoutsLabel,
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_progress.currentWeek / 12).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppTheme.subtleFill(context),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(
                    l10n.dialog_weekLabel(1),
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 11,
                  ),
                ),
                  Text(
                    l10n.dialog_weekLabel(12),
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPhase(AppLocalizations l10n, int week) {
    if (week <= 4) return l10n.dialog_foundationPhase;
    if (week <= 8) return l10n.dialog_buildingPhase;
    return l10n.dialog_peakPhase;
  }
}

class _WeekPlanCard extends StatelessWidget {
  final int week;
  final bool isCurrentWeek;
  final int completedWorkouts;

  const _WeekPlanCard({
    required this.week,
    this.isCurrentWeek = false,
    this.completedWorkouts = 0,
  });

  String _getPhase(AppLocalizations l10n, int w) {
    if (w <= 4) return l10n.dialog_foundation;
    if (w <= 8) return l10n.dialog_building;
    return l10n.dialog_peak;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = _getPhase(l10n, week);
    final phaseColors = <String, Color>{
      l10n.dialog_foundation: AppTheme.achievementGreen,
      l10n.dialog_building: AppTheme.stepsOrange,
      l10n.dialog_peak: AppTheme.hydrationBlue,
    };
    final color = phaseColors[phase]!;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentWeek
              ? color.withValues(alpha: 0.5)
              : AppTheme.subtleFill(context, 0.08),
          width: isCurrentWeek ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrentWeek
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.subtleFill(context, 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'W$week',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCurrentWeek
                            ? color
                            : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                  Text(
                    l10n.dialog_weekLabel(week),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (isCurrentWeek) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.dialog_current,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleFill(context, 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    phase,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(7, (i) {
              final day = i + 1;
              final rest = isRestDay(day);
              final focus = getFocusForDay(week, day);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rest
                            ? AppTheme.subtleFill(context, 0.04)
                            : AppTheme.subtleFill(context, 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'D$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: rest
                              ? AppTheme.textDisabled(context)
                              : AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ExerciseLocalizer.focusName(l10n, focus),
                        style: TextStyle(
                          fontSize: 13,
                          color: rest
                              ? AppTheme.textDisabled(context)
                              : AppTheme.textPrimary(context),
                          fontStyle:
                              rest ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    if (rest)
                      Icon(
                        Icons.nightlight_round,
                        size: 14,
                        color: AppTheme.textDisabled(context),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
