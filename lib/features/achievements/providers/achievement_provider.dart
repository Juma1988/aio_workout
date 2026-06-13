import 'package:flutter/foundation.dart';

import '../../../core/clock.dart';
import '../../../data/weight_entry.dart';
import '../../../data/workout_log.dart' as legacy;
import '../../../services/workout_storage_service.dart';
import '../models/achievement_category.dart';
import '../models/achievement_definition.dart';
import '../models/achievement_result.dart';
import '../services/achievement_service.dart';
import '../services/achievement_storage.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _service;
  bool _initialized = false;
  List<AchievementResult> _results = [];
  List<String> _pendingNewUnlocks = [];

  AchievementProvider({
    required AchievementStorage storage,
    required Clock clock,
    required WorkoutStorageService workoutStorage,
  }) : _service = AchievementService(
          storage: storage,
          clock: clock,
          workoutStorage: workoutStorage,
        );

  AchievementService get service => _service;
  List<AchievementDefinition> get definitions => _service.definitions;
  List<AchievementResult> get results => _results;
  int get unlockedCount => _service.unlockedCount;
  int get totalCount => _service.totalCount;
  bool get isInitialized => _initialized;
  List<String> get pendingNewUnlocks => _pendingNewUnlocks;

  AchievementResult? get closestToUnlock => _service.closestToUnlock;

  List<AchievementResult> resultsFor(AchievementCategory category) =>
      _results.where((r) => r.definition.category == category).toList();

  int unlockedFor(AchievementCategory category) =>
      _results.where((r) => r.definition.category == category && r.isUnlocked).length;

  int totalFor(AchievementCategory category) =>
      _results.where((r) => r.definition.category == category).length;

  Future<void> initialize() async {
    await _service.initialize();
    _results = _service.computeAllResults();
    _initialized = true;
    notifyListeners();
  }

  Future<void> evaluateAll() async {
    final sessions = await _service.workoutStorage.loadSessions();
    final todaySteps = await _service.workoutStorage.loadTodaySteps();
    final todayHydration = await _service.workoutStorage.loadTodayHydration();
    final weightEntries = await _service.workoutStorage.loadWeightEntries();
    final progress = await _service.workoutStorage.loadProgramProgress();

    final result = await _service.evaluate(
      sessions: sessions,
      todaySteps: todaySteps,
      todayHydration: todayHydration,
      weightEntries: weightEntries,
      currentWeek: progress.currentWeek,
    );

    _results = _service.computeAllResults();
    _pendingNewUnlocks = result.newlyUnlockedIds;
    notifyListeners();
  }

  Future<void> evaluateFromWorkout(List<legacy.WorkoutSession> sessions) async {
    final weightEntries = await _service.workoutStorage.loadWeightEntries();
    final progress = await _service.workoutStorage.loadProgramProgress();

    final result = await _service.evaluate(
      sessions: sessions,
      todaySteps: 0,
      todayHydration: 0.0,
      weightEntries: weightEntries,
      currentWeek: progress.currentWeek,
    );

    _results = _service.computeAllResults();
    _pendingNewUnlocks = result.newlyUnlockedIds;
    notifyListeners();
  }

  Future<void> evaluateSteps(int todaySteps) async {
    final sessions = await _service.workoutStorage.loadSessions();
    final weightEntries = await _service.workoutStorage.loadWeightEntries();
    final progress = await _service.workoutStorage.loadProgramProgress();
    final hydration = await _service.workoutStorage.loadTodayHydration();

    final result = await _service.evaluate(
      sessions: sessions,
      todaySteps: todaySteps,
      todayHydration: hydration,
      weightEntries: weightEntries,
      currentWeek: progress.currentWeek,
    );

    _results = _service.computeAllResults();
    _pendingNewUnlocks = result.newlyUnlockedIds;
    notifyListeners();
  }

  Future<void> evaluateHydration(double todayHydration) async {
    final sessions = await _service.workoutStorage.loadSessions();
    final weightEntries = await _service.workoutStorage.loadWeightEntries();
    final progress = await _service.workoutStorage.loadProgramProgress();
    final steps = await _service.workoutStorage.loadTodaySteps();

    final result = await _service.evaluate(
      sessions: sessions,
      todaySteps: steps,
      todayHydration: todayHydration,
      weightEntries: weightEntries,
      currentWeek: progress.currentWeek,
    );

    _results = _service.computeAllResults();
    _pendingNewUnlocks = result.newlyUnlockedIds;
    notifyListeners();
  }

  Future<void> evaluateWeight(List<WeightEntry> weightEntries) async {
    final sessions = await _service.workoutStorage.loadSessions();
    final progress = await _service.workoutStorage.loadProgramProgress();
    final steps = await _service.workoutStorage.loadTodaySteps();
    final hydration = await _service.workoutStorage.loadTodayHydration();

    final result = await _service.evaluate(
      sessions: sessions,
      todaySteps: steps,
      todayHydration: hydration,
      weightEntries: weightEntries,
      currentWeek: progress.currentWeek,
    );

    _results = _service.computeAllResults();
    _pendingNewUnlocks = result.newlyUnlockedIds;
    notifyListeners();
  }

  void clearPendingUnlocks() {
    _pendingNewUnlocks = [];
    notifyListeners();
  }

  List<AchievementResult> pendingAchievementDetails() {
    return _pendingNewUnlocks
        .map((id) => _results.firstWhere((r) => r.definition.id == id))
        .toList();
  }
}
