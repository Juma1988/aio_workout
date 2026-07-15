import 'exercise.dart';
import 'workout_log.dart';

Level _parseLevel(String? name) {
  if (name == null || name.isEmpty) return Level.beginner;
  for (final l in Level.values) {
    if (l.name == name) return l;
  }
  return Level.beginner;
}

class PlanExerciseSlot {
  final String exerciseId;
  final String exerciseName;
  final Level chosenLevel;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;

  const PlanExerciseSlot({
    required this.exerciseId,
    required this.exerciseName,
    this.chosenLevel = Level.beginner,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
  });

  factory PlanExerciseSlot.fromExercise(Exercise ex) {
    final lvl = ex.getLevel(ex.recommendedLevel);
    return PlanExerciseSlot(
      exerciseId: ex.uuid,
      exerciseName: ex.name,
      chosenLevel: ex.recommendedLevel,
      sets: lvl?.sets,
      reps: lvl?.reps,
      durationSeconds: lvl?.durationSeconds,
      weightKg: lvl?.weightKg,
    );
  }

  factory PlanExerciseSlot.fromJson(Map<String, dynamic> json) {
    return PlanExerciseSlot(
      exerciseId: json['exerciseId'] as String,
      exerciseName: (json['exerciseName'] as String?) ?? json['exerciseId'] as String,
      chosenLevel: _parseLevel(json['chosenLevel'] as String?),
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'chosenLevel': chosenLevel.name,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (weightKg != null) 'weightKg': weightKg,
      };

  PlanExerciseSlot copyWith({
    String? exerciseId,
    String? exerciseName,
    Level? chosenLevel,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
  }) {
    return PlanExerciseSlot(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      chosenLevel: chosenLevel ?? this.chosenLevel,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}

class PlanDay {
  final int dayNumber;
  final List<PlanExerciseSlot> exercises;

  const PlanDay({
    required this.dayNumber,
    this.exercises = const [],
  });

  bool get isRest => exercises.isEmpty;

  factory PlanDay.empty(int dayNumber) => PlanDay(dayNumber: dayNumber);

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      dayNumber: (json['dayNumber'] as num).toInt(),
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => PlanExerciseSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  PlanDay copyWith({
    int? dayNumber,
    List<PlanExerciseSlot>? exercises,
  }) {
    return PlanDay(
      dayNumber: dayNumber ?? this.dayNumber,
      exercises: exercises ?? this.exercises,
    );
  }
}

class PlanWeek {
  final int weekNumber;
  final List<PlanDay> days;

  const PlanWeek({
    required this.weekNumber,
    required this.days,
  });

  int get exerciseCount =>
      days.fold(0, (sum, d) => sum + d.exercises.length);

  factory PlanWeek.empty(int weekNumber) {
    return PlanWeek(
      weekNumber: weekNumber,
      days: List.generate(7, (i) => PlanDay.empty(i + 1)),
    );
  }

  factory PlanWeek.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>? ?? const [])
        .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
        .toList();
    final weekNumber = (json['weekNumber'] as num).toInt();
    if (days.length >= 7) {
      return PlanWeek(weekNumber: weekNumber, days: days.take(7).toList());
    }
    final filled = List<PlanDay>.from(days);
    for (var i = filled.length + 1; i <= 7; i++) {
      filled.add(PlanDay.empty(i));
    }
    return PlanWeek(weekNumber: weekNumber, days: filled);
  }

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'days': days.map((d) => d.toJson()).toList(),
      };

  PlanWeek copyWith({
    int? weekNumber,
    List<PlanDay>? days,
  }) {
    return PlanWeek(
      weekNumber: weekNumber ?? this.weekNumber,
      days: days ?? this.days,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String name;
  final bool isDefault;
  final List<PlanWeek> weeks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    this.isDefault = false,
    required this.weeks,
    required this.createdAt,
    required this.updatedAt,
  });

  int get weekCount => weeks.length;

  int get totalExercises =>
      weeks.fold(0, (sum, w) => sum + w.exerciseCount);

  factory WorkoutPlan.create({required String name}) {
    final now = DateTime.now();
    return WorkoutPlan(
      id: 'plan-${now.millisecondsSinceEpoch}',
      name: name,
      isDefault: false,
      weeks: [PlanWeek.empty(1)],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Virtual card stats for the built-in 12-week program (not stored in prefs).
  static const int defaultPlanWeeks = 12;

  /// 5 workout days/week × 6 default exercises × 12 weeks (days 4 & 7 rest).
  static int defaultPlanExerciseTotal() {
    var total = 0;
    for (var week = 1; week <= defaultPlanWeeks; week++) {
      for (var day = 1; day <= 7; day++) {
        if (!isRestDay(day)) total += 6;
      }
    }
    return total;
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      weeks: (json['weeks'] as List<dynamic>? ?? const [])
          .map((e) => PlanWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isDefault': isDefault,
        'weeks': weeks.map((w) => w.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  WorkoutPlan copyWith({
    String? id,
    String? name,
    bool? isDefault,
    List<PlanWeek>? weeks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      weeks: weeks ?? this.weeks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
