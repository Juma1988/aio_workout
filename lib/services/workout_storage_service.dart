import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/weight_entry.dart';
import '../data/workout.dart';
import '../data/workout_log.dart';
import '../data/workout_plan.dart';

/// Whether [seedMockData] should generate fake records for development/testing.
/// Always false in release builds — users never see fabricated data.
bool _debugAllowMockData = false;

/// Returns the local date as a YYYY-MM-DD string, avoiding timezone ambiguity.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Thin wrapper around SharedPreferences with error-tolerant defaults.
///
/// Every read/write is wrapped in try/catch. On failure the method logs the
/// error and returns a safe default (empty list, zero, false, etc.) so the app
/// never crashes from a storage glitch. Write failures are silently swallowed
/// (the caller's optimistic UI already updated) but logged for debugging.
class WorkoutStorageService {
  static const _sessionsKey = 'workout_sessions';
  static const _programKey = 'program_progress';
  static const _todayDateKey = 'today_date';
  static const _todayStepsKey = 'today_steps';
  static const _todayHydrationKey = 'today_hydration';
  static const _todayUuidsKey = 'today_completed_uuids';

  static const _weightEntriesKey = 'weight_entries';
  static const _weightGoalKey = 'weight_goal_kg';
  static const _customWorkoutsKey = 'custom_workouts';
  static const _userPlansKey = 'user_workout_plans';

  static final WorkoutStorageService _instance =
      WorkoutStorageService._();
  factory WorkoutStorageService() => _instance;
  WorkoutStorageService._();

  String get _todayKey => dateKey(DateTime.now());

  // ── Sessions ──

  Future<List<WorkoutSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadSessions error: $e');
      return [];
    }
  }

  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(sessions.map((e) => e.toJson()).toList());
      await prefs.setString(_sessionsKey, raw);
    } catch (e) {
      debugPrint('saveSessions error: $e');
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    try {
      final sessions = await loadSessions();
      sessions.add(session);
      await saveSessions(sessions);
    } catch (e) {
      debugPrint('addSession error: $e');
    }
  }

  // ── Program progress ──

  Future<ProgramProgress> loadProgramProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_programKey);
      if (raw == null) return const ProgramProgress();
      return ProgramProgress.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('loadProgramProgress error: $e');
      return const ProgramProgress();
    }
  }

  Future<void> saveProgramProgress(ProgramProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_programKey, jsonEncode(progress.toJson()));
    } catch (e) {
      debugPrint('saveProgramProgress error: $e');
    }
  }

  // ── Today's transient state ──

  Future<int> loadTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_todayDateKey);
      if (savedDate != _todayKey) return 0;
      return prefs.getInt(_todayStepsKey) ?? 0;
    } catch (e) {
      debugPrint('loadTodaySteps error: $e');
      return 0;
    }
  }

  Future<double> loadTodayHydration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_todayDateKey);
      if (savedDate != _todayKey) return 0.0;
      return prefs.getDouble(_todayHydrationKey) ?? 0.0;
    } catch (e) {
      debugPrint('loadTodayHydration error: $e');
      return 0.0;
    }
  }

  Future<Set<String>> loadTodayCompletedUuids() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_todayDateKey);
      if (savedDate != _todayKey) return {};
      final raw = prefs.getStringList(_todayUuidsKey);
      return raw?.toSet() ?? {};
    } catch (e) {
      debugPrint('loadTodayCompletedUuids error: $e');
      return {};
    }
  }

  /// Loads saved completed exercise UUIDs from storage without checking
  /// the date key. Used at day-boundary to preserve partial workouts.
  Future<Set<String>> loadRawCompletedUuids() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_todayUuidsKey);
      return raw?.toSet() ?? {};
    } catch (e) {
      debugPrint('loadRawCompletedUuids error: $e');
      return {};
    }
  }

  Future<void> saveTodayState({
    required int steps,
    required double hydration,
    required Set<String> completedUuids,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_todayDateKey, _todayKey);
      await prefs.setInt(_todayStepsKey, steps);
      await prefs.setDouble(_todayHydrationKey, hydration);
      await prefs.setStringList(_todayUuidsKey, completedUuids.toList());
    } catch (e) {
      debugPrint('saveTodayState error: $e');
    }
  }

  Future<void> clearTodayState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_todayDateKey);
      await prefs.remove(_todayStepsKey);
      await prefs.remove(_todayHydrationKey);
      await prefs.remove(_todayUuidsKey);
    } catch (e) {
      debugPrint('clearTodayState error: $e');
    }
  }

  // ── Weight entries ──

  Future<List<WeightEntry>> loadWeightEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weightEntriesKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadWeightEntries error: $e');
      return [];
    }
  }

  Future<void> saveWeightEntries(List<WeightEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _weightEntriesKey,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('saveWeightEntries error: $e');
    }
  }

  Future<void> addWeightEntry(WeightEntry entry) async {
    try {
      final entries = await loadWeightEntries();
      final key = dateKey(entry.date);
      final existingIdx = entries.indexWhere(
        (e) => dateKey(e.date) == key,
      );
      if (existingIdx >= 0) {
        entries[existingIdx] = entry;
      } else {
        entries.add(entry);
      }
      await saveWeightEntries(entries);
    } catch (e) {
      debugPrint('addWeightEntry error: $e');
    }
  }

  Future<double?> loadWeightGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_weightGoalKey);
    } catch (e) {
      debugPrint('loadWeightGoal error: $e');
      return null;
    }
  }

  Future<void> saveWeightGoal(double kg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_weightGoalKey, kg);
    } catch (e) {
      debugPrint('saveWeightGoal error: $e');
    }
  }

  // ── Custom Workouts ──

  Future<List<Workout>> loadCustomWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customWorkoutsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Workout.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadCustomWorkouts error: $e');
      return [];
    }
  }

  Future<void> saveCustomWorkouts(List<Workout> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(workouts.map((e) => e.toJson()).toList());
      await prefs.setString(_customWorkoutsKey, raw);
    } catch (e) {
      debugPrint('saveCustomWorkouts error: $e');
    }
  }

  Future<void> addCustomWorkout(Workout workout) async {
    try {
      final workouts = await loadCustomWorkouts();
      workouts.add(workout);
      await saveCustomWorkouts(workouts);
    } catch (e) {
      debugPrint('addCustomWorkout error: $e');
    }
  }

  Future<void> updateCustomWorkout(Workout workout) async {
    try {
      final workouts = await loadCustomWorkouts();
      final idx = workouts.indexWhere((w) => w.uuid == workout.uuid);
      if (idx != -1) {
        workouts[idx] = workout;
        await saveCustomWorkouts(workouts);
      }
    } catch (e) {
      debugPrint('updateCustomWorkout error: $e');
    }
  }

  Future<void> deleteCustomWorkout(String uuid) async {
    try {
      final workouts = await loadCustomWorkouts();
      workouts.removeWhere((w) => w.uuid == uuid);
      await saveCustomWorkouts(workouts);
    } catch (e) {
      debugPrint('deleteCustomWorkout error: $e');
    }
  }

  // ── User Workout Plans (multi-week custom programs) ──

  Future<List<WorkoutPlan>> loadUserPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userPlansKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
          .where((p) => !p.isDefault)
          .toList();
    } catch (e) {
      debugPrint('loadUserPlans error: $e');
      return [];
    }
  }

  Future<void> saveUserPlans(List<WorkoutPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtered = plans.where((p) => !p.isDefault).toList();
      final raw = jsonEncode(filtered.map((e) => e.toJson()).toList());
      await prefs.setString(_userPlansKey, raw);
    } catch (e) {
      debugPrint('saveUserPlans error: $e');
    }
  }

  Future<void> upsertUserPlan(WorkoutPlan plan) async {
    if (plan.isDefault) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPlansKey);
    List<WorkoutPlan> plans = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        plans = list
            .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
            .where((p) => !p.isDefault)
            .toList();
      } catch (e) {
        debugPrint('upsertUserPlan parse error: $e');
        // Do not wipe existing data on parse failure.
        rethrow;
      }
    }
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx == -1) {
      plans.add(plan);
    } else {
      plans[idx] = plan;
    }
    final encoded = jsonEncode(plans.map((e) => e.toJson()).toList());
    await prefs.setString(_userPlansKey, encoded);
  }

  Future<void> deleteUserPlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPlansKey);
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List<dynamic>;
    final plans = list
        .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
        .where((p) => !p.isDefault && p.id != id)
        .toList();
    await prefs.setString(
      _userPlansKey,
      jsonEncode(plans.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> seedMockData() async {
    if (kReleaseMode || !_debugAllowMockData) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // ── Workout sessions (8 sessions over past ~20 days) ──
      const exercisePool = [
        ('ex-plank-001', 'Plank'),
        ('ex-pushups-001', 'Push Ups'),
        ('ex-squats-001', 'Bodyweight Squats'),
        ('ex-overheadpress-001', 'Overhead Press'),
        ('ex-jumpingjacks-001', 'Jumping Jacks'),
        ('ex-deadbug-001', 'Dead Bug'),
        ('ex-bicepcurls-001', 'Bicep Curls'),
        ('ex-highkneemarch-001', 'Gentle High-Knee March'),
        ('ex-glutebridge-001', 'Glute Bridge'),
        ('ex-birddog-001', 'Bird Dog'),
        ('ex-cocoons-001', 'Cocoons'),
        ('ex-sidelyinglegraise-001', 'Side-Lying Leg Raise'),
      ];

      final mockSessions = <Map<String, dynamic>>[];
      for (int i = 0; i < 8; i++) {
        final daysAgo = 20 - (i * 2);
        final date = DateTime(now.year, now.month, now.day - daysAgo,
            6 + (i % 12), (i * 13) % 60);
        final weekNum = ((20 - daysAgo) ~/ 7) + 1;
        final dayNum = (i % 4) + 1;
        final focus = getFocusForDay(weekNum, dayNum);

        final exerciseCount = 3 + (i % 3);
        final exercises = <Map<String, dynamic>>[];
        for (int e = 0; e < exerciseCount; e++) {
          final poolIdx = (i * 3 + e) % exercisePool.length;
          final (uuid, name) = exercisePool[poolIdx];
          exercises.add({
            'exerciseUuid': uuid,
            'exerciseName': name,
            'setsCompleted': 3 + (e % 3),
            'repsCompleted': 8 + (e * 2),
            'notes': '',
          });
        }

        mockSessions.add({
          'uuid': 'mock-session-$i',
          'date': date.toIso8601String(),
          'weekNumber': weekNum,
          'dayNumber': dayNum,
          'focus': focus,
          'durationSeconds': 1500 + (i * 180),
          'exercises': exercises,
          'plannedExerciseUuids': exercises.map((e) => e['exerciseUuid']).toList(),
          'steps': 0,
          'hydrationLiters': 0.0,
          'achievementsUnlocked': <String>[],
        });
      }
      await prefs.setString(_sessionsKey, jsonEncode(mockSessions));

      // ── Program progress ──
      await prefs.setString(_programKey, jsonEncode({
        'currentWeek': 3,
        'currentDay': 2,
        'lastAdvanceDate': _todayKey,
      }));

      // ── Today's state ──
      await prefs.setString(_todayDateKey, _todayKey);
      await prefs.setInt(_todayStepsKey, 7234);
      await prefs.setDouble(_todayHydrationKey, 1.8);
      await prefs.setStringList(_todayUuidsKey, []);

      // ── Weight entries (14 days trending down 70.0 → 68.5) ──
      final mockWeights = <Map<String, dynamic>>[];
      final baseWeight = 70.0;
      for (int i = 13; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i, 7, 0);
        final trend = baseWeight - (13 - i) * 0.1;
        final noise = (i % 3 - 1) * 0.15;
        mockWeights.add({
          'uuid': 'mock-weight-$i',
          'date': date.toIso8601String(),
          'weightKg': double.parse((trend + noise).toStringAsFixed(1)),
        });
      }
      await prefs.setString(_weightEntriesKey, jsonEncode(mockWeights));
      await prefs.setDouble(_weightGoalKey, 75.0);

      // ── Profile data ──
      await prefs.setString('profile_name', 'Alex Rivera');
      await prefs.setString('profile_email', 'alex@workout.dev');
      await prefs.remove('profile_avatar_path');
      await prefs.setInt('profile_age', 28);
      await prefs.setString('profile_goal', 'general_fitness');
      await prefs.setInt('rest_timer_seconds', 30);
      await prefs.setString('custom_exercises', '[]');
      await prefs.setBool('theme_is_dark', true);

      // ── Edit profile data ──
      await prefs.setDouble('profile_weight_kg', 70.0);
      await prefs.setDouble('profile_height_cm', 175.0);
      await prefs.setString('profile_gender', 'male');
      await prefs.setString('profile_dob', '1997-01-15');

      // ── Home section visibility (all visible) ──
      for (final key in ['show_steps', 'show_achievements', 'show_hydration', 'show_weight_trend']) {
        await prefs.setBool(key, true);
      }

      // ── Notification preferences (defaults) ──
      await prefs.setBool('notifications_master', true);
      await prefs.setBool('notifications_daily_reminder', true);
      await prefs.setInt('notifications_daily_hour', 8);
      await prefs.setInt('notifications_daily_minute', 0);
      await prefs.setBool('notifications_missed_workout', false);
      await prefs.setBool('notifications_achievement', true);
      await prefs.setBool('notifications_recovery', true);
      await prefs.setBool('notifications_weekly_progress', true);
      await prefs.setInt('notifications_weekly_day', DateTime.monday);
      await prefs.setInt('notifications_weekly_hour', 10);
      await prefs.setInt('notifications_weekly_minute', 0);
      await prefs.setBool('notifications_weight_follow_up', false);
      await prefs.setDouble('notifications_weight_target', 75.0);
      await prefs.setInt('notifications_weight_interval_days', 3);
      await prefs.setBool('notifications_quiet_hours_enabled', false);
      await prefs.setString('notifications_language', 'en');
      await prefs.setBool('notifications_use_metric', true);

      debugPrint('[seed] Mock data written for all keys');
    } catch (e) {
      debugPrint('seedMockData error: $e');
    }
  }
}
