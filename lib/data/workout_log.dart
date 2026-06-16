import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'exercise_localizer.dart';

class CompletedExercise {
  final String exerciseUuid;
  final String exerciseName;
  final int setsCompleted;
  final int? repsCompleted;
  final int? durationSeconds;
  final String notes;

  const CompletedExercise({
    required this.exerciseUuid,
    required this.exerciseName,
    required this.setsCompleted,
    this.repsCompleted,
    this.durationSeconds,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'exerciseUuid': exerciseUuid,
    'exerciseName': exerciseName,
    'setsCompleted': setsCompleted,
    if (repsCompleted != null) 'repsCompleted': repsCompleted,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    'notes': notes,
  };

  factory CompletedExercise.fromJson(Map<String, dynamic> json) =>
      CompletedExercise(
        exerciseUuid: json['exerciseUuid'] as String,
        exerciseName: json['exerciseName'] as String? ?? '',
        setsCompleted: json['setsCompleted'] as int,
        repsCompleted: json['repsCompleted'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        notes: json['notes'] as String? ?? '',
      );
}

class WorkoutSession {
  final String uuid;
  final DateTime date;
  final int weekNumber;
  final int dayNumber;
  final String focus;
  final int durationSeconds;
  final List<CompletedExercise> exercises;
  final List<String> plannedExerciseUuids;
  final int steps;
  final double hydrationLiters;
  final List<String> achievementsUnlocked;
  final String? notes;

  const WorkoutSession({
    required this.uuid,
    required this.date,
    required this.weekNumber,
    required this.dayNumber,
    required this.focus,
    required this.durationSeconds,
    required this.exercises,
    this.plannedExerciseUuids = const [],
    this.steps = 0,
    this.hydrationLiters = 0.0,
    this.achievementsUnlocked = const [],
    this.notes,
  });

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.setsCompleted);

  Set<String> get completedUuids =>
      exercises.map((e) => e.exerciseUuid).toSet();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'uuid': uuid,
    'date': date.toIso8601String(),
    'weekNumber': weekNumber,
    'dayNumber': dayNumber,
    'focus': focus,
    'durationSeconds': durationSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'plannedExerciseUuids': plannedExerciseUuids,
    'steps': steps,
    'hydrationLiters': hydrationLiters,
    'achievementsUnlocked': achievementsUnlocked,
    if (notes != null) 'notes': notes,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      WorkoutSession(
        uuid: json['uuid'] as String,
        date: DateTime.parse(json['date'] as String),
        weekNumber: json['weekNumber'] as int,
        dayNumber: json['dayNumber'] as int,
        focus: json['focus'] as String,
        durationSeconds: json['durationSeconds'] as int,
        exercises: (json['exercises'] as List<dynamic>)
            .map(
              (e) =>
                  CompletedExercise.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        plannedExerciseUuids: (json['plannedExerciseUuids'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        hydrationLiters: (json['hydrationLiters'] as num?)?.toDouble() ?? 0.0,
        achievementsUnlocked:
            (json['achievementsUnlocked'] as List<dynamic>?)?.cast<String>() ??
                [],
        notes: json['notes'] as String?,
      );
}

class ProgramProgress {
  final int currentWeek;
  final int currentDay;

  /// The date (YYYY-MM-DD) when this progress was last advanced.
  /// Used to determine how many days to catch up on app launch / midnight rollover.
  /// Null means it has never been set (first launch or migration).
  final String? lastAdvanceDate;

  const ProgramProgress({
    this.currentWeek = 1,
    this.currentDay = 1,
    this.lastAdvanceDate,
  });

  ProgramProgress advance() {
    if (currentDay >= 7) {
      return ProgramProgress(
        currentWeek: currentWeek + 1,
        currentDay: 1,
        lastAdvanceDate: lastAdvanceDate,
      );
    }
    return ProgramProgress(
      currentWeek: currentWeek,
      currentDay: currentDay + 1,
      lastAdvanceDate: lastAdvanceDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentWeek': currentWeek,
    'currentDay': currentDay,
    if (lastAdvanceDate != null) 'lastAdvanceDate': lastAdvanceDate,
  };

  factory ProgramProgress.fromJson(Map<String, dynamic> json) =>
      ProgramProgress(
        currentWeek: json['currentWeek'] as int? ?? 1,
        currentDay: json['currentDay'] as int? ?? 1,
        lastAdvanceDate: json['lastAdvanceDate'] as String?,
      );
}

bool isRestDay(int day) => day == 4 || day == 7;

String getFocusForDay(int week, int day) {
  if (isRestDay(day)) return 'Rest Day';

  if (week <= 4) {
    const focuses = {
      1: 'Core Foundation',
      2: 'Upper Body Basics',
      3: 'Lower Body Foundation',
      5: 'Full Body Foundation',
      6: 'Cardio & Conditioning',
    };
    return focuses[day] ?? 'Core Foundation';
  }
  if (week <= 8) {
    const focuses = {
      1: 'Dynamic Core',
      2: 'Upper Body Power',
      3: 'Lower Body Strength',
      5: 'Full Body Conditioning',
      6: 'Cardio Endurance',
    };
    return focuses[day] ?? 'Dynamic Core';
  }
  const focuses = {
    1: 'Advanced Core',
    2: 'Upper Body Peak',
    3: 'Lower Body Peak',
    5: 'Full Body HIIT',
    6: 'Peak Cardio',
  };
  return focuses[day] ?? 'Advanced Core';
}

/// Returns the localized focus name for the given [week] and [day].
///
/// Delegates to [getFocusForDay] for the English name and then looks up
/// the corresponding ARB key via [ExerciseLocalizer.focusName].
String getLocalizedFocus(AppLocalizations l10n, int week, int day) {
  return ExerciseLocalizer.focusName(l10n, getFocusForDay(week, day));
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

List<Achievement> evaluateAchievements(List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final unlocked = <Achievement>[];

  final totalWorkouts = sessions.length;
  final totalSets =
      sessions.fold(0, (sum, s) => sum + s.totalSets);
  final completedWeeks =
      sessions.map((s) => s.weekNumber).toSet().length;
  final coreWorkouts = sessions
      .where((s) => s.focus.toLowerCase().contains('core'))
      .length;
  final upperWorkouts = sessions
      .where(
          (s) => s.focus.toLowerCase().contains('upper'))
      .length;
  final lowerWorkouts = sessions
      .where(
          (s) => s.focus.toLowerCase().contains('lower'))
      .length;
  final fullBodyWorkouts = sessions
      .where(
          (s) => s.focus.toLowerCase().contains('full'))
      .length;

  final sorted = List<WorkoutSession>.from(sessions)
    ..sort((a, b) => a.date.compareTo(b.date));

  int maxStreak = 0;
  int currentStreak = 0;
  DateTime? prevDate;
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
    maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  void addIf(String id, String title, String desc, IconData icon, bool condition) {
    if (condition) {
      unlocked.add(Achievement(
        id: id,
        title: title,
        description: desc,
        icon: icon,
        isUnlocked: true,
        unlockedAt: now,
      ));
    }
  }

  addIf('first_steps', 'First Steps', 'Complete your first workout',
      Icons.directions_run, totalWorkouts >= 1);
  addIf('week_warrior', 'Week Warrior', 'Complete a full week (5 workouts)',
      Icons.shield, completedWeeks >= 1 && sessions.where((s) => s.weekNumber == 1).length >= 4);
  addIf('dedicated', 'Dedicated', 'Complete 4 consecutive weeks',
      Icons.star, completedWeeks >= 4);
  addIf('halfway', 'Halfway There', 'Complete 6 weeks',
      Icons.trending_up, completedWeeks >= 6);
  addIf('graduate', 'Program Graduate', 'Complete all 12 weeks',
      Icons.school, completedWeeks >= 12);
  addIf('core_crusher', 'Core Crusher', 'Complete 10 core-focused workouts',
      Icons.fitness_center, coreWorkouts >= 10);
  addIf('upper_champ', 'Upper Body Champ', 'Complete 10 upper body workouts',
      Icons.pan_tool, upperWorkouts >= 10);
  addIf('lower_legend', 'Lower Body Legend', 'Complete 10 lower body workouts',
      Icons.directions_walk, lowerWorkouts >= 10);
  addIf('full_fusion', 'Full Body Fusion', 'Complete 10 full body workouts',
      Icons.local_fire_department, fullBodyWorkouts >= 10);
  addIf('volume_100', 'Volume 100', 'Complete 100 total exercise sets',
      Icons.looks_one, totalSets >= 100);
  addIf('volume_500', 'Volume 500', 'Complete 500 total exercise sets',
      Icons.looks_two, totalSets >= 500);
  addIf('streak_5', 'Streak Master', 'Complete 5 workouts in a row',
      Icons.whatshot, maxStreak >= 5);

  return unlocked;
}

const allAchievementDefinitions = [
  AchievementData(id: 'first_steps', title: 'First Steps', description: 'Complete your first workout', icon: Icons.directions_run),
  AchievementData(id: 'week_warrior', title: 'Week Warrior', description: 'Complete a full week (5 workouts)', icon: Icons.shield),
  AchievementData(id: 'dedicated', title: 'Dedicated', description: 'Complete 4 consecutive weeks', icon: Icons.star),
  AchievementData(id: 'halfway', title: 'Halfway There', description: 'Complete 6 weeks', icon: Icons.trending_up),
  AchievementData(id: 'graduate', title: 'Program Graduate', description: 'Complete all 12 weeks', icon: Icons.school),
  AchievementData(id: 'core_crusher', title: 'Core Crusher', description: 'Complete 10 core workouts', icon: Icons.fitness_center),
  AchievementData(id: 'upper_champ', title: 'Upper Body Champ', description: 'Complete 10 upper body workouts', icon: Icons.pan_tool),
  AchievementData(id: 'lower_legend', title: 'Lower Body Legend', description: 'Complete 10 lower body workouts', icon: Icons.directions_walk),
  AchievementData(id: 'full_fusion', title: 'Full Body Fusion', description: 'Complete 10 full body workouts', icon: Icons.local_fire_department),
  AchievementData(id: 'volume_100', title: 'Volume 100', description: 'Complete 100 total exercise sets', icon: Icons.looks_one),
  AchievementData(id: 'volume_500', title: 'Volume 500', description: 'Complete 500 total exercise sets', icon: Icons.looks_two),
  AchievementData(id: 'streak_5', title: 'Streak Master', description: 'Complete 5 workouts in a row', icon: Icons.whatshot),
];

class AchievementProgress {
  final int current;
  final int target;
  final String label;

  const AchievementProgress({
    required this.current,
    required this.target,
    required this.label,
  });

  double get fraction => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => current >= target;

  String get display => '$current / $target';
}

class AchievementResult {
  final AchievementData definition;
  final bool isUnlocked;
  final AchievementProgress progress;

  const AchievementResult({
    required this.definition,
    required this.isUnlocked,
    required this.progress,
  });
}

List<AchievementResult> computeAllAchievements(List<WorkoutSession> sessions) {
  final totalWorkouts = sessions.length;
  final totalSets = sessions.fold(0, (sum, s) => sum + s.totalSets);
  final completedWeeks = sessions.map((s) => s.weekNumber).toSet().length;
  final week1Sessions = sessions.where((s) => s.weekNumber == 1).length;
  final coreWorkouts = sessions.where((s) => s.focus.toLowerCase().contains('core')).length;
  final upperWorkouts = sessions.where((s) => s.focus.toLowerCase().contains('upper')).length;
  final lowerWorkouts = sessions.where((s) => s.focus.toLowerCase().contains('lower')).length;
  final fullBodyWorkouts = sessions.where((s) => s.focus.toLowerCase().contains('full')).length;

  final sorted = List<WorkoutSession>.from(sessions)
    ..sort((a, b) => a.date.compareTo(b.date));
  int maxStreak = 0;
  int currentStreak = 0;
  DateTime? prevDate;
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
    maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  final progresses = <String, AchievementProgress>{
    'first_steps': AchievementProgress(current: totalWorkouts, target: 1, label: 'Workouts'),
    'week_warrior': AchievementProgress(current: week1Sessions, target: 5, label: 'Week 1 workouts'),
    'dedicated': AchievementProgress(current: completedWeeks, target: 4, label: 'Weeks completed'),
    'halfway': AchievementProgress(current: completedWeeks, target: 6, label: 'Weeks completed'),
    'graduate': AchievementProgress(current: completedWeeks, target: 12, label: 'Weeks completed'),
    'core_crusher': AchievementProgress(current: coreWorkouts, target: 10, label: 'Core workouts'),
    'upper_champ': AchievementProgress(current: upperWorkouts, target: 10, label: 'Upper body workouts'),
    'lower_legend': AchievementProgress(current: lowerWorkouts, target: 10, label: 'Lower body workouts'),
    'full_fusion': AchievementProgress(current: fullBodyWorkouts, target: 10, label: 'Full body workouts'),
    'volume_100': AchievementProgress(current: totalSets, target: 100, label: 'Sets completed'),
    'volume_500': AchievementProgress(current: totalSets, target: 500, label: 'Sets completed'),
    'streak_5': AchievementProgress(current: maxStreak, target: 5, label: 'Day streak'),
  };

  return allAchievementDefinitions.map((def) {
    final p = progresses[def.id]!;
    return AchievementResult(
      definition: def,
      isUnlocked: p.isComplete,
      progress: p,
    );
  }).toList();
}

class AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
