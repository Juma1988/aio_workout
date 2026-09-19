import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'exercise_localizer.dart';

enum Level {
  beginner,
  intermediate,
  advanced,
  custom;

  String get label {
    switch (this) {
      case Level.beginner:
        return 'Beginner';
      case Level.intermediate:
        return 'Intermediate';
      case Level.advanced:
        return 'Advanced';
      case Level.custom:
        return 'Custom';
    }
  }

  /// Returns the localized level label for display purposes.
  /// Uses [ExerciseLocalizer.levelLabel] to look up the ARB key.
  /// Prefer this over [label] anywhere user-facing.
  String localized(AppLocalizations l10n) =>
      ExerciseLocalizer.levelLabel(l10n, name);
}

/// Category / muscle registries expose keys only. Colors and icons live in
/// `core/theme/exercise_visuals.dart`; localized labels come from
/// [ExerciseLocalizer]. The English [ExerciseCategory.label] /
/// [TargetMuscle.label] strings are debug identifiers, not display copy.
const Map<String, ExerciseCategory> exerciseCategories = {
  'strength': ExerciseCategory(key: 'strength', label: 'Strength'),
  'cardio': ExerciseCategory(key: 'cardio', label: 'Cardio'),
  'core': ExerciseCategory(key: 'core', label: 'Core'),
  'flexibility': ExerciseCategory(key: 'flexibility', label: 'Flexibility'),
  'fullbody': ExerciseCategory(key: 'fullbody', label: 'Full Body'),
  'upperbody': ExerciseCategory(key: 'upperbody', label: 'Upper Body'),
  'lowerbody': ExerciseCategory(key: 'lowerbody', label: 'Lower Body'),
};

const Map<String, TargetMuscle> targetMuscles = {
  'chest': TargetMuscle(key: 'chest', label: 'Chest'),
  'back': TargetMuscle(key: 'back', label: 'Back'),
  'shoulders': TargetMuscle(key: 'shoulders', label: 'Shoulders'),
  'arms': TargetMuscle(key: 'arms', label: 'Arms'),
  'legs': TargetMuscle(key: 'legs', label: 'Legs'),
  'core': TargetMuscle(key: 'core', label: 'Core'),
  'fullbody': TargetMuscle(key: 'fullbody', label: 'Full Body'),
  'cardio': TargetMuscle(key: 'cardio', label: 'Cardio'),
};

class ExerciseCategory {
  static const unknown = ExerciseCategory(key: 'other', label: 'Other');

  final String key;
  final String label;

  const ExerciseCategory({required this.key, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseCategory &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ExerciseCategory($key)';
}

class TargetMuscle {
  static const unknown = TargetMuscle(key: 'other', label: 'Other');

  final String key;
  final String label;

  const TargetMuscle({required this.key, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetMuscle &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'TargetMuscle($key)';
}

ExerciseCategory? getCategory(String key) => exerciseCategories[key];
TargetMuscle? getTargetMuscle(String key) => targetMuscles[key];

/// Safe [Level] parser: unknown or missing names fall back to
/// [Level.beginner] instead of throwing (see `Level.values.byName`).
/// Logs in debug builds so corrupt records stay visible.
Level safeParseLevel(String? name) {
  if (name == null || name.isEmpty) return Level.beginner;
  for (final l in Level.values) {
    if (l.name == name) return l;
  }
  assert(() {
    debugPrint('safeParseLevel: unknown level "$name", falling back to beginner');
    return true;
  }());
  return Level.beginner;
}

/// Drops duplicate [ExerciseLevel] entries (keeps the first per [Level]).
/// Duplicate tiers are a data-entry error; keeping both would make
/// `getLevel` return whichever came first silently.
List<ExerciseLevel> _dedupeLevels(List<ExerciseLevel> levels, String uuid) {
  final seen = <Level>{};
  final out = <ExerciseLevel>[];
  for (final l in levels) {
    if (seen.add(l.level)) {
      out.add(l);
    } else {
      assert(() {
        debugPrint('_dedupeLevels($uuid): duplicate ${l.level.name} dropped');
        return true;
      }());
    }
  }
  return out;
}

/// Trims equipment text; empty becomes null so `!= null` checks stay honest.
String? _normalizeEquipment(String? raw) {
  final text = raw?.trim() ?? '';
  return text.isEmpty ? null : text;
}

/// Canonical tag set: lowercase, trimmed, de-duplicated.
/// The search field (`exercise_dialog.dart`) already lowercases the query,
/// so stored tags must match that normalization to be findable.
List<String> _normalizeTags(List<String> tags) {
  final seen = <String>{};
  final out = <String>[];
  for (final t in tags) {
    final norm = t.trim().toLowerCase();
    if (norm.isNotEmpty && seen.add(norm)) out.add(norm);
  }
  return out;
}

class ExerciseLevel {
  final Level level;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;

  const ExerciseLevel({
    required this.level,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
  });

  factory ExerciseLevel.fromJson(Map<String, dynamic> json) {
    return ExerciseLevel(
      level: safeParseLevel(json['level'] as String?),
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
    );
  }

  /// Single-source view of this level's dosage.
  Prescription toPrescription() => Prescription(
        sets: sets,
        reps: reps,
        durationSeconds: durationSeconds,
        weightKg: weightKg,
      );

  factory ExerciseLevel.fromPrescription(Level level, Prescription p) {
    return ExerciseLevel(
      level: level,
      sets: p.sets,
      reps: p.reps,
      durationSeconds: p.durationSeconds,
      weightKg: p.weightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (weightKg != null) 'weightKg': weightKg,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLevel &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          sets == other.sets &&
          reps == other.reps &&
          durationSeconds == other.durationSeconds &&
          weightKg == other.weightKg;

  @override
  int get hashCode => Object.hash(level, sets, reps, durationSeconds, weightKg);

  @override
  String toString() =>
      'ExerciseLevel(level: $level, sets: $sets, reps: $reps, '
      'duration: ${durationSeconds}s, weight: ${weightKg}kg)';
}

/// A single dosage of an exercise: the four numbers that every
/// prescription-carrying type in the app ([ExerciseLevel], [ExerciseRef],
/// `PlanExerciseSlot`) embeds. Convert via `toPrescription()` and format
/// via [display] so the rules live in exactly one place.
class Prescription {
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;

  const Prescription({
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
  });

  /// Valid when exactly one effort axis is present: reps XOR duration.
  /// `sets` is optional (rep-only entries like Cocoons exist in the catalog).
  bool get isValid {
    final hasReps = (reps ?? 0) > 0;
    final hasDuration = (durationSeconds ?? 0) > 0;
    return hasReps != hasDuration;
  }

  /// Canonical one-line display, e.g. "4 × 12 • 12 kg", "45s", "12 reps".
  String display() {
    final parts = <String>[];
    if (sets != null && reps != null) {
      parts.add('$sets × $reps');
    } else if (sets != null) {
      parts.add('$sets sets');
    } else if (reps != null) {
      parts.add('$reps reps');
    } else if (durationSeconds != null) {
      parts.add(_formatDuration(durationSeconds!));
    }
    if (weightKg != null) parts.add(_formatWeight(weightKg!));
    return parts.join(' • ');
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  static String _formatWeight(double kg) {
    final text = kg % 1 == 0 ? kg.toInt().toString() : kg.toString();
    return '$text kg';
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (weightKg != null) 'weightKg': weightKg,
    };
  }
}

class Exercise {
  final String uuid;
  final String name;
  final String? description;
  final bool isDefault;
  final String categoryKey;
  final String targetMuscleKey;
  final Level recommendedLevel;
  final List<ExerciseLevel> levels;
  final String? equipment;
  final List<String> tags;
  final String? videoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdByUserId;

  ExerciseCategory get category => exerciseCategories[categoryKey] ?? ExerciseCategory.unknown;
  TargetMuscle get targetMuscle => targetMuscles[targetMuscleKey] ?? TargetMuscle.unknown;

  Exercise({
    required this.uuid,
    required this.name,
    this.description,
    required this.isDefault,
    required this.categoryKey,
    required this.targetMuscleKey,
    required this.recommendedLevel,
    this.levels = const [],
    this.equipment,
    this.tags = const [],
    this.videoUrl,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.createdByUserId = '',
  });

  bool get isTimeBased => levels.any((l) => (l.durationSeconds ?? 0) > 0);

  ExerciseLevel? getLevel(Level level) {
    for (final l in levels) {
      if (l.level == level) return l;
    }
    return null;
  }

  /// Resolves the level to display/log: requested → recommended → first.
  /// Falls back loudly (debug log) instead of silently using the wrong tier.
  ExerciseLevel? resolveLevel(Level level) {
    final exact = getLevel(level);
    if (exact != null) return exact;
    final recommended = getLevel(recommendedLevel);
    if (recommended != null) {
      assert(() {
        debugPrint(
            'resolveLevel($name): $level missing, using recommended $recommendedLevel');
        return true;
      }());
      return recommended;
    }
    if (levels.isNotEmpty) {
      assert(() {
        debugPrint('resolveLevel($name): no usable level, using first entry');
        return true;
      }());
      return levels.first;
    }
    return null;
  }

  String getRecommendedDisplay() {
    final lvl = resolveLevel(recommendedLevel);
    return lvl?.toPrescription().display() ?? '';
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      categoryKey: (json['category'] as String?) ??
          (json['categoryKey'] as String?) ??
          'strength',
      targetMuscleKey: (json['targetMuscle'] as String?) ??
          (json['targetMuscleKey'] as String?) ??
          'fullbody',
      recommendedLevel: safeParseLevel(json['recommendedLevel'] as String?),
      levels: _dedupeLevels(
        (json['levels'] as List<dynamic>? ?? const [])
            .map((e) => ExerciseLevel.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['uuid'] as String? ?? '',
      ),
      equipment: _normalizeEquipment(json['equipment'] as String?),
      tags: _normalizeTags(
        (json['tags'] as List<dynamic>? ?? const [])
            .map((t) => t.toString())
            .toList(),
      ),
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdByUserId: (json['createdByUserId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      if (description != null) 'description': description,
      'isDefault': isDefault,
      // Canonical keys; fromJson still accepts the legacy
      // 'category' / 'targetMuscle' aliases for stored records.
      'categoryKey': categoryKey,
      'targetMuscleKey': targetMuscleKey,
      'recommendedLevel': recommendedLevel.name,
      'levels': levels.map((l) => l.toJson()).toList(),
      if (equipment != null) 'equipment': equipment,
      'tags': tags,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'createdByUserId': createdByUserId,
    };
  }

  Exercise copyWith({
    String? uuid,
    String? name,
    String? description,
    bool? isDefault,
    String? categoryKey,
    String? targetMuscleKey,
    Level? recommendedLevel,
    List<ExerciseLevel>? levels,
    String? equipment,
    List<String>? tags,
    String? videoUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
  }) {
    return Exercise(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      categoryKey: categoryKey ?? this.categoryKey,
      targetMuscleKey: targetMuscleKey ?? this.targetMuscleKey,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
      levels: levels ?? this.levels,
      equipment: equipment ?? this.equipment,
      tags: tags ?? this.tags,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'Exercise($name, $categoryKey, $recommendedLevel)';
}

class ExerciseRef {
  final String exerciseId;
  final Level? chosenLevel;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final int? restSecondsBetweenSets;
  final String? notes;

  ExerciseRef({
    required this.exerciseId,
    this.chosenLevel,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    this.restSecondsBetweenSets,
    this.notes,
  });

  ExerciseRef copyWith({
    String? exerciseId,
    Level? chosenLevel,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
    int? restSecondsBetweenSets,
    String? notes,
  }) {
    return ExerciseRef(
      exerciseId: exerciseId ?? this.exerciseId,
      chosenLevel: chosenLevel ?? this.chosenLevel,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
      restSecondsBetweenSets:
          restSecondsBetweenSets ?? this.restSecondsBetweenSets,
      notes: notes ?? this.notes,
    );
  }

  factory ExerciseRef.fromJson(Map<String, dynamic> json) {
    return ExerciseRef(
      exerciseId: json['exerciseId'] as String,
      chosenLevel: json['chosenLevel'] != null
          ? safeParseLevel(json['chosenLevel'] as String?)
          : null,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      restSecondsBetweenSets: (json['restSecondsBetweenSets'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      if (chosenLevel != null) 'chosenLevel': chosenLevel!.name,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (weightKg != null) 'weightKg': weightKg,
      if (restSecondsBetweenSets != null) 'restSecondsBetweenSets': restSecondsBetweenSets,
      if (notes != null) 'notes': notes,
    };
  }

  /// Single-source view of this ref's dosage.
  Prescription toPrescription() => Prescription(
        sets: sets,
        reps: reps,
        durationSeconds: durationSeconds,
        weightKg: weightKg,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseRef &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId &&
          chosenLevel == other.chosenLevel &&
          sets == other.sets &&
          reps == other.reps &&
          durationSeconds == other.durationSeconds &&
          weightKg == other.weightKg &&
          restSecondsBetweenSets == other.restSecondsBetweenSets;

  @override
  int get hashCode => Object.hash(
    exerciseId,
    chosenLevel,
    sets,
    reps,
    durationSeconds,
    weightKg,
    restSecondsBetweenSets,
  );

  @override
  String toString() => 'ExerciseRef($exerciseId, $chosenLevel)';
}

final Exercise plank = Exercise(
  uuid: 'ex-plank-001',
  name: 'Plank',
  description:
      'Hold a straight line from head to heels, supported on forearms and toes.',
  isDefault: true,
  categoryKey: 'core',
  targetMuscleKey: 'core',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, durationSeconds: 30),
    ExerciseLevel(level: Level.intermediate, durationSeconds: 45),
    ExerciseLevel(level: Level.advanced, durationSeconds: 60),
  ],
  equipment: 'bodyweight',
  tags: ['core', 'stability', 'isometric'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise cocoons = Exercise(
  uuid: 'ex-cocoons-001',
  name: 'Cocoons',
  description: 'From high plank, roll into a tight tuck and back out.',
  isDefault: true,
  categoryKey: 'core',
  targetMuscleKey: 'core',
  recommendedLevel: Level.intermediate,
  levels: [
    ExerciseLevel(level: Level.beginner, reps: 8),
    ExerciseLevel(level: Level.intermediate, reps: 12),
    ExerciseLevel(level: Level.advanced, reps: 15),
  ],
  equipment: 'bodyweight',
  tags: ['core', 'dynamic'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise pushUps = Exercise(
  uuid: 'ex-pushups-001',
  name: 'Push Ups',
  description:
      'Classic push-up from high plank position. Lower chest to floor and press back up.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'chest',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 8),
    ExerciseLevel(level: Level.intermediate, sets: 4, reps: 12),
    ExerciseLevel(level: Level.advanced, sets: 5, reps: 15),
  ],
  equipment: 'bodyweight',
  tags: ['upper body', 'pushing'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise squats = Exercise(
  uuid: 'ex-squats-001',
  name: 'Bodyweight Squats',
  description:
      'Stand with feet shoulder-width, lower hips back and down as if sitting, then stand.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'legs',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 10),
    ExerciseLevel(level: Level.intermediate, sets: 4, reps: 15),
    ExerciseLevel(level: Level.advanced, sets: 5, reps: 20),
  ],
  equipment: 'bodyweight',
  tags: ['lower body', 'legs'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise overheadPress = Exercise(
  uuid: 'ex-overheadpress-001',
  name: 'Overhead Press',
  description:
      'Press dumbbells or bar from shoulder height straight overhead to full lockout.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'shoulders',
  recommendedLevel: Level.intermediate,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 6, weightKg: 8),
    ExerciseLevel(level: Level.intermediate, sets: 4, reps: 8, weightKg: 12),
    ExerciseLevel(level: Level.advanced, sets: 5, reps: 10, weightKg: 16),
  ],
  equipment: 'dumbbells',
  tags: ['shoulders', 'pressing'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise jumpingJacks = Exercise(
  uuid: 'ex-jumpingjacks-001',
  name: 'Jumping Jacks',
  description:
      'Jump while spreading legs and raising arms overhead, then return to start.',
  isDefault: true,
  categoryKey: 'cardio',
  targetMuscleKey: 'fullbody',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, durationSeconds: 30),
    ExerciseLevel(level: Level.intermediate, durationSeconds: 45),
    ExerciseLevel(level: Level.advanced, durationSeconds: 60),
  ],
  equipment: 'bodyweight',
  tags: ['cardio', 'full body'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise deadBug = Exercise(
  uuid: 'ex-deadbug-001',
  name: 'Dead Bug',
  description:
      'Lie on back, extend opposite arm and leg while keeping lower back pressed to floor.',
  isDefault: true,
  categoryKey: 'core',
  targetMuscleKey: 'core',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, reps: 8),
    ExerciseLevel(level: Level.intermediate, reps: 12),
    ExerciseLevel(level: Level.advanced, reps: 16),
  ],
  equipment: 'bodyweight',
  tags: ['core', 'stability'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise bicepCurls = Exercise(
  uuid: 'ex-bicepcurls-001',
  name: 'Bicep Curls',
  description:
      'Curl dumbbells from sides to shoulders while keeping elbows tucked.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'arms',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 10, weightKg: 5),
    ExerciseLevel(level: Level.intermediate, sets: 3, reps: 12, weightKg: 8),
    ExerciseLevel(level: Level.advanced, sets: 4, reps: 12, weightKg: 10),
  ],
  equipment: 'dumbbells',
  tags: ['arms', 'isolation'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise highKneeMarch = Exercise(
  uuid: 'ex-highkneemarch-001',
  name: 'Gentle High-Knee March',
  description:
      'March in place lifting knees to hip height. Keep core engaged and back straight.',
  isDefault: true,
  categoryKey: 'core',
  targetMuscleKey: 'legs',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 20),
    ExerciseLevel(level: Level.intermediate, sets: 3, reps: 30),
    ExerciseLevel(level: Level.advanced, sets: 4, reps: 40),
  ],
  equipment: 'bodyweight',
  tags: ['core', 'cardio', 'march'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise gluteBridge = Exercise(
  uuid: 'ex-glutebridge-001',
  name: 'Glute Bridge',
  description:
      'Lie on back with knees bent, lift hips toward ceiling, squeeze glutes at the top.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'legs',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 15),
    ExerciseLevel(level: Level.intermediate, sets: 3, reps: 20),
    ExerciseLevel(level: Level.advanced, sets: 4, reps: 25),
  ],
  equipment: 'bodyweight',
  tags: ['lower body', 'glutes', 'core'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise birdDog = Exercise(
  uuid: 'ex-birddog-001',
  name: 'Bird Dog',
  description:
      'From all fours, extend opposite arm and leg, hold for 2 seconds, return. Alternate sides.',
  isDefault: true,
  categoryKey: 'core',
  targetMuscleKey: 'core',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 10),
    ExerciseLevel(level: Level.intermediate, sets: 3, reps: 14),
    ExerciseLevel(level: Level.advanced, sets: 4, reps: 18),
  ],
  equipment: 'bodyweight',
  tags: ['core', 'stability', 'coordination'],
  createdAt: DateTime(2025, 1, 1),
);

final Exercise sideLyingLegRaise = Exercise(
  uuid: 'ex-sidelyinglegraise-001',
  name: 'Side-Lying Leg Raise',
  description:
      'Lie on side, lift top leg keeping hips stacked and core engaged. Lower slowly.',
  isDefault: true,
  categoryKey: 'strength',
  targetMuscleKey: 'legs',
  recommendedLevel: Level.beginner,
  levels: [
    ExerciseLevel(level: Level.beginner, sets: 3, reps: 12),
    ExerciseLevel(level: Level.intermediate, sets: 3, reps: 16),
    ExerciseLevel(level: Level.advanced, sets: 4, reps: 20),
  ],
  equipment: 'bodyweight',
  tags: ['lower body', 'glutes', 'hips'],
  createdAt: DateTime(2025, 1, 1),
);

/// Built-in exercise catalog shipped with the app.
/// `restExercise` is intentionally excluded: rest is modelled as absence
/// (see `PlanDay.isRest`), not as a fake exercise.
final List<Exercise> defaultExercises = <Exercise>[
  plank,
  cocoons,
  pushUps,
  squats,
  overheadPress,
  jumpingJacks,
  deadBug,
  bicepCurls,
  highKneeMarch,
  gluteBridge,
  birdDog,
  sideLyingLegRaise,
];
