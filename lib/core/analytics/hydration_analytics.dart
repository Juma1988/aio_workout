import '../../models/hydration_data.dart';
import '../utils/date_utils.dart' show dateKey;

/// Pure business logic for hydration analytics.
/// These functions are independent of storage and can be tested without mocking.
class HydrationAnalytics {
  /// Computes the current streak of consecutive days meeting the goal.
  static int computeStreak({
    required List<HydrationEntry> entries,
    required double goal,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final key = dateKey(day);
      final dayEntries = entries.where((e) => e.date == key).toList();
      final total = dayEntries.fold(0.0, (sum, e) => sum + e.liters);
      if (total >= goal) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Computes weekly hydration data from entries and goal.
  static WeeklyHydrationData computeWeekData({
    required List<HydrationEntry> entries,
    required double goal,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
    final days = <DailyHydrationSummary>[];

    double totalLiters = 0;
    double totalGoalLiters = 0;
    int daysMetGoal = 0;

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = dateKey(day);
      final dayEntries = entries.where((e) => e.date == key).toList();
      final daySummary = DailyHydrationSummary.fromEntries(key, dayEntries, goal);
      days.add(daySummary);
      totalLiters += daySummary.totalLiters;
      totalGoalLiters += goal;
      if (daySummary.goalProgress >= 1.0) {
        daysMetGoal++;
      }
    }

    return WeeklyHydrationData(
      days: days,
      totalLiters: totalLiters,
      totalGoalLiters: totalGoalLiters,
      averageDailyLiters: totalLiters / 7.0,
      daysMetGoal: daysMetGoal,
    );
  }

  /// Computes monthly hydration data from entries and goal.
  static MonthlyHydrationData computeMonthData({
    required List<HydrationEntry> entries,
    required double goal,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final firstOfMonth = DateTime(ref.year, ref.month, 1);
    final weeks = <WeeklyHydrationData>[];
    double totalLiters = 0;
    double totalGoalLiters = 0;
    int activeDays = 0;
    int daysMetGoal = 0;

    DateTime weekStart = firstOfMonth;
    while (weekStart.month == ref.month || weekStart.isBefore(firstOfMonth.add(const Duration(days: 7)))) {
      final weekData = computeWeekData(
        entries: entries,
        goal: goal,
        referenceDate: weekStart.add(const Duration(days: 3)),
      );
      if (weekData.days.any((d) => d.date.startsWith('${ref.year}-${ref.month.toString().padLeft(2, '0')}'))) {
        weeks.add(weekData);
        totalLiters += weekData.totalLiters;
        totalGoalLiters += weekData.totalGoalLiters;
        activeDays += weekData.days.where((d) => d.totalLiters > 0).length;
        daysMetGoal += weekData.daysMetGoal;
      }
      weekStart = weekStart.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    final daysInMonth = ref.month == 12
        ? DateTime(ref.year + 1, 1, 0).day
        : DateTime(ref.year, ref.month + 1, 0).day;

    return MonthlyHydrationData(
      weeks: weeks,
      totalLiters: totalLiters,
      totalGoalLiters: totalGoalLiters,
      averageDailyLiters: daysInMonth > 0 ? totalLiters / daysInMonth.toDouble() : 0.0,
      activeDays: activeDays,
      daysMetGoal: daysMetGoal,
    );
  }

  /// Computes breakdown by source for given entries.
  static Map<HydrationSource, double> computeBreakdown(List<HydrationEntry> entries) {
    final map = <HydrationSource, double>{};
    for (final e in entries) {
      map.update(e.source, (v) => v + e.liters, ifAbsent: () => e.liters);
    }
    return map;
  }
}