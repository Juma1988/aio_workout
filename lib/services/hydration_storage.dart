import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hydration_data.dart';
import '../core/utils/date_utils.dart' show dateKey;
import '../core/analytics/hydration_analytics.dart';

class HydrationStorage {
  static const _hydrationHistoryKey = 'hydration_history';
  static const _dailyGoalKey = 'hydration_daily_goal';

  static final HydrationStorage _instance = HydrationStorage._();
  factory HydrationStorage() => _instance;
  HydrationStorage._();

  /// Loads all stored hydration entries.
  Future<List<HydrationEntry>> loadAllEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_hydrationHistoryKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HydrationEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('HydrationStorage.loadAllEntries error: $e');
      return [];
    }
  }

  /// Persists the full list of entries.
  Future<void> saveAllEntries(List<HydrationEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_hydrationHistoryKey, raw);
    } catch (e) {
      debugPrint('HydrationStorage.saveAllEntries error: $e');
    }
  }

  /// Adds a single drink entry (always appends — never replaces).
  Future<void> addDrink(HydrationEntry entry) async {
    try {
      final entries = await loadAllEntries();
      entries.add(entry);
      await saveAllEntries(entries);
    } catch (e) {
      debugPrint('HydrationStorage.addDrink error: $e');
    }
  }

  /// Removes a specific drink entry by id.
  Future<void> removeDrink(String id) async {
    try {
      final entries = await loadAllEntries();
      entries.removeWhere((e) => e.id == id);
      await saveAllEntries(entries);
    } catch (e) {
      debugPrint('HydrationStorage.removeDrink error: $e');
    }
  }

  /// Returns all entries for a given date key (yyyy-MM-dd).
  Future<List<HydrationEntry>> loadEntriesForDate(String date) async {
    final entries = await loadAllEntries();
    return entries.where((e) => e.date == date).toList();
  }

  /// Returns the sum total of all liters recorded today.
  Future<double> loadTodayHydration() async {
    final today = dateKey(DateTime.now());
    final entries = await loadEntriesForDate(today);
    double total = 0.0;
    for (final e in entries) {
      total += e.liters;
    }
    return total;
  }

  /// Saves a quick hydration entry for today using a simple amount.
  Future<void> saveTodayHydration(double liters) async {
    final today = dateKey(DateTime.now());
    await addDrink(HydrationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: today,
      timestamp: DateTime.now(),
      liters: liters,
      source: HydrationSource.water,
    ));
  }

  /// Persists a drink entry with full details (source, notes).
  Future<void> logDrink({
    required double liters,
    HydrationSource source = HydrationSource.water,
    String notes = '',
  }) async {
    final today = dateKey(DateTime.now());
    await addDrink(HydrationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: today,
      timestamp: DateTime.now(),
      liters: liters,
      source: source,
      notes: notes,
    ));
  }

  // ── Daily Goal ──

  Future<double> loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_dailyGoalKey) ?? 2.5;
    } catch (e) {
      return 2.5;
    }
  }

  Future<void> saveDailyGoal(double goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_dailyGoalKey, goal);
    } catch (e) {
      debugPrint('HydrationStorage.saveDailyGoal error: $e');
    }
  }

  // ── Today's summary ──

  Future<DailyHydrationSummary> loadTodaySummary() async {
    final today = dateKey(DateTime.now());
    final goal = await loadDailyGoal();
    final entries = await loadEntriesForDate(today);
    return DailyHydrationSummary.fromEntries(today, entries, goal);
  }

  // ── Week / Month data ──

  Future<WeeklyHydrationData> loadWeekData({DateTime? referenceDate}) async {
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
    return HydrationAnalytics.computeWeekData(
      entries: entries,
      goal: goal,
      referenceDate: referenceDate,
    );
  }

  Future<MonthlyHydrationData> loadMonthData({DateTime? referenceDate}) async {
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
    return HydrationAnalytics.computeMonthData(
      entries: entries,
      goal: goal,
      referenceDate: referenceDate,
    );
  }

  Future<List<DailyHydrationSummary>> loadLast7Days() async {
    final now = DateTime.now();
    final entries = await loadAllEntries();
    final goal = await loadDailyGoal();
    final days = <DailyHydrationSummary>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = dateKey(day);
      final dayEntries = entries.where((e) => e.date == key).toList();
      days.add(DailyHydrationSummary.fromEntries(key, dayEntries, goal));
    }

    return days;
  }

  // ── Streak computation ──

  /// Computes the current streak of consecutive days meeting the goal.
  Future<int> computeStreak() async {
    final entries = await loadAllEntries();
    final goal = await loadDailyGoal();
    return HydrationAnalytics.computeStreak(
      entries: entries,
      goal: goal,
    );
  }

  // ── Today's drinks breakdown by source ──

  Future<Map<HydrationSource, double>> loadTodayBreakdown() async {
    final today = dateKey(DateTime.now());
    final entries = await loadEntriesForDate(today);
    return HydrationAnalytics.computeBreakdown(entries);
  }

  // ── Mock data ──

  Future<void> seedMockData() async {
    if (kReleaseMode || !kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final mockEntries = <Map<String, dynamic>>[];
      int idCounter = 0;
      for (int i = 13; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final baseDate = dateKey(date);
        final numDrinks = 3 + (i % 3);
        for (int d = 0; d < numDrinks; d++) {
          final amount = [0.25, 0.25, 0.5, 0.3, 0.2][d % 5];
          mockEntries.add({
            'id': 'mock-hydration-${idCounter++}',
            'date': baseDate,
            'timestamp': DateTime(
              date.year, date.month, date.day,
              8 + d * 3, (d * 17) % 60,
            ).toIso8601String(),
            'liters': amount,
            'source': HydrationSource.values[(i + d) % HydrationSource.values.length].name,
            'notes': '',
          });
        }
      }
      await prefs.setString(_hydrationHistoryKey, jsonEncode(mockEntries));
      await prefs.setDouble(_dailyGoalKey, 2.5);

      debugPrint('[seed] Mock hydration data written (${mockEntries.length} entries)');
    } catch (e) {
      debugPrint('seedMockData error: $e');
    }
  }
}
