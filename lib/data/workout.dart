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

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool,
      focus: json['focus'] as String,
      level: json['level'] as String,
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => ExerciseRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByUserId: (json['createdByUserId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'isDefault': isDefault,
      'focus': focus,
      'level': level,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'createdByUserId': createdByUserId,
    };
  }
}
