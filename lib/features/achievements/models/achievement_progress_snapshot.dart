class AchievementProgressSnapshot {
  final int current;
  final int target;
  final DateTime updatedAt;

  const AchievementProgressSnapshot({
    required this.current,
    required this.target,
    required this.updatedAt,
  });

  double get fraction => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => current >= target;

  String get display => '$current / $target';

  Map<String, dynamic> toJson() => {
    'current': current,
    'target': target,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AchievementProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      AchievementProgressSnapshot(
        current: json['current'] as int,
        target: json['target'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
