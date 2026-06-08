import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/workout_log.dart';

class WorkoutStorageService {
  static const _sessionsKey = 'workout_sessions';
  static const _programKey = 'program_progress';
  static const _todayDateKey = 'today_date';
  static const _todayStepsKey = 'today_steps';
  static const _todayHydrationKey = 'today_hydration';
  static const _todayUuidsKey = 'today_completed_uuids';

  static final WorkoutStorageService _instance =
      WorkoutStorageService._();
  factory WorkoutStorageService() => _instance;
  WorkoutStorageService._();

  String get _todayKey => DateTime.now().toIso8601String().substring(0, 10);

  Future<List<WorkoutSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) =>
              WorkoutSession.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveSessions(
      List<WorkoutSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((e) => e.toJson()).toList());
    await prefs.setString(_sessionsKey, raw);
  }

  Future<void> addSession(WorkoutSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

  Future<ProgramProgress> loadProgramProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_programKey);
    if (raw == null) return const ProgramProgress();
    return ProgramProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProgramProgress(
      ProgramProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _programKey, jsonEncode(progress.toJson()));
  }

  Future<int> loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_todayDateKey);
    if (savedDate != _todayKey) return 0;
    return prefs.getInt(_todayStepsKey) ?? 0;
  }

  Future<double> loadTodayHydration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_todayDateKey);
    if (savedDate != _todayKey) return 0.0;
    return prefs.getDouble(_todayHydrationKey) ?? 0.0;
  }

  Future<Set<String>> loadTodayCompletedUuids() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_todayDateKey);
    if (savedDate != _todayKey) return {};
    final raw = prefs.getStringList(_todayUuidsKey);
    return raw?.toSet() ?? {};
  }

  Future<void> saveTodayState({
    required int steps,
    required double hydration,
    required Set<String> completedUuids,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _todayKey);
    await prefs.setInt(_todayStepsKey, steps);
    await prefs.setDouble(_todayHydrationKey, hydration);
    await prefs.setStringList(_todayUuidsKey, completedUuids.toList());
  }

  Future<void> clearTodayState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_todayDateKey);
    await prefs.remove(_todayStepsKey);
    await prefs.remove(_todayHydrationKey);
    await prefs.remove(_todayUuidsKey);
  }
}
