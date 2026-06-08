// lib/data/workout.dart
import 'exercise.dart';

/// A workout plan/template
class Workout {
  final String uuid;
  final String name;
  final bool isDefault;
  final String focus;
  final String level;

  final List<ExerciseRef> exercises;
  final int estimatedDurationMinutes;

  final DateTime createdAt;
  final String createdByUserId;

  Workout({
    required this.uuid,
    required this.name,
    required this.isDefault,
    required this.focus,
    required this.level,
    this.exercises = const [],
    this.estimatedDurationMinutes = 0,
    required this.createdAt,
    this.createdByUserId = '',
  });

  Workout copyWith({
    String? uuid,
    String? name,
    bool? isDefault,
    String? focus,
    String? level,
    List<ExerciseRef>? exercises,
    int? estimatedDurationMinutes,
    DateTime? createdAt,
    String? createdByUserId,
  }) {
    return Workout(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      focus: focus ?? this.focus,
      level: level ?? this.level,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}
