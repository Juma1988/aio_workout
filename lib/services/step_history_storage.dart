import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/step_data.dart';
import '../../services/workout_storage_service.dart' show dateKey;

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
    await saveEntry(StepEntry(
      date: today,
      steps: steps,
      distanceKm: distanceKm,
      caloriesBurned: calories,
    ));
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
    final ref = referenceDate ?? DateTime.now();
    final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
    final goal = await loadDailyGoal();
    final entries = await loadAllEntries();
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
      days.add(DailyStepSummary(
        date: key,
        steps: steps,
        distanceKm: entry?.distanceKm ?? 0.0,
        caloriesBurned: entry?.caloriesBurned ?? 0,
        goalProgress: goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0,
      ));
    }

    return WeeklyStepData(
      days: days,
      totalSteps: totalSteps,
      totalDistanceKm: totalDistance,
      totalCaloriesBurned: totalCalories,
      averageSteps: totalSteps / 7.0,
    );
  }

  Future<MonthlyStepData> loadMonthData({DateTime? referenceDate}) async {
    final ref = referenceDate ?? DateTime.now();
    final firstOfMonth = DateTime(ref.year, ref.month, 1);
    final weeks = <WeeklyStepData>[];
    int totalSteps = 0;
    double totalDistance = 0;
    int totalCalories = 0;
    int activeDays = 0;

    DateTime weekStart = firstOfMonth;
    while (weekStart.month == ref.month || weekStart.isBefore(firstOfMonth.add(const Duration(days: 7)))) {
      final weekData = await loadWeekData(referenceDate: weekStart.add(const Duration(days: 3)));
      if (weekData.days.any((d) => d.date.startsWith('${ref.year}-${ref.month.toString().padLeft(2, '0')}'))) {
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

  Future<List<DailyStepSummary>> loadLast7Days() async {
    final now = DateTime.now();
    final entries = await loadAllEntries();
    final goal = await loadDailyGoal();
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
      days.add(DailyStepSummary(
        date: key,
        steps: steps,
        distanceKm: entry?.distanceKm ?? 0.0,
        caloriesBurned: entry?.caloriesBurned ?? 0,
        goalProgress: goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0,
      ));
    }

    return days;
  }
}
