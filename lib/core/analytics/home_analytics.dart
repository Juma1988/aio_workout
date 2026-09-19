import '../../data/weight_entry.dart';
import '../../data/workout_log.dart';
import '../clock.dart';
import '../../features/home/models/trend_info.dart';

/// Pure business logic for home screen analytics.
/// These functions are independent of UI and can be tested without widgets.
class HomeAnalytics {
  /// Computes weekly workout levels (0.0 to 1.0) for each day of the week.
  static List<double> computeWeeklyLevels({
    required List<WorkoutSession>? sessions,
    required Clock clock,
  }) {
    if (sessions == null || sessions.isEmpty) {
      return List.filled(7, 0.0);
    }

    final now = clock.now();
    final weekday = now.weekday; // 1=Mon .. 7=Sun
    final monday = now.subtract(Duration(days: weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = mondayDate.add(const Duration(days: 7));

    final levels = List.filled(7, 0.0);
    for (final s in sessions) {
      if (s.date.isBefore(mondayDate) || s.date.isAfter(weekEnd)) continue;
      final dayIdx = s.date.weekday - 1; // 0=Mon..6=Sun
      if (isRestDay(s.dayNumber)) {
        levels[dayIdx] = 1.0;
      } else {
        final planned = s.plannedExerciseUuids.length;
        if (planned == 0) {
          levels[dayIdx] = 1.0;
        } else {
          levels[dayIdx] = (s.exercises.length / planned).clamp(0.0, 1.0);
        }
      }
    }

    return levels;
  }

  /// Computes total exercises completed this week.
  static int computeTotalExercises({
    required List<WorkoutSession>? sessions,
    required Clock clock,
  }) {
    final now = clock.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = mondayDate.add(const Duration(days: 7));

    return (sessions ?? [])
        .where((s) =>
            !s.date.isBefore(mondayDate) && !s.date.isAfter(weekEnd))
        .fold<int>(0, (sum, s) => sum + s.exercises.length);
  }

  /// Computes weight trend from entries.
  static TrendInfo computeTrend({
    required List<WeightEntry> entries,
    required Clock clock,
  }) {
    if (entries.length < 2) return TrendInfo.none();

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weekAgo = clock.now().subtract(const Duration(days: 7));
    final weekEntries = sorted.where((e) => e.date.isAfter(weekAgo)).toList();

    if (weekEntries.length >= 2) {
      final current = weekEntries.last.weightKg;
      final previous = weekEntries.first.weightKg;
      return TrendInfo(
        changeKg: current - previous,
        period: 'this week',
      );
    }

    final last = sorted.last.weightKg;
    final prev = sorted[sorted.length - 2].weightKg;
    return TrendInfo(
      changeKg: last - prev,
      period: 'last entry',
    );
  }

  /// Checks if all exercises for today are completed.
  static bool areAllExercisesDone({
    required int currentDay,
    required Set<String> completedUuids,
  }) {
    final exercises = getTodayExercises(currentDay);
    return exercises.isNotEmpty &&
        exercises.every((e) => completedUuids.contains(e.uuid));
  }
}