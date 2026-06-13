import 'dart:convert';
import 'unlocked_achievement.dart';
import 'achievement_progress_snapshot.dart';

class AchievementState {
  final int schemaVersion;
  final DateTime lastUpdatedAt;
  final String? migratedFrom;
  final List<UnlockedAchievement> unlocked;
  final Map<String, AchievementProgressSnapshot> progress;

  const AchievementState({
    this.schemaVersion = 1,
    required this.lastUpdatedAt,
    this.migratedFrom,
    this.unlocked = const [],
    this.progress = const {},
  });

  bool isUnlocked(String id) =>
      unlocked.any((u) => u.achievementId == id);

  DateTime? unlockedAt(String id) {
    final idx = unlocked.indexWhere((u) => u.achievementId == id);
    return idx >= 0 ? unlocked[idx].unlockedAt : null;
  }

  AchievementProgressSnapshot? progressFor(String id) => progress[id];

  Set<String> get unlockedIds =>
      unlocked.map((u) => u.achievementId).toSet();

  static const int _currentVersion = 1;

  Map<String, dynamic> toJson() => {
    'schemaVersion': _currentVersion,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    if (migratedFrom != null) 'migratedFrom': migratedFrom,
    'unlocked': unlocked.map((u) => u.toJson()).toList(),
    'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory AchievementState.fromJson(Map<String, dynamic> json) {
    final unlockedRaw = json['unlocked'] as List<dynamic>? ?? [];
    final progressRaw = json['progress'] as Map<String, dynamic>? ?? {};

    return AchievementState(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : DateTime.now(),
      migratedFrom: json['migratedFrom'] as String?,
      unlocked: unlockedRaw
          .map((e) => UnlockedAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: progressRaw.map((k, v) => MapEntry(
            k,
            AchievementProgressSnapshot.fromJson(v as Map<String, dynamic>),
          )),
    );
  }

  factory AchievementState.empty() => AchievementState(
        lastUpdatedAt: DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory AchievementState.fromJsonString(String raw) =>
      AchievementState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
