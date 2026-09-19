import '../../models/step_data.dart';
import '../utils/date_utils.dart' show dateKey;

/// Pure business logic for step analytics.
/// These functions are independent of storage and can be tested without mocking.
class StepAnalytics {
  /// Computes weekly step data from entries and goal.
  static WeeklyStepData computeWeekData({
    required List<StepEntry> entries,
    required int goal,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
    final days = <DailyStepSummary>[];

    int totalSteps = 0;
    double totalDistance = 0;
    int totalCalories = 0;

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = dateKey(day);
      StepEntry? entry;
      for (final e in entries) {
        if (e.date == key) {
          entry = e;
          break;
        }
      }
      final steps = entry?.steps ?? 0;
      totalSteps += steps;
      totalDistance += entry?.distanceKm ?? 0;
      totalCalories += entry?.caloriesBurned ?? 0;
      days.add(
        DailyStepSummary(
          date: key,
          steps: steps,
          distanceKm: entry?.distanceKm ?? 0.0,
          caloriesBurned: entry?.caloriesBurned ?? 0,
          goalProgress: goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0,
        ),
      );
    }

    return WeeklyStepData(
      days: days,
      totalSteps: totalSteps,
      totalDistanceKm: totalDistance,
      totalCaloriesBurned: totalCalories,
      averageSteps: totalSteps / 7.0,
    );
  }

  /// Computes monthly step data from entries and goal.
  static MonthlyStepData computeMonthData({
    required List<StepEntry> entries,
    required int goal,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final firstOfMonth = DateTime(ref.year, ref.month, 1);
    final weeks = <WeeklyStepData>[];
    int totalSteps = 0;
    double totalDistance = 0;
    int totalCalories = 0;
    int activeDays = 0;

    DateTime weekStart = firstOfMonth;
    while (weekStart.month == ref.month ||
        weekStart.isBefore(firstOfMonth.add(const Duration(days: 7)))) {
      final weekData = computeWeekData(
        entries: entries,
        goal: goal,
        referenceDate: weekStart.add(const Duration(days: 3)),
      );
      if (weekData.days.any(
        (d) => d.date.startsWith(
          '${ref.year}-${ref.month.toString().padLeft(2, '0')}',
        ),
      )) {
        weeks.add(weekData);
        totalSteps += weekData.totalSteps;
        totalDistance += weekData.totalDistanceKm;
        totalCalories += weekData.totalCaloriesBurned;
        activeDays += weekData.days.where((d) => d.steps > 0).length;
      }
      weekStart = weekStart.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    final daysInMonth = ref.month == 12
        ? DateTime(ref.year + 1, 1, 0).day
        : DateTime(ref.year, ref.month + 1, 0).day;

    return MonthlyStepData(
      weeks: weeks,
      totalSteps: totalSteps,
      totalDistanceKm: totalDistance,
      totalCaloriesBurned: totalCalories,
      averageSteps: daysInMonth > 0 ? totalSteps / daysInMonth.toDouble() : 0.0,
      activeDays: activeDays,
    );
  }

  /// Computes last 7 days summary.
  static List<DailyStepSummary> computeLast7Days({
    required List<StepEntry> entries,
    required int goal,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final days = <DailyStepSummary>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = dateKey(day);
      StepEntry? entry;
      for (final e in entries) {
        if (e.date == key) {
          entry = e;
          break;
        }
      }
      final steps = entry?.steps ?? 0;
      days.add(
        DailyStepSummary(
          date: key,
          steps: steps,
          distanceKm: entry?.distanceKm ?? 0.0,
          caloriesBurned: entry?.caloriesBurned ?? 0,
          goalProgress: goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0,
        ),
      );
    }

    return days;
  }
}