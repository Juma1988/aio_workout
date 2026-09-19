import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/step_data.dart';
import '../core/utils/date_utils.dart' show dateKey;
import '../core/analytics/step_analytics.dart';

class StepHistoryStorage {
  static const _stepHistoryKey = 'step_history';
  static const _dailyGoalKey = 'steps_daily_goal';
  static const _useSensorKey = 'steps_use_sensor';

  static final StepHistoryStorage _instance = StepHistoryStorage._();
  factory StepHistoryStorage() => _instance;
  StepHistoryStorage._();

  Future<List<StepEntry>> loadAllEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stepHistoryKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => StepEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('StepHistoryStorage.loadAllEntries error: $e');
      return [];
    }
  }

  Future<void> saveAllEntries(List<StepEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_stepHistoryKey, raw);
    } catch (e) {
      debugPrint('StepHistoryStorage.saveAllEntries error: $e');
    }
  }

  Future<void> saveEntry(StepEntry entry) async {
    try {
      final entries = await loadAllEntries();
      final idx = entries.indexWhere((e) => e.date == entry.date);
      if (idx >= 0) {
        entries[idx] = entry;
      } else {
        entries.add(entry);
      }
      await saveAllEntries(entries);
    } catch (e) {
      debugPrint('StepHistoryStorage.saveEntry error: $e');
    }
  }

  Future<StepEntry?> loadEntryForDate(String date) async {
    try {
      final entries = await loadAllEntries();
      for (final e in entries) {
        if (e.date == date) return e;
      }
      return null;
    } catch (e) {
      debugPrint('StepHistoryStorage.loadEntryForDate error: $e');
      return null;
    }
  }

  Future<int> loadTodaySteps() async {
    final today = dateKey(DateTime.now());
    final entry = await loadEntryForDate(today);
    return entry?.steps ?? 0;
  }

  Future<void> saveTodaySteps(int steps) async {
    final today = dateKey(DateTime.now());
    final distanceKm = StepEntry.stepsToDistanceKm(steps);
    final calories = StepEntry.stepsToCalories(steps);
    await saveEntry(
      StepEntry(
        date: today,
        steps: steps,
        distanceKm: distanceKm,
        caloriesBurned: calories,
      ),
    );
  }

  Future<int> loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_dailyGoalKey) ?? 10000;
    } catch (e) {
      return 10000;
    }
  }

  Future<void> saveDailyGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyGoalKey, goal);
    } catch (e) {
      debugPrint('StepHistoryStorage.saveDailyGoal error: $e');
    }
  }

  Future<bool> loadUseSensor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useSensorKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> saveUseSensor(bool use) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useSensorKey, use);
    } catch (e) {
      debugPrint('StepHistoryStorage.saveUseSensor error: $e');
    }
  }

  Future<DailyStepSummary> loadTodaySummary() async {
    final today = dateKey(DateTime.now());
    final entry = await loadEntryForDate(today);
    final goal = await loadDailyGoal();
    final steps = entry?.steps ?? 0;
    return DailyStepSummary(
      date: today,
      steps: steps,
      distanceKm: entry?.distanceKm ?? 0.0,
      caloriesBurned: entry?.caloriesBurned ?? 0,
      goalProgress: goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0,
    );
  }

  Future<WeeklyStepData> loadWeekData({DateTime? referenceDate}) async {
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
    return StepAnalytics.computeWeekData(
      entries: entries,
      goal: goal,
      referenceDate: referenceDate,
    );
  }

  Future<MonthlyStepData> loadMonthData({DateTime? referenceDate}) async {
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
    return StepAnalytics.computeMonthData(
      entries: entries,
      goal: goal,
      referenceDate: referenceDate,
    );
  }

  Future<List<DailyStepSummary>> loadLast7Days() async {
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
    return StepAnalytics.computeLast7Days(
      entries: entries,
      goal: goal,
    );
  }
}
