import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/clock.dart';
import '../../../data/workout_log.dart' as legacy;
import '../../../data/weight_entry.dart';
import '../../../services/workout_storage_service.dart';
import '../models/achievement_category.dart';
import '../models/achievement_definition.dart';
import '../models/achievement_progress_snapshot.dart';
import '../models/achievement_result.dart';
import '../models/achievement_state.dart';
import '../models/all_achievement_definitions.dart';
import '../models/unlocked_achievement.dart';
import 'achievement_storage.dart';

class AchievementService {
  final AchievementStorage storage;
  final Clock clock;
  final WorkoutStorageService workoutStorage;

  AchievementState? _cachedState;

  AchievementService({
    required this.storage,
    required this.clock,
    required this.workoutStorage,
  });

  List<AchievementDefinition> get definitions => allAchievementDefinitions;

  AchievementState get state =>
      _cachedState ?? AchievementState.empty();

  int get unlockedCount => state.unlocked.length;

  int get totalCount => definitions.length;

  Set<String> get unlockedIds => state.unlockedIds;

  // ── Initialization ──

  Future<void> initialize() async {
    _cachedState = await storage.loadState();
    final migrated = await storage.hasMigrationRun();
    if (!migrated) {
      await _runMigration();
    }
  }

  Future<void> _runMigration() async {
    try {
      final sessions = await workoutStorage.loadSessions();
      final progress = await workoutStorage.loadProgramProgress();
      final weightEntries = await workoutStorage.loadWeightEntries();
      final prefs = await SharedPreferences.getInstance();

      final unlocked = <UnlockedAchievement>[];
      final completedWeeks =
          sessions.map((s) => s.weekNumber).toSet().length;
      final totalWorkouts = sessions.length;
      final totalSets =
          sessions.fold(0, (sum, s) => sum + s.totalSets);
      final coreWorkouts = sessions
          .where((s) => s.focus.toLowerCase().contains('core'))
          .length;
      final upperWorkouts = sessions
          .where((s) => s.focus.toLowerCase().contains('upper'))
          .length;
      final lowerWorkouts = sessions
          .where((s) => s.focus.toLowerCase().contains('lower'))
          .length;
      final fullBodyWorkouts = sessions
          .where((s) => s.focus.toLowerCase().contains('full'))
          .length;
      final week1Sessions =
          sessions.where((s) => s.weekNumber == 1).length;

      int maxStreak = 0;
      int currentStreak = 0;
      DateTime? prevDate;
      final sorted = List<legacy.WorkoutSession>.from(sessions)
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final s in sorted) {
        if (prevDate == null) {
          currentStreak = 1;
        } else {
          final diff = s.date.difference(prevDate).inDays;
          if (diff <= 2) {
            currentStreak++;
          } else {
            currentStreak = 1;
          }
        }
        prevDate = s.date;
        maxStreak = max(maxStreak, currentStreak);
      }

      final totalSteps =
          sessions.fold(0, (sum, s) => sum + s.steps);
      final totalHydration =
          sessions.fold<double>(0.0, (sum, s) => sum + s.hydrationLiters);

      // Legacy achievement check
      void tryUnlock(
          String id, bool condition, String by, [String? sid]) {
        if (condition) {
          unlocked.add(UnlockedAchievement(
            achievementId: id,
            unlockedAt: clock.now(),
            unlockedBy: by,
            sessionId: sid,
          ));
        }
      }

      tryUnlock('first_steps', totalWorkouts >= 1, 'workout_completed');
      tryUnlock(
          'workout_10', totalWorkouts >= 10, 'workout_completed');
      tryUnlock(
          'workout_25', totalWorkouts >= 25, 'workout_completed');
      tryUnlock(
          'workout_50', totalWorkouts >= 50, 'workout_completed');
      tryUnlock(
          'workout_100', totalWorkouts >= 100, 'workout_completed');
      tryUnlock('core_crusher', coreWorkouts >= 10, 'workout_completed');
      tryUnlock('upper_champ', upperWorkouts >= 10, 'workout_completed');
      tryUnlock('lower_legend', lowerWorkouts >= 10, 'workout_completed');
      tryUnlock('full_fusion', fullBodyWorkouts >= 10, 'workout_completed');
      tryUnlock('volume_100', totalSets >= 100, 'workout_completed');
      tryUnlock('volume_500', totalSets >= 500, 'workout_completed');
      tryUnlock('volume_1000', totalSets >= 1000, 'workout_completed');
      tryUnlock(
          'week_warrior',
          completedWeeks >= 1 && week1Sessions >= 4,
          'workout_completed');
      tryUnlock('dedicated', completedWeeks >= 4, 'workout_completed');
      tryUnlock('halfway', completedWeeks >= 6, 'workout_completed');
      tryUnlock('graduate', completedWeeks >= 12, 'workout_completed');
      tryUnlock('streak_5', maxStreak >= 5, 'workout_completed');
      tryUnlock('steps_10k', totalSteps >= 10000, 'steps_updated');
      tryUnlock('steps_50k', totalSteps >= 50000, 'steps_updated');
      tryUnlock('steps_100k', totalSteps >= 100000, 'steps_updated');
      tryUnlock('steps_500k', totalSteps >= 500000, 'steps_updated');
      tryUnlock('water_10L', totalHydration >= 10, 'hydration_updated');
      tryUnlock('water_50L', totalHydration >= 50, 'hydration_updated');
      tryUnlock('water_100L', totalHydration >= 100, 'hydration_updated');
      tryUnlock(
          'first_weight', weightEntries.isNotEmpty, 'weight_logged');
      tryUnlock('weight_consistent', weightEntries.length >= 7,
          'weight_logged');
      final weightGoal = prefs.getDouble('weight_goal_kg');
      tryUnlock(
          'goal_setter', weightGoal != null && weightGoal > 0, 'profile_updated');

      // Build progress snapshots
      final progressMap = <String, AchievementProgressSnapshot>{};
      final now = clock.now();
      for (final def in definitions) {
        final current = _currentFor(def, totalWorkouts, totalSets,
            coreWorkouts, upperWorkouts, lowerWorkouts, fullBodyWorkouts,
            completedWeeks, week1Sessions, maxStreak, totalSteps,
            totalHydration, weightEntries.length, progress.currentWeek);
        if (current > 0) {
          progressMap[def.id] = AchievementProgressSnapshot(
            current: min(current, def.target),
            target: def.target,
            updatedAt: now,
          );
        }
      }

      _cachedState = AchievementState(
        lastUpdatedAt: now,
        migratedFrom: 'legacy',
        unlocked: unlocked,
        progress: progressMap,
      );
      await storage.saveState(_cachedState!);
      await storage.markMigrationComplete();
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }

  int _currentFor(
    AchievementDefinition def,
    int totalWorkouts,
    int totalSets,
    int coreWorkouts,
    int upperWorkouts,
    int lowerWorkouts,
    int fullBodyWorkouts,
    int completedWeeks,
    int week1Sessions,
    int maxStreak,
    int totalSteps,
    double totalHydration,
    int weightEntryCount,
    int currentWeek,
  ) {
    return switch (def.id) {
      'first_steps' => totalWorkouts >= 1 ? 1 : 0,
      'workout_10' => totalWorkouts,
      'workout_25' => totalWorkouts,
      'workout_50' => totalWorkouts,
      'workout_100' => totalWorkouts,
      'core_crusher' => coreWorkouts,
      'upper_champ' => upperWorkouts,
      'lower_legend' => lowerWorkouts,
      'full_fusion' => fullBodyWorkouts,
      'volume_100' => totalSets,
      'volume_500' => totalSets,
      'volume_1000' => totalSets,
      'week_warrior' => week1Sessions,
      'dedicated' => completedWeeks,
      'halfway' => completedWeeks,
      'graduate' => completedWeeks,
      'streak_5' => maxStreak,
      'steps_10k' => totalSteps,
      'steps_50k' => totalSteps,
      'steps_100k' => totalSteps,
      'steps_500k' => totalSteps,
      'water_10L' => totalHydration.round(),
      'water_50L' => totalHydration.round(),
      'water_100L' => totalHydration.round(),
      'first_weight' => weightEntryCount >= 1 ? 1 : 0,
      'weight_consistent' => weightEntryCount,
      'goal_setter' => 0, // check separately
      'profile_complete' => 0,
      'early_bird' => 0,
      'night_owl' => 0,
      _ => 0,
    };
  }

  // ── Evaluation ──

  Future<EvaluatedAchievementSet> evaluate({
    required List<legacy.WorkoutSession> sessions,
    required int todaySteps,
    required double todayHydration,
    required List<WeightEntry> weightEntries,
    required int currentWeek,
  }) async {
    await _ensureLoaded();

    final before = state.unlockedIds;
    final now = clock.now();

    final totalWorkouts = sessions.length;
    final totalSets = sessions.fold(0, (sum, s) => sum + s.totalSets);
    final completedWeeks =
        sessions.map((s) => s.weekNumber).toSet().length;
    final week1Sessions =
        sessions.where((s) => s.weekNumber == 1).length;
    final coreWorkouts =
        sessions.where((s) => s.focus.toLowerCase().contains('core')).length;
    final upperWorkouts =
        sessions.where((s) => s.focus.toLowerCase().contains('upper')).length;
    final lowerWorkouts =
        sessions.where((s) => s.focus.toLowerCase().contains('lower')).length;
    final fullBodyWorkouts =
        sessions.where((s) => s.focus.toLowerCase().contains('full')).length;

    int maxStreak = 0;
    int curStreak = 0;
    DateTime? prevDate;
    final sorted = List<legacy.WorkoutSession>.from(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final s in sorted) {
      if (prevDate == null) {
        curStreak = 1;
      } else {
        final diff = s.date.difference(prevDate).inDays;
        if (diff <= 2) {
          curStreak++;
        } else {
          curStreak = 1;
        }
      }
      prevDate = s.date;
      maxStreak = max(maxStreak, curStreak);
    }

    final totalSteps =
        sessions.fold(todaySteps, (sum, s) => sum + s.steps);
    final totalHydration =
        sessions.fold<double>(0.0, (sum, s) => sum + s.hydrationLiters);

    final prefs = await SharedPreferences.getInstance();

    void checkAndUnlock(String id, bool condition, String by) {
      if (condition && !state.isUnlocked(id)) {
        _addUnlock(UnlockedAchievement(
          achievementId: id,
          unlockedAt: now,
          unlockedBy: by,
        ));
      }
    }

    checkAndUnlock('first_steps', totalWorkouts >= 1, 'workout_completed');
    checkAndUnlock('workout_10', totalWorkouts >= 10, 'workout_completed');
    checkAndUnlock('workout_25', totalWorkouts >= 25, 'workout_completed');
    checkAndUnlock('workout_50', totalWorkouts >= 50, 'workout_completed');
    checkAndUnlock('workout_100', totalWorkouts >= 100, 'workout_completed');
    checkAndUnlock('core_crusher', coreWorkouts >= 10, 'workout_completed');
    checkAndUnlock('upper_champ', upperWorkouts >= 10, 'workout_completed');
    checkAndUnlock('lower_legend', lowerWorkouts >= 10, 'workout_completed');
    checkAndUnlock('full_fusion', fullBodyWorkouts >= 10, 'workout_completed');
    checkAndUnlock('volume_100', totalSets >= 100, 'workout_completed');
    checkAndUnlock('volume_500', totalSets >= 500, 'workout_completed');
    checkAndUnlock('volume_1000', totalSets >= 1000, 'workout_completed');
    checkAndUnlock('week_warrior', completedWeeks >= 1 && week1Sessions >= 4,
        'workout_completed');
    checkAndUnlock('dedicated', completedWeeks >= 4, 'workout_completed');
    checkAndUnlock('halfway', completedWeeks >= 6, 'workout_completed');
    checkAndUnlock('graduate', completedWeeks >= 12, 'workout_completed');
    checkAndUnlock('streak_5', maxStreak >= 5, 'workout_completed');
    checkAndUnlock('steps_10k', totalSteps >= 10000, 'steps_updated');
    checkAndUnlock('steps_50k', totalSteps >= 50000, 'steps_updated');
    checkAndUnlock('steps_100k', totalSteps >= 100000, 'steps_updated');
    checkAndUnlock('steps_500k', totalSteps >= 500000, 'steps_updated');
    checkAndUnlock('water_10L', totalHydration >= 10, 'hydration_updated');
    checkAndUnlock('water_50L', totalHydration >= 50, 'hydration_updated');
    checkAndUnlock('water_100L', totalHydration >= 100, 'hydration_updated');
    checkAndUnlock(
        'first_weight', weightEntries.isNotEmpty, 'weight_logged');
    checkAndUnlock(
        'weight_consistent', weightEntries.length >= 7, 'weight_logged');
    final weightGoal = prefs.getDouble('weight_goal_kg');
    checkAndUnlock('goal_setter', weightGoal != null && weightGoal > 0,
        'profile_updated');

    // Update progress snapshots
    for (final def in definitions) {
      final current = _currentFor(def, totalWorkouts, totalSets,
          coreWorkouts, upperWorkouts, lowerWorkouts, fullBodyWorkouts,
          completedWeeks, week1Sessions, maxStreak, totalSteps,
          totalHydration, weightEntries.length, currentWeek);
      if (current > 0) {
        _cachedState = AchievementState(
          schemaVersion: state.schemaVersion,
          lastUpdatedAt: now,
          migratedFrom: state.migratedFrom,
          unlocked: state.unlocked,
          progress: {
            ...state.progress,
            def.id: AchievementProgressSnapshot(
              current: current > def.target ? def.target : current,
              target: def.target,
              updatedAt: now,
            ),
          },
        );
      }
    }

    final after = state.unlockedIds;
    final newIds = after.difference(before).toList();

    await storage.saveState(_cachedState!);

    return EvaluatedAchievementSet(
      newlyUnlockedIds: newIds,
      previouslyUnlockedIds: before,
    );
  }

  // ── Direct unlock (for event hooks) ──

  void _addUnlock(UnlockedAchievement ua) {
    _cachedState = AchievementState(
      schemaVersion: state.schemaVersion,
      lastUpdatedAt: clock.now(),
      migratedFrom: state.migratedFrom,
      unlocked: [...state.unlocked, ua],
      progress: state.progress,
    );
  }

  Future<void> unlockDirect(String id, String by) async {
    if (state.isUnlocked(id)) return;
    _addUnlock(UnlockedAchievement(
      achievementId: id,
      unlockedAt: clock.now(),
      unlockedBy: by,
    ));
    await storage.saveState(_cachedState!);
  }

  // ── Queries ──

  List<AchievementResult> computeAllResults() {
    return definitions.map((def) {
      final isUnlocked = state.isUnlocked(def.id);
      return AchievementResult(
        definition: def,
        isUnlocked: isUnlocked,
        unlockedAt: state.unlockedAt(def.id),
        progress: state.progressFor(def.id),
      );
    }).toList();
  }

  List<AchievementResult> resultsByCategory(AchievementCategory category) {
    return computeAllResults()
        .where((r) => r.definition.category == category)
        .toList();
  }

  AchievementResult? get closestToUnlock {
    final results = computeAllResults()
        .where((r) => !r.isUnlocked && r.hasProgress)
        .toList();
    if (results.isEmpty) return null;
    results.sort((a, b) => b.progressFraction.compareTo(a.progressFraction));
    return results.first;
  }

  Future<void> _ensureLoaded() async {
    _cachedState ??= await storage.loadState();
  }

  Future<void> refresh() async {
    _cachedState = await storage.loadState();
  }
}

class EvaluatedAchievementSet {
  final List<String> newlyUnlockedIds;
  final Set<String> previouslyUnlockedIds;

  const EvaluatedAchievementSet({
    required this.newlyUnlockedIds,
    required this.previouslyUnlockedIds,
  });

  bool get hasNewUnlocks => newlyUnlockedIds.isNotEmpty;
}
