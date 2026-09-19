/// Helper class that provides week/month navigation logic.
/// Reduces duplication between hydration and step history screens.
class DateRangeNavigator {
  /// Calculate previous week start date.
  static DateTime previousWeekStart(DateTime currentWeekStart) {
    return currentWeekStart.subtract(const Duration(days: 7));
  }

  /// Calculate next week start date (if not in the future).
  static DateTime? nextWeekStart(DateTime currentWeekStart) {
    final next = currentWeekStart.add(const Duration(days: 7));
    if (next.isAfter(DateTime.now())) return null;
    return next;
  }

  /// Calculate previous month start date.
  static DateTime previousMonthStart(DateTime currentMonth) {
    return DateTime(currentMonth.year, currentMonth.month - 1, 1);
  }

  /// Calculate next month start date (if not in the future).
  static DateTime? nextMonthStart(DateTime currentMonth) {
    final next = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    if (next.isAfter(DateTime.now())) return null;
    return next;
  }

  /// Check if a date is in the future.
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Get the reference date for week data loading.
  static DateTime weekReferenceDate(DateTime weekStart) {
    return weekStart.add(const Duration(days: 3));
  }
}