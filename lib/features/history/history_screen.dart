import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/workout_log.dart';
import '../../services/workout_storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _loading = true;
  ProgramProgress _progress = const ProgramProgress();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = WorkoutStorageService();
    final sessions = await service.loadSessions();
    final progress = await service.loadProgramProgress();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _progress = progress;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'History',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Week ${_progress.currentWeek} \u2022 Day ${_progress.currentDay}',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_sessions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: AppTheme.textDisabled(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No workouts yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete your first workout to see it here',
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _buildWeeklyList(context),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyList(BuildContext context) {
    final grouped = <int, List<WorkoutSession>>{};
    for (final s in _sessions) {
      grouped.putIfAbsent(s.weekNumber, () => []);
      grouped[s.weekNumber]!.add(s);
    }
    final weeks = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final week = weeks[index];
        final weekSessions = grouped[week]!;
        return _WeekCard(
          week: week,
          sessions: weekSessions,
          onSessionTap: (s) => _showSessionDetail(context, s),
        );
      },
    );
  }

  void _showSessionDetail(BuildContext context, WorkoutSession session) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.achievementGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.focus,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Week ${session.weekNumber} \u2022 Day ${session.dayNumber}',
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(
              context,
              Icons.timer_outlined,
              _formatDuration(session.durationSeconds),
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              Icons.fitness_center,
              '${session.exercises.length} exercises',
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              Icons.repeat,
              '${session.totalSets} total sets',
            ),
            if (session.steps > 0) ...[
              const SizedBox(height: 8),
              _detailRow(
                context,
                Icons.directions_run,
                '${session.steps} steps',
                color: AppTheme.stepsOrange,
              ),
            ],
            if (session.hydrationLiters > 0) ...[
              const SizedBox(height: 8),
              _detailRow(
                context,
                Icons.water_drop,
                '${session.hydrationLiters.toStringAsFixed(1)}L water',
                color: AppTheme.hydrationBlue,
              ),
            ],
            const SizedBox(height: 8),
            _detailRow(
              context,
              Icons.calendar_today,
              _formatDate(session.date),
            ),
            if (session.achievementsUnlocked.isNotEmpty) ...[
              const SizedBox(height: 16),
              _detailRow(
                context,
                Icons.emoji_events,
                '${session.achievementsUnlocked.length} achievement${session.achievementsUnlocked.length > 1 ? 's' : ''}',
                color: AppTheme.achievementGreen,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: session.achievementsUnlocked.map((id) {
                  final def = allAchievementDefinitions
                      .where((a) => a.id == id)
                      .firstOrNull;
                  if (def == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.achievementGreen
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(def.icon,
                            size: 14,
                            color: AppTheme.achievementGreen),
                        const SizedBox(width: 4),
                        Text(
                          def.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.achievementGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (session.exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Exercises',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ...session.exercises.map(
                (ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.achievementGreen
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.exerciseName,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${ex.setsCompleted} sets${ex.repsCompleted != null ? ' \u00d7 ${ex.repsCompleted} reps' : ''}${ex.durationSeconds != null ? ' ${ex.durationSeconds}s' : ''}',
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (session.plannedExerciseUuids.length >
                  session.exercises.length) ...[
                const SizedBox(height: 6),
                _detailRow(
                  context,
                  Icons.remove_red_eye,
                  '${session.plannedExerciseUuids.length - session.exercises.length} exercise${session.plannedExerciseUuids.length - session.exercises.length > 1 ? 's' : ''} not completed',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.textSecondary(context)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0) return '${min}min ${sec}s';
    return '${sec}s';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _WeekCard extends StatefulWidget {
  final int week;
  final List<WorkoutSession> sessions;
  final void Function(WorkoutSession) onSessionTap;

  const _WeekCard({
    required this.week,
    required this.sessions,
    required this.onSessionTap,
  });

  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  bool _expanded = true;

  int get _completedDays => widget.sessions.length;
  int get _totalDuration =>
      widget.sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppTheme.subtleFill(context, 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: _expanded
                  ? Radius.zero
                  : const Radius.circular(14),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'W${widget.week}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${widget.week}',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_completedDays workouts \u2022 ${_formatDuration(_totalDuration)}',
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: AppTheme.kAnimFast,
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppTheme.kAnimMedium,
            curve: AppTheme.kEaseOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildDaysList(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList(BuildContext context) {
    final sessionDays = {
      for (final s in widget.sessions) s.dayNumber: s,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: List.generate(7, (i) {
          final day = i + 1;
          final session = sessionDays[day];
          final isRestDay = day > 4;

          if (isRestDay) {
            return _buildRestDayTile(context, day);
          }
          if (session != null) {
            return _buildSessionTile(context, session);
          }
          return _buildEmptyDayTile(context, day);
        }),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, WorkoutSession session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: AppTheme.subtleFill(context, 0.04),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onSessionTap(session),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppTheme.achievementGreen,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.subtleFill(context, 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'D${session.dayNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    session.focus,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(session.durationSeconds),
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppTheme.textDisabled(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDayTile(BuildContext context, int day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.subtleFill(context, 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.subtleFill(context, 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'D$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDisabled(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Not completed',
              style: TextStyle(
                color: AppTheme.textDisabled(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayTile(BuildContext context, int day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.subtleFill(context, 0.02),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 18,
              color: AppTheme.textDisabled(context),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'D$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDisabled(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Rest Day',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    if (min > 0) return '${min}min';
    return '${seconds}s';
  }
}
